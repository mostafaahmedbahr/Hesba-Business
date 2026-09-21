import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';

import '../../../../helpers/mock_repos.dart';

void main() {
  group('ExpensesRepoImpl', () {
    late MockExpensesRepo mockRepo;

    setUp(() {
      mockRepo = MockExpensesRepo();
    });

    test('addExpense should create expense with correct fields', () async {
      final expense = await mockRepo.addExpense(
        ownerId: 'user1',
        shopId: 'shop1',
        title: 'إيجار',
        category: 'إيجار',
        amount: 1500.0,
        note: 'إيجار يناير',
        date: DateTime(2026, 1, 1),
      );
      expect(expense.title, 'إيجار');
      expect(expense.amount, 1500.0);
      expect(expense.category, 'إيجار');
      expect(expense.expenseId, isNotEmpty);
    });

    test('updateExpense should preserve createdAt', () async {
      final original = ExpenseModel(
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
      mockRepo.addToMap(original);

      final updated = await mockRepo.updateExpense(
        expenseId: 'exp1',
        ownerId: 'user1',
        shopId: 'shop1',
        title: 'إيجار معدل',
        category: 'إيجار',
        amount: 2000.0,
        note: '',
        date: DateTime(2026, 2, 1),
      );
      expect(updated.title, 'إيجار معدل');
      expect(updated.amount, 2000.0);
      expect(updated.createdAt, DateTime(2026, 1, 1));
    });

    test('deleteExpense should remove expense', () async {
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

      await mockRepo.deleteExpense(expenseId: 'exp1', shopId: 'shop1');
      expect(await mockRepo.watchExpenses(shopId: 'shop1').first, isEmpty);
    });
  });
}
