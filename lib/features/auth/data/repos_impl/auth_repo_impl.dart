import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/register_model.dart';
import '../repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepoImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : firebaseAuth =
      firebaseAuth ?? FirebaseAuth.instance,
        firestore =
            firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
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
      shopImageUrl: model.shopImageUrl.trim(),
      address: model.address.trim(),
      city: model.city.trim(),
      state: model.state.trim(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    // 4. Save owner data
    await firestore
        .collection('users')
        .doc(user.uid)
        .set(registerModel.toJson());

    // 5. Save shop data
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

    return registerModel;
  }
}