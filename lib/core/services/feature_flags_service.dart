import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// مفاتيح التحكم عن بُعد (Feature Flags) المخزنة في Firestore.
///
/// المستند: `feature_flags/home`
/// الحقول: `showSubscriptionSection` و`showBackup` (bool)
///
///   true  → القسم يظهر للعملاء
///   false → القسم يختفي
///
/// القيم الافتراضية `true` عشان أي مشكلة في الشبكة/الصلاحيات ما تخبيش
/// القسم بالغلط. الـ refresh مش بيرمي أبداً (نفس فلسفة AppSettingsService).
class FeatureFlagsService {
  FeatureFlagsService._();

  static const String collection = 'feature_flags';
  static const String homeDoc = 'home';
  static const String showSubscriptionKey = 'showSubscriptionSection';
  static const String showBackupKey = 'showBackup';

  static bool _showSubscriptionSection = true;
  static bool _showBackup = true;

  /// هل قسم الاشتراك ظاهر في الرئيسية؟
  static bool get showSubscriptionSection => _showSubscriptionSection;

  /// هل زرار النسخ الاحتياطي ظاهر في قائمة العميل؟
  static bool get showBackup => _showBackup;

  /// يجلب أحدث قيمة من Firestore ويحدّث الكاش.
  static Future<void> refresh() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .doc(homeDoc)
          .get();
      final data = snap.data();
      if (data == null) return;
      final value = data[showSubscriptionKey];
      if (value is bool) _showSubscriptionSection = value;
      final backupValue = data[showBackupKey];
      if (backupValue is bool) _showBackup = backupValue;
    } catch (e, logSt) {
      AppLogger.nonFatal(
        'core/services/feature_flags_service.dart',
        e,
        logSt,
        severity: LoggingSeverity.warning,
      );
    }
  }

  /// كتابة القيمة (للأدمن فقط — القواعد بتسمح بـ isAdmin كتابة).
  static Future<void> setShowSubscriptionSection(bool value) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(homeDoc)
        .set({showSubscriptionKey: value}, SetOptions(merge: true));
    _showSubscriptionSection = value;
  }

  /// كتابة مفتاح النسخ الاحتياطي (للأدمن فقط — القواعد بتسمح بـ isAdmin كتابة).
  static Future<void> setShowBackup(bool value) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(homeDoc)
        .set({showBackupKey: value}, SetOptions(merge: true));
    _showBackup = value;
  }

  @visibleForTesting
  static void debugSet(bool value, {bool? showBackup}) {
    _showSubscriptionSection = value;
    if (showBackup != null) _showBackup = showBackup;
  }

  @visibleForTesting
  static void debugReset() {
    _showSubscriptionSection = true;
    _showBackup = true;
  }
}
