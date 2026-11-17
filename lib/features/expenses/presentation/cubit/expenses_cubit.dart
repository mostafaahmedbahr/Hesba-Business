import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/expense_model.dart';
import '../../data/repos/expenses_repo.dart';
import 'expenses_state.dart';
import 'package:hesba/core/services/app_logger.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpensesRepo expensesRepo;
  StreamSubscription<List<ExpenseModel>>? _expensesSubscription;
  StreamSubscription<AppEvent>? _eventSub;
  String? _lastShopId;

  /// Dedicated write guard. Do NOT reuse `state.status == loading`: the list
  /// subscription also sets `loading`, and a submit made while the list is
  /// loading must not be silently dropped.
  bool _saving = false;
  int _loadGeneration = 0;

  ExpensesCubit({required this.expensesRepo}) : super(const ExpensesState()) {
    // أي إضافة/تعديل/حذف من أي Cubit تاني يحدّث القائمة فوراً
    _eventSub = AppEvents.instance.stream.listen((event) {
      if (event.type == AppEventType.expenseCreated ||
          event.type == AppEventType.expenseUpdated ||
          event.type == AppEventType.expenseDeleted) {
        if (_lastShopId != null) loadExpenses(shopId: _lastShopId!);
      }
    });
  }

  void reset() {
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(const ExpensesState());
  }

  Future<String?> _resolveShopId(String? providedShopId) async {
    if (providedShopId != null && providedShopId.isNotEmpty) return providedShopId;
    return expensesRepo.getShopId();
  }

  Future<void> loadExpenses({required String shopId}) async {
    final generation = ++_loadGeneration;
    _lastShopId = shopId;
    _expensesSubscription?.cancel();
    _expensesSubscription = null;
    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    String? resolvedShopId;
    try {
      resolvedShopId = await _resolveShopId(shopId);
    } catch (e, logSt) {
      AppLogger.nonFatal('features/expenses/presentation/cubit/expenses_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed && generation == _loadGeneration) {
        emit(state.copyWith(
          status: ExpensesStatus.error,
          errorMessage: friendlyError(e),
        ));
      }
      return;
    }
    if (isClosed || generation != _loadGeneration) return;
    // مزامنة المصروفات المتكررة (تسجيل أي موعد فات) قبل الاشتراك في
    // الستريم فتظهر أي مصروفات جديدة فورًا.
    try {
      await expensesRepo.syncRecurringExpenses();
    } catch (logErr, logSt) { AppLogger.nonFatal('features/expenses/presentation/cubit/expenses_cubit.dart', logErr, logSt, severity: LoggingSeverity.warning); }
    if (isClosed || generation != _loadGeneration) return;
    // حتى لو الـ shopId فاضي، اعرض الكل (repo بيعمل fallback)
    final effectiveShopId = resolvedShopId ?? shopId;
    _expensesSubscription = expensesRepo.watchExpenses(shopId: effectiveShopId).listen(
      (expenses) {
        if (isClosed) return;
        // القوالب المتكررة ليست مصروفات فعلية — لا تُحتسب في الإجمالي.
        final total = expenses
            .where((e) => !e.isTemplate)
            .fold<double>(0, (acc, e) => acc + e.amount);
        emit(state.copyWith(
          status: ExpensesStatus.success,
          expenses: expenses,
          totalAmount: total,
        ));
      },
      onError: (e) {
        if (isClosed) return;
        final msg = friendlyError(e);
        emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
      },
    );
  }

  Future<void> addExpense({
    required String ownerId,
    required String shopId,
    required String  shopName,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
    String recurrence = 'none',
    String dueTime = '',
  }) async {
    if (_saving) return;
    if (title.trim().isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'عنوان المصروف مطلوب'));
      return;
    }
    if (amount <= 0) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'المبلغ يجب أن يكون أكبر من صفر'));
      return;
    }
    if (category.isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'اختر تصنيف المصروف'));
      return;
    }

    _saving = true;
    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    try {
      final expense = await expensesRepo.addExpense(
        ownerId: ownerId,
        shopId: shopId,
        shopName: shopName,
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
        recurrence: recurrence,
        dueTime: dueTime,
      );
      AppEvents.instance.expenseCreated({
        'title': title,
        'amount': amount,
        'category': category,
      });
      AppEvents.instance.productChanged();
      if (!isClosed) {
        emit(state.copyWith(status: ExpensesStatus.success, addedExpense: expense, errorMessage: null));
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/expenses/presentation/cubit/expenses_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      final msg = friendlyError(e);
      if (!isClosed) emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
    } finally {
      _saving = false;
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String ownerId,
    required String shopId,
    required String shopName,
    required String title,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
    String recurrence = 'none',
    String dueTime = '',
  }) async {
    if (_saving) return;
    if (title.trim().isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'عنوان المصروف مطلوب'));
      return;
    }
    if (amount <= 0) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'المبلغ يجب أن يكون أكبر من صفر'));
      return;
    }
    if (category.isEmpty) {
      emit(state.copyWith(status: ExpensesStatus.error, errorMessage: 'اختر تصنيف المصروف'));
      return;
    }

    _saving = true;
    emit(state.copyWith(status: ExpensesStatus.loading, errorMessage: null));
    try {
      final expense = await expensesRepo.updateExpense(
        expenseId: expenseId,
        ownerId: ownerId,
        shopId: shopId,
        shopName: shopName,
        title: title,
        category: category,
        amount: amount,
        note: note,
        date: date,
        recurrence: recurrence,
        dueTime: dueTime,
      );
      AppEvents.instance.expenseUpdated({
        'title': title,
        'amount': amount,
        'category': category,
      });
      AppEvents.instance.productChanged();
      if (!isClosed) {
        emit(state.copyWith(status: ExpensesStatus.success, addedExpense: expense, errorMessage: null));
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/expenses/presentation/cubit/expenses_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      final msg = friendlyError(e);
      if (!isClosed) emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
    } finally {
      _saving = false;
    }
  }

  /// يحدث البحث.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// يحدث فلتر التصنيف.
  void setCategoryFilter(String filter) {
    if (filter == state.categoryFilter) return;
    emit(state.copyWith(categoryFilter: filter));
  }

  /// يحذف مصروف. التفاصيل (title/amount) اختيارية وبتتحط في سجل العمليات
  /// والإشعار عشان اللي يقرا يعرف أنهي مصروف اتحذف وكم كان.
  Future<void> deleteExpense({
    required String expenseId,
    required String shopId,
    String title = '',
    double amount = 0,
    String category = '',
  }) async {
    if (_saving) return;
    _saving = true;
    try {
      await expensesRepo.deleteExpense(expenseId: expenseId, shopId: shopId);
      AppEvents.instance.expenseDeleted({
        'title': title,
        'amount': amount,
        'category': category,
      });
      AppEvents.instance.productChanged();
      if (!isClosed) emit(state.copyWith(status: ExpensesStatus.success));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/expenses/presentation/cubit/expenses_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      final msg = friendlyError(e);
      if (!isClosed) {
        emit(state.copyWith(status: ExpensesStatus.error, errorMessage: msg));
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    _eventSub?.cancel();
    return super.close();
  }
}
