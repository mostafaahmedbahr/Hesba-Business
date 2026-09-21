import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hesba/features/expenses/data/models/expense_model.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';

class MockExpensesRepo implements ExpensesRepo {
  final Map<String, ExpenseModel> _expenses = {};

  @override
  Future<ExpenseModel> addExpense({
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final expense = ExpenseModel(
      expenseId: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      shopId: shopId,
      title: title,
      category: category,
      amount: amount,
      note: note,
      date: date,
      createdAt: DateTime.now(),
    );
    _expenses[expense.expenseId] = expense;
    return expense;
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    final existing = _expenses[expenseId];
    if (existing == null) throw Exception('Expense not found');
    final updated = existing.copyWith(
      title: title,
      category: category,
      amount: amount,
      note: note,
      date: date,
    );
    _expenses[expenseId] = updated;
    return updated;
  }

  @override
  Future<List<ExpenseModel>> getExpenses({required String shopId}) async {
    return _expenses.values
        .where((e) => e.shopId == shopId)
        .toList();
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses({required String shopId}) {
    return Stream.value(
      _expenses.values.where((e) => e.shopId == shopId).toList(),
    );
  }

  @override
  Future<void> deleteExpense({required String expenseId, required String shopId}) async {
    _expenses.remove(expenseId);
  }

  void addToMap(ExpenseModel expense) {
    _expenses[expense.expenseId] = expense;
  }
}
