import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/returns_repo.dart';
import 'returns_list_state.dart';

/// لوجيك قائمة المرتجعات (الـ View غبية — بتنادي بس).
class ReturnsListCubit extends Cubit<ReturnsListState> {
  final ReturnsRepo _repo; // بوابة الداتا.
  StreamSubscription? _sub; // ستريم المرتجعات.

  ReturnsListCubit({required ReturnsRepo repo})
      : _repo = repo,
        super(const ReturnsListState());

  /// تجهيز القائمة: يجيب المحل + يشترك في المرتجعات live.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: ReturnsListStatus.loading, clearError: true));
    final shopId = await _repo.getShopId();
    // مفيش محل.
    if (shopId == null || shopId.isEmpty) {
      emit(state.copyWith(
        status: ReturnsListStatus.failure,
        errorMessage: 'لم يتم العثور على المتجر',
      ));
      return;
    }
    emit(state.copyWith(shopId: shopId));
    await _sub?.cancel();
    // يسمع التحديثات live.
    _sub = _repo.watchReturns(shopId: shopId).listen(
      (returns) {
        if (isClosed) return;
        emit(state.copyWith(status: ReturnsListStatus.success, returns: returns, clearError: true));
      },
      onError: (Object e) {
        if (isClosed) return;
        emit(state.copyWith(
          status: ReturnsListStatus.failure,
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

  /// يحدث فلتر السبب.
  void setReasonFilter(String filter) {
    if (filter == state.reasonFilter) return;
    emit(state.copyWith(reasonFilter: filter));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
