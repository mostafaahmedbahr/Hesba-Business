import '../../../../core/utils/paged_fetch.dart';
import '../models/expense_model.dart';

abstract class ExpensesRepo {
  Future<ExpenseModel> addExpense({
    required String ownerId,
    required String shopId,
    required String shopName,
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
    required String shopName,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
  });

  Future<List<ExpenseModel>> getExpenses({required String shopId});

  Stream<List<ExpenseModel>> watchExpenses({required String shopId});

  /// كل مصروفات المحل بترقيم cursor (بلا حد صامت) — لحسابات التقارير.
  Future<PagedResult<ExpenseModel>> fetchAllExpenses({required String shopId});

  /// حدث خفيف (أثر على أحدث مصروف) يعيد تحميل التقارير live.
  Stream<void> watchLatestExpense({required String shopId});

  Future<void> deleteExpense({required String expenseId, required String shopId});

  /// Current user's shopId (`null` when signed out or not yet assigned).
  Future<String?> getShopId();
}
