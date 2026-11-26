import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/paged_fetch.dart';
import '../../../sales/data/models/sale_model.dart';
import '../models/return_model.dart';
import '../repos/returns_repo.dart';
import 'package:hesba/core/services/shop_id_resolver.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

class ReturnsRepoImpl implements ReturnsRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ReturnsRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) => resolveCachedShopId(
        firestore: firestore,
        auth: auth,
        provided: providedShopId,
      );

  Future<String?> _resolveOwnerId(String? providedOwnerId) async {
    if (providedOwnerId != null && providedOwnerId.isNotEmpty) return providedOwnerId;
    return _uid;
  }

  @override
  Future<ReturnModel> addReturn({
    required String ownerId,
    required String shopId,
    String? originalSaleId,
    required List<ReturnItemModel> items,
    required String reason,
    required String note,
    String? requestId,
  }) async {
    if (items.isEmpty) throw Exception('يجب إضافة منتج واحد على الأقل'.tr());
    if (originalSaleId == null || originalSaleId.isEmpty) {
      throw Exception('يجب اختيار فاتورة للمرتجع'.tr());
    }
    if (reason.trim().isEmpty) throw Exception('اختر سبب المرتجع'.tr());

    // Idempotency: a retry after a lost response must not restore stock or
    // settle the debt a second time. Return the original return document.
    if (requestId != null) {
      final existing =
          await firestore.collection(AppConstants.returnsCollection).doc(requestId).get();
      if (existing.exists && existing.data() != null) {
        return ReturnModel.fromJson(existing.data()!);
      }
    }

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر'.tr());
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً'.tr());
    }

    for (final item in items) {
      if (item.productName.trim().isEmpty) throw Exception('اسم المنتج مطلوب'.tr());
      if (item.quantity <= 0) throw Exception(uiTr('الكمية يجب أن تكون أكبر من صفر: ${item.productName}'));
      if (item.unitPrice < 0) throw Exception(uiTr('السعر غير صحيح: ${item.productName}'));
    }

    // Validate against original sale and already returned quantities
    final saleDoc = await firestore.collection(AppConstants.salesCollection).doc(originalSaleId).get();
    if (!saleDoc.exists) throw Exception('الفاتورة الأصلية غير موجودة'.tr());
    final saleData = saleDoc.data()!;
    if (saleData['shopId'] != resolvedShopId) throw Exception('الفاتورة لا تتبع نفس المتجر'.tr());
    final saleItems = (saleData['items'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Map of productId/index -> sold quantity
    final soldQtyByKey = <String, double>{};
    for (int i = 0; i < saleItems.length; i++) {
      final it = saleItems[i];
      final pid = it['productId'] as String? ?? '';
      final qty = (it['quantity'] as num?)?.toDouble() ?? 0;
      final name = it['productName'] as String? ?? '';
      // نفس المنتج قد يظهر في أكثر من سطر بالفاتورة: يجب الجمع، لا الاستبدال
      // بآخر سطر — وإلا تُحسب الكمية القابلة للإرجاع أقل من المباعة فعلياً
      // (فيُرفض مرتجع كامل قانوني) وتختل مطابقة التكلفة في التقارير.
      if (pid.isNotEmpty) {
        soldQtyByKey[pid] = (soldQtyByKey[pid] ?? 0) + qty;
      }
      soldQtyByKey['idx::$i'] = qty;
      if (name.isNotEmpty) {
        soldQtyByKey['name::$name'] = (soldQtyByKey['name::$name'] ?? 0) + qty;
      }
    }

    // Scoped by shopId: Firestore rules only allow reads that prove
    // ownerId/shopId ownership, so an originalSaleId-only query is
    // rejected with permission-denied.
    final alreadySnap = await firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: resolvedShopId)
        .where('originalSaleId', isEqualTo: originalSaleId)
        .get();
    final returnedQtyByKey = <String, double>{};
    for (final doc in alreadySnap.docs) {
      final rItems = (doc.data()['items'] as List<dynamic>? ?? []);
      for (final r in rItems) {
        final rit = Map<String, dynamic>.from(r);
        final pid = rit['productId'] as String? ?? '';
        final qty = (rit['quantity'] as num?)?.toDouble() ?? 0;
        final name = rit['productName'] as String? ?? '';
        if (pid.isNotEmpty) returnedQtyByKey[pid] = (returnedQtyByKey[pid] ?? 0) + qty;
        if (name.isNotEmpty) returnedQtyByKey['name::$name'] = (returnedQtyByKey['name::$name'] ?? 0) + qty;
      }
    }

    for (final item in items) {
      // Find matching sold qty
      double soldQty = 0;
      if (item.productId.isNotEmpty && soldQtyByKey.containsKey(item.productId)) {
        soldQty = soldQtyByKey[item.productId]!;
      } else if (soldQtyByKey.containsKey('name::${item.productName}')) {
        soldQty = soldQtyByKey['name::${item.productName}']!;
      } else {
        throw Exception(uiTr('المنتج ${item.productName} غير موجود في الفاتورة الأصلية'));
      }
      final already = item.productId.isNotEmpty
          ? (returnedQtyByKey[item.productId] ?? 0)
          : (returnedQtyByKey['name::${item.productName}'] ?? 0);
      final available = soldQty - already;
      if (item.quantity > available + 0.001) {
        throw Exception(uiTr('الكمية للإرجاع أكبر من المتاح لـ ${item.productName} (المتاح: $available، المباع: $soldQty، المرجع سابقاً: $already)'));
      }
      // Ensure unitPrice matches original (preserve discount)
      double originalPrice = 0;
      for (final si in saleItems) {
        if ((si['productId'] as String? ?? '') == item.productId ||
            (si['productName'] as String? ?? '') == item.productName) {
          originalPrice = (si['unitPrice'] as num?)?.toDouble() ?? 0;
          break;
        }
      }
      if ((item.unitPrice - originalPrice).abs() > 0.01) {
        throw Exception(uiTr('سعر المنتج ${item.productName} يجب أن يكون نفس سعر البيع الأصلي (${originalPrice.toStringAsFixed(2)} ج.م)'));
      }
    }

    final grossSubtotal = items.fold<double>(0, (acc, e) => acc + e.total);

    // Smart discount allocation: refund only the net paid amount proportionally
    final saleSubtotal = (saleData['subtotal'] as num?)?.toDouble() ?? grossSubtotal;
    final saleDiscount = (saleData['discount'] as num?)?.toDouble() ?? 0;
    final double discountRatio = saleSubtotal > 0 ? (saleDiscount / saleSubtotal).clamp(0.0, 1.0).toDouble() : 0.0;

    double allocatedDiscount = 0;
    for (final item in items) {
      allocatedDiscount += item.total * discountRatio;
    }
    // Round to 2 decimals for currency
    allocatedDiscount = double.parse(allocatedDiscount.toStringAsFixed(2));
    final netTotal = double.parse((grossSubtotal - allocatedDiscount).clamp(0, grossSubtotal).toStringAsFixed(2));

    // لقطة العميل من فاتورة البيع — تسهّل البحث باسم/رقم العميل في قائمة المرتجعات.
    final personId = (saleData['personId'] as String?)?.trim() ?? '';
    final personName = (saleData['personName'] as String?)?.trim() ?? '';
    final personPhone = (saleData['personPhone'] as String?)?.trim() ?? '';

    final ref = requestId == null
        ? firestore.collection(AppConstants.returnsCollection).doc()
        : firestore.collection(AppConstants.returnsCollection).doc(requestId);

    final ret = ReturnModel(
      returnId: ref.id,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      originalSaleId: originalSaleId,
      items: items,
      subtotal: grossSubtotal,
      discount: allocatedDiscount,
      total: netTotal,
      reason: reason.trim(),
      note: note.trim(),
      personId: personId,
      personName: personName,
      personPhone: personPhone,
      createdAt: DateTime.now(),
    );

    // ذمة آجل مرتبطة بهذه الفاتورة؟ (الذمة بتتكتب صحبة البيع، وبتشير
    // للفاتورة عبر saleId) — المرتجع هيقللها بمبلغ المرتجع الصافي.
    String? linkedDebtId;
    if (originalSaleId.isNotEmpty) {
      final dSnap = await firestore
          .collection(AppConstants.debtsCollection)
          .where('shopId', isEqualTo: resolvedShopId)
          .where('saleId', isEqualTo: originalSaleId)
          .limit(5)
          .get();
      if (dSnap.docs.isNotEmpty) linkedDebtId = dSnap.docs.first.id;
    }
    final linkedDebtRef = linkedDebtId == null
        ? null
        : firestore.collection(AppConstants.debtsCollection).doc(linkedDebtId);

    ReturnModel? alreadyWritten;
    await firestore.runTransaction((transaction) async {
      // Guard against a concurrent retry with the same id.
      if (requestId != null) {
        final existing = await transaction.get(ref);
        if (existing.exists && existing.data() != null) {
          alreadyWritten = ReturnModel.fromJson(existing.data()!);
          return;
        }
      }
      // كل القراءات أولًا (منتجات + الذمة لو موجودة) — ثم أي كتابة.
      final productReads = <String, Map<String, dynamic>>{};
      for (final item in items) {
        if (item.productId.isEmpty) continue;
        final productRef =
            firestore.collection(AppConstants.productsCollection).doc(item.productId);
        final snap = await transaction.get(productRef);
        if (snap.exists) productReads[item.productId] = snap.data()!;
      }

      var debtAmount = 0.0;
      var debtPaid = 0.0;
      var debtExists = false;
      if (linkedDebtRef != null) {
        final snap = await transaction.get(linkedDebtRef);
        final data = snap.data();
        if (snap.exists && data != null && data['shopId'] == resolvedShopId) {
          debtExists = true;
          debtAmount = (data['amount'] as num?)?.toDouble() ?? 0;
          debtPaid = (data['paidAmount'] as num?)?.toDouble() ?? 0;
        }
      }

      // استرجاع المخزون.
      for (final item in items) {
        if (item.productId.isEmpty) continue;
        final data = productReads[item.productId];
        if (data == null) continue;
        final currentStock = (data['stock'] as num?)?.toDouble() ?? 0;
        transaction.update(
          firestore.collection(AppConstants.productsCollection).doc(item.productId),
          {
            'stock': currentStock + item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
      transaction.set(ref, ret.toJson());

      // تسوية الذمة (إن وُجدت): المرتجع يُسجَّل كـ "دفعة تسوية" لا تتجاوز
      // المتبقي — فالفاتورة الآجلة والمديونية بيصاحوا بعض تلقائيًا.
      if (debtExists && linkedDebtRef != null) {
        final remaining = debtAmount - debtPaid;
        var adj = ret.total;
        if (adj > remaining) adj = remaining;
        adj = double.parse(adj.toStringAsFixed(2));
        if (adj > 0.005) {
          final invoiceShort = originalSaleId.length >= 6
              ? originalSaleId.substring(0, 6)
              : originalSaleId;
          final paymentRef =
              linkedDebtRef.collection(AppConstants.debtPaymentsSubCollection).doc();
          transaction.set(paymentRef, {
            'id': paymentRef.id,
            'ownerId': resolvedOwnerId,
            'shopId': resolvedShopId,
            'amount': adj,
            'note': uiTr('تسوية مرتجع — فاتورة #$invoiceShort'),
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(linkedDebtRef, {
            'paidAmount': FieldValue.increment(adj),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    return alreadyWritten ?? ret;
  }

  @override
  Future<List<ReturnModel>> getReturns({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) return [];
    final snap = await firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: resolvedShopId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    return snap.docs.map((d) => ReturnModel.fromJson(d.data())).toList();
  }

  /// id محل اليوزر الحالي.
  @override
  Future<String?> getShopId() => _resolveShopId(null);

  @override
  Stream<List<ReturnModel>> watchReturns({required String shopId}) {
    return firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReturnModel.fromJson(d.data())).toList());
  }

  @override
  Future<PagedResult<ReturnModel>> fetchAllReturns({
    required String shopId,
    DateTime? from,
  }) {
    return fetchAllPages<ReturnModel>(
      idOf: (ret) => ret.returnId,
      fetchPage: (cursor) async {
        Query<Map<String, dynamic>> query = firestore
            .collection(AppConstants.returnsCollection)
            .where('shopId', isEqualTo: shopId);
        if (from != null) {
          query = query.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
          );
        }
        query = query
            .orderBy('createdAt', descending: true)
            .limit(kReportPageSize);
        if (cursor != null) {
          query = query
              .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>);
        }
        final snap = await query.get();
        return PageResult<ReturnModel>(
          items: snap.docs.map((d) => ReturnModel.fromJson(d.data())).toList(),
          cursor: snap.docs.isEmpty ? null : snap.docs.last,
          hasMore: snap.docs.length >= kReportPageSize,
        );
      },
    );
  }

  @override
  Stream<List<SaleModel>> watchShopSales({required String shopId}) {
    return firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SaleModel.fromJson(d.data())).toList());
  }

  @override
  Future<Map<String, double>> getAlreadyReturnedQuantities(
      String saleId) async {
    // The returns read rules require the query to be provably scoped to
    // the caller's shop/owner. Filtering by originalSaleId alone makes
    // Firestore answer permission-denied, which surfaced as
    // _historyFailed in the add-return screen.
    final shopId = await _resolveShopId(null);
    if (shopId == null || shopId.isEmpty) return <String, double>{};
    final snap = await firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: shopId)
        .where('originalSaleId', isEqualTo: saleId)
        .get();
    final map = <String, double>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final items = (data['items'] as List<dynamic>? ?? []);
      for (int i = 0; i < items.length; i++) {
        final it = Map<String, dynamic>.from(items[i]);
        final pid = it['productId'] as String? ?? '';
        final qty = (it['quantity'] as num?)?.toDouble() ?? 0;
        if (pid.isNotEmpty) {
          map[pid] = (map[pid] ?? 0) + qty;
        } else {
          final key = '::$i';
          map[key] = (map[key] ?? 0) + qty;
        }
        final pname = it['productName'] as String? ?? '';
        if (pname.isNotEmpty) {
          map['name::$pname'] = (map['name::$pname'] ?? 0) + qty;
        }
      }
    }
    return map;
  }
}
