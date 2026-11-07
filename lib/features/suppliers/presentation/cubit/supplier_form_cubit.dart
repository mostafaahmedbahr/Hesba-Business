import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repos/suppliers_repo.dart';
import '../states/supplier_form_state.dart';

/// يدير نموذج إضافة/تعديل المورد: تعبئة القيم، التحقق، الحفظ،
/// والحماية من إرسال مزدوج أثناء الحفظ.
class SupplierFormCubit extends Cubit<SupplierFormState> {
  final SuppliersRepo _repo;

  SupplierFormCubit({required this._repo}) : super(const SupplierFormState());

  /// يعبّئ الحقول من مورد موجود (وضع التعديل). آمن أكثر من مرة.
  void initForEdit({
    required String name,
    required String phone,
    required String companyName,
    required String secondaryPhone,
    required String email,
    required String address,
    required String city,
    required String notes,
  }) {
    emit(
      state.copyWith(
        name: name,
        phone: phone,
        companyName: companyName,
        secondaryPhone: secondaryPhone,
        email: email,
        address: address,
        city: city,
        notes: notes,
      ),
    );
  }

  // ── تحديث الحقول ──
  void onNameChanged(String v) => emit(state.copyWith(name: v));
  void onPhoneChanged(String v) => emit(state.copyWith(phone: v));
  void onCompanyNameChanged(String v) => emit(state.copyWith(companyName: v));
  void onSecondaryPhoneChanged(String v) =>
      emit(state.copyWith(secondaryPhone: v));
  void onEmailChanged(String v) => emit(state.copyWith(email: v));
  void onAddressChanged(String v) => emit(state.copyWith(address: v));
  void onCityChanged(String v) => emit(state.copyWith(city: v));
  void onNotesChanged(String v) => emit(state.copyWith(notes: v));

  /// تحقق مبكر من الحقول المطلوبة قبل الحفظ (رسائل عربية مفهومة).
  /// يرجع رسالة الخطأ أو null لو كل شيء سليم.
  String? validate() {
    if (state.name.trim().isEmpty) return 'supplierErrNameRequired';
    if (state.phone.trim().isEmpty) return 'supplierErrPhoneRequired';
    return null;
  }

  /// حفظ المورد. [supplierId] != null يعني وضع التعديل.
  ///
  /// يتجاهل أي استدعاء أثناء الحفظ (حارس من تكرار الإرسال).
  /// يرجع المورد المحفوظ بعد النجاح، أو null بعد الفشل.
  Future<SupplierModel?> submit({String? supplierId}) async {
    if (state.status == SupplierFormStatus.saving) return null;

    final validationError = validate();
    if (validationError != null) {
      emit(
        state.copyWith(
          status: SupplierFormStatus.failure,
          errorMessage: validationError,
        ),
      );
      return null;
    }

    emit(state.copyWith(status: SupplierFormStatus.saving, errorMessage: null));

    try {
      final saved = supplierId == null
          ? await _repo.addSupplier(
              name: state.name,
              phone: state.phone,
              companyName: state.companyName,
              secondaryPhone: state.secondaryPhone,
              email: state.email,
              address: state.address,
              city: state.city,
              notes: state.notes,
            )
          : await _repo.updateSupplier(
              supplierId: supplierId,
              name: state.name,
              phone: state.phone,
              companyName: state.companyName,
              secondaryPhone: state.secondaryPhone,
              email: state.email,
              address: state.address,
              city: state.city,
              notes: state.notes,
            );
      emit(state.copyWith(status: SupplierFormStatus.success));
      return saved;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[SupplierFormCubit] save failed: $msg');
      emit(
        state.copyWith(status: SupplierFormStatus.failure, errorMessage: msg),
      );
      return null;
    }
  }

  /// يشيل رسالة الخطأ بعد عرضها.
  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }
  }
}
