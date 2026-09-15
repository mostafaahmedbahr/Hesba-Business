import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/return_model.dart';
import '../repos/returns_repo.dart';

class ReturnsRepoImpl implements ReturnsRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ReturnsRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) return providedShopId;
    if (_uid == null) return null;
    final doc = await firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

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
  }) async {
    if (items.isEmpty) throw Exception('يجب إضافة منتج واحد على الأقل');
    if (originalSaleId == null || originalSaleId.isEmpty) {
      throw Exception('يجب اختيار فاتورة للمرتجع');
    }
    if (reason.trim().isEmpty) throw Exception('اختر سبب المرتجع');

    final resolvedShopId = await _resolveShopId(shopId);
    final resolvedOwnerId = await _resolveOwnerId(ownerId);

    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    for (final item in items) {
      if (item.productName.trim().isEmpty) throw Exception('اسم المنتج مطلوب');
      if (item.quantity <= 0) throw Exception('الكمية يجب أن تكون أكبر من صفر: ${item.productName}');
      if (item.unitPrice < 0) throw Exception('السعر غير صحيح: ${item.productName}');
    }

    // Validate against original sale and already returned quantities
    final saleDoc = await firestore.collection(AppConstants.salesCollection).doc(originalSaleId).get();
    if (!saleDoc.exists) throw Exception('الفاتورة الأصلية غير موجودة');
    final saleData = saleDoc.data()!;
    if (saleData['shopId'] != resolvedShopId) throw Exception('الفاتورة لا تتبع نفس المتجر');
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
      if (pid.isNotEmpty) soldQtyByKey[pid] = qty;
      soldQtyByKey['idx::$i'] = qty;
      if (name.isNotEmpty) soldQtyByKey['name::$name'] = qty;
    }

    final alreadySnap = await firestore
        .collection(AppConstants.returnsCollection)
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
        throw Exception('المنتج ${item.productName} غير موجود في الفاتورة الأصلية');
      }
      final already = item.productId.isNotEmpty
          ? (returnedQtyByKey[item.productId] ?? 0)
          : (returnedQtyByKey['name::${item.productName}'] ?? 0);
      final available = soldQty - already;
      if (item.quantity > available + 0.001) {
        throw Exception('الكمية للإرجاع أكبر من المتاح لـ ${item.productName} (المتاح: $available، المباع: $soldQty، المرجع سابقاً: $already)');
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
        throw Exception('سعر المنتج ${item.productName} يجب أن يكون نفس سعر البيع الأصلي (${originalPrice.toStringAsFixed(2)} ج.م)');
      }
    }

    final grossSubtotal = items.fold<double>(0, (sum, e) => sum + e.total);

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

    final ref = firestore.collection(AppConstants.returnsCollection).doc();

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
      createdAt: DateTime.now(),
    );

    await firestore.runTransaction((transaction) async {
      for (final item in items) {
        if (item.productId.isNotEmpty) {
          final productRef = firestore.collection(AppConstants.productsCollection).doc(item.productId);
          final snap = await transaction.get(productRef);
          if (!snap.exists) {
            // If product not found, still allow return as manual item but skip stock update
            continue;
          }
          final data = snap.data()!;
          final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
          final newStock = currentStock + item.quantity.toInt();
          transaction.update(productRef, {
            'stock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      transaction.set(ref, ret.toJson());
    });

    return ret;
  }

  @override
  Future<List<ReturnModel>> getReturns({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) return [];
    final snap = await firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: resolvedShopId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ReturnModel.fromJson(d.data())).toList();
  }

  @override
  Stream<List<ReturnModel>> watchReturns({required String shopId}) {
    return firestore
        .collection(AppConstants.returnsCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReturnModel.fromJson(d.data())).toList());
  }
}
