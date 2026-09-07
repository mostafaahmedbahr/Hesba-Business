import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repos/contact_repo.dart';

class ContactRepoImpl implements ContactRepo {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ContactRepoImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Future<String> submitFeedback({
    required String type,
    required String title,
    required String description,
  }) async {
    final ref = _firestore.collection('feedback').doc();
    final user = _auth.currentUser;

    await ref.set({
      'id': ref.id,
      'userId': user?.uid ?? '',
      'userEmail': user?.email ?? '',
      'type': type.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }
}