import 'package:cloud_firestore/cloud_firestore.dart';

import '../extensions/log_util.dart';
import '../models/admin_settings.dart';

/// الإعدادات الحية للتطبيق: أسعار الاشتراكات، الفترة التجريبية، وأرقام المحافظ.
///
/// تُقرأ من نفس المستند الذي يعدّله الداشبورد (`admin_settings/settings`)،
/// فكل تعديل هناك ينعكس على التطبيق فوراً بدون إعادة إصدار.
///
/// الاستخدام:
///   - `AppSettingsService.current` — قراءة لحظية (الافتراضية قبل أول جلب).
///   - `await AppSettingsService.refresh()` — تحديث قبل شاشة تهمّها الإعدادات.
class AppSettingsService {
  AppSettingsService._();

  static AdminSettings _current = AdminSettings.defaults;

  /// آخر إعدادات معروفة (الافتراضية = نفس قيم التطبيق القديمة قبل أول جلب).
  static AdminSettings get current => _current;

  /// جلب الإعدادات من Firestore.
  ///
  /// الفشل (offline / قواعد / أي خطأ) يُبقي القيم الحالية ولا يرمي أبداً —
  /// هذه الدالة تُستدعى في بداية الشاشات ف يجب ألا تُفشل تدفّقها.
  static Future<void> refresh() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('settings')
          .get();
      final data = snap.data();
      if (data != null && data.isNotEmpty) {
        _current = AdminSettings.fromJson(data);
      }
    } catch (e) {
      logWarning('[AppSettings] refresh failed: $e');
    }
  }
}
