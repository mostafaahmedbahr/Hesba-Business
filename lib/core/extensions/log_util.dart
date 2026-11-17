import '../services/app_logger.dart';

/// غلافات توافقية فوق [AppLogger] — تُبقي الاستخدامات القديمة شغالة
/// وتوجّه كلها للسجل المركزي. لا تستخدم الألوان المباشرة هنا.
void logError(String msg) => AppLogger.error(msg);

void logSuccess(String msg) => AppLogger.info(msg);

void logWarning(String msg) => AppLogger.warning(msg);
