import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_message.dart';
import '../../data/repos/returns_repo.dart';
import 'returns_list_state.dart';
import 'package:hesba/core/services/app_logger.dart';

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
    String? shopId;
    try {
      shopId = await _repo.getShopId();
    } catch (e, logSt) {
      AppLogger.nonFatal('features/returns/presentation/cubit/returns_list_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      if (!isClosed) {
        emit(state.copyWith(
          status: ReturnsListStatus.failure,
          errorMessage: friendlyError(e),
        ));
      }
      return;
    }
    if (isClosed) return;
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
          errorMessage: friendlyError(e),
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
