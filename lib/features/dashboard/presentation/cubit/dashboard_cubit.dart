import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/repos/dashboard_repo.dart';
import '../states/dashboard_state.dart';
import 'package:hesba/core/services/app_logger.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepo _repo;
  StreamSubscription<({String? name, String? imageUrl})>? _shopSub;
  StreamSubscription<AppEvent>? _appEventSub;
  DateTime? _lastLoadTime;
  bool _isLoading = false;

  DashboardCubit({required this._repo})
      : super(const DashboardState());

  /// الأرقام بتتحدّث من [AppEvents] بعد كل عملية كتابة، ومن السحب للتحديث،
  /// ومن الأزرار اللي بتنادى [refresh]. مفيش listener على كوليكشن كامل.
  void init() {
    _listenShopIdentity();
    _listenAppEvents();
    loadDashboardData();
  }

  void _listenShopIdentity() {
    _shopSub?.cancel();
    _shopSub = _repo.watchShopIdentity().listen((shop) {
      if (!isClosed) {
        emit(
          state.copyWith(
            shopName: shop.name ?? '',
            shopImageUrl: shop.imageUrl ?? '',
          ),
        );
      }
    });
  }

  void _listenAppEvents() {
    _appEventSub?.cancel();
    _appEventSub = AppEvents.instance.stream.listen((event) {
      if (event.type == AppEventType.saleCreated ||
          event.type == AppEventType.returnCreated ||
          event.type == AppEventType.expenseCreated ||
          event.type == AppEventType.productChanged) {
        if (!isClosed) loadDashboardData();
      }
    });
  }

  /// Public method to allow manual refresh after sale/return/expense actions
  /// Only triggers load if not already loading and not recently loaded
  Future<void> refresh() {
    if (_isLoading) return Future.value();
    if (_lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < const Duration(milliseconds: 500)) {
      return Future.value();
    }
    return loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    if (isClosed) return;
    if (_isLoading) return;
    _isLoading = true;
    _lastLoadTime = DateTime.now();
    emit(state.copyWith(status: DashboardStatus.loading));

    try {
      // Resolve the user's shop once per load. Previously all six calls below
      // re-read users/{uid}, i.e. six identical reads on every dashboard refresh.
      // Pass a non-null sentinel when signed out so the repo methods never
      // re-read users/{uid}; an empty shopId simply matches no documents.
      final shopId = await _repo.getShopId() ?? '';
      // Today's money metrics now come from a single pass per collection
      // (sales/returns/expenses read once each instead of twice).
      final results = await Future.wait([
        _repo.getTodaySummary(shopId: shopId),
        _repo.getProductsCount(shopId: shopId),
        _repo.getLowStockProductsCount(shopId: shopId),
      ]);

      final today = results[0] as TodaySummary;
      final byMethod = today.salesByMethod;
      final salesTotal = byMethod.values.fold<double>(0, (s, v) => s + v);
      final returnsTotal = today.returnsTotal;
      final returnsCount = today.returnsCount;
      final expensesTotal = today.expensesTotal;
      final productsCount = results[1] as int;
      final lowStockCount = results[2] as int;

      if (isClosed) return;
      emit(state.copyWith(
        status: DashboardStatus.success,
        todaySalesTotal: salesTotal,
        todaySalesByMethod: byMethod,
        todayReturnsTotal: returnsTotal,
        todayReturnsCount: returnsCount,
        todayNetSales: salesTotal - returnsTotal,
        todayExpensesTotal: expensesTotal,
        productsCount: productsCount,
        lowStockCount: lowStockCount,
        clearError: true,
        hasLoaded: true,
        refreshRevision: state.refreshRevision + 1,
      ));
    } catch (e, logSt) {
      AppLogger.nonFatal('features/dashboard/presentation/cubit/dashboard_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (isClosed) return;
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: friendlyError(e),
      ));
    } finally {
      _isLoading = false;
    }
  }

  @override
  Future<void> close() {
    _shopSub?.cancel();
    _appEventSub?.cancel();
    return super.close();
  }
}
