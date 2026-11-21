import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/features/reports/presentation/cubit/reports_state.dart';
import 'package:hesba/features/reports/presentation/widgets/reports_filters.dart';

/// Widget-level coverage for the reports period selector (the control that
/// drives the new in-memory period switching).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('tapping a period chip reports the selected period', (tester) async {
    ReportPeriod? selected;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: ReportsPeriodChips(
            period: ReportPeriod.week,
            onChanged: (period) => selected = period,
          ),
        ),
      ),
    ));

    await tester.scrollUntilVisible(find.text('الكل'), 200);
    await tester.pump();
    await tester.tap(find.text('الكل'));
    await tester.pump();

    expect(selected, ReportPeriod.all);
  });

  testWidgets('the current period chip is marked selected', (tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: ReportsPeriodChips(period: ReportPeriod.week, onChanged: (_) {}),
        ),
      ),
    ));

    expect(tester.widget<ChoiceChip>(find.byWidgetPredicate(
      (w) => w is ChoiceChip && w.label is Text && (w.label as Text).data == '7 أيام',
    )).selected, isTrue);
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('30 يوم'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
  });
}
