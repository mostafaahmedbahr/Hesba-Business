import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/services/app_logger.dart';

void main() {
  setUp(AppLogger.clear);

  group('AppLogger', () {
    test('يسجل مستوى وشدة وسياق صحيحين', () {
      AppLogger.warning('تحذير تجريبي', context: 'test/ctx');
      final e = AppLogger.entries.single;
      expect(e.severity, LoggingSeverity.warning);
      expect(e.message, 'تحذير تجريبي');
      expect(e.context, 'test/ctx');
    });

    test('nonFatal يضع severity والسياق والـ stackTrace', () {
      final st = StackTrace.current;
      AppLogger.nonFatal(
        'features/sales/add_sale_view',
        Exception('فشل'),
        st,
        severity: LoggingSeverity.error,
      );
      final e = AppLogger.entries.single;
      expect(e.severity, LoggingSeverity.error);
      expect(e.context, 'features/sales/add_sale_view');
      expect(e.error, isA<Exception>());
      expect(e.stackTrace, same(st));
      expect(e.message, contains('features/sales/add_sale_view'));
    });

    test('الحلقة لا تتجاوز الحد الأقصى (300) ويُسقط الأقدم', () {
      for (var i = 0; i < AppLogger.maxEntries + 10; i++) {
        AppLogger.info('حدث $i');
      }
      final entries = AppLogger.entries;
      expect(entries, hasLength(AppLogger.maxEntries));
      // الأقدم (0-9) اتمسح، والأحدث موجود.
      expect(entries.first.message, 'حدث 10');
      expect(entries.last.message, 'حدث ${AppLogger.maxEntries + 9}');
    });

    test('clear يمسح الحلقة', () {
      AppLogger.error('x');
      AppLogger.clear();
      expect(AppLogger.entries, isEmpty);
    });

    test('قائمة entries غير قابلة للتعديل', () {
      expect(
        () => AppLogger.entries.add(
          LogEntry(
            timestamp: DateTime(2026),
            severity: LoggingSeverity.info,
            message: 'x',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
