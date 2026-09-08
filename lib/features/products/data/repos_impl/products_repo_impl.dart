import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/product.dart';
import '../repos/products_repo.dart';

class ProductsRepoImpl implements ProductsRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProductsRepoImpl({
    required this._auth,
    required this._firestore,
  });

  String? get _uid => _auth.currentUser?.uid;

  Future<String?> _getShopId() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data()?['shopId'] as String?;
  }

  @override
  Stream<List<Product>> watchProducts() {
    if (_uid == null) {
      return const Stream.empty();
    }
    return () async* {
      final shopId = await _getShopId();
      if (shopId == null) yield const <Product>[];
      await for (final snap in _firestore
          .collection(AppConstants.productsCollection)
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
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

  @override
  Future<void> addProduct(Product product) async {
    final shopId = await _getShopId();
    if (shopId == null) return;
    final ref = _firestore
        .collection(AppConstants.productsCollection)
        .doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      ...product.toJson(),
      'id': ref.id,
      'shopId': shopId,
      'ownerId': _uid,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (product.id.isEmpty) return;
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update({
      ...product.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (productId.isEmpty) return;
    await _firestore
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }
}