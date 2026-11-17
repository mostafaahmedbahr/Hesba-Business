import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/accounts/data/models/debt_model.dart';
import 'package:hesba/features/accounts/data/models/payment_model.dart';
import 'package:hesba/features/accounts/data/repos/accounts_repo.dart';
import 'package:hesba/features/accounts/presentation/cubit/debt_details_cubit.dart';
import 'package:hesba/features/accounts/presentation/states/debt_details_state.dart';

class MockAccountsRepo extends Mock implements AccountsRepo {}

/// Debt payment: success / failure / repeated submission / concurrent calls.
void main() {
  late MockAccountsRepo repo;
  late DebtDetailsCubit cubit;

  const debtId = 'debt-1';

  void stubPayment() {
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
  }

  setUp(() {
    repo = MockAccountsRepo();
    cubit = DebtDetailsCubit(repo: repo, debtId: debtId);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('success: saving resolved, returns true, no error', () async {
    stubPayment();
    final ok = await cubit.addPayment(amount: 50, note: 'دفعة');
    expect(ok, isTrue);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  test('failure: returns false with error in state, saving resolved', () async {
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenThrow(Exception('overdue lock'));

    final ok = await cubit.addPayment(amount: 50, note: '');
    expect(ok, isFalse);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.errorMessage, isNotEmpty);
    expect(cubit.state.errorMessage, isNot(contains('overdue lock')));
  });

  test('repeated submission while in flight writes only once', () async {
    final completer = Completer<void>();
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = cubit.addPayment(amount: 50);
    final second = cubit.addPayment(amount: 50); // ignored
    expect(cubit.state.saving, isTrue);
    completer.complete();
    final results = await Future.wait([first, second]);

    expect(results, [true, false]);
    verify(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).called(1);
    expect(cubit.state.saving, isFalse);
  });

  test('concurrent different amounts: only the first write is issued', () async {
    final a = Completer<void>();
    final b = Completer<void>();
    var calls = 0;
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => (calls++ == 0 ? a : b).future);

    final f1 = cubit.addPayment(amount: 50);
    final f2 = cubit.addPayment(amount: 999);
    b.complete();
    a.complete();
    await Future.wait([f1, f2]);
    expect(calls, 1);
  });

  test('retry after failure is allowed', () async {
    var calls = 0;
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) {
      calls++;
      if (calls == 1) throw Exception('network');
      return Future.value();
    });

    expect(await cubit.addPayment(amount: 50), isFalse);
    expect(await cubit.addPayment(amount: 50), isTrue);
    expect(calls, 2);
  });

  test('close during payment does not emit after close', () async {
    final completer = Completer<void>();
    when(
      () => repo.addPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => completer.future);

    final pending = cubit.addPayment(amount: 50);
    await cubit.close();
    completer.complete();
    expect(await pending, isTrue);
  });

  test('failed stream read clears stale debt so the UI stops showing old data',
      () async {
    final debtStream = StreamController<DebtModel?>.broadcast();
    final paymentsStream = StreamController<List<PaymentModel>>.broadcast();
    when(() => repo.watchDebt(debtId)).thenAnswer((_) => debtStream.stream);
    when(() => repo.watchPayments(debtId)).thenAnswer((_) => paymentsStream.stream);

    cubit.init();
    debtStream.add(null); // document disappeared / read failure
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailsStatus.failure);
    expect(cubit.state.debt, isNull);
    expect(cubit.state.errorMessage, isNotNull);

    await debtStream.close();
    await paymentsStream.close();
  });
}

/// Small helper to let stream listeners process their events.
Future<void> pumpEventQueue() => Future<void>.delayed(Duration.zero);
