import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../data/models/return_model.dart';
import '../../data/repos/returns_repo.dart';
import 'returns_state.dart';

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
    if (items.isEmpty) {
      emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'أضف منتج واحد على الأقل'));
      return;
    }
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'اسم المنتج مطلوب'));
        return;
      }
      if (item.quantity <= 0) {
        emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'الكمية يجب أن تكون أكبر من صفر: ${item.productName}'));
        return;
      }
    }
    if (reason.trim().isEmpty) {
      emit(state.copyWith(status: ReturnsStatus.error, errorMessage: 'اختر سبب المرتجع'));
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

      AppEvents.instance.returnCreated();
      AppEvents.instance.productChanged();

      emit(ReturnsState(status: ReturnsStatus.success, ret: ret));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(ReturnsState(status: ReturnsStatus.error, errorMessage: msg));
    }
  }
}
