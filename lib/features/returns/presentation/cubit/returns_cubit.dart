import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/return_model.dart';
import '../../data/repos/returns_repo.dart';
import 'returns_state.dart';
import 'package:hesba/core/services/app_logger.dart';

class ReturnsCubit extends Cubit<ReturnsState> {
  final ReturnsRepo returnsRepo;

  ReturnsCubit({required this.returnsRepo}) : super(const ReturnsState());

  void reset() => emit(const ReturnsState());

  Future<void> addReturn({
    required String ownerId,
    required String shopId,
    String? originalSaleId,
    required List<ReturnItemModel> items,
    required String reason,
    required String note,
  }) async {
    // Re-entrancy guard: a second tap while the first write is in flight must
    // never reach the repo (two returns would double-refund and double-reverse COGS).
    if (state.status == ReturnsStatus.loading) return;
    if (items.isEmpty) {
      emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'retErrMinOne'));
      return;
    }
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'retErrNameRequired'));
        return;
      }
      if (item.quantity <= 0) {
        emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'retErrQtyPositive', errorArgs: {'name': item.productName}));
        return;
      }
    }
    if (reason.trim().isEmpty) {
      emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'retErrReasonRequired'));
      return;
    }

    emit(state.copyWith(status: ReturnsStatus.loading, errorMessage: null));

    try {
      final ret = await returnsRepo.addReturn(
        ownerId: ownerId,
        shopId: shopId,
        originalSaleId: originalSaleId,
        items: items,
        reason: reason,
        note: note,
      );

      AppEvents.instance.returnCreated({
        'total': ret.total,
        'reason': ret.reason,
        'items': ret.items
            .map((i) => {'name': i.productName, 'qty': i.quantity})
            .toList(),
      });
      AppEvents.instance.productChanged();

      if (!isClosed) {
        emit(ReturnsState(status: ReturnsStatus.success, ret: ret));
      }
    } catch (e, logSt) {
      AppLogger.nonFatal('features/returns/presentation/cubit/returns_cubit.dart', e, logSt, severity: LoggingSeverity.warning);
      final msg = friendlyError(e);
      if (!isClosed) {
        emit(ReturnsState(status: ReturnsStatus.error, errorMessage: msg));
      }
    }
  }
}
