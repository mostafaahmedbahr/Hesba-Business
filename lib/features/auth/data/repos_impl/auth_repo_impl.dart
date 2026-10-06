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
    print('[AuthRepoImpl] login() called with email: ${email.trim()}');
    try {
      print('[AuthRepoImpl] calling firebaseAuth.signInWithEmailAndPassword...');
      await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('[AuthRepoImpl] login success! User: ${firebaseAuth.currentUser?.uid}');
    } catch (e) {
      print('[AuthRepoImpl] login FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<RegisterModel> register({
    required RegisterModel model,
    required String password,
  }) async {
    print('[AuthRepoImpl] register() called with email: ${model.email}');
    // 1. Create Firebase Authentication account
    print('[AuthRepoImpl] creating Firebase Auth account...');
    final credential =
    await firebaseAuth.createUserWithEmailAndPassword(
      email: model.email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      print('[AuthRepoImpl] register FAILED: user is null after creation');
      throw Exception('فشل إنشاء الحساب');
    }
    print('[AuthRepoImpl] Firebase Auth account created. UID: ${user.uid}');

    // 2. Generate shop ID
    final shopRef =
    firestore.collection('shops').doc();
    print('[AuthRepoImpl] generated shopId: ${shopRef.id}');

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
    print('[AuthRepoImpl] saving owner data to users/${user.uid}...');
    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .set(_ownerJson(registerModel));
    } catch (e) {
      await _rollbackAccount(user);
      rethrow;
    }
    print('[AuthRepoImpl] owner data saved successfully');

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
    print('[AuthRepoImpl] saving shop data to shops/${shopRef.id}...');
    try {
      await shopRef.set({
        'shopId': shopRef.id,
        'ownerId': user.uid,
        'shopName': registerModel.shopName,
        'businessType': registerModel.businessType,
        'shopPhone': registerModel.shopPhone,
        'locationUrl': registerModel.locationUrl,
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
    print('[AuthRepoImpl] shop data saved successfully');

    print('[AuthRepoImpl] register() completed successfully');
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