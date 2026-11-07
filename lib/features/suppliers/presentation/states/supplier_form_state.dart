import 'package:equatable/equatable.dart';

enum SupplierFormStatus { idle, saving, success, failure }

/// حالة نموذج إضافة/تعديل المورد.
///
/// [saving] هي الحارس ضد تكرار الإرسال: أي ضغطة أثناء الحفظ تُتجاهل.
/// [saved] = true بعد نجاح الحفظ (لإغلاق الشاشة مرة واحدة).
class SupplierFormState extends Equatable {
  final SupplierFormStatus status;
  final String? errorMessage;

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
