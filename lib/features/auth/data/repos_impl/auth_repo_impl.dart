import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../subscription/data/repos/subscription_repo.dart';
import '../models/register_model.dart';
import '../repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SubscriptionRepo? subscriptionRepo;

  AuthRepoImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    this.subscriptionRepo,
  })  : firebaseAuth =
      firebaseAuth ?? FirebaseAuth.instance,
        firestore =
            firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<RegisterModel> register({
    required RegisterModel model,
    required String password,
  }) async {
    // 1. Create Firebase Authentication account
    final credential =
    await firebaseAuth.createUserWithEmailAndPassword(
      email: model.email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('فشل إنشاء الحساب');
    }

    // 2. Generate shop ID
    final shopRef =
    firestore.collection('shops').doc();

    final now = DateTime.now();

    // 3. Create final model
    final registerModel = RegisterModel(
      ownerId: user.uid,
      shopId: shopRef.id,
      ownerName: model.ownerName.trim(),
      email: model.email.trim(),
      phone: model.phone.trim(),
      shopName: model.shopName.trim(),
      businessType: model.businessType.trim(),
      shopPhone: model.shopPhone.trim(),
      locationUrl: model.locationUrl.trim(),
      latitude: model.latitude,
      longitude: model.longitude,
      locationAddress: model.locationAddress.trim(),
      shopImageUrl: model.shopImageUrl.trim(),
      address: model.address.trim(),
      city: model.city.trim(),
      state: model.state.trim(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    // 4. Save owner data. Any Firestore failure below rolls the freshly
    // created Auth account back, so we never leave an orphan login with
    // no / incomplete profile documents.
    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .set(_ownerJson(registerModel));
    } catch (e) {
      await _rollbackAccount(user);
      rethrow;
    }

    // 4b. Hand out the free trial. Best effort: the first read of the
    // subscription still creates it, so registration never fails because of it.
    try {
      await subscriptionRepo?.startTrialForNewUser(
        userId: user.uid,
        createdAt: now,
      );
    } catch (e) {
      logWarning('[AuthRepoImpl] trial could not be created now: $e');
    }

    // 5. Save shop data (same rollback guarantee as the owner doc).
    try {
      await shopRef.set({
        'shopId': shopRef.id,
        'ownerId': user.uid,
        'shopName': registerModel.shopName,
        'businessType': registerModel.businessType,
        'shopPhone': registerModel.shopPhone,
        'locationUrl': registerModel.locationUrl,
        'latitude': registerModel.latitude,
        'longitude': registerModel.longitude,
        'locationAddress': registerModel.locationAddress,
        'shopImageUrl': registerModel.shopImageUrl,
        'address': registerModel.address,
        'city': registerModel.city,
        'state': registerModel.state,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isActive': true,
      });
    } catch (e) {
      await _rollbackAccount(user);
      rethrow;
    }

    return registerModel;
  }

  /// Owner doc payload with Firestore-native date types (Timestamp, not raw
  /// DateTime) so sorting/filtering matches the shops collection.
  Map<String, dynamic> _ownerJson(RegisterModel m) {
    final json = m.toJson();
    json['createdAt'] = Timestamp.fromDate(m.createdAt);
    json['updatedAt'] = Timestamp.fromDate(m.updatedAt);
    return json;
  }

  /// Best-effort rollback of a half-registered account.
  Future<void> _rollbackAccount(User user) async {
    try {
      await firestore.collection('users').doc(user.uid).delete();
    } catch (_) {}
    try {
      await user.delete();
    } catch (e) {
      logWarning('[AuthRepoImpl] rollback incomplete (manual cleanup needed): $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    logSuccess('[AuthRepoImpl] sending password reset email');
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    logSuccess('[AuthRepoImpl] password reset email sent');
  }
}