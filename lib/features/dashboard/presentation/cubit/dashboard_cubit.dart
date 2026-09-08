import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/dashboard_repo.dart';
import '../states/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepo _repo;

  DashboardCubit({required DashboardRepo repo})
      : _repo = repo,
        super(const DashboardState());

  void init() {
    _listenShopName();
    loadDashboardData();
  }

  void _listenShopName() {
    _repo.watchShopName().listen((name) {
      if (!isClosed) {
        emit(state.copyWith(shopName: name ?? ''));
      }
    });
  }

  Future<void> loadDashboardData() async {
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      final results = await Future.wait([
        _repo.getTodaySalesTotal(),
        _repo.getTodayReturnsTotal(),
        _repo.getTodayExpensesTotal(),
        _repo.getProductsCount(),
        _repo.getLowStockProductsCount(),
      ]);

      final salesTotal = results[0] as double;
      final returnsTotal = results[1] as double;
      final expensesTotal = results[2] as double;
      final productsCount = results[3] as int;
      final lowStockCount = results[4] as int;

      emit(state.copyWith(
        status: DashboardStatus.success,
        todaySalesTotal: salesTotal,
        todayNetSales: salesTotal - returnsTotal,
        todayExpensesTotal: expensesTotal,
        productsCount: productsCount,
        lowStockCount: lowStockCount,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
