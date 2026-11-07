import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../data/repos/suppliers_repo.dart';
import '../states/supplier_details_state.dart';

/// يدير شاشة تفاصيل المورد: تحميله مع منتجاته المرتبطة، تعديل ملاحظاته،
/// وحذفه مع منع الحذف عند وجود منتجات مرتبطة.
class SupplierDetailsCubit extends Cubit<SupplierDetailsState> {
  final SuppliersRepo _repo;

  SupplierDetailsCubit({required this._repo})
    : super(const SupplierDetailsState());

  /// يحمّل المورد ومنتجاته المرتبطة. آمن أكثر من مرة.
  Future<void> load(String supplierId) async {
    emit(const SupplierDetailsState());
    try {
      final supplier = await _repo.getSupplierById(supplierId);
      if (supplier == null) {
        emit(
          state.copyWith(
            status: SupplierDetailsStatus.failure,
            errorMessage: 'supplierErrNotFound',
          ),
        );
        return;
      }
      final products = await _repo.getLinkedProducts(supplierId);
      emit(
        state.copyWith(
          status: SupplierDetailsStatus.success,
          supplier: supplier,
          linkedProducts: products,
          clearError: true,
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[SupplierDetailsCubit] load failed: $msg');
      emit(
        state.copyWith(
          status: SupplierDetailsStatus.failure,
          errorMessage: msg,
        ),
      );
    }
  }

  /// حفظ ملاحظات المورد (بدون أي بيانات مالية).
  Future<bool> saveNotes(String notes) async {
    final supplier = state.supplier;
    if (supplier == null || state.busy) return false;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final updated = await _repo.updateSupplier(
        supplierId: supplier.id,
        notes: notes,
      );
      // إعادة تحميل المنتجات حتى يظهر اسم المورد المحدّث في اللقطة.
      final products = await _repo.getLinkedProducts(supplier.id);
      emit(
        state.copyWith(
          status: SupplierDetailsStatus.success,
          supplier: updated,
          linkedProducts: products,
          busy: false,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[SupplierDetailsCubit] saveNotes failed: $msg');
      emit(state.copyWith(busy: false, errorMessage: msg));
      return false;
    }
  }

  /// حذف المورد — يفشل برسالة واضحة عند وجود منتجات مرتبطة.
  Future<bool> delete() async {
    final supplier = state.supplier;
    if (supplier == null || state.busy) return false;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.deleteSupplier(supplier.id);
      emit(state.copyWith(busy: false, clearError: true));
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[SupplierDetailsCubit] delete failed: $msg');
      emit(state.copyWith(busy: false, errorMessage: msg));
      return false;
    }
  }
}
