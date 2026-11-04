import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import 'product_field.dart';
import 'product_form_config.dart';

/// الكاتلوج المركزي لحقول المنتجات حسب النشاط التجاري.
///
/// لإضافة نشاط جديد: أضف مفتاحه في [_profileByBusinessType] ثم ابنِ ملفه
/// التعريفي في [_fieldsFor]. لا يحتاج أي تعديل في الواجهة.
class ProductFieldsCatalog {
  const ProductFieldsCatalog._();

  // ── الملفات التعريفية ──
  static const String profileRestaurant = 'restaurant'; // مطعم / كافيه
  static const String profileVariants = 'variants'; // ملابس / أحذية
  static const String profileRetail = 'retail'; // سوبر ماركت / بقالة / لحوم ...
  static const String profilePharmacy = 'pharmacy'; // صيدلية
  static const String profileElectronics = 'electronics'; // إلكترونيات
  static const String profileBeauty = 'beauty'; // عطور
  static const String profileHomeGoods = 'homeGoods'; // أدوات منزلية
  static const String profileFlorist = 'florist'; // ورد
  static const String profileBarber = 'barber'; // حلاقة
  static const String profileGeneric = 'generic'; // غير ذلك / غير معروف

  /// ربط كل قيمة businessTypes (18 قيمة عربية) بملفها التعريفي.
  /// القيم تطابق RegisterConstants.businessTypes حرفياً.
  static const Map<String, String> _profileByBusinessType = {
    'مطعم': profileRestaurant,
    'كافيه': profileRestaurant,
    'محل ملابس': profileVariants,
    'محل أحذية': profileVariants,
    'سوبر ماركت': profileRetail,
    'بقالة': profileRetail,
    'محل خضروات': profileRetail,
    'محل فواكه': profileRetail,
    'محل لحوم': profileRetail,
    'محل أسماك': profileRetail,
    'محل حلويات': profileRetail,
    'صيدلية': profilePharmacy,
    'محل إلكترونيات': profileElectronics,
    'محل عطور': profileBeauty,
    'محل أدوات منزلية': profileHomeGoods,
    'محل ورد': profileFlorist,
    'محل حلاقة': profileBarber,
    'غير ذلك': profileGeneric,
  };

  /// الملف التعريفي لنشاط (null/غير معروف → generic).
  static String profileFor(String? businessType) {
    final type = businessType?.trim();
    if (type == null || type.isEmpty) return profileGeneric;
    return _profileByBusinessType[type] ?? profileGeneric;
  }

  /// بناء إعدادات الفورم لنشاط تجاري (null → إعدادات عامة آمنة).
  static ProductFormConfig configFor(String? businessType) {
    final profile = profileFor(businessType);
    return ProductFormConfig(
      profileId: profile,
      businessType: businessType,
      fields: _fieldsFor(profile),
    );
  }

  // ───────────────────────── الحقول الأساسية المشتركة ─────────────────────────

  static const ProductFieldConfig _name = ProductFieldConfig(
    key: ProductFieldKeys.name,
    type: ProductFieldType.text,
    labelKey: 'productFormName',
    hintKey: 'productFormNameHint',
    icon: Icons.inventory_2_rounded,
    required: true,
    section: ProductFormSection.basic,
  );

  static const ProductFieldConfig _category = ProductFieldConfig(
    key: ProductFieldKeys.category,
    type: ProductFieldType.category,
    labelKey: 'productFormCategory',
    icon: Icons.category_rounded,
    required: true,
    section: ProductFormSection.basic,
  );

  static const ProductFieldConfig _code = ProductFieldConfig(
    key: ProductFieldKeys.code,
    type: ProductFieldType.code,
    labelKey: 'productFormCode',
    hintKey: 'productFormCodeHint',
    icon: Icons.qr_code_2_rounded,
    section: ProductFormSection.basic,
  );

