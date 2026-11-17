import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/sales/data/models/sale_model.dart';
import 'package:hesba/features/sales/data/repos/sales_repo.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:hesba/features/sales/presentation/cubit/sales_state.dart';

class MockSalesRepo extends Mock implements SalesRepo {}

/// Sale creation: success / failure / repeated submission / concurrent calls.
void main() {
  late MockSalesRepo repo;
  late SalesCubit cubit;

  final items = [
    SaleItemModel(
      productId: 'p1',
      productName: 'منتج p1',
      quantity: 2,
      unitPrice: 100,
      costPrice: 60,
    ),
  ];

  SaleModel makeSale() => SaleModel(
        saleId: 's1',
        ownerId: 'owner-1',
        shopId: 'shop-1',
        items: items,
        subtotal: 200,
        discount: 0,
        total: 200,
        paymentMethod: 'cash',
        note: '',
        createdAt: DateTime(2026, 1, 5),
      );

  void stubAddSale() {
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => makeSale());
  }

  Future<void> submit() => cubit.addSale(
        ownerId: 'owner-1',
        shopId: 'shop-1',
        items: items,
        discount: 0,
        paymentMethod: 'cash',
        note: '',
      );

  setUp(() {
    repo = MockSalesRepo();
    cubit = SalesCubit(salesRepo: repo);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('success: loading resolved to success with the created sale', () async {
    stubAddSale();
    await submit();

    expect(cubit.state.status, SalesStatus.success);
    expect(cubit.state.sale?.saleId, 's1');
    expect(cubit.state.errorMessage, isNull);
  });

  test('failure: error is in state, sale is null, loading is resolved', () async {
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenThrow(Exception('boom'));

    await submit();

    expect(cubit.state.status, SalesStatus.error);
    // Raw SDK/exception text must never reach the user.
    expect(cubit.state.errorMessage, isNotEmpty);
    expect(cubit.state.errorMessage, isNot(contains('boom')));
    expect(cubit.state.sale, isNull);
  });

  test('validation error never reaches the repo', () async {
    await cubit.addSale(
      ownerId: 'owner-1',
      shopId: 'shop-1',
      items: const [],
      discount: 0,
      paymentMethod: 'cash',
      note: '',
    );
    expect(cubit.state.status, SalesStatus.error);
    expect(cubit.state.errorMessage, 'saleErrMinOne');
  });

  test('repeated submission while in flight writes only once', () async {
    final completer = Completer<SaleModel>();
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = submit();
    final second = submit(); // double tap — must be ignored
    expect(cubit.state.status, SalesStatus.loading);
    completer.complete(makeSale());
    await Future.wait([first, second]);

    verify(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).called(1);
    expect(cubit.state.status, SalesStatus.success);
  });

  test('concurrent different requests: second is rejected, no stale overwrite', () async {
    final firstCompleter = Completer<SaleModel>();
    final secondCompleter = Completer<SaleModel>();
    var call = 0;
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => (call++ == 0 ? firstCompleter : secondCompleter).future);

    final a = submit();
    final b = submit();
    secondCompleter.complete(makeSale()); // newer request resolves first
    firstCompleter.complete(makeSale());
    await Future.wait([a, b]);

    expect(call, 1); // only one write ever issued
  });

  test('retry after failure is allowed', () async {
    var call = 0;
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) {
      call++;
      if (call == 1) throw Exception('offline');
      return Future.value(makeSale());
    });

    await submit();
    expect(cubit.state.status, SalesStatus.error);
    await submit();
    expect(call, 2);
    expect(cubit.state.status, SalesStatus.success);
  });

  test('close during in-flight request does not throw or emit after close', () async {
    final completer = Completer<SaleModel>();
    when(
      () => repo.addSale(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        items: any(named: 'items'),
        discount: any(named: 'discount'),
        paymentMethod: any(named: 'paymentMethod'),
        note: any(named: 'note'),
        customerName: any(named: 'customerName'),
        customerPhone: any(named: 'customerPhone'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => completer.future);

    final pending = submit();
    await cubit.close();
    completer.complete(makeSale());
    await pending;
    // No StateError from emitting on a closed cubit.
  });
}
