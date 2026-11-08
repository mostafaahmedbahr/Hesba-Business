import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/person_model.dart';
import '../../data/repos/accounts_repo.dart';
import '../states/accounts_state.dart';

/// يدير شاشة الحسابات: ستريم المديونيات والأشخاص، التبويبات،
/// البحث، والفلاتر.
class AccountsCubit extends Cubit<AccountsState> {
  final AccountsRepo _repo;
  StreamSubscription<List<DebtModel>>? _debtsSub;
  StreamSubscription<List<PersonModel>>? _personsSub;

  AccountsCubit({required this._repo}) : super(const AccountsState());

  /// يشترك في مديونيات المحل والأشخاص المحفوظين.
  void init() {
    _debtsSub ??= _repo.watchDebts().listen(
      (list) => emit(
        state.copyWith(
          status: AccountsStatus.success,
          debts: list,
          clearError: true,
        ),
      ),
      onError: (Object e) => emit(
        state.copyWith(status: AccountsStatus.failure, errorMessage: '$e'),
      ),
    );

    _personsSub ??= _repo.watchPersons().listen(
      (list) => emit(state.copyWith(persons: list)),
      onError: (Object e) => logWarning('[AccountsCubit] persons: $e'),
    );

    if (state.status == AccountsStatus.loading) {
      emit(state.copyWith(status: AccountsStatus.success, clearError: true));
    }
  }

  /// تبديل التبويب (عملاء / موردين) — يحتفظ بإعدادات البحث والفلاتر.
  void setTab(AccountsTab tab) {
    if (tab == state.activeTab) return;
    emit(state.copyWith(activeTab: tab));
  }

  /// تحديث البحث المحلي.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// فلترة بحالة السداد — مرّر null لإرجاع الكل.
  void setStatusFilter(DebtStatus? status) {
    emit(state.copyWith(statusFilter: status));
  }

  void setDateFrom(DateTime? date) => emit(state.copyWith(dateFrom: date));

  void setDateTo(DateTime? date) => emit(state.copyWith(dateTo: date));

  /// مسح كل الفلاتر (يبقى البحث كما هو).
  void clearFilters() {
    emit(state.copyWith(
      statusFilter: null,
      dateFrom: null,
      dateTo: null,
    ));
  }

  /// إعادة تحميل القائمة (سحب للتحديث).
  Future<void> refresh() async {
    _debtsSub?.cancel();
    _personsSub?.cancel();
    _debtsSub = null;
    _personsSub = null;
    emit(state.copyWith(status: AccountsStatus.loading, clearError: true));
    init();
  }

  @override
  Future<void> close() {
    _debtsSub?.cancel();
    _personsSub?.cancel();
    return super.close();
  }
}