  static const ProductFieldConfig _costPrice = ProductFieldConfig(
    key: ProductFieldKeys.costPrice,
    type: ProductFieldType.decimal,
    labelKey: 'productFormCostPrice',
    icon: Icons.shopping_cart_rounded,
    required: true,
    section: ProductFormSection.pricing,
    paired: true,
  );

  static const ProductFieldConfig _price = ProductFieldConfig(
    key: ProductFieldKeys.price,
    type: ProductFieldType.decimal,
    labelKey: 'productFormPrice',
    icon: Icons.sell_rounded,
    required: true,
    section: ProductFormSection.pricing,
    paired: true,
  );

  static const ProductFieldConfig _stock = ProductFieldConfig(
    key: ProductFieldKeys.stock,
    type: ProductFieldType.number,
    labelKey: 'productFormStock',
    icon: Icons.numbers_rounded,
    required: true,
    section: ProductFormSection.pricing,
    paired: true,
  );

  static const ProductFieldConfig _lowStock = ProductFieldConfig(
    key: ProductFieldKeys.lowStockThreshold,
    type: ProductFieldType.number,
    labelKey: 'productFormLowStock',
    icon: Icons.low_priority_rounded,
    section: ProductFormSection.pricing,
    paired: true,
  );

  static const ProductFieldConfig _image = ProductFieldConfig(
    key: ProductFieldKeys.imageUrl,
    type: ProductFieldType.image,
    labelKey: 'productFormImage',
    icon: Icons.image_rounded,
    section: ProductFormSection.media,
  );

  static const ProductFieldConfig _notes = ProductFieldConfig(
    key: ProductFieldKeys.notes,
    type: ProductFieldType.multiline,
    labelKey: 'productFormNotes',
    hintKey: 'productFormNotesHint',
    icon: Icons.notes_rounded,
    section: ProductFormSection.media,
  );

  /// حقول أي نشاط: أساسية + أسعار + صورة + ملاحظات.
  static List<ProductFieldConfig> _baseFields({
    ProductFieldConfig notes = _notes,
    List<ProductFieldConfig> extra = const [],
    List<ProductFieldConfig> beforeNotes = const [],
  }) =>
      [
        _name,
        _category,
        _code,
        _costPrice,
        _price,
        _stock,
        _lowStock,
        ...extra,
        ...beforeNotes,
        _image,
        notes,
      ];

  // ────────────────────────── الملفات التعريفية ──────────────────────────

