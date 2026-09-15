import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../data/repos/dashboard_repo.dart';
import '../states/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepo _repo;
  StreamSubscription<void>? _dashboardSub;
  StreamSubscription<String?>? _shopNameSub;
  StreamSubscription<AppEvent>? _appEventSub;
  Timer? _debounce;

  DashboardCubit({required DashboardRepo repo})
      : _repo = repo,
        super(const DashboardState());

  void init() {
    _listenShopName();
    loadDashboardData();
    _startAutoRefresh();
    _listenAppEvents();
  }

  void _listenShopName() {
    _shopNameSub?.cancel();
    _shopNameSub = _repo.watchShopName().listen((name) {
      if (!isClosed) {
        emit(state.copyWith(shopName: name ?? ''));
      }
    });
  }

  void _startAutoRefresh() {
    _dashboardSub?.cancel();
    _dashboardSub = _repo.watchDashboardChanges().listen((_) {
      // Debounce to avoid spamming Firestore with rapid consecutive loads
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        if (!isClosed) loadDashboardData();
      });
    });
  }

  void _listenAppEvents() {
    _appEventSub?.cancel();
    _appEventSub = AppEvents.instance.stream.listen((event) {
      if (event.type == AppEventType.saleCreated ||
          event.type == AppEventType.returnCreated ||
          event.type == AppEventType.expenseCreated ||
          event.type == AppEventType.productChanged) {
        // Immediate refresh without debounce for user-triggered events
        if (!isClosed) loadDashboardData();
      }
    });
  }

  /// Public method to allow manual refresh after sale/return/expense actions
  Future<void> refresh() => loadDashboardData();

  Future<void> loadDashboardData() async {
    if (isClosed) return;
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

      if (isClosed) return;
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
      if (isClosed) return;
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _dashboardSub?.cancel();
    _shopNameSub?.cancel();
    _appEventSub?.cancel();
    return super.close();
  }
}
