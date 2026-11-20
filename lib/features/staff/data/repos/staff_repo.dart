import '../models/staff_model.dart';

abstract class StaffRepo {
  /// حسابات الموظفين التابعة للمحل الحالي (لقطة واحدة عند الطلب).
  Future<List<StaffModel>> getStaff();

  /// ينشئ حساب دخول (Firebase Auth) + مستند مستخدم بدور staff.
  /// لا يغيّر جلسة صاحب المحل (يستخدم تطبيق Firebase مؤقت).
  Future<void> addStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// تعديل الاسم/الهاتف أو إيقاف/تفعيل الحساب.
  Future<void> updateStaff({
    required String uid,
    required String name,
    required String phone,
    required bool isActive,
  });

  /// يرسل رابط إعادة تعيين كلمة المرور للموظف على بريده.
  Future<void> sendPasswordReset({required String email});
}
