import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../repos/account_repo.dart';

class AccountRepoImpl implements AccountRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountRepoImpl({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  @override
  String? currentUserId() => _auth.currentUser?.uid;

  @override
  Stream<UserProfile?> watchProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromJson(snap.data() ?? {});
    });
  }

  @override
  Future<UserProfile?> getProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromJson(snap.data() ?? {});
  }

  @override
  Future<void> updateProfile({
    required String ownerName,
    required String phone,
    required String shopName,
    required String businessType,
    required String shopPhone,
    required String address,
    required String state,
    required String city,
    required String locationUrl,
    required String shopImageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('auth/user-not-logged-in');
    }
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final shopId = userSnap.data()?['shopId'] as String?;

    // Owner fields -> users doc (also mirrors shop fields for the profile view).
    await userRef.update({
      'ownerName': ownerName.trim(),
      'phone': phone.trim(),
      'shopName': shopName.trim(),
      'businessType': businessType.trim(),
      'shopPhone': shopPhone.trim(),
      'address': address.trim(),
      'state': state.trim(),
      'city': city.trim(),
      'locationUrl': locationUrl.trim(),
      'shopImageUrl': shopImageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Shop fields -> shops doc (single source for shop features).
    if (shopId != null && shopId.isNotEmpty) {
      await _firestore.collection('shops').doc(shopId).update({
        'shopName': shopName.trim(),
        'businessType': businessType.trim(),
        'shopPhone': shopPhone.trim(),
        'address': address.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'locationUrl': locationUrl.trim(),
        'shopImageUrl': shopImageUrl.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('auth/user-not-logged-in');
    }

    // Re-authenticate with current password before changing it.
    final credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}
