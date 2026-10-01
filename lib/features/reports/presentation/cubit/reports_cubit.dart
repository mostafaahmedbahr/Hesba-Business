import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/data/repos/expenses_repo.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../returns/data/repos/returns_repo.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../../sales/data/repos/sales_repo.dart';
import 'reports_state.dart';

/// لوجيك التقارير (3 ستريمات + فترة — الـ View غبية).
class ReportsCubit extends Cubit<ReportsState> {
  final SalesRepo _salesRepo;
  final ReturnsRepo _returnsRepo;
  final ExpensesRepo _expensesRepo;
  StreamSubscription<List<SaleModel>>? _salesSub;
  StreamSubscription<List<ReturnModel>>? _returnsSub;
  StreamSubscription<List<ExpenseModel>>? _expensesSub;

  ReportsCubit({
    required SalesRepo salesRepo,
    required ReturnsRepo returnsRepo,
    required ExpensesRepo expensesRepo,
  })  : _salesRepo = salesRepo,
        _returnsRepo = returnsRepo,
        _expensesRepo = expensesRepo,
        super(const ReportsState());

  /// تجهيز: يجيب المحل + يشترك live في القوائم التلاتة.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: ReportsStatus.loading, clearError: true));
    final shopId = await _salesRepo.getShopId();
    // مفيش محل.
    if (shopId == null || shopId.isEmpty) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: 'لم يتم العثور على المتجر',
      ));
      return;
    }
    emit(state.copyWith(shopId: shopId));
    await _cancelAll();
    // المبيعات live (آخر 300).
    _salesSub = _salesRepo.watchSales(shopId: shopId).listen(
      (list) {
        if (isClosed) return;
        final capped = list.length > 300 ? list.sublist(0, 300) : list;
        emit(state.copyWith(status: ReportsStatus.success, allSales: capped, clearError: true));
      },
      onError: (Object e) => _fail(e),
    );
    // المرتجعات live.
    _returnsSub = _returnsRepo.watchReturns(shopId: shopId).listen(
      (list) {
        if (isClosed) return;
        final capped = list.length > 300 ? list.sublist(0, 300) : list;
        emit(state.copyWith(status: ReportsStatus.success, allReturns: capped, clearError: true));
      },
      onError: (Object e) => _fail(e),
    );
    // المصروفات live.
    _expensesSub = _expensesRepo.watchExpenses(shopId: shopId).listen(
      (list) {
        if (isClosed) return;
        final capped = list.length > 300 ? list.sublist(0, 300) : list;
        emit(state.copyWith(status: ReportsStatus.success, allExpenses: capped, clearError: true));
      },
      onError: (Object e) => _fail(e),
    );
  }

  /// يغير الفترة (فوري — الداتا في الذاكرة).
  void setPeriod(ReportPeriod period) {
    if (period == state.period) return;
    emit(state.copyWith(period: period));
  }

  void _fail(Object e) {
    if (isClosed) return;
    emit(state.copyWith(
      status: ReportsStatus.failure,
      errorMessage: e.toString().replaceAll('Exception: ', ''),
    ));
  }

  Future<void> _cancelAll() async {
    await _salesSub?.cancel();
    await _returnsSub?.cancel();
    await _expensesSub?.cancel();
  }

  @override
  Future<void> close() {
    _cancelAll();
    return super.close();
  }
}
