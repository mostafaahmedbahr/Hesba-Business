import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Single place that answers "who is the current owner, and what is
/// their shop?".
///
/// Replaces the copy-pasted `FirebaseAuth.instance.currentUser` +
/// `users/{uid}.shopId` lookups that used to live in every form view and
/// cubit — one implementation, one error policy (null on any failure).
class ShopResolver {
  ShopResolver({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get currentUid => _auth.currentUser?.uid;

  Future<String?> getShopId() async {
    final uid = currentUid;
    if (uid == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final shopId = doc.data()?['shopId'] as String?;
      return (shopId == null || shopId.isEmpty) ? null : shopId;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getShopBusinessType() async {
    try {
      final shopId = await getShopId();
      if (shopId == null) return null;
      final doc = await _firestore.collection('shops').doc(shopId).get();
      return doc.data()?['businessType'] as String?;
    } catch (_) {
      return null;
    }
  }
}
