import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/returns/data/models/return_model.dart';
import 'package:hesba/features/returns/data/repos/returns_repo.dart';
import 'package:hesba/features/returns/presentation/cubit/returns_cubit.dart';
import 'package:hesba/features/returns/presentation/cubit/returns_state.dart';

class MockReturnsRepo extends Mock implements ReturnsRepo {}

/// Return creation: success / failure / repeated submission / concurrent calls.
/// A duplicate return would double-refund and double-reverse COGS, so the guard
/// is a financial-integrity requirement, not just UI polish.
void main() {
  late MockReturnsRepo repo;
  late ReturnsCubit cubit;

  final items = [
    ReturnItemModel(
      productId: 'p1',
      productName: 'منتج p1',
      quantity: 1,
      unitPrice: 100,
    ),
  ];

  ReturnModel makeReturn() => ReturnModel(
        returnId: 'r1',
        ownerId: 'owner-1',
        shopId: 'shop-1',
        originalSaleId: 's1',
        items: items,
        subtotal: 100,
        discount: 20,
        total: 80,
        reason: 'عيب',
        note: '',
        createdAt: DateTime(2026, 1, 5),
      );

  void stubAddReturn() {
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => makeReturn());
  }

  Future<void> submit() => cubit.addReturn(
        ownerId: 'owner-1',
        shopId: 'shop-1',
        originalSaleId: 's1',
        items: items,
        reason: 'عيب',
        note: '',
      );

  setUp(() {
    repo = MockReturnsRepo();
    cubit = ReturnsCubit(returnsRepo: repo);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('success: loading resolved to success with the created return', () async {
    stubAddReturn();
    await submit();
    expect(cubit.state.status, ReturnsStatus.success);
    expect(cubit.state.ret?.returnId, 'r1');
    expect(cubit.state.errorMessage, isNull);
  });

  test('failure: error in state, ret is null, loading resolved', () async {
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenThrow(Exception('offline'));
    await submit();
    expect(cubit.state.status, ReturnsStatus.error);
    expect(cubit.state.errorMessage, isNotEmpty);
    expect(cubit.state.errorMessage, isNot(contains('offline')));
    expect(cubit.state.ret, isNull);
  });

  test('validation error never reaches the repo', () async {
    await cubit.addReturn(
      ownerId: 'owner-1',
      shopId: 'shop-1',
      originalSaleId: 's1',
      items: const [],
      reason: 'عيب',
      note: '',
    );
    expect(cubit.state.status, ReturnsStatus.error);
    expect(cubit.state.errorMessage, 'retErrMinOne');
  });

  test('repeated submission while in flight writes only once', () async {
    final completer = Completer<ReturnModel>();
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = submit();
    final second = submit();
    expect(cubit.state.status, ReturnsStatus.loading);
    completer.complete(makeReturn());
    await Future.wait([first, second]);

    verify(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).called(1);
    expect(cubit.state.status, ReturnsStatus.success);
  });

  test('concurrent different requests: only one write issued', () async {
    final a = Completer<ReturnModel>();
    final b = Completer<ReturnModel>();
    var calls = 0;
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => (calls++ == 0 ? a : b).future);

    final f1 = submit();
    final f2 = submit();
    b.complete(makeReturn());
    a.complete(makeReturn());
    await Future.wait([f1, f2]);
    expect(calls, 1);
  });

  test('retry after failure is allowed', () async {
    var calls = 0;
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) {
      calls++;
      if (calls == 1) throw Exception('no network');
      return Future.value(makeReturn());
    });

    await submit();
    expect(cubit.state.status, ReturnsStatus.error);
    await submit();
    expect(calls, 2);
    expect(cubit.state.status, ReturnsStatus.success);
  });

  test('close during in-flight request does not throw after close', () async {
    final completer = Completer<ReturnModel>();
    when(
      () => repo.addReturn(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        originalSaleId: any(named: 'originalSaleId'),
        items: any(named: 'items'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => completer.future);

    final pending = submit();
    await cubit.close();
    completer.complete(makeReturn());
    await pending;
  });
}
