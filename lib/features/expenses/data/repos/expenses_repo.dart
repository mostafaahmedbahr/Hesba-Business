import '../models/expense_model.dart';

abstract class ExpensesRepo {
  Future<ExpenseModel> addExpense({
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  });

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  });

  Future<List<ExpenseModel>> getExpenses({required String shopId});

  Stream<List<ExpenseModel>> watchExpenses({required String shopId});

  Future<void> deleteExpense({required String expenseId, required String shopId});

  /// Current user's shopId (`null` when signed out or not yet assigned).
  Future<String?> getShopId();
}
