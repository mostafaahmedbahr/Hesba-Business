import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/staff_model.dart';
import '../repos/staff_repo.dart';

/// إدارة الحسابات الفرعية. إنشاء حساب الموظف يتم عبر تطبيق Firebase
/// مؤقت حتى لا يتم تسجيل الدخول تلقائيًا بحساب الموظف ويُطرد صاحب المحل.
class StaffRepoImpl implements StaffRepo {
  static const String _tempAppName = 'hesba-staff-creation';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StaffRepoImpl({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Stream<List<StaffModel>> watchStaff() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('ownerId', isEqualTo: uid)
        .where('role', isEqualTo: AppConstants.roleStaff)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StaffModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  @override
  Future<void> addStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final ownerUid = _uid;
    if (ownerUid == null) throw Exception('يجب تسجيل الدخول أولاً');

    final ownerDoc =
        await _firestore.collection(AppConstants.usersCollection).doc(ownerUid).get();
    final data = ownerDoc.data();
    final shopId = data?['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }

    FirebaseApp? tempApp;
    try {
      tempApp = Firebase.apps.firstWhere((a) => a.name == _tempAppName);
    } catch (_) {
      tempApp = await Firebase.initializeApp(
        name: _tempAppName,
        options: Firebase.app().options,
      );
    }

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final staffUid = credential.user?.uid;
      if (staffUid == null || staffUid.isEmpty) {
        throw Exception('فشل إنشاء الحساب');
      }
      final now = FieldValue.serverTimestamp();
      await _firestore.collection(AppConstants.usersCollection).doc(staffUid).set({
        'uid': staffUid,
        'role': AppConstants.roleStaff,
        'ownerId': ownerUid,
        'shopId': shopId,
        'shopName': data?['shopName'] ?? '',
        'ownerName': name.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });
      await tempAuth.signOut();
    } catch (e) {
      rethrow;
    } finally {
      // حذف التطبيق المؤقت يمنع أي أثر لجلسة الموظف على جهاز الصاحب.
      try {
        await tempApp.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> updateStaff({
    required String uid,
    required String name,
    required String phone,
    required bool isActive,
  }) async {
    final ownerUid = _uid;
    if (ownerUid == null) throw Exception('يجب تسجيل الدخول أولاً');
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'name': name.trim(),
      'ownerName': name.trim(),
      'phone': phone.trim(),
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
