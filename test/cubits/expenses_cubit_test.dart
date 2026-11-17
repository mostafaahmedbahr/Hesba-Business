import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';
import 'package:hesba/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:hesba/features/expenses/presentation/cubit/expenses_state.dart';

class MockExpensesRepo extends Mock implements ExpensesRepo {}

/// Expense creation: success / failure / repeated submission / concurrent calls.
void main() {
  late MockExpensesRepo repo;
  late ExpensesCubit cubit;

  ExpenseModel makeExpense() => ExpenseModel(
        expenseId: 'e1',
        ownerId: 'owner-1',
        shopId: 'shop-1',
        shopName: 'محل',
        title: 'إيجار',
        category: 'عام',
        amount: 100,
        note: '',
        date: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5),
      );

  void stubAdd() {
    when(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => makeExpense());
  }

  Future<void> submit() => cubit.addExpense(
        ownerId: 'owner-1',
        shopId: 'shop-1',
        shopName: 'محل',
        title: 'إيجار',
        category: 'عام',
        amount: 100,
        note: '',
        date: DateTime(2026, 1, 5),
      );

  setUp(() {
    repo = MockExpensesRepo();
    cubit = ExpensesCubit(expensesRepo: repo);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('success: loading resolved to success with the created expense', () async {
    stubAdd();
    await submit();
    expect(cubit.state.status, ExpensesStatus.success);
    expect(cubit.state.addedExpense?.expenseId, 'e1');
    expect(cubit.state.errorMessage, isNull);
  });

  test('failure: error in state, loading resolved', () async {
    when(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).thenThrow(Exception('write failed'));
    await submit();
    expect(cubit.state.status, ExpensesStatus.error);
    expect(cubit.state.errorMessage, isNotEmpty);
    expect(cubit.state.errorMessage, isNot(contains('write failed')));
  });

  test('validation error never reaches the repo', () async {
    await cubit.addExpense(
      ownerId: 'owner-1',
      shopId: 'shop-1',
      shopName: 'محل',
      title: '  ',
      category: 'عام',
      amount: 100,
      note: '',
      date: DateTime(2026, 1, 5),
    );
    expect(cubit.state.status, ExpensesStatus.error);
    expect(cubit.state.errorMessage, 'عنوان المصروف مطلوب');
  });

  test('repeated submission while in flight writes only once', () async {
    final completer = Completer<ExpenseModel>();
    when(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = submit();
    final second = submit();
    expect(cubit.state.status, ExpensesStatus.loading);
    completer.complete(makeExpense());
    await Future.wait([first, second]);

    verify(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).called(1);
    expect(cubit.state.status, ExpensesStatus.success);
  });

  test('concurrent add + update: only one write is issued', () async {
    final a = Completer<ExpenseModel>();
    final b = Completer<ExpenseModel>();
    var addCalls = 0;
    when(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) => (addCalls++ == 0 ? a : b).future);
    when(
      () => repo.updateExpense(
        expenseId: any(named: 'expenseId'),
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
      ),
    ).thenAnswer((_) async => makeExpense());

    final f1 = submit();
    final f2 = cubit.updateExpense(
      expenseId: 'e1',
      ownerId: 'owner-1',
      shopId: 'shop-1',
      shopName: 'محل',
      title: 'إيجار',
      category: 'عام',
      amount: 200,
      note: '',
      date: DateTime(2026, 1, 5),
    );
    b.complete(makeExpense());
    a.complete(makeExpense());
    await Future.wait([f1, f2]);
    expect(addCalls, 1);
  });

  test('retry after failure is allowed', () async {
    var calls = 0;
    when(
      () => repo.addExpense(
        ownerId: any(named: 'ownerId'),
        shopId: any(named: 'shopId'),
        shopName: any(named: 'shopName'),
        title: any(named: 'title'),
        category: any(named: 'category'),
        amount: any(named: 'amount'),
        note: any(named: 'note'),
        date: any(named: 'date'),
        recurrence: any(named: 'recurrence'),
        dueTime: any(named: 'dueTime'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) {
      calls++;
      if (calls == 1) throw Exception('offline');
      return Future.value(makeExpense());
    });

    await submit();
    expect(cubit.state.status, ExpensesStatus.error);
    await submit();
    expect(calls, 2);
    expect(cubit.state.status, ExpensesStatus.success);
  });
}
