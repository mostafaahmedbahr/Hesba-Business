import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hesba/core/constants/app_constants.dart';
import 'package:hesba/features/auth/data/repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<dynamic> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String shopName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final shopRef = await _firestore
          .collection(AppConstants.shopsCollection)
          .add({
        'name': shopName,
        'ownerUid': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'shopId': shopRef.id,
        'role': AppConstants.roleOwner,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
