import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/admin_repo.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object?> get props => [];
}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardEmpty extends AdminDashboardState {}

class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded({
    required this.shops,
    required this.active,
    required this.trial,
    required this.expired,
    required this.pending,
    required this.products,
    required this.sales,
    required this.expenses,
    required this.subscriptionsByMonth,
    required this.shopsByMonth,
    required this.revenueByMonth,
  });

  final int shops;
  final int active;
  final int trial;
  final int expired;
  final int pending;
  final int products;
  final int sales;
  final int expenses;
  final Map<String, int> subscriptionsByMonth;
  final Map<String, int> shopsByMonth;
  final Map<String, int> revenueByMonth;

  @override
  List<Object?> get props => [
        shops, active, trial, expired, pending, products, sales, expenses,
        subscriptionsByMonth, shopsByMonth, revenueByMonth,
      ];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({required this.repo}) : super(AdminDashboardLoading());
  final AdminRepo repo;

  Future<void> load() async {
    emit(AdminDashboardLoading());
    try {
      final results = await Future.wait([
        repo.countShops(),
        repo.countActiveSubscriptions(),
        repo.countTrialSubscriptions(),
        repo.countExpiredSubscriptions(),
        repo.countPendingRequests(),
        repo.countProducts(),
        repo.countSales(),
        repo.countExpenses(),
        repo.subscriptionCountsByMonth(months: 12),
        repo.shopsByMonth(months: 12),
        repo.revenueByMonth(months: 12),
      ]);
      emit(AdminDashboardLoaded(
        shops: results[0] as int,
        active: results[1] as int,
        trial: results[2] as int,
        expired: results[3] as int,
        pending: results[4] as int,
        products: results[5] as int,
        sales: results[6] as int,
        expenses: results[7] as int,
        subscriptionsByMonth: results[8] as Map<String, int>,
        shopsByMonth: results[9] as Map<String, int>,
        revenueByMonth: results[10] as Map<String, int>,
      ));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}
