import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// شدة الحدث المُسجّل.
enum LoggingSeverity { debug, info, warning, error }

/// حدث مُسجّل واحد داخل حلقة الذاكرة.
class LogEntry {
  final DateTime timestamp;
  final LoggingSeverity severity;

  /// رسالة مختصرة (سياق / وصف).
  final String message;

  /// سياق إضافي اختياري (اسم الملف/الوحدة أو الشاشة).
  final String? context;

  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.severity,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
  });
}

/// نظام التسجيل المركزي بدل ~150 catch صامت أو debugPrint مبعثر.
///
/// - حلقة ذاكرة (Ring Buffer) بحد أقصى [maxEntries] حدث — للتشخيص داخل
///   التطبيق بدون أي خدمة خارجية.
/// - [nonFatal] نقطة موحّدة تُستدعى من كل catch غير قاتل في الكود.
/// - [installGlobalHandlers] يربط FlutterError وPlatformDispatcher.onError
///   عشان حتى الأخطاء غير الملتقطة تدخل السجل.
/// - في debug تُطبع كل المستويات، وفي release تُطبع warning/error فقط —
///   والحلقة بتتسجّل دائمًا (وتمامًا في الذاكرة، لا تُحفظ على القرص).
abstract class AppLogger {
  static const int maxEntries = 300;

  static final List<LogEntry> _entries = [];

  /// آخر الأحداث (الأحدث آخرًا) — غير قابلة للتعديل.
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  /// يلتقط خطأً غير قاتل من مسار catch ويضعه في السجل.
  ///
  /// الاستخدام القياسي داخل أي catch:
  /// ```dart
  /// } catch (logErr, logSt) {
  ///   AppLogger.nonFatal('features/sales/add_sale_view', logErr, logSt);
  ///   ...
  /// }
  /// ```
  static void nonFatal(
    String context,
    Object error,
    StackTrace stackTrace, {
    LoggingSeverity severity = LoggingSeverity.warning,
  }) =>
      _record(
        severity,
        'خطأ غير قاتل في $context',
        context: context,
        error: error,
        stackTrace: stackTrace,
      );

  static void debug(String message, {String? context}) =>
      _record(LoggingSeverity.debug, message, context: context);

  static void info(String message, {String? context}) =>
      _record(LoggingSeverity.info, message, context: context);

  static void warning(
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _record(
        LoggingSeverity.warning,
        message,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );

  static void error(
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _record(
        LoggingSeverity.error,
        message,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );

  /// مسح الحلقة (زر "مسح السجل" في شاشة التشخيص).
  static void clear() => _entries.clear();

  /// يربط معالجات الأخطاء العامة — يُستدعى مرة واحدة في main().
  static void installGlobalHandlers() {
    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.error(
        'FlutterError غير ملتقط',
        context: 'flutter',
        error: details.exception,
        stackTrace: details.stack,
      );
      // نحافظ على سلوك الـ console الافتراضي (red screen في debug).
      defaultOnError?.call(details);
    };
    ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.error(
        'خطأ غير متزامن غير ملتقط',
        context: 'platform',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    };
  }

  static void _record(
    LoggingSeverity severity,
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      severity: severity,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
    if (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(entry);

    // الطباعة: كل المستويات في debug؛ warning/error فقط في release.
    final shouldPrint = kDebugMode ||
        severity == LoggingSeverity.warning ||
        severity == LoggingSeverity.error;
    if (!shouldPrint) return;

    final tag = switch (severity) {
      LoggingSeverity.debug => '\x1B[90mD',
      LoggingSeverity.info => '\x1B[36mI',
      LoggingSeverity.warning => '\x1B[33mW',
      LoggingSeverity.error => '\x1B[31mE',
    };
    // لا نطبع تفاصيل المكدس على كل حدث — فقط مع الخطأ في debug.
    if (error != null) {
      debugPrint('$tag $message'
          '${context == null ? '' : ' [$context]'} → $error\x1B[0m');
    } else {
      debugPrint('$tag $message${context == null ? '' : ' [$context]'}\x1B[0m');
    }
  }
}
