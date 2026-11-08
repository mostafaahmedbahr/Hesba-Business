import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../../core/utils/validators.dart';
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

  // مفاتيح الأخطاء المرتبطة بكل حقل (لرسائل الحفظ العامة في [errorMessage]).
  static bool _isNameKey(String? key) => key == 'supplierErrNameRequired';
  static bool _isPhoneKey(String? key) =>
      key == 'supplierErrPhoneRequired' ||
      key == 'supplierErrPhoneInvalid' ||
      key == 'supplierErrPhoneInvalidEgypt' ||
      key == 'supplierErrDuplicatePhone';
  static bool _isSecondaryPhoneKey(String? key) =>
      key == 'supplierErrSecondaryPhoneInvalidEgypt';
  static bool _isEmailKey(String? key) => key == 'supplierErrEmailInvalid';

  // ── تحقق لحظي (live) لأخطاء الفورمات — بيتنفذ مع كل حرف ──
  // الحقول الفارغة ما بتطلعش خطأ وهي لسه فاضية؛ الخطأ بيظهر بس
  // لما المستخدم يكتب قيمة غلط، وبيختفي لما يتصلّح.
  String? _livePhoneError(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return Validators.egyptianPhone(t) != null
        ? 'supplierErrPhoneInvalidEgypt'
        : null;
  }

  String? _liveSecondaryPhoneError(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return Validators.optionalEgyptianPhone(t) != null
        ? 'supplierErrSecondaryPhoneInvalidEgypt'
        : null;
  }

  String? _liveEmailError(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return Validators.optionalEmail(t) != null
        ? 'supplierErrEmailInvalid'
        : null;
  }

  // ── تحديث الحقول ──
  void onNameChanged(String v) => emit(
    state.copyWith(
      name: v,
      // لو فيه خطأ "الاسم مطلوب" ظاهر والحقل اتكتب فيه — شيله فورًا.
      nameError: v.trim().isNotEmpty ? null : state.nameError,
      errorMessage:
          _isNameKey(state.errorMessage) ? null : state.errorMessage,
    ),
  );
  void onPhoneChanged(String v) => emit(
    state.copyWith(
      phone: v,
      // بيتحدث مع كل حرف: يظهر أول ما الرقم يبقى غلط ويختفي لما يتظبط.
      phoneError: _livePhoneError(v),
      errorMessage: _isPhoneKey(state.errorMessage) ? null : state.errorMessage,
    ),
  );
  void onCompanyNameChanged(String v) => emit(state.copyWith(companyName: v));
  void onSecondaryPhoneChanged(String v) => emit(
    state.copyWith(
      secondaryPhone: v,
      secondaryPhoneError: _liveSecondaryPhoneError(v),
      errorMessage: _isSecondaryPhoneKey(state.errorMessage)
          ? null
          : state.errorMessage,
    ),
  );
  void onEmailChanged(String v) => emit(
    state.copyWith(
      email: v,
      emailError: _liveEmailError(v),
      errorMessage: _isEmailKey(state.errorMessage)
          ? null
          : state.errorMessage,
    ),
  );
  void onAddressChanged(String v) => emit(state.copyWith(address: v));
  void onCityChanged(String v) => emit(state.copyWith(city: v));
  void onNotesChanged(String v) => emit(state.copyWith(notes: v));

  /// خطأ الهاتف وقت الحفظ: فاضي → مطلوب، مكتوب غلط → صيغة غير سليمة.
  String? _submitPhoneError() {
    final t = state.phone.trim();
    if (t.isEmpty) return 'supplierErrPhoneRequired';
    return Validators.egyptianPhone(t) != null
        ? 'supplierErrPhoneInvalidEgypt'
        : null;
  }

  /// تحقق مبكر من الحقول المطلوبة قبل الحفظ (رسائل عربية مفهومة).
  /// يرجع رسالة الخطأ أو null لو كل شيء سليم.
  String? validate() {
    if (state.name.trim().isEmpty) return 'supplierErrNameRequired';
    if (state.phone.trim().isEmpty) return 'supplierErrPhoneRequired';
    // نفس تحقق التسجيل (010/011/012/015) — الرسائل بالعربية الجاهزة.
    if (Validators.egyptianPhone(state.phone) != null) {
      return 'supplierErrPhoneInvalidEgypt';
    }
    if (Validators.optionalEgyptianPhone(state.secondaryPhone) != null) {
      return 'supplierErrSecondaryPhoneInvalidEgypt';
    }
    if (Validators.optionalEmail(state.email) != null) {
      return 'supplierErrEmailInvalid';
    }
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
      // عبّي أخطاء كل حقل عشان تظهر تحت الحقول مباشرة (حتى لو المستخدم
      // لسه ما لمسش الحقل خالص وضغط حفظ).
      emit(
        state.copyWith(
          status: SupplierFormStatus.failure,
          errorMessage: validationError,
          nameError:
              state.name.trim().isEmpty ? 'supplierErrNameRequired' : null,
          phoneError: _submitPhoneError(),
          secondaryPhoneError: _liveSecondaryPhoneError(state.secondaryPhone),
          emailError: _liveEmailError(state.email),
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
      emit(
        state.copyWith(
          status: SupplierFormStatus.success,
          errorMessage: null,
          nameError: null,
          phoneError: null,
          secondaryPhoneError: null,
          emailError: null,
        ),
      );
      return saved;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[SupplierFormCubit] save failed: $msg');
      emit(
        state.copyWith(
          status: SupplierFormStatus.failure,
          errorMessage: msg,
          // رقم مكرر من السيرفر؟ يرجع يظهر تحت خانة الهاتف مباشرة.
          phoneError: msg == 'supplierErrDuplicatePhone'
              ? msg
              : state.phoneError,
        ),
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
