import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/auth/data/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Users
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  // Shops
  Future<String> createShop(Map<String, dynamic> data) async {
    final ref = await _firestore
        .collection(AppConstants.shopsCollection)
        .add(data);
    return ref.id;
  }

  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.shopsCollection)
        .doc(shopId)
        .update(data);
  }

  // Products
  Future<String> addProduct(String shopId, Map<String, dynamic> data) async {
    final ref = await _firestore
        .collection(AppConstants.shopsCollection)
        .doc(shopId)
        .collection(AppConstants.productsCollection)
        .add(data);
    return ref.id;
  }

  Stream<QuerySnapshot> getProducts(String shopId) {
    return _firestore
        .collection(AppConstants.shopsCollection)
        .doc(shopId)
        .collection(AppConstants.productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Sales
  Future<String> addSale(String shopId, Map<String, dynamic> data) async {
    final ref = await _firestore
        .collection(AppConstants.shopsCollection)
        .doc(shopId)
        .collection(AppConstants.salesCollection)
        .add(data);
    return ref.id;
  }

  Stream<QuerySnapshot> getSales(String shopId) {
    return _firestore
        .collection(AppConstants.shopsCollection)
        .doc(shopId)
        .collection(AppConstants.salesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
