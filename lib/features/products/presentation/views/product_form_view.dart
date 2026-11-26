import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/shop_resolver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_parser.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../categories/data/repos/category_repo.dart';
import '../../../categories/presentation/views/category_management_view.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../../suppliers/data/repos/suppliers_repo.dart';
import '../../data/models/product_field.dart';
import '../../data/models/product_form_config.dart';
import '../../data/repos/product_config_repo.dart';
import '../cubit/product_form_cubit.dart';
import '../cubit/products_cubit.dart';
import '../states/product_form_state.dart';
import '../widgets/product_form/product_delete_dialog.dart';
import '../widgets/product_form/product_form_actions_bar.dart';
import '../widgets/product_form/product_form_chips_field.dart';
import '../widgets/product_form/product_form_date_field.dart';
import '../widgets/product_form/product_form_dropdown_field.dart';
import '../widgets/product_form/product_form_icon_button.dart';
import '../widgets/product_form/product_form_image_field.dart';
import '../widgets/product_form/product_form_optional_specs.dart';
import '../widgets/product_form/product_form_section.dart';
import '../widgets/product_form/product_form_supplier_field.dart';
import '../widgets/product_form/product_form_text_field.dart';
import '../widgets/product_form/product_form_toggle.dart';
import '../widgets/product_form/product_form_variants_editor.dart';
import '../widgets/product_form/product_profit_preview.dart';
import 'package:hesba/core/services/app_logger.dart';

/// نموذج إضافة/تعديل منتج — الحقول تُبنى بالكامل من ProductFieldsCatalog
/// حسب نوع نشاط المتجر (لا توجد قوائم حقول ثابتة في الواجهة).
class ProductFormView extends StatefulWidget {
  final ProductsCubit cubit;
  final Product? product;
  const ProductFormView({super.key, required this.cubit, this.product});
  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final ProductFormCubit _formCubit;

  // قيم الحقول النصية (key → controller).
  final Map<String, TextEditingController> _controllers = {};
  // القيم الخاصة بالحقول غير النصية (صورة/تاريخ/مفتاح/chips).
  final Map<String, dynamic> _specValues = {};
  // القوائم المنسدلة (key → الاختيار الحالي) + "أخرى".tr() المخصص.
  final Map<String, String?> _dropdownValues = {};
  final Set<String> _dropdownTouched = {};
  final Map<String, bool> _customFlags = {};
  final Map<String, TextEditingController> _customControllers = {};
  // صفوف جدول كميات اللون والمقاس.
  final List<ProductVariantRow> _variants = [];

  String? _category;
  bool _customCategory = false;
  late final TextEditingController _customCategoryController;
  late List<String> _categories = _categoriesFor(widget.cubit.state.shopType);
  List<String> _customCategories = [];
  String? _shopId;
  bool _saving = false;
  bool _deleting = false;
  bool get _isEdit => widget.product != null;

  List<String> get _allCategories {
    final base = List<String>.from(_categories);
    // ادمج المخصصة قبل "أخرى".tr() مع منع التكرار
    final other = base.isNotEmpty ? base.removeLast() : null;
    final lowerBase = base.map((e) => e.trim().toLowerCase()).toSet();
    for (final c in _customCategories) {
      final trimmed = c.trim();
      if (trimmed.isEmpty) continue;
      if (lowerBase.contains(trimmed.toLowerCase())) continue;
      if (base.map((e) => e.toLowerCase()).contains(trimmed.toLowerCase())) {
        continue;
      }
      base.add(trimmed);
    }
    if (other != null) base.add(other);
    return base;
  }

  List<String> _categoriesFor(String? shopType) =>
      AppConstants.productCategoriesByBusinessType[shopType] ??
      AppConstants.defaultProductCategories;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _customCategoryController = TextEditingController();

    _formCubit = ProductFormCubit(configRepo: sl<ProductConfigRepo>());
    _formCubit.load(existing: p);

