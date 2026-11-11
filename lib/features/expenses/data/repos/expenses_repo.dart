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

    /// اختياري: تكرار المصروف — 'none' (الافتراضي) أو daily/weekly/monthly.
    String recurrence,

    /// 'HH:mm' موعد الاستحقاق (مطلوب عندما recurrence != 'none').
    String dueTime,
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
    String recurrence,
    String dueTime,
  });

  /// مزامنة المصروفات المتكررة: يسجل تلقائيًا أي موعد فات (طبيقية
  /// المستندات `expenses` الجديدة بنفس بيانات القالب) ويحدّث الموعد
  /// القادم، ثم يعيد ضبط الإشعارات لكل قالب.
  ///
  /// يعيد عدد المواعد المولّدة. يُستدعى عند فتح التطبيق وفي كل
  /// إضافة/تعديل/حذف مصروف — العملية ذرّية ولا تُولّد أي تكرار
  /// مكرر عند الفتح المتزامن من أكثر من جهاز.
  Future<int> syncRecurringExpenses();

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
