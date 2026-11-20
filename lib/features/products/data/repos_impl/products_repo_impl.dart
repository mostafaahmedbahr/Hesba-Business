import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/search_tokens.dart';
import '../repos/products_repo.dart';
import 'package:hesba/core/services/shop_id_resolver.dart';

class ProductsRepoImpl implements ProductsRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProductsRepoImpl({required this._auth, required this._firestore});

  String? get _uid => _auth.currentUser?.uid;

  Future<String?> _getShopId() =>
      resolveCachedShopId(firestore: _firestore, auth: _auth);

  @override
  Stream<List<Product>> watchProducts() {
    if (_uid == null) {
      return const Stream.empty();
    }
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null) yield const <Product>[];
      await for (final snap
          in _firestore
              .collection(AppConstants.productsCollection)
              .where('shopId', isEqualTo: shopId)
              .orderBy('createdAt', descending: true)
              .limit(500)
              .snapshots()) {
        yield snap.docs
            .map((doc) => Product.fromJson(doc.data(), docId: doc.id))
            .toList();
      }
    }();
  }

  @override
  Future<String?> getShopBusinessType() async {
    final shopId = await _getShopId();
    if (shopId == null) return null;
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (!doc.exists) return null;
    return doc.data()?['businessType'] as String?;
  }

  /// يتأكد إن معرّف المورد (لو موجود) تابع للمحل الحالي فعلاً —
  /// حتى لا يرتبط منتج بمورد محل آخر.
  Future<void> _assertSupplierInShop(String? supplierId, String shopId) async {
    if (supplierId == null || supplierId.isEmpty) return;
    final snap = await _firestore
        .collection(AppConstants.suppliersCollection)
        .doc(supplierId)
        .get();
    final data = snap.data();
    if (!snap.exists || data == null || data['shopId'] != shopId) {
      throw Exception('supplierErrNotAuthorized');
    }
  }

  @override
  Future<void> addProduct(Product product) async {
    final shopId = await _getShopId();
    // Never silently no-op: the caller would show success for a write that
    // never happened. Surface a mapped error instead.
    if (shopId == null) throw StateError('shop-not-resolved');
    await _assertSupplierInShop(product.supplierId, shopId);
    final ref = _firestore.collection(AppConstants.productsCollection).doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      ...product.toJson(),
      'searchTokens': SearchTokens.product(product.name),
      'id': ref.id,
      'shopId': shopId,
      'ownerId': _uid,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _assertOwnership(String productId) async {
    final shopId = await _getShopId();
    if (shopId == null) throw Exception('لم يتم العثور على المتجر');
    final snap = await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .get();
    final data = snap.data();
    if (!snap.exists || data == null) throw Exception('المنتج غير موجود');
    if (data['shopId'] != shopId || (data['ownerId'] as String?) != _uid) {
      throw Exception('غير مصرح بتعديل هذا المنتج');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (product.id.isEmpty) throw StateError('invalid-id');
    await _assertOwnership(product.id);
    final shopId = await _getShopId();
    if (shopId == null) throw Exception('لم يتم العثور على المتجر');
    await _assertSupplierInShop(product.supplierId, shopId);
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update({
          ...product.toJson(),
          'searchTokens': SearchTokens.product(product.name),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (productId.isEmpty) throw StateError('invalid-id');
    await _assertOwnership(productId);
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }
}
