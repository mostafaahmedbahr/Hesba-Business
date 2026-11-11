import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/sale_model.dart';
import '../../data/repos/sales_repo.dart';
import 'customer_sales_state.dart';

/// يدير شاشة «سجل مشتريات العميل»: ستريم حيّ لفواتير عميل معين.
class CustomerSalesCubit extends Cubit<CustomerSalesState> {
  final SalesRepo _repo;
  StreamSubscription<List<SaleModel>>? _sub;

  CustomerSalesCubit({required this._repo}) : super(const CustomerSalesState());

  /// يبدأ الاستماع لفواتير [personId] داخل [shopId].
  void init({
    required String shopId,
    required String personId,
    required String personName,
    required String personPhone,
  }) {
    emit(state.copyWith(
      status: CustomerSalesStatus.loading,
      shopId: shopId,
      personId: personId,
      personName: personName,
      personPhone: personPhone,
      clearError: true,
    ));
    if (personId.isEmpty) {
      emit(state.copyWith(
        status: CustomerSalesStatus.failure,
        errorMessage: 'customerSalesMissingPerson',
      ));
      return;
    }
    _sub?.cancel();
    _sub = _repo
        .watchSalesForPerson(shopId: shopId, personId: personId)
        .listen(
      (list) => emit(state.copyWith(
        status: CustomerSalesStatus.success,
        sales: list,
        clearError: true,
      )),
      onError: (Object e) => emit(state.copyWith(
        status: CustomerSalesStatus.failure,
        errorMessage: '$e',
      )),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
