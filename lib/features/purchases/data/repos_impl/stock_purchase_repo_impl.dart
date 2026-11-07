import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/stock_movement_model.dart';
import '../models/stock_purchase_model.dart';
import '../repos/stock_purchase_repo.dart';
import '../stock_purchase_calculator.dart';

class StockPurchaseRepoImpl implements StockPurchaseRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  StockPurchaseRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String providedShopId) async {
    if (providedShopId.trim().isNotEmpty) return providedShopId.trim();
    final uid = _uid;
    if (uid == null) return null;
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<String?> _resolveOwnerId(String providedOwnerId) async {
    if (providedOwnerId.trim().isNotEmpty) return providedOwnerId.trim();
    return _uid;
  }

  @override
  String generatePurchaseId() =>
      firestore.collection(AppConstants.stockPurchasesCollection).doc().id;

  @override
  Future<StockPurchase> addPurchase({
    required String purchaseId,
    required String ownerId,
    required String shopId,
    String supplierName = '',
    String supplierPhone = '',
    String invoiceNumber = '',
    required DateTime purchaseDate,
    String notes = '',
    required List<PurchaseLineInput> lines,
  }) async {
    if (purchaseId.trim().isEmpty) {
      throw Exception('معرّف الفاتورة مطلوب');
    }
    if (lines.isEmpty) {
      throw Exception('يجب إضافة منتج واحد على الأقل');
    }

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);
    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // ── حماية من التكرار (قبل المعاملة) ──────────────────────
    // لو العملية السابقة نجحت فعلاً والرد ضاع (أو إعادة محاولة بنفس
    // purchaseId)، الفاتورة موجودة بالفعل → نرفض قبل أي كتابة.
    // (الاستعلام محصور بمحل المستخدم — مسموح حسب قواعد القراءة.)
    final existing = await firestore
        .collection(AppConstants.stockPurchasesCollection)
        .where('purchaseId', isEqualTo: purchaseId)
        .where('shopId', isEqualTo: resolvedShopId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('الفاتورة محفوظة مسبقاً — لم يتم تكرارها');
    }

    final purchaseRef = firestore
        .collection(AppConstants.stockPurchasesCollection)
        .doc(purchaseId);

    // مراجع الحركات تُنشأ قبل المعاملة حتى تبقى ثابتة لو أُعيد المحاولة.
    final movementRefs = [
      for (final _ in lines)
        firestore.collection(AppConstants.stockMovementsCollection).doc(),
    ];

    StockPurchase? saved;
    await firestore.runTransaction((transaction) async {
      // ── 1) كل القراءات أولاً: لقطات موثوقة لكل منتج ────────
      // (حماية التكرار الإضافية: set فوق فاتورة موجودة = update حسب
      // القواعد، وتحديث الفواتير للمسؤول فقط → المعاملة تفشل وترتد.)
      final snapshots = <String, ProductSnapshot>{};
      for (final line in lines) {
        if (snapshots.containsKey(line.productId)) continue;
        final snap = await transaction.get(
          firestore
              .collection(AppConstants.productsCollection)
              .doc(line.productId),
        );
        if (!snap.exists) {
          continue; // الـ calculator هيرفضها كمنتج ناقص.
        }
        final data = snap.data()!;
        snapshots[line.productId] = ProductSnapshot(
          id: line.productId,
          name: data['name'] as String? ?? '',
          shopId: data['shopId'] as String? ?? '',
          stock: (data['stock'] as num?)?.toDouble() ?? 0,
          costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0,
        );
      }

      // ── 2) الحساب كله من القيم الموثوقة (لا ثقة بالواجهة) ────
      // أي استثناء هنا يُفشل المعاملة كاملة بلا أي كتابة.
      final computed = StockPurchaseCalculator.compute(
        shopId: resolvedShopId,
        lines: lines,
        products: snapshots,
      );

      final now = DateTime.now();
      final purchase = StockPurchase(
        purchaseId: purchaseId,
        ownerId: resolvedOwnerId,
        shopId: resolvedShopId,
        supplierName: supplierName.trim(),
        supplierPhone: supplierPhone.trim(),
        invoiceNumber: invoiceNumber.trim(),
        purchaseDate: purchaseDate,
        totalAmount: computed.totalAmount,
        notes: notes.trim(),
        items: computed.items,
        createdAt: now,
      );

      // ── 3) الكتابة الذرّية: المنتجات + الفاتورة + الحركات ───
      for (final item in computed.items) {
        final update = computed.productUpdates[item.productId]!;
        transaction.update(
          firestore
              .collection(AppConstants.productsCollection)
              .doc(item.productId),
          {
            'stock': update.newStock,
            // نفس حقل costPrice الحالي — لا حقل تكلفة ثاني منافس.
            'costPrice': update.newAverageCost,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      transaction.set(purchaseRef, purchase.toJson());

      for (var i = 0; i < computed.items.length; i++) {
        final item = computed.items[i];
        transaction.set(
          movementRefs[i],
          StockMovement(
            movementId: movementRefs[i].id,
            shopId: resolvedShopId,
            ownerId: resolvedOwnerId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            previousStock: item.previousStock,
            newStock: item.newStock,
            unitCost: item.purchaseUnitCost,
            referenceId: purchaseId,
            createdAt: now,
          ).toJson(),
        );
      }

      saved = purchase;
    });

    return saved!;
  }
}
