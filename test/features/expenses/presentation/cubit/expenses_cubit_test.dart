import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';

import '../../../../helpers/mock_repos.dart';

void main() {
  late MockExpensesRepo mockRepo;
  late ExpensesCubit cubit;

  setUp(() {
    mockRepo = MockExpensesRepo();
    cubit = ExpensesCubit(expensesRepo: mockRepo, auth: null);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be ExpensesState with initial status', () {
    expect(cubit.state.status.name, 'initial');
  });

  test('loadExpenses should emit loading then success', () async {
    final expense = ExpenseModel(
      expenseId: 'exp1',
      ownerId: 'user1',
      shopId: 'shop1',
      title: 'إيجار',
      category: 'إيجار',
      amount: 1000.0,
      note: '',
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    mockRepo.addToMap(expense);

    cubit.loadExpenses(shopId: 'shop1');
    await Future.delayed(Duration.zero);

    expect(cubit.state.status.name, 'success');
    expect(cubit.state.expenses.length, 1);
    expect(cubit.state.totalAmount, 1000.0);
  });

  test('addExpense should reject empty title', () async {
    await cubit.addExpense(
      ownerId: 'user1',
      shopId: 'shop1',
      title: '',
      category: 'إيجار',
      amount: 1000.0,
      note: '',
      date: DateTime(2026, 1, 1),
    );
    expect(cubit.state.status.name, 'error');
    expect(cubit.state.errorMessage, 'عنوان المصروف مطلوب');
  });

  test('addExpense should reject zero or negative amount', () async {
    await cubit.addExpense(
      ownerId: 'user1',
      shopId: 'shop1',
      title: 'إيجار',
      category: 'إيجار',
      amount: -100,
      note: '',
      date: DateTime(2026, 1, 1),
    );
    expect(cubit.state.status.name, 'error');
    expect(cubit.state.errorMessage, 'المبلغ يجب أن يكون أكبر من صفر');
  });

  test('addExpense should reject empty category', () async {
    await cubit.addExpense(
      ownerId: 'user1',
      shopId: 'shop1',
      title: 'إيجار',
      category: '',
      amount: 1000.0,
      note: '',
      date: DateTime(2026, 1, 1),
    );
    expect(cubit.state.status.name, 'error');
    expect(cubit.state.errorMessage, 'اختر تصنيف المصروف');
  });

  test('updateExpense should reject empty title', () async {
    await cubit.updateExpense(
      expenseId: 'exp1',
      ownerId: 'user1',
      shopId: 'shop1',
      title: '',
      category: 'إيجار',
      amount: 1000.0,
      note: '',
      date: DateTime(2026, 1, 1),
    );
    expect(cubit.state.status.name, 'error');
    expect(cubit.state.errorMessage, 'عنوان المصروف مطلوب');
  });

  test('updateExpense should reject zero or negative amount', () async {
    await cubit.updateExpense(
      expenseId: 'exp1',
      ownerId: 'user1',
      shopId: 'shop1',
      title: 'إيجار',
      category: 'إيجار',
      amount: -100,
      note: '',
      date: DateTime(2026, 1, 1),
    );
    expect(cubit.state.status.name, 'error');
    expect(cubit.state.errorMessage, 'المبلغ يجب أن يكون أكبر من صفر');
  });

  test('deleteExpense should call repo without error', () async {
    final expense = ExpenseModel(
      expenseId: 'exp1',
      ownerId: 'user1',
      shopId: 'shop1',
      title: 'إيجار',
      category: 'إيجار',
      amount: 1000.0,
      note: '',
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    mockRepo.addToMap(expense);

    await cubit.deleteExpense(expenseId: 'exp1', shopId: 'shop1');
    expect(cubit.state.status.name, 'success');
  });

  test('reset should clear state', () {
    cubit.reset();
    expect(cubit.state.status.name, 'initial');
    expect(cubit.state.expenses.length, 0);
  });
}