  /// مطعم / كافيه: توفر + إضافات + مكونات — بدون لون أو مقاس إطلاقاً.
  static const ProductFieldConfig _availability = ProductFieldConfig(
    key: ProductFieldKeys.availability,
    type: ProductFieldType.toggle,
    labelKey: 'productFormAvailability',
    icon: Icons.check_circle_outline_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _addons = ProductFieldConfig(
    key: ProductFieldKeys.addons,
    type: ProductFieldType.chips,
    labelKey: 'productFormAddons',
    hintKey: 'productFormAddonsHint',
    icon: Icons.add_circle_outline_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _ingredients = ProductFieldConfig(
    key: ProductFieldKeys.ingredients,
    type: ProductFieldType.chips,
    labelKey: 'productFormIngredients',
    hintKey: 'productFormIngredientsHint',
    icon: Icons.restaurant_menu_rounded,
    optional: true,
    section: ProductFormSection.specs,
  );

  static ProductFormConfig _restaurant(String? type) => ProductFormConfig(
    profileId: profileRestaurant,
    businessType: type,
    fields: _baseFields(
      notes: const ProductFieldConfig(
        key: ProductFieldKeys.notes,
        type: ProductFieldType.multiline,
        labelKey: 'productFormDescription',
        hintKey: 'productFormDescriptionHint',
        icon: Icons.notes_rounded,
        section: ProductFormSection.media,
      ),
      extra: const [_availability, _addons, _ingredients],
    ),
  );

  // ── ملابس / أحذية: لون + مقاس + موديل + كميات لكل لون ومقاس ──

  static const ProductFieldConfig _color = ProductFieldConfig(
    key: ProductFieldKeys.color,
    type: ProductFieldType.text,
    labelKey: 'productFormColor',
    hintKey: 'productFormColorHint',
    icon: Icons.palette_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _size = ProductFieldConfig(
    key: ProductFieldKeys.size,
    type: ProductFieldType.dropdown,
    labelKey: 'productFormSize',
    hintKey: 'productFormSizeHint',
    icon: Icons.straighten_rounded,
    section: ProductFormSection.specs,
    options: AppConstants.productSizes,
    allowCustom: true,
  );

  static const ProductFieldConfig _model = ProductFieldConfig(
    key: ProductFieldKeys.model,
    type: ProductFieldType.text,
    labelKey: 'productFormModel',
    hintKey: 'productFormModelHint',
    icon: Icons.style_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _variants = ProductFieldConfig(
    key: ProductFieldKeys.variants,
    type: ProductFieldType.variants,
    labelKey: 'productFormVariants',
    hintKey: 'productFormVariantsHint',
    icon: Icons.grid_view_rounded,
    section: ProductFormSection.specs,
  );

  static ProductFormConfig _variantsProfile(String? type) => ProductFormConfig(
    profileId: profileVariants,
    businessType: type,
    fields: _baseFields(extra: const [_color, _size, _model, _variants]),
  );

  // ── بقالة / سوبر ماركت / لحوم / خضروات ...: باركود + وحدة + صلاحية ──

  static const ProductFieldConfig _barcode = ProductFieldConfig(
    key: ProductFieldKeys.barcode,
    type: ProductFieldType.text,
    labelKey: 'productFormBarcode',
    hintKey: 'productFormBarcodeHint',
    icon: Icons.qr_code_scanner_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _unit = ProductFieldConfig(
    key: ProductFieldKeys.unit,
    type: ProductFieldType.dropdown,
    labelKey: 'productFormUnit',
    hintKey: 'productFormUnitHint',
    icon: Icons.straighten_rounded,
    section: ProductFormSection.specs,
    options: [
      'قطعة',
      'كجم',
      'جرام',
      'لتر',
      'مل',
      'علبة',
      'كرتونة',
      'دستة',
      'أخرى',
    ],
    allowCustom: true,
  );

  static const ProductFieldConfig _expiryDate = ProductFieldConfig(
    key: ProductFieldKeys.expiryDate,
    type: ProductFieldType.date,
    labelKey: 'productFormExpiryDate',
    icon: Icons.event_rounded,
    optional: true,
    section: ProductFormSection.specs,
  );

  static ProductFormConfig _retail(String? type) => ProductFormConfig(
    profileId: profileRetail,
    businessType: type,
    fields: _baseFields(extra: const [_barcode, _unit, _expiryDate]),
  );

  // ── صيدلية: باركود + مصنع + تركيز + صلاحية (إجباري) + رقم تشغيلة ──

  static const ProductFieldConfig _manufacturer = ProductFieldConfig(
    key: ProductFieldKeys.manufacturer,
    type: ProductFieldType.text,
    labelKey: 'productFormManufacturer',
    hintKey: 'productFormManufacturerHint',
    icon: Icons.factory_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _concentration = ProductFieldConfig(
    key: ProductFieldKeys.concentration,
    type: ProductFieldType.text,
    labelKey: 'productFormConcentration',
    hintKey: 'productFormConcentrationHint',
    icon: Icons.science_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _expiryRequired = ProductFieldConfig(
    key: ProductFieldKeys.expiryDate,
    type: ProductFieldType.date,
    labelKey: 'productFormExpiryDate',
    icon: Icons.event_rounded,
    required: true,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _batchNumber = ProductFieldConfig(
    key: ProductFieldKeys.batchNumber,
    type: ProductFieldType.text,
    labelKey: 'productFormBatchNumber',
    hintKey: 'productFormBatchNumberHint',
    icon: Icons.confirmation_number_rounded,
    section: ProductFormSection.specs,
  );

  static ProductFormConfig _pharmacy(String? type) => ProductFormConfig(
    profileId: profilePharmacy,
    businessType: type,
    fields: _baseFields(
      extra: const [
        _barcode,
        _manufacturer,
        _concentration,
        _expiryRequired,
        _batchNumber,
      ],
    ),
  );

  // ── إلكترونيات: ماركة + موديل + تسلسلي (اختياري) + ضمان ──

  static const ProductFieldConfig _brand = ProductFieldConfig(
    key: ProductFieldKeys.brand,
    type: ProductFieldType.text,
    labelKey: 'productFormBrand',
    hintKey: 'productFormBrandHint',
    icon: Icons.branding_watermark_rounded,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _serialNumber = ProductFieldConfig(
    key: ProductFieldKeys.serialNumber,
    type: ProductFieldType.text,
    labelKey: 'productFormSerialNumber',
    hintKey: 'productFormSerialNumberHint',
    icon: Icons.pin_rounded,
    optional: true,
    section: ProductFormSection.specs,
  );

  static const ProductFieldConfig _warranty = ProductFieldConfig(
    key: ProductFieldKeys.warranty,
    type: ProductFieldType.text,
    labelKey: 'productFormWarranty',
    hintKey: 'productFormWarrantyHint',
    icon: Icons.verified_user_rounded,
    section: ProductFormSection.specs,
  );

  static ProductFormConfig _electronics(String? type) => ProductFormConfig(
    profileId: profileElectronics,
    businessType: type,
    fields: _baseFields(
      extra: const [_brand, _model, _serialNumber, _warranty],
    ),
  );

  // ── عطور: ماركة + حجم + صلاحية اختيارية ──

  static ProductFormConfig _beauty(String? type) => ProductFormConfig(
    profileId: profileBeauty,
    businessType: type,
    fields: _baseFields(extra: const [_brand, _concentration, _expiryDate]),
  );

  // ── أدوات منزلية: باركود + وحدة قياس ──

  static ProductFormConfig _homeGoods(String? type) => ProductFormConfig(
    profileId: profileHomeGoods,
    businessType: type,
    fields: _baseFields(extra: const [_barcode, _unit]),
  );

  // ── ورد: وحدة قياس + ملاحظات وصفية ──

  static ProductFormConfig _florist(String? type) => ProductFormConfig(
    profileId: profileFlorist,
    businessType: type,
    fields: _baseFields(extra: const [_unit]),
  );

  // ── حلاقة: باركود + وحدة قياس ──

  static ProductFormConfig _barber(String? type) => ProductFormConfig(
    profileId: profileBarber,
    businessType: type,
    fields: _baseFields(extra: const [_barcode, _unit]),
  );

  // ── عام: حقول أساسية فقط (منتجات بلا مواصفات إضافية) ──

  static ProductFormConfig _generic(String? type) => ProductFormConfig(
    profileId: profileGeneric,
    businessType: type,
    fields: _baseFields(),
  );

  static List<ProductFieldConfig> _fieldsFor(String profile) => switch (profile) {
    profileRestaurant => _fieldsOf(_restaurant(null)),
    profileVariants => _fieldsOf(_variantsProfile(null)),
    profileRetail => _fieldsOf(_retail(null)),
    profilePharmacy => _fieldsOf(_pharmacy(null)),
    profileElectronics => _fieldsOf(_electronics(null)),
    profileBeauty => _fieldsOf(_beauty(null)),
    profileHomeGoods => _fieldsOf(_homeGoods(null)),
    profileFlorist => _fieldsOf(_florist(null)),
    profileBarber => _fieldsOf(_barber(null)),
    _ => _fieldsOf(_generic(null)),
  };

  static List<ProductFieldConfig> _fieldsOf(ProductFormConfig c) => c.fields;
}
