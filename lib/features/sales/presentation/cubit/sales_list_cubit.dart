import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/sales_repo.dart';
import 'sales_list_state.dart';

/// لوجيك قائمة المبيعات (الـ View غبية — بتنادي بس).
class SalesListCubit extends Cubit<SalesListState> {
  final SalesRepo _repo; // بوابة الداتا.
  StreamSubscription? _sub; // ستريم المبيعات.

  SalesListCubit({required SalesRepo repo})
      : _repo = repo,
        super(const SalesListState());

  /// تجهيز القائمة: يجيب المحل + يشترك في المبيعات live.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: SalesListStatus.loading, clearError: true));
    final shopId = await _repo.getShopId();
    // مفيش محل.
    if (shopId == null || shopId.isEmpty) {
      emit(state.copyWith(
        status: SalesListStatus.failure,
        errorMessage: 'لم يتم العثور على المتجر',
      ));
      return;
    }
    emit(state.copyWith(shopId: shopId));
    await _sub?.cancel();
    // يسمع التحديثات live.
    _sub = _repo.watchSales(shopId: shopId).listen(
      (sales) {
        if (isClosed) return;
        emit(state.copyWith(status: SalesListStatus.success, sales: sales, clearError: true));
      },
      onError: (Object e) {
        if (isClosed) return;
        emit(state.copyWith(
          status: SalesListStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ));
      },
    );
  }

  /// يحدث البحث.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// يحدث فلتر الدفع.
  void setPaymentFilter(String filter) {
    if (filter == state.paymentFilter) return;
    emit(state.copyWith(paymentFilter: filter));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
