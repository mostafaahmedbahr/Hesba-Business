import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/core/models/product.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';
import 'package:hesba/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:hesba/features/expenses/presentation/cubit/expenses_state.dart';
import 'package:hesba/features/products/data/repos_impl/products_repo_impl.dart';
import 'package:hesba/features/returns/data/repos/returns_repo.dart';
import 'package:hesba/features/returns/presentation/cubit/returns_list_cubit.dart';
import 'package:hesba/features/returns/presentation/cubit/returns_list_state.dart';
import 'package:hesba/features/sales/data/repos/sales_repo.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_list_cubit.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_list_state.dart';

import '../helpers/test_auth.dart';

class MockSalesRepo extends Mock implements SalesRepo {}
class MockReturnsRepo extends Mock implements ReturnsRepo {}
class MockExpensesRepo extends Mock implements ExpensesRepo {}

/// Critical failure scenarios: loading must always resolve and failed writes
/// must never be reported as success.
void main() {
  group('list bootstraps resolve loading when shop lookup fails', () {
    test('sales list: failed getShopId -> failure, not endless loading', () async {
      final repo = MockSalesRepo();
      when(repo.getShopId).thenThrow(Exception('offline'));
      final cubit = SalesListCubit(repo: repo);

      await cubit.bootstrap();

      expect(cubit.state.status, SalesListStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.errorMessage, isNot(contains('offline')));
      await cubit.close();
    });

    test('returns list: failed getShopId -> failure, not endless loading',
        () async {
      final repo = MockReturnsRepo();
      when(repo.getShopId).thenThrow(Exception('offline'));
      final cubit = ReturnsListCubit(repo: repo);

      await cubit.bootstrap();

      expect(cubit.state.status, ReturnsListStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });

    test('expenses list: failed shop resolution -> failure status', () async {
      final repo = MockExpensesRepo();
      when(repo.getShopId).thenThrow(Exception('offline'));
      final cubit = ExpensesCubit(expensesRepo: repo);

      // Empty provided id forces the repo to resolve it via getShopId().
      await cubit.loadExpenses(shopId: '');

      expect(cubit.state.status, ExpensesStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });
  });

  test('product write without a resolved shop throws instead of silently '
      'returning success', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = ProductsRepoImpl(
      auth: signedOutAuth(),
      firestore: firestore,
    );
    // AuthRepo is only used for supplier checks, which are never reached when
    // shop resolution fails; a simple mock is enough.
    await expectLater(
      repo.addProduct(_product()),
      throwsA(isA<StateError>()),
    );
  });
}

Product _product() => Product(
      id: '',
      name: 'منتج',
      price: 10,
      costPrice: 5,
      stock: 1,
      category: '',
      shopId: '',
      ownerId: '',
    );
