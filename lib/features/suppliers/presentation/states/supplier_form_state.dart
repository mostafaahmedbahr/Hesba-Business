import 'package:equatable/equatable.dart';

enum SupplierFormStatus { idle, saving, success, failure }

/// حالة نموذج إضافة/تعديل المورد.
///
/// [saving] هي الحارس ضد تكرار الإرسال: أي ضغطة أثناء الحفظ تُتجاهل.
/// [saved] = true بعد نجاح الحفظ (لإغلاق الشاشة مرة واحدة).
///
/// أخطاء الحقول ([nameError] / [phoneError] / [secondaryPhoneError] /
/// [emailError]) بتتحدث مع كل حرف أثناء الكتابة (live validation) —
/// يعني الرسالة تحت الحقل بتظهر بمجرد ما الرقم/البريد يكون غلط،
/// وبتختفي أول ما يتصلّح. [errorMessage] مخصص لأخطاء الحفظ/السيرفر
/// (و للرسائل العامة والـ listener بتاع الـ toast).
class SupplierFormState extends Equatable {
  final SupplierFormStatus status;
  final String? errorMessage;

  /// أخطاء كل حقل على حدة (بمفاتيح الترجمة) — بتتحدث لحظيًا أثناء الكتابة.
  final String? nameError;
  final String? phoneError;
  final String? secondaryPhoneError;
  final String? emailError;

  /// القيم المعبّأة لعرضها مجدداً بعد فشل الحفظ.
  final String name;
  final String phone;
  final String companyName;
  final String secondaryPhone;
  final String email;
  final String address;
  final String city;
  final String notes;

  const SupplierFormState({
    this.status = SupplierFormStatus.idle,
    this.errorMessage,
    this.nameError,
    this.phoneError,
    this.secondaryPhoneError,
    this.emailError,
    this.name = '',
    this.phone = '',
    this.companyName = '',
    this.secondaryPhone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.notes = '',
  });

  bool get isSaving => status == SupplierFormStatus.saving;
  bool get saved => status == SupplierFormStatus.success;

  SupplierFormState copyWith({
    SupplierFormStatus? status,
    Object? errorMessage = _sentinel,
    Object? nameError = _sentinel,
    Object? phoneError = _sentinel,
    Object? secondaryPhoneError = _sentinel,
    Object? emailError = _sentinel,
    String? name,
    String? phone,
    String? companyName,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? notes,
  }) {
    return SupplierFormState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      nameError: identical(nameError, _sentinel)
          ? this.nameError
          : nameError as String?,
      phoneError: identical(phoneError, _sentinel)
          ? this.phoneError
          : phoneError as String?,
      secondaryPhoneError: identical(secondaryPhoneError, _sentinel)
          ? this.secondaryPhoneError
          : secondaryPhoneError as String?,
      emailError: identical(emailError, _sentinel)
          ? this.emailError
          : emailError as String?,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      notes: notes ?? this.notes,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    nameError,
    phoneError,
    secondaryPhoneError,
    emailError,
    name,
    phone,
    companyName,
    secondaryPhone,
    email,
    address,
    city,
    notes,
  ];
}
