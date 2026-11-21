import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/stock_purchase_item.dart';
import '../repos/stock_purchase_repo.dart';
import 'package:hesba/core/services/shop_id_resolver.dart';

class StockPurchaseRepoImpl implements StockPurchaseRepo {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StockPurchaseRepoImpl({required this._firestore, required this._auth});

  String? get _uid => _auth.currentUser?.uid;

  Future<Map<String, String?>> _resolveShop() async {
    final identity = await resolveCachedShopIdentity(
      firestore: _firestore,
      auth: _auth,
    );
    return {'shopId': identity.shopId, 'shopName': identity.shopName};
  }

  @override
  Future<String?> getShopId() async => (await _resolveShop())['shopId'];

  @override
  Future<String?> getShopName() async => (await _resolveShop())['shopName'];

  @override
  Future<void> addPurchase({
    required String ownerId,
    required String shopId,
    required String shopName,
    required List<StockPurchaseItem> items,
    required double totalAmount,
    required String note,
    required DateTime date,
  }) async {
    if (items.isEmpty) throw Exception('يجب إضافة صنف واحد على الأقل');
    for (final item in items) {
      if (item.quantity <= 0) throw Exception('الكمية غير صحيحة: ${item.productName}');
      if (item.unitCost < 0) throw Exception('التكلفة غير صحيحة: ${item.productName}');
    }

    final shop = await _resolveShop();
    final resolvedShopId = (shopId.isNotEmpty ? shopId : shop['shopId']);
    if (resolvedShopId == null || resolvedShopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    final resolvedOwnerId = ownerId.isNotEmpty ? ownerId : _uid;
    if (resolvedOwnerId == null || resolvedOwnerId.isEmpty) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final purchaseRef = _firestore.collection(AppConstants.stockPurchasesCollection).doc();

    await _firestore.runTransaction((tx) async {
      final movementRefs = <DocumentReference<Map<String, dynamic>>>[];
      final movementDocs = <Map<String, dynamic>>[];

      for (final item in items) {
        if (item.productId.isEmpty) continue;
        final productRef = _firestore
            .collection(AppConstants.productsCollection)
            .doc(item.productId);
        final snap = await tx.get(productRef);
        if (!snap.exists) throw Exception('المنتج غير موجود: ${item.productName}');
        final pData = snap.data()!;
        if (pData['shopId'] != resolvedShopId) {
          throw Exception('المنتج لا يتبع هذا المحل: ${item.productName}');
        }
        final previous = (pData['stock'] as num?)?.toDouble() ?? 0;
        final next = previous + item.quantity;
        tx.update(productRef, {
          'stock': next,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final mRef = _firestore.collection(AppConstants.stockMovementsCollection).doc();
        movementRefs.add(mRef);
        movementDocs.add({
          'id': mRef.id,
          'ownerId': resolvedOwnerId,
          'shopId': resolvedShopId,
          'productId': item.productId,
          'productName': item.productName,
          'movementType': 'purchase',
          'quantity': item.quantity,
          'previousStock': previous,
          'newStock': next,
          'purchaseId': purchaseRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      tx.set(purchaseRef, {
        'id': purchaseRef.id,
        'ownerId': resolvedOwnerId,
        'shopId': resolvedShopId,
        'shopName': shopName,
        'supplierId': '',
        'supplierName': '',
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'note': note.trim(),
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': resolvedOwnerId,
      });

      for (int i = 0; i < movementRefs.length; i++) {
        tx.set(movementRefs[i], movementDocs[i]);
      }
    });
  }
}
