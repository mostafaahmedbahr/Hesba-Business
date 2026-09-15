import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/sale_model.dart';
import '../repos/sales_repo.dart';

class SalesRepoImpl implements SalesRepo {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SalesRepoImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get _uid => auth.currentUser?.uid;

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) {
      return providedShopId;
    }
    if (_uid == null) return null;
    final doc = await firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  Future<String?> _resolveOwnerId(String? providedOwnerId) async {
    if (providedOwnerId != null && providedOwnerId.isNotEmpty) {
      return providedOwnerId;
    }
    return _uid;
  }

  @override
  Future<SaleModel> addSale({
    required String ownerId,
    required String shopId,
    required List<SaleItemModel> items,
    required double discount,
    required String paymentMethod,
    required String note,
  }) async {
    if (items.isEmpty) {
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

    // Validate items
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        throw Exception('اسم المنتج مطلوب');
      }
      if (item.quantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر: ${item.productName}');
      }
      if (item.unitPrice <= 0) {
        throw Exception('سعر المنتج يجب أن يكون أكبر من صفر: ${item.productName}');
      }
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final double finalDiscount = discount < 0 ? 0 : discount > subtotal ? subtotal : discount;
    final double total = subtotal - finalDiscount < 0 ? 0 : subtotal - finalDiscount;

    final saleRef = firestore.collection(AppConstants.salesCollection).doc();

    final sale = SaleModel(
      saleId: saleRef.id,
      ownerId: resolvedOwnerId,
      shopId: resolvedShopId,
      items: items,
      subtotal: subtotal,
      discount: finalDiscount.toDouble(),
      total: total,
      paymentMethod: paymentMethod,
      note: note.trim(),
      createdAt: DateTime.now(),
    );

    // Use transaction to ensure stock availability and decrement atomically
    await firestore.runTransaction((transaction) async {
      // Check stock for items that have productId
      for (final item in items) {
        if (item.productId.isNotEmpty) {
          final productRef = firestore
              .collection(AppConstants.productsCollection)
              .doc(item.productId);
          final snap = await transaction.get(productRef);
          if (!snap.exists) {
            throw Exception('المنتج غير موجود: ${item.productName}');
          }
          final data = snap.data()!;
          final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
          final isActive = data['isActive'] as bool? ?? true;
          if (!isActive) {
            throw Exception('المنتج غير متاح: ${item.productName}');
          }
          if (currentStock < item.quantity) {
            throw Exception(
                'الكمية المطلوبة غير متوفرة لـ ${item.productName} (المتاح: $currentStock)');
          }
          // Decrement stock
          transaction.update(productRef, {
            'stock': currentStock - item.quantity.toInt(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.set(saleRef, sale.toJson());
    });

    return sale;
  }

  @override
  Future<List<SaleModel>> getSales({required String shopId}) async {
    final resolvedShopId = await _resolveShopId(shopId);
    if (resolvedShopId == null) return [];
    final snap = await firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: resolvedShopId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => SaleModel.fromJson(d.data()))
        .toList();
  }

  @override
  Stream<List<SaleModel>> watchSales({required String shopId}) {
    return firestore
        .collection(AppConstants.salesCollection)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SaleModel.fromJson(d.data())).toList());
  }
}
