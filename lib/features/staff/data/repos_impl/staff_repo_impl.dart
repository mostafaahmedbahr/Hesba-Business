import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/staff_model.dart';
import '../repos/staff_repo.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';

/// إدارة الحسابات الفرعية. إنشاء حساب الموظف يتم عبر تطبيق Firebase
/// مؤقت حتى لا يتم تسجيل الدخول تلقائيًا بحساب الموظف ويُطرد صاحب المحل.
class StaffRepoImpl implements StaffRepo {
  static const String _tempAppName = 'hesba-staff-creation';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StaffRepoImpl({required this._auth, required this._firestore});

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<List<StaffModel>> getStaff() async {
    final uid = _uid;
    if (uid == null) return const [];
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .where('ownerId', isEqualTo: uid)
        .where('role', isEqualTo: AppConstants.roleStaff)
        .get();
    return snap.docs
        .map((d) => StaffModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  @override
  Future<void> addStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final ownerUid = _uid;
    if (ownerUid == null) throw Exception('يجب تسجيل الدخول أولاً'.tr());

    final ownerDoc =
        await _firestore.collection(AppConstants.usersCollection).doc(ownerUid).get();
    final data = ownerDoc.data();
    final shopId = data?['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) {
      throw Exception('لم يتم العثور على المتجر'.tr());
    }

    // البحث عن التطبيق المؤقت بشكل آمن: firstWhere يرمي StateError
    // ("Bad state: No element") لما التطبيق لا يكون موجودًا بعد، وهي الحالة
    // الطبيعية عند إضافة حساب فرعي للمرة الأولى — فنتجنب الاستثناء هنا.
    FirebaseApp? tempApp;
    for (final app in Firebase.apps) {
      if (app.name == _tempAppName) {
        tempApp = app;
        break;
      }
    }
    tempApp ??= await Firebase.initializeApp(
      name: _tempAppName,
      options: Firebase.app().options,
    );

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final staffUid = credential.user?.uid;
      if (staffUid == null || staffUid.isEmpty) {
        throw Exception('فشل إنشاء الحساب'.tr());
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
    } catch (e, logSt) {
      AppLogger.nonFatal('features/staff/data/repos_impl/staff_repo_impl.dart', e, logSt, severity: LoggingSeverity.error);
      rethrow;
    } finally {
      // حذف التطبيق المؤقت يمنع أي أثر لجلسة الموظف على جهاز الصاحب.
      try {
        await tempApp.delete();
      } catch (logErr, logSt) { AppLogger.nonFatal('features/staff/data/repos_impl/staff_repo_impl.dart', logErr, logSt, severity: LoggingSeverity.warning); }
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
    if (ownerUid == null) throw Exception('يجب تسجيل الدخول أولاً'.tr());
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
