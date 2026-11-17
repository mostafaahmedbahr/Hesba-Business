import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/accounts/data/models/debt_model.dart';
import 'package:hesba/features/accounts/data/models/person_model.dart';
import 'package:hesba/features/accounts/data/repos/accounts_repo.dart';
import 'package:hesba/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:hesba/features/accounts/presentation/states/accounts_state.dart';
import 'package:hesba/features/admin/data/models/profit_summary.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/data/repos/admin_search_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/global_search_cubit.dart';
import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos/sales_repo.dart';
import 'package:hesba/features/sales/presentation/cubit/customer_sales_cubit.dart';
import 'package:hesba/features/sales/presentation/cubit/customer_sales_state.dart';

class MockAdminSearchRepo extends Mock implements AdminSearchRepo {}
class MockAdminRepo extends Mock implements AdminRepo {}
class MockAccountsRepo extends Mock implements AccountsRepo {}
class MockSalesRepo extends Mock implements SalesRepo {}

/// Regression tests for stale-result races, refresh semantics and lifecycle.
void main() {
  group('GlobalSearchCubit — older query cannot overwrite newer', () {
    late MockAdminSearchRepo repo;
    late GlobalSearchCubit cubit;

    setUp(() {
      repo = MockAdminSearchRepo();
      cubit = GlobalSearchCubit(searchRepo: repo);
    });
    tearDown(() async => cubit.close());

    test('slow first query result is ignored after a newer query started', () async {
      final old = Completer<List<AdminSearchHit>>();
      final fresh = Completer<List<AdminSearchHit>>();
      when(() => repo.search(any())).thenAnswer((inv) {
        final q = inv.positionalArguments.first as String;
        return Future.value(q == 'old' ? old.future : fresh.future);
      });

      // search() debounces 400ms; drive the internal runs through search calls
      // by awaiting the timer via short delays.
      cubit.search('old');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      // old query is in flight
      expect(cubit.state, isA<SearchLoading>());
      cubit.search('fresh');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      fresh.complete([const AdminSearchHit('shop', 'جديد', '2')]);
      await pump();
      expect((cubit.state as SearchResults).hits.single.title, 'جديد');

      old.complete([const AdminSearchHit('shop', 'قديم', '1')]);
      await pump();
      // newer result must still be shown
      expect((cubit.state as SearchResults).hits.single.title, 'جديد');
    });
  });

  group('AdminDashboardCubit — concurrent loads', () {
    late MockAdminRepo repo;
    late AdminDashboardCubit cubit;

    void stubLoad() {
      when(repo.countShops).thenAnswer((_) async => 1);
      when(repo.countActiveSubscriptions).thenAnswer((_) async => 2);
      when(repo.countTrialSubscriptions).thenAnswer((_) async => 3);
      when(repo.countExpiredSubscriptions).thenAnswer((_) async => 4);
      when(repo.countPendingRequests).thenAnswer((_) async => 5);
      when(repo.countProducts).thenAnswer((_) async => 6);
      when(repo.countSales).thenAnswer((_) async => 7);
      when(repo.countExpenses).thenAnswer((_) async => 8);
      when(() => repo.subscriptionCountsByMonth(months: any(named: 'months')))
          .thenAnswer((_) async => {});
      when(() => repo.shopsByMonth(months: any(named: 'months')))
          .thenAnswer((_) async => {});
      when(() => repo.revenueByMonth(months: any(named: 'months')))
          .thenAnswer((_) async => {});
      when(repo.profitSummary).thenAnswer((_) async => ProfitSummary.empty);
    }

    setUp(() {
      repo = MockAdminRepo();
      cubit = AdminDashboardCubit(repo: repo);
      stubLoad();
    });
    tearDown(() async => cubit.close());

    test('second load while first is in flight is ignored', () async {
      final gate = Completer<int>();
      when(repo.countShops).thenAnswer((_) => gate.future);

      final first = cubit.load();
      final second = cubit.load(); // ignored

      gate.complete(10);
      await Future.wait([first, second]);
      verify(repo.countShops).called(1);
      expect(cubit.state, isA<AdminDashboardLoaded>());
    });

    test('close during load does not emit after close', () async {
      final gate = Completer<int>();
      when(repo.countShops).thenAnswer((_) => gate.future);
      final pending = cubit.load();
      await cubit.close();
      gate.complete(1);
      await pending;
    });
  });

  group('AccountsCubit — refresh keeps loading until data arrives', () {
    late MockAccountsRepo repo;
    late AccountsCubit cubit;
    late StreamController<List<DebtModel>> debts;
    late StreamController<List<PersonModel>> persons;

    setUp(() {
      repo = MockAccountsRepo();
      debts = StreamController<List<DebtModel>>.broadcast();
      persons = StreamController<List<PersonModel>>.broadcast();
      when(repo.watchDebts).thenAnswer((_) => debts.stream);
      when(repo.watchPersons).thenAnswer((_) => persons.stream);
      cubit = AccountsCubit(repo: repo);
    });
    tearDown(() async {
      await cubit.close();
      await debts.close();
      await persons.close();
    });

    test('refresh does not mark old debts as fresh success immediately', () async {
      cubit.init();
      debts.add([]);
      await pump();

      final refresh = cubit.refresh();
      expect(cubit.state.status, AccountsStatus.loading);
      await pump();
      // Still loading until the stream emits — not flipped to success.
      expect(cubit.state.status, AccountsStatus.loading);
      debts.add([]);
      await pump();
      await refresh;
      expect(cubit.state.status, AccountsStatus.success);
    });

    test('stream error clears stale debts so the error becomes visible', () async {
      cubit.init();
      debts.add([_debt('d1')]);
      await pump();
      expect(cubit.state.debts, hasLength(1));

      debts.addError(Exception('permission denied'));
      await pump();
      expect(cubit.state.status, AccountsStatus.failure);
      expect(cubit.state.debts, isEmpty);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });

  group('CustomerSalesCubit — re-init clears previous customer', () {
    late MockSalesRepo repo;
    late CustomerSalesCubit cubit;
    late StreamController<List<SaleModel>> stream;

    setUp(() {
      repo = MockSalesRepo();
      stream = StreamController<List<SaleModel>>.broadcast();
      when(() => repo.watchSalesForPerson(
            shopId: any(named: 'shopId'),
            personId: any(named: 'personId'),
          )).thenAnswer((_) => stream.stream);
      cubit = CustomerSalesCubit(repo: repo);
    });
    tearDown(() async {
      await cubit.close();
      await stream.close();
    });

    test('old sales are cleared when switching customers', () async {
      cubit.init(shopId: 's', personId: 'p1', personName: 'أ', personPhone: '1');
      stream.add([_sale('old')]);
      await pump();
      expect(cubit.state.sales, hasLength(1));

      cubit.init(shopId: 's', personId: 'p2', personName: 'ب', personPhone: '2');
      expect(cubit.state.sales, isEmpty);
      expect(cubit.state.status, CustomerSalesStatus.loading);
    });
  });
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

DebtModel _debt(String id) => DebtModel(
      id: id,
      ownerId: 'owner-1',
      shopId: 'shop-1',
      personId: 'person-1',
      personName: 'أحمد',
      personPhone: '01000000001',
      partyType: 'customer',
      direction: 'receivable',
      amount: 100,
      paidAmount: 0,
      note: '',
      createdAt: DateTime(2026, 1, 5),
    );

SaleModel _sale(String id) => SaleModel(
      saleId: id,
      ownerId: 'owner-1',
      shopId: 'shop-1',
      items: const [],
      subtotal: 100,
      discount: 0,
      total: 100,
      paymentMethod: 'cash',
      note: '',
      createdAt: DateTime(2026, 1, 5),
    );
