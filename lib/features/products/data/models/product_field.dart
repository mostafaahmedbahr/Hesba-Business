import 'package:flutter/material.dart';

/// مفاتيح حقول المنتج — موحّدة بين الكاتلوج والفورم والـ specs.
abstract class ProductFieldKeys {
  // ── حقول أساسية (موجودة كـ top-level في Product للتوافق مع البيانات القديمة) ──
  static const String name = 'name';
  static const String category = 'category';
  static const String code = 'code';
  static const String costPrice = 'costPrice';
  static const String price = 'price';
  static const String stock = 'stock';
  static const String lowStockThreshold = 'lowStockThreshold';
  static const String color = 'color';
  static const String size = 'size';
  static const String notes = 'notes';
  static const String imageUrl = 'imageUrl';

  // ── مواصفات إضافية (تُخزَّن داخل Product.specs) ──
  static const String availability = 'availability';
  static const String addons = 'addons';
  static const String ingredients = 'ingredients';
  static const String model = 'model';
  static const String variants = 'variants';
  static const String barcode = 'barcode';
  static const String unit = 'unit';
  static const String expiryDate = 'expiryDate';
  static const String brand = 'brand';
  static const String serialNumber = 'serialNumber';
  static const String warranty = 'warranty';
  static const String manufacturer = 'manufacturer';
  static const String concentration = 'concentration';
  static const String batchNumber = 'batchNumber';
}

/// نوع الحقل — يحدّد الودجت المسؤول عن عرضه وتحريره في الواجهة.
enum ProductFieldType {
  /// حقل نصي عادي.
  text,

  /// حقل رقم صحيح (كمية).
  number,

  /// حقل رقم عشري (أسعار).
  decimal,

  /// نص متعدد الأسطر (وصف / ملاحظات).
  multiline,

  /// قائمة منسدلة بقيم ثابتة (مقاس، وحدة قياس...).
  dropdown,

  /// اختيار تاريخ (تاريخ الصلاحية).
  date,

  /// مفتاح تشغيل (حالة التوفر).
  toggle,

  /// قائمة عناصر قابلة للإضافة (الإضافات، المكونات).
  chips,

  /// رفع صورة المنتج.
  image,

  /// جدول الكميات لكل لون ومقاس.
  variants,

  /// قائمة الأقسام (سلوك خاص: أقسام المخصصة + "أخرى").
  category,

  /// كود المنتج + زر توليد تلقائي.
  code,
}

/// مجموعة حقول الفورم (قسم داخل الشاشة).
enum ProductFormSection {
  /// معلومات أساسية: الاسم، القسم، الكود.
  basic,

  /// التسعير والمخزون.
  pricing,

  /// مواصفات تختلف حسب النشاط.
  specs,

  /// الصورة والوصف.
  media,
}

/// تعريف حقل واحد داخل نموذج إضافة/تعديل المنتج.
///
/// البيانات فقط — بدون أي منطق عرض، حتى يبقى الكاتلوج مركزياً وسهل التوسع.
@immutable
class ProductFieldConfig {
  /// مفتاح التخزين (داخل Product أو Product.specs).
  final String key;

  final ProductFieldType type;

  /// مفتاح الترجمة لعنوان الحقل.
  final String labelKey;

  /// مفتاح الترجمة للنص الإرشادي (اختياري).
  final String? hintKey;

  /// أيقونة الحقل.
  final IconData icon;

  /// هل الحقل إجباري؟.
  final bool required;

  /// حقل اختياري: مخفي افتراضياً ويمكن إظهاره من "مواصفات إضافية".
  final bool optional;

  /// قسم الحقل داخل الشاشة.
  final ProductFormSection section;

  /// قيم القائمة المنسدلة (يُستخدم مع [ProductFieldType.dropdown]).
  final List<String> options;

  /// هل يدعم "أخرى" بكتابة نص حر؟ (المقاس / وحدة القياس).
  final bool allowCustom;

  /// يُعرض بجانب حقل آخر في نفس صف (سعر التكلفة + سعر البيع).
  final bool paired;

  const ProductFieldConfig({
    required this.key,
    required this.type,
    required this.labelKey,
    required this.icon,
    this.hintKey,
    this.required = false,
    this.optional = false,
    this.section = ProductFormSection.specs,
    this.options = const [],
    this.allowCustom = false,
    this.paired = false,
  });
}