    // قيم غير النصية (تُقرأ من specs — المنتجات القديمة ترجع القيم الافتراضية).
    _specValues[ProductFieldKeys.imageUrl] = p?.imageUrl ?? '';
    _specValues[ProductFieldKeys.availability] =
        p?.specs[ProductFieldKeys.availability] as bool? ?? true;
    _specValues[ProductFieldKeys.expiryDate] =
        p?.specs[ProductFieldKeys.expiryDate] as String?;
    _specValues[ProductFieldKeys.addons] = _readChips(ProductFieldKeys.addons);
    _specValues[ProductFieldKeys.ingredients] = _readChips(
      ProductFieldKeys.ingredients,
    );
    _readVariants();

    final savedCategory = p?.category ?? '';
    if (savedCategory.isNotEmpty) {
      if (_categories.contains(savedCategory)) {
        _category = savedCategory;
      } else {
        _category = _otherOption;
        _customCategory = true;
        _customCategoryController.text = savedCategory;
      }
    }

    if (widget.cubit.state.shopType == null) {
      widget.cubit.loadShopType().then((type) {
        if (mounted && type != null) {
          setState(() => _categories = _categoriesFor(type));
        }
      });
    }
    _loadCustomCategories();
  }

  List<String> _readChips(String key) {
    final raw = widget.product?.specs[key];
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  void _readVariants() {
    final raw = widget.product?.specs[ProductFieldKeys.variants];
    if (raw is! List) return;
    for (final row in raw) {
      if (row is Map) {
        final savedSize = '${row['size'] ?? ''}';
        final isCustomSize =
            savedSize.isNotEmpty &&
            !AppConstants.productSizesFor(
              widget.cubit.state.shopType,
            ).contains(savedSize);
        _variants.add(
          ProductVariantRow(
            color: '${row['color'] ?? ''}',
            size: savedSize,
            qty: '${row['qty'] ?? ''}',
            useCustomSize: isCustomSize,
          ),
        );
      }
    }
  }

  /// تحديث علم "مقاس مخصص" بعد تحميل مقاسات النشاط الفعلية.
  /// مقاس قديم (مثلاً 42 في محل أحذية) ما يعتبرش مخصص بعد ما عرفنا
  /// أن المقاس ده ضمن قائمة المقاسات الخاصة بالنشاط.
  void _syncVariantCustomFlags(List<String> sizes) {
    for (final row in _variants) {
      row.useCustomSize = row.size.isNotEmpty && !sizes.contains(row.size);
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      _shopId = await sl<ShopResolver>().getShopId();
      if (_shopId == null || _shopId!.isEmpty) return;
      final list = await sl<CategoryRepo>().getCustomCategories(_shopId!);
      if (!mounted) return;
      setState(() => _customCategories = list);
      final saved = widget.product?.category ?? '';
      if (saved.isNotEmpty &&
          list.map((e) => e.toLowerCase()).contains(saved.toLowerCase())) {
        setState(() {
          _category = saved;
          _customCategory = false;
        });
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/products/presentation/views/product_form_view.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
    }
  }

  String get _otherOption =>
      _allCategories.isNotEmpty ? _allCategories.last : _categories.last;

  @override
  void dispose() {
    _formCubit.close();
    _customCategoryController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: _initialText(key)),
  );

  TextEditingController _customCtrl(String key) =>
      _customControllers.putIfAbsent(key, () => TextEditingController());

  /// القيمة الابتدائية للحقول النصية من المنتج الحالي.
  String _initialText(String key) {
    final p = widget.product;
    switch (key) {
      case ProductFieldKeys.name:
        return p?.name ?? '';
      case ProductFieldKeys.code:
        return (p?.code.isNotEmpty ?? false)
            ? p!.code
            : _generateCode(widget.cubit.state.products);
      case ProductFieldKeys.costPrice:
        return p != null ? _num(p.costPrice) : '';
      case ProductFieldKeys.price:
        return p != null ? _num(p.price) : '';
      case ProductFieldKeys.stock:
        return p != null ? p.stockLabel : '';
      case ProductFieldKeys.lowStockThreshold:
        return p != null ? p.lowStockLabel : '5';
      case ProductFieldKeys.color:
        return p?.color ?? '';
      case ProductFieldKeys.size:
        return p?.size ?? '';
      case ProductFieldKeys.notes:
        return p?.notes ?? '';
      default:
        final v = p?.specs[key];
        return v is String ? v : '';
    }
  }

  String _generateCode(List<Product> products) {
    var max = 0;
    final reg = RegExp(r'^PRD-(\d+)$');
    for (final product in products) {
      final m = reg.firstMatch(product.code.trim());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'PRD-${(max + 1).toString().padLeft(3, '0')}';
  }

  void _regenerateCode() => setState(
    () => _controllers[ProductFieldKeys.code]?.text = _generateCode(
      widget.cubit.state.products,
    ),
  );

  // ─────────────────────────── الحفظ ───────────────────────────

  /// تجميع كل القيم الظاهرة في خريطة واحدة (مفتاح الحقل → قيمته).
  Map<String, dynamic> _collectValues() {
    final values = <String, dynamic>{};
    for (final f in _formCubit.state.config.fields) {
      if (!_formCubit.isFieldVisible(f)) continue;
      values[f.key] = switch (f.type) {
        ProductFieldType.category => _categoryValue(),
        ProductFieldType.code => _ctrl(f.key).text,
        ProductFieldType.dropdown => _dropdownValue(f),
        ProductFieldType.date => _specValues[f.key],
        ProductFieldType.toggle => _specValues[f.key] ?? true,
        ProductFieldType.chips => List<String>.from(
          _specValues[f.key] as List? ?? const [],
        ),
        ProductFieldType.image => _specValues[f.key] ?? '',
        ProductFieldType.variants => [for (final r in _variants) r.toMap()],
        _ => _ctrl(f.key).text,
      };
    }
    return values;
  }

  String _categoryValue() {
    if (_customCategory) return _customCategoryController.text.trim();
    return _category ?? '';
  }

  String _dropdownValue(ProductFieldConfig f) {
    if (_customFlags[f.key] == true) return _customCtrl(f.key).text.trim();
    return _dropdownValues[f.key] ?? '';
  }

  String? _categoryValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'validatorRequired'.tr() : null;

  Future<void> _save() async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;
    final values = _collectValues();
    final errorKey = _formCubit.validate(values);
    if (errorKey != null) {
      AppToast.error(context, errorKey.tr());
      return;
    }
    setState(() => _saving = true);
    // لقطة الاسم: نعيد قراءة اسم المورد الحيّ عند الحفظ حتى لا يعرض
    // المنتج اسماً قديماً لو اتغيّر المورد من شاشة تانية.
    await _refreshSupplierSnapshot();
    final product = _formCubit.buildProduct(
      existing: widget.product,
      values: values,
    );
    final ok = _isEdit
        ? await widget.cubit.updateProduct(product)
        : await widget.cubit.addProduct(product);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      AppToast.success(
        context,
        _isEdit ? 'productUpdated'.tr() : 'productSaved'.tr(),
      );
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      AppToast.error(context, 'productSaveFailed'.tr());
    }
  }

  /// يعيد قراءة اسم المورد الحيّ قبل الحفظ (لقطة العرض في المنتج).
  ///
  /// فشل القراءة مش بيوقف الحفظ — الاسم المخزّن في الحالة يفضل كما هو.
  Future<void> _refreshSupplierSnapshot() async {
    final id = _formCubit.state.supplierId;
    if (id == null || id.isEmpty) return;
    try {
      final supplier = await sl<SuppliersRepo>().getSupplierById(id);
      if (!mounted || supplier == null) return;
      final liveName = supplier.displayName;
      if (liveName.isNotEmpty && liveName != _formCubit.state.supplierName) {
        _formCubit.setSupplier(id, liveName);
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal(
        'features/products/presentation/views/product_form_view.dart',
        logErr,
        logSt,
        severity: LoggingSeverity.warning,
      );
      // أفضل جهد فقط.
    }
  }

  Future<void> _delete() async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ProductDeleteDialog(),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    final deleted = await widget.cubit.deleteProduct(widget.product!.id);
    if (!mounted) return;
    if (deleted) {
      HapticFeedback.heavyImpact();
      AppToast.success(context, 'productDeleted'.tr());
      Navigator.pop(context);
    } else {
      setState(() => _deleting = false);
      AppToast.error(context, 'productDeleteFailed'.tr());
    }
  }

  // ─────────────────────────── البناء ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEdit ? 'productFormEdit'.tr() : 'productFormAdd'.tr(),
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
          ),
        ),
      ),
      body: BlocBuilder<ProductFormCubit, ProductFormState>(
        bloc: _formCubit,
        builder: (context, state) {
          if (!state.isReady) {
            return const LoadingWidget();
          }
          _syncVariantCustomFlags(
            state.config.field(ProductFieldKeys.size)?.options ??
                AppConstants.productSizesFor(state.businessType),
          );
          _ensureDropdownInitials(state.config);
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                ..._buildSections(state),
                // المورد (اختياري) — بعد الأقسام الأساسية وقبل المواصفات.
                ProductSupplierField(
                  key: const ValueKey('productSupplierField'),
                  supplierId: state.supplierId,
                  supplierName: state.supplierName,
                  existing: widget.product,
                  onCleared: (_) => _formCubit.setSupplier(null, null),
                  onSelected: (supplier) =>
                      _formCubit.setSupplier(supplier.id, supplier.displayName),
                ),
                SizedBox(height: 14.h),
                if (state.config.optionalFields.isNotEmpty) ...[
                  ProductFormOptionalSpecs(
                    fields: state.config.optionalFields,
                    visible: state.visibleOptional,
                    onToggle: _formCubit.toggleOptional,
                  ),
                  SizedBox(height: 14.h),
                ],
                SizedBox(height: 8.h),
                ProductFormActionsBar(
                  isEdit: _isEdit,
                  saving: _saving,
                  deleting: _deleting,
                  onSave: _save,
                  onDelete: _delete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// بناء الأقسام الظاهرة حسب ترتيب الكاتلوج (الأقسام الفارغة تُتخطى).
  List<Widget> _buildSections(ProductFormState state) {
    final out = <Widget>[];
    for (final section in kProductFormSectionOrder) {
      final fields = state.config
          .fieldsOf(section)
          .where(_formCubit.isFieldVisible)
          .toList(growable: false);
      if (fields.isEmpty) continue;
      final meta = _sectionMeta(section);
      out.add(
        ProductFormSectionCard(
          icon: meta.$1,
          titleKey: meta.$2,
          gradient: meta.$3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldsBody(fields),
              if (section == ProductFormSection.pricing) ...[
                SizedBox(height: 12.h),
                ProductProfitPreview(
                  costText: _ctrl(ProductFieldKeys.costPrice).text,
                  priceText: _ctrl(ProductFieldKeys.price).text,
                ),
              ],
            ],
          ),
        ),
      );
      out.add(SizedBox(height: 14.h));
    }
    return out;
  }

  (IconData, String, List<Color>) _sectionMeta(ProductFormSection section) =>
      switch (section) {
        ProductFormSection.basic => (
          Icons.info_outline_rounded,
          'productFormSectionBasic',
          const [AppTheme.primaryColor, AppTheme.brightBlue],
        ),
        ProductFormSection.pricing => (
          Icons.payments_rounded,
          'productFormSectionPricing',
          const [AppTheme.successDark, AppTheme.mintLight],
        ),
        ProductFormSection.specs => (
          Icons.tune_rounded,
          'productFormSectionSpecs',
          const [AppTheme.violetDeep, AppTheme.violetSoft],
        ),
        ProductFormSection.media => (
          Icons.image_rounded,
          'productFormSectionMedia',
          const [AppTheme.warningAmber, AppTheme.goldLight],
        ),
      };

  /// ترتيب الحقول داخل القسم: الحقول المزدوجة (paired) في نفس الصف.
  Widget _fieldsBody(List<ProductFieldConfig> fields) {
    final rows = <Widget>[];
    var i = 0;
    while (i < fields.length) {
      final f = fields[i];
      if (f.paired && i + 1 < fields.length && fields[i + 1].paired) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _render(f)),
              SizedBox(width: 10.w),
              Expanded(child: _render(fields[i + 1])),
            ],
          ),
        );
        i += 2;
      } else {
        rows.add(_render(f));
        i += 1;
      }
      rows.add(SizedBox(height: 12.h));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return Column(children: rows);
  }

  /// تحويل تعريف حقل واحد إلى الودجت المناسب لنوعه.
  Widget _render(ProductFieldConfig f) {
    switch (f.type) {
      case ProductFieldType.category:
        return _renderCategory(f);
      case ProductFieldType.code:
        return ProductFormTextField(
          key: ValueKey(f.key),
          controller: _ctrl(f.key),
          label: f.labelKey.tr(),
          hint: f.hintKey?.tr(),
          icon: f.icon,
          suffixIcon: ProductFormIconButton(
            icon: Icons.autorenew_rounded,
            color: AppTheme.primaryColor,
            onTap: _regenerateCode,
          ),
        );
      case ProductFieldType.dropdown:
        return _renderDropdown(f);
      case ProductFieldType.date:
        return ProductFormDateField(
          key: ValueKey(f.key),
          label: f.labelKey.tr(),
          icon: f.icon,
          value: _specValues[f.key] as String?,
          required: f.required,
          validator: (v) {
            if (f.required && (v == null || v.trim().isEmpty)) {
              return 'validatorRequired'.tr();
            }
            return null;
          },
          onChanged: (v) => setState(() => _specValues[f.key] = v),
        );
      case ProductFieldType.toggle:
        return ProductFormToggle(
          key: ValueKey(f.key),
          label: f.labelKey.tr(),
          icon: f.icon,
          value: _specValues[f.key] as bool? ?? true,
          onLabel: 'productFormAvailable'.tr(),
          offLabel: 'productFormUnavailable'.tr(),
          onChanged: (v) => setState(() => _specValues[f.key] = v),
        );
      case ProductFieldType.chips:
        return ProductFormChipsField(
          key: ValueKey(f.key),
          label: f.labelKey.tr(),
          hint: f.hintKey?.tr(),
          icon: f.icon,
          values: List<String>.from(_specValues[f.key] as List? ?? const []),
          onChanged: (v) => setState(() => _specValues[f.key] = v),
        );
      case ProductFieldType.image:
        return ProductFormImageField(
          key: ValueKey(f.key),
          imageUrl: _specValues[f.key] as String? ?? '',
          onChanged: (v) => setState(() => _specValues[f.key] = v),
        );
      case ProductFieldType.variants:
        return ProductFormVariantsEditor(
          key: ValueKey(f.key),
          rows: _variants,
          availableStock: _variantsAvailableStock(),
          sizeOptions:
              _formCubit.state.config.field(ProductFieldKeys.size)?.options ??
              AppConstants.productSizesFor(_formCubit.state.businessType),
          validator: (rows) {
            for (final r in rows) {
              final qty = r.qty.trim();
              if (qty.isEmpty ||
                  (double.tryParse(NumberParser.toLatin(qty)) ?? -1) < 0) {
                return 'productsInvalidNumber'.tr();
              }
              if (r.useCustomSize && r.size.trim().isEmpty) {
                return 'productFormCustomSize'.tr();
              }
            }
            final available = _variantsAvailableStock();
            final total = ProductFormVariantsEditor.totalQty(rows);
            if (available != null && total > available) {
              return 'productFormVariantsExceed'.tr();
            }
            return null;
          },
          onAdd: () => setState(() {
            _variants.add(ProductVariantRow());
            _syncStockFromVariants();
          }),
          onRemove: (i) => setState(() {
            _variants.removeAt(i);
            _syncStockFromVariants();
          }),
          onChange: (i, row) => setState(() {
            _variants[i] = row;
            _syncStockFromVariants();
          }),
        );
      case ProductFieldType.multiline:
        return ProductFormTextField(
          key: ValueKey(f.key),
          controller: _ctrl(f.key),
          label: f.labelKey.tr(),
          hint: f.hintKey?.tr(),
          icon: f.icon,
          required: f.required,
          maxLines: 3,
          validator: _fieldValidator(f),
          onChanged: (_) => setState(() {}),
        );
      case ProductFieldType.text:
      case ProductFieldType.number:
      case ProductFieldType.decimal:
        return ProductFormTextField(
          key: ValueKey(f.key),
          controller: _ctrl(f.key),
          label: f.labelKey.tr(),
          hint: f.hintKey?.tr(),
          icon: f.icon,
          required: f.required,
          suffix: f.type == ProductFieldType.decimal
              ? 'currencyEGP'.tr()
              : null,
          keyboard: switch (f.type) {
            ProductFieldType.decimal => const TextInputType.numberWithOptions(
              decimal: true,
            ),
            ProductFieldType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          validator: _fieldValidator(f),
          onChanged: (_) => setState(() {}),
        );
    }
  }

  /// الكمية الإجمالية تُملأ تلقائياً من الجدول فقط لو المستخدم ما كتبش فوق.
  /// لو الكمية المكتوبة موجودة تبقى سقف (cap): المجموع مينفعش يعديها والتحقق بيمنع الحفظ.
  void _syncStockFromVariants() {
    final current = _ctrl(ProductFieldKeys.stock).text.trim();
    if (current.isNotEmpty) return;
    final total = ProductFormVariantsEditor.totalQty(_variants);
    _ctrl(ProductFieldKeys.stock).text = total == total.roundToDouble()
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(1);
  }

  double? _variantsAvailableStock() {
    final text = _ctrl(ProductFieldKeys.stock).text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(NumberParser.toLatin(text));
  }

  /// قواعد التحقق المطبقة على الحقول النصية/الرقمية (نفس منطق Cubit).
  FormFieldValidator<String>? _fieldValidator(ProductFieldConfig f) {
    return (String? v) {
      final text = (v ?? '').trim();
      // الكمية تُحسب من صفوف Variants لو موجودة.
      if (f.key == ProductFieldKeys.stock && _variants.isNotEmpty) return null;
      if (f.required && text.isEmpty) return 'validatorRequired'.tr();
      if (text.isEmpty) return null;
      switch (f.type) {
        case ProductFieldType.decimal:
          final n = double.tryParse(NumberParser.toLatin(text));
          if (n == null) return 'validatorNumber'.tr();
          if (f.key == ProductFieldKeys.stock ||
              f.key == ProductFieldKeys.lowStockThreshold) {
            if (n < 0) return 'productsInvalidNumber'.tr();
            break;
          }
          if (n <= 0) return 'validatorPositiveNumber'.tr();
        case ProductFieldType.number:
          final n = int.tryParse(NumberParser.toLatin(text));
          if (n == null || n < 0) return 'productsInvalidNumber'.tr();
        default:
          break;
      }
      return null;
    };
  }

  Widget _renderCategory(ProductFieldConfig f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductFormDropdownField<String>(
          label: f.labelKey.tr(),
          icon: f.icon,
          value: _category,
          items: [
            for (final c in _allCategories)
              DropdownMenuItem(
                value: c,
                child: Text(c.tr(), style: TextStyle(fontSize: 13.sp)),
              ),
          ],
          onChanged: (v) => setState(() {
            _category = v;
            _customCategory = v == _otherOption;
          }),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementView(),
                ),
              );
            },
            icon: Icon(
              Icons.settings_rounded,
              size: 14.sp,
              color: AppTheme.primaryColor,
            ),
            label: Text(
              'productFormManageCategories'.tr(),
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        if (_customCategory) ...[
          SizedBox(height: 12.h),
          ProductFormTextField(
            key: const ValueKey('customCategory'),
            controller: _customCategoryController,
            label: 'productFormCustomCategory'.tr(),
            hint: 'productFormCategoryHint'.tr(),
            icon: Icons.edit_rounded,
            required: true,
            validator: _categoryValidator,
          ),
        ],
      ],
    );
  }

  /// قائمة منسدلة عامة (مقاس، وحدة قياس...) مع دعم "أخرى".tr() الكتابة الحرة.
  Widget _renderDropdown(ProductFieldConfig f) {
    final current = _dropdownValues[f.key];
    final items = <DropdownMenuItem<String>>[
      for (final o in f.options)
        DropdownMenuItem(
          value: o,
          child: Text(o, style: TextStyle(fontSize: 13.sp)),
        ),
      if (f.allowCustom && !f.options.contains('أخرى'))
        DropdownMenuItem(
          value: 'أخرى',
          child: Text('أخرى'.tr(), style: TextStyle(fontSize: 13.sp)),
        ),
      // قيمة قديمة غير موجودة في القائمة → نعرضها لمنع خطأ Assertion.
      if (current != null && current.isNotEmpty && !f.options.contains(current))
        DropdownMenuItem(
          value: current,
          child: Text(current.tr(), style: TextStyle(fontSize: 13.sp)),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(f.key),
          initialValue: current,
          isExpanded: true,
          decoration: productFormDecoration(
            context,
            label: f.labelKey.tr(),
            icon: f.icon,
            required: f.required,
          ),
          items: items,
          validator: (v) => f.required && (v == null || v.isEmpty)
              ? 'validatorRequired'.tr()
              : null,
          onChanged: (v) => setState(() {
            _dropdownTouched.add(f.key);
            _dropdownValues[f.key] = v;
            _customFlags[f.key] = v == 'أخرى';
          }),
          style: TextStyle(
            fontSize: 13.5.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(16.r),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.sp,
            color: AppTheme.primaryColor,
          ),
        ),
        if (_customFlags[f.key] == true) ...[
          SizedBox(height: 12.h),
          ProductFormTextField(
            key: ValueKey('${f.key}_custom'),
            controller: _customCtrl(f.key),
            label: 'productFormCustomValue'.tr(),
            hint: f.hintKey?.tr(),
            icon: Icons.edit_rounded,
            required: true,
            validator: _categoryValidator,
          ),
        ],
      ],
    );
  }

  /// تهيئة القوائم المنسدلة من بيانات المنتج الحالي (مرة واحدة عند الجاهزية).
  void _ensureDropdownInitials(ProductFormConfig config) {
    for (final f in config.fields) {
      if (f.type != ProductFieldType.dropdown) continue;
      if (_dropdownTouched.contains(f.key)) continue;
      if (_dropdownValues.containsKey(f.key)) continue;
      final saved = f.key == ProductFieldKeys.size
          ? (widget.product?.size ?? '')
          : '${widget.product?.specs[f.key] ?? ''}';
      if (saved.isEmpty) continue;
      if (f.options.contains(saved)) {
        _dropdownValues[f.key] = saved;
      } else if (f.allowCustom) {
        _dropdownValues[f.key] = 'أخرى';
        _customFlags[f.key] = true;
        _customCtrl(f.key).text = saved;
      } else {
        _dropdownValues[f.key] = saved;
      }
    }
  }

  static String _num(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
