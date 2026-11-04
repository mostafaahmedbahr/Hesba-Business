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
  });

  bool get isReady => status == ProductFormStatus.ready;

  ProductFormState copyWith({
    ProductFormStatus? status,
    ProductFormConfig? config,
    String? businessType,
    Set<String>? visibleOptional,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      config: config ?? this.config,
      businessType: businessType ?? this.businessType,
      visibleOptional: visibleOptional ?? this.visibleOptional,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
