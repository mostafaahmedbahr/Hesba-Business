import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_events.dart';
import '../../data/models/sale_model.dart';
import '../../data/repos/sales_repo.dart';
import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final SalesRepo salesRepo;

  SalesCubit({
    required this.salesRepo,
  }) : super(const SalesState());

  void reset() => emit(const SalesState());

  Future<void> addSale({
    required String ownerId,
    required String shopId,
    required List<SaleItemModel> items,
    required double discount,
    required String paymentMethod,
    required String note,
  }) async {
    // Client-side validation for better UX before hitting repo
    if (items.isEmpty) {
      emit(
        state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'أضف منتج واحد على الأقل',
        ),
      );
      return;
    }

    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'اسم المنتج مطلوب في أحد الأسطر',
        ));
        return;
      }
      if (item.quantity <= 0) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'الكمية يجب أن تكون أكبر من صفر: ${item.productName}',
        ));
        return;
      }
      if (item.unitPrice <= 0) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'السعر يجب أن يكون أكبر من صفر: ${item.productName}',
        ));
        return;
      }
    }

    if (discount < 0) {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: 'الخصم لا يمكن أن يكون سالباً',
      ));
      return;
    }

    emit(
      state.copyWith(
        status: SalesStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final sale = await salesRepo.addSale(
        ownerId: ownerId,
        shopId: shopId,
        items: items,
        discount: discount,
        paymentMethod: paymentMethod,
        note: note,
      );

      // Notify whole app (Home, Dashboard, etc.) to refresh
      AppEvents.instance.saleCreated();
      AppEvents.instance.productChanged();

      emit(
        SalesState(
          status: SalesStatus.success,
          sale: sale,
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(
        SalesState(
          status: SalesStatus.error,
          errorMessage: msg,
        ),
      );
    }
  }
}
