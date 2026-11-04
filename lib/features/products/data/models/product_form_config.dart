import 'product_field.dart';

/// ترتيب الأقسام المعروضة في الفورم (من الأعلى للأسفل).
const List<ProductFormSection> kProductFormSectionOrder = [
  ProductFormSection.basic,
  ProductFormSection.pricing,
  ProductFormSection.specs,
  ProductFormSection.media,
];

/// إعدادات نموذج المنتج لنشاط تجاري واحد: الحقول + الترتيب + الإجباري/الاختياري.
///
/// هذا هو المصدر الوحيد الذي تعتمد عليه واجهة الإضافة/التعديل —
/// لا توجد قوائم حقول ثابتة داخل الودجت إطلاقاً.
class ProductFormConfig {
  /// معرّف الملف التعريفي (restaurant / variants / retail / ...).
  final String profileId;

  /// نوع النشاط التجاري كما هو مخزّن في Firebase (قد يكون null).
  final String? businessType;

  /// كل حقول هذا النشاط مرتبة حسب العرض.
  final List<ProductFieldConfig> fields;

  const ProductFormConfig({
    required this.profileId,
    required this.businessType,
    required this.fields,
  });

  /// الحقول الظاهرة في قسم معين بالترتيب.
  List<ProductFieldConfig> fieldsOf(ProductFormSection section) =>
      fields.where((f) => f.section == section).toList(growable: false);

  /// هل يحتوي النشاط على حقل معين؟.
  bool has(String key) => fields.any((f) => f.key == key);

  ProductFieldConfig? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// الحقول الاختيارية (مخفية افتراضياً).
  List<ProductFieldConfig> get optionalFields =>
      fields.where((f) => f.optional).toList(growable: false);
}
