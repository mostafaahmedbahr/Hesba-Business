import '../../data/models/product_fields_catalog.dart';
import '../../data/models/product_form_config.dart';

enum ProductFormStatus { loading, ready, failure }

/// حالة نموذج إضافة/تعديل المنتج.
class ProductFormState {
  final ProductFormStatus status;

  /// إعدادات الحقول للنشاط الحالي (تبدأ بـ generic حتى لا تظهر حقول خاطئة).
  final ProductFormConfig config;

  /// نوع النشاط من Firebase (null لو لم يُقرأ بعد).
  final String? businessType;

  /// مفاتيح الحقول الاختيارية المُظهَّرة حالياً.
  final Set<String> visibleOptional;

  final String? errorMessage;

  /// المورد المختار في نموذج المنتج (اختياري).
  ///
  /// `supplierId` هو مرجع العلاقة الأساسي و`supplierName` لقطة عرض —
  /// كلاهما null لما ميكونش فيه مورد.
  final String? supplierId;
  final String? supplierName;

  const ProductFormState({
    this.status = ProductFormStatus.loading,
    this.config = const ProductFormConfig(
      profileId: ProductFieldsCatalog.profileGeneric,
      businessType: null,
      fields: [],
    ),
    this.businessType,
    this.visibleOptional = const {},
    this.errorMessage,
    this.supplierId,
    this.supplierName,
  });

  bool get isReady => status == ProductFormStatus.ready;

  ProductFormState copyWith({
    ProductFormStatus? status,
    ProductFormConfig? config,
    String? businessType,
    Set<String>? visibleOptional,
    String? errorMessage,
    bool clearError = false,
    // إرسال null صرياً يشيل المورد؛ عدم إرساله يُبقي القيمة الحالية.
    Object? supplierId = _keepValue,
    Object? supplierName = _keepValue,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      config: config ?? this.config,
      businessType: businessType ?? this.businessType,
      visibleOptional: visibleOptional ?? this.visibleOptional,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      supplierId: identical(supplierId, _keepValue)
          ? this.supplierId
          : supplierId as String?,
      supplierName: identical(supplierName, _keepValue)
          ? this.supplierName
          : supplierName as String?,
    );
  }

  /// علامة عدم التغيير للحقول التي تقبل الإلغاء بـ null.
  static const Object _keepValue = Object();
}
