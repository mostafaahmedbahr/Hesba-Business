import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/utils/paged_fetch.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';
import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos/returns_repo.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos/sales_repo.dart';
import 'package:hesba/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:hesba/features/reports/presentation/cubit/reports_state.dart';

class MockSalesRepo extends Mock implements SalesRepo {}

class MockReturnsRepo extends Mock implements ReturnsRepo {}

class MockExpensesRepo extends Mock implements ExpensesRepo {}

/// The reports cubit must fetch each data window once, then serve every
/// period switch from memory — especially the expensive "all history" scan.
void main() {
  late MockSalesRepo sales;
  late MockReturnsRepo returns;
  late MockExpensesRepo expenses;
  late ReportsCubit cubit;
  late int salesFetches;
  late List<DateTime?> requestedWindows;

  setUp(() async {
    sales = MockSalesRepo();
    returns = MockReturnsRepo();
    expenses = MockExpensesRepo();
    salesFetches = 0;
    requestedWindows = <DateTime?>[];

    when(() => sales.getShopId()).thenAnswer((_) async => 'shop-1');
    when(() => sales.fetchAllSales(
          shopId: any(named: 'shopId'),
          from: any(named: 'from'),
        )).thenAnswer((invocation) async {
      salesFetches++;
      requestedWindows.add(invocation.namedArguments[#from] as DateTime?);
      return const PagedResult<SaleModel>(items: [], isComplete: true);
    });
    when(() => returns.fetchAllReturns(
          shopId: any(named: 'shopId'),
          from: any(named: 'from'),
        )).thenAnswer(
        (_) async => const PagedResult<ReturnModel>(items: [], isComplete: true));
    when(() => expenses.fetchAllExpenses(
          shopId: any(named: 'shopId'),
          from: any(named: 'from'),
        )).thenAnswer(
        (_) async => const PagedResult<ExpenseModel>(items: [], isComplete: true));

    cubit = ReportsCubit(
      salesRepo: sales,
      returnsRepo: returns,
      expensesRepo: expenses,
    );
    await cubit.bootstrap();
  });

  tearDown(() => cubit.close());

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('bootstrap fetches a bounded recent window only', () {
    expect(salesFetches, 1);
    expect(requestedWindows.single, isNotNull);
    expect(cubit.state.dataComplete, isTrue);
  });

  test('first "all" selection scans full history exactly once', () async {
    cubit.setPeriod(ReportPeriod.all);
    await settle();

    expect(salesFetches, 2);
    expect(requestedWindows.last, isNull);
    expect(cubit.state.period, ReportPeriod.all);
  });

  test('toggling all -> week -> all does NOT rescan full history', () async {
    cubit.setPeriod(ReportPeriod.all);
    await settle();
    final afterAll = salesFetches;

    cubit.setPeriod(ReportPeriod.week);
    await settle();
    cubit.setPeriod(ReportPeriod.all);
    await settle();

    expect(salesFetches, afterAll);
    expect(cubit.state.period, ReportPeriod.all);
  });

  test('refresh keeps the loaded window (no surprise full scan)', () async {
    await cubit.refresh();
    await settle();
    expect(salesFetches, 2);
    expect(requestedWindows.last, isNotNull);
  });
}
