import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_profile.dart';
import '../repos/account_repo.dart';
import 'package:hesba/core/services/app_logger.dart';

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
    double? latitude,
    double? longitude,
    String locationAddress = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('auth/user-not-logged-in');
    }
    final userRef = _firestore.collection('users').doc(uid);

    final locationFields = <String, dynamic>{
      'locationUrl': locationUrl.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress.trim(),
    };

    // Both documents in ONE transaction: a failure can no longer leave the
    // user profile updated while the shop mirror keeps the old name.
    await _firestore.runTransaction((txn) async {
      final userSnap = await txn.get(userRef);
      final shopId = userSnap.data()?['shopId'] as String?;

      txn.update(userRef, {
        'ownerName': ownerName.trim(),
        'phone': phone.trim(),
        'shopName': shopName.trim(),
        'businessType': businessType.trim(),
        'shopPhone': shopPhone.trim(),
        'address': address.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'shopImageUrl': shopImageUrl.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...locationFields,
      });

      if (shopId != null && shopId.isNotEmpty) {
        txn.update(_firestore.collection('shops').doc(shopId), {
          'shopName': shopName.trim(),
          'businessType': businessType.trim(),
          'shopPhone': shopPhone.trim(),
          'address': address.trim(),
          'state': state.trim(),
          'city': city.trim(),
          'shopImageUrl': shopImageUrl.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          ...locationFields,
        });
      }
    });
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
  Future<void> requestAccountDeletion({
    required String currentPassword,
    String reason = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('auth/user-not-logged-in');
    }
    final uid = user.uid;
    // Re-authenticate: deletion requests must come from a verified session.
    final credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    final snap = await _firestore.collection('users').doc(uid).get();
    final data = snap.data() ?? const {};
    await _firestore.collection('account_deletion_requests').add({
      'userId': uid,
      'ownerName': data['ownerName'] ?? '',
      'shopName': data['shopName'] ?? '',
      'shopId': data['shopId'] ?? '',
      'email': user.email ?? data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'reason': reason.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> logout() async {
    // Drop the device token first so the next account on this device does
    // not receive the previous owner's pushes. Best effort only.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (logErr, logSt) { AppLogger.nonFatal('features/profile/data/repos_impl/account_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning); }
    await _auth.signOut();
  }

  @override
  Future<bool?> getStaffActiveState(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      return doc.data()?['isActive'] as bool? ?? true;
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/profile/data/repos_impl/account_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning);
      return null;
    }
  }
}
