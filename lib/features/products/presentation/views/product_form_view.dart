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
import '../../../categories/data/repos/category_repo.dart';
import '../../../categories/presentation/views/category_management_view.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../data/models/product_field.dart';
import '../../data/models/product_form_config.dart';
import '../../data/repos/product_config_repo.dart';
import '../cubit/product_form_cubit.dart';
import '../cubit/products_cubit.dart';
import '../states/product_form_state.dart';
import '../widgets/product_form/product_form_chips_field.dart';
import '../widgets/product_form/product_form_date_field.dart';
import '../widgets/product_form/product_form_image_field.dart';
import '../widgets/product_form/product_form_optional_specs.dart';
import '../widgets/product_form/product_form_section.dart';
import '../widgets/product_form/product_form_text_field.dart';
import '../widgets/product_form/product_form_toggle.dart';
import '../widgets/product_form/product_form_variants_editor.dart';

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
  // القوائم المنسدلة (key → الاختيار الحالي) + "أخرى" المخصص.
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
  StreamSubscription<List<String>>? _catSub;

  bool _saving = false;
  bool _deleting = false;
  bool get _isEdit => widget.product != null;

  List<String> get _allCategories {
    final base = List<String>.from(_categories);
    // ادمج المخصصة قبل "أخرى" مع منع التكرار
    final other = base.isNotEmpty ? base.removeLast() : null;
    final lowerBase = base.map((e) => e.trim().toLowerCase()).toSet();
    for (final c in _customCategories) {
      final trimmed = c.trim();
      if (trimmed.isEmpty) continue;
      if (lowerBase.contains(trimmed.toLowerCase())) continue;
      if (base.map((e) => e.toLowerCase()).contains(trimmed.toLowerCase())) continue;
      base.add(trimmed);
    }
    if (other != null) base.add(other);
    return base;
  }

  List<String> _categoriesFor(String? shopType) =>
      AppConstants.productCategoriesByBusinessType[shopType] ?? AppConstants.defaultProductCategories;

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
    _specValues[ProductFieldKeys.ingredients] = _readChips(ProductFieldKeys.ingredients);
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
        if (mounted && type != null) setState(() => _categories = _categoriesFor(type));
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
        _variants.add(ProductVariantRow(
          color: '${row['color'] ?? ''}',
          size: '${row['size'] ?? ''}',
          qty: '${row['qty'] ?? ''}',
        ));
      }
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      _shopId = await sl<ShopResolver>().getShopId();
      if (_shopId == null || _shopId!.isEmpty) return;
      final repo = sl<CategoryRepo>();
      _catSub?.cancel();
      _catSub = repo.watchCustomCategories(_shopId!).listen((list) {
        if (!mounted) return;
        setState(() => _customCategories = list);
        final saved = widget.product?.category ?? '';
        if (saved.isNotEmpty && list.map((e) => e.toLowerCase()).contains(saved.toLowerCase())) {
          setState(() {
            _category = saved;
            _customCategory = false;
          });
        }
      });
    } catch (_) {}
  }

  String get _otherOption => _allCategories.isNotEmpty ? _allCategories.last : _categories.last;

  @override
  void dispose() {
    _catSub?.cancel();
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

  TextEditingController _customCtrl(String key) => _customControllers.putIfAbsent(
    key,
    () => TextEditingController(),
  );

  /// القيمة الابتدائية للحقول النصية من المنتج الحالي.
  String _initialText(String key) {
    final p = widget.product;
    switch (key) {
      case ProductFieldKeys.name:
        return p?.name ?? '';
      case ProductFieldKeys.code:
        return (p?.code.isNotEmpty ?? false) ? p!.code : _generateCode(widget.cubit.state.products);
      case ProductFieldKeys.costPrice:
        return p != null ? _num(p.costPrice) : '';
      case ProductFieldKeys.price:
        return p != null ? _num(p.price) : '';
      case ProductFieldKeys.stock:
        return p != null ? '${p.stock}' : '';
      case ProductFieldKeys.lowStockThreshold:
        return p != null ? '${p.lowStockThreshold}' : '5';
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

  void _regenerateCode() =>
      setState(() => _controllers[ProductFieldKeys.code]?.text = _generateCode(widget.cubit.state.products));

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
        ProductFieldType.chips =>
          List<String>.from(_specValues[f.key] as List? ?? const []),
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
    final product = _formCubit.buildProduct(existing: widget.product, values: values);
    final ok = _isEdit
        ? await widget.cubit.updateProduct(product)
        : await widget.cubit.addProduct(product);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      AppToast.success(context, _isEdit ? 'productUpdated'.tr() : 'productSaved'.tr());
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      AppToast.error(context, 'productSaveFailed'.tr());
    }
  }

  Future<void> _delete() async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24.r)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64.w, height: 64.w, decoration: BoxDecoration(color: AppTheme.dangerSoft, shape: BoxShape.circle), child: Icon(Icons.delete_rounded, color: AppTheme.danger, size: 28.sp)),
            SizedBox(height: 14.h),
            Text('productDeleteConfirmTitle'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text('productDeleteConfirmBody'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            SizedBox(height: 18.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('cancel'.tr()))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('productDelete'.tr()))),
            ]),
          ]),
        ),
      ),
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
        title: Text(_isEdit ? 'productFormEdit'.tr() : 'productFormAdd'.tr(), style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.close_rounded, size: 22.sp), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
      ),
      body: BlocBuilder<ProductFormCubit, ProductFormState>(
        bloc: _formCubit,
        builder: (context, state) {
          if (!state.isReady) {
            return Center(
              child: SizedBox(
                width: 26.w,
                height: 26.w,
                child: const CircularProgressIndicator(strokeWidth: 2.6, color: AppTheme.primaryColor),
              ),
            );
          }
          _ensureDropdownInitials(state.config);
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              children: [
                ..._buildSections(state),
                if (state.config.optionalFields.isNotEmpty) ...[
                  ProductFormOptionalSpecs(
                    fields: state.config.optionalFields,
                    visible: state.visibleOptional,
                    onToggle: _formCubit.toggleOptional,
                  ),
                  SizedBox(height: 14.h),
                ],
                SizedBox(height: 8.h),
                SizedBox(
                  height: 54.h,
                  child: FilledButton(
                    onPressed: _saving || _deleting ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                    child: _saving
                        ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18.sp), SizedBox(width: 8.w), Text(_isEdit ? 'productFormUpdate'.tr() : 'productFormSave'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800))]),
                  ),
                ),
                if (_isEdit) ...[
                  SizedBox(height: 10.h),
                  SizedBox(height: 50.h, child: OutlinedButton.icon(onPressed: _saving || _deleting ? null : _delete, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))), icon: _deleting ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.danger)) : const Icon(Icons.delete_outline_rounded, size: 18), label: Text('productDelete'.tr(), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700)))),
                ],
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
      out.add(ProductFormSectionCard(
        icon: meta.$1,
        titleKey: meta.$2,
        gradient: meta.$3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldsBody(fields),
            if (section == ProductFormSection.pricing) ...[
              SizedBox(height: 12.h),
              _profitPreview(),
            ],
          ],
        ),
      ));
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
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _render(f)),
            SizedBox(width: 10.w),
            Expanded(child: _render(fields[i + 1])),
          ],
        ));
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
          suffixIcon: _iconBtn(Icons.autorenew_rounded, AppTheme.primaryColor, _regenerateCode),
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
            if (f.required && (v == null || v.trim().isEmpty)) return 'validatorRequired'.tr();
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
          validator: (rows) {
            for (final r in rows) {
              final qty = r.qty.trim();
              if (qty.isEmpty || (int.tryParse(NumberParser.toLatin(qty)) ?? -1) < 0) {
                return 'productsInvalidNumber'.tr();
              }
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
          suffix: f.type == ProductFieldType.decimal ? 'currencyEGP'.tr() : null,
          keyboard: switch (f.type) {
            ProductFieldType.decimal => const TextInputType.numberWithOptions(decimal: true),
            ProductFieldType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          validator: _fieldValidator(f),
          onChanged: (_) => setState(() {}),
        );
    }
  }

  /// الكمية الإجمالية تتبع صفوف جدول Variants تلقائياً.
  void _syncStockFromVariants() {
    final total = ProductFormVariantsEditor.totalQty(_variants);
    _ctrl(ProductFieldKeys.stock).text = '$total';
  }

  /// قواعد التحقق المطبقة على الحقول النصية/الرقمية (نفس منطق Cubit).
  FormFieldValidator<String>? _fieldValidator(ProductFieldConfig f) {    return (String? v) {
      final text = (v ?? '').trim();
      // الكمية تُحسب من صفوف Variants لو موجودة.
      if (f.key == ProductFieldKeys.stock && _variants.isNotEmpty) return null;
      if (f.required && text.isEmpty) return 'validatorRequired'.tr();
      if (text.isEmpty) return null;
      switch (f.type) {
        case ProductFieldType.decimal:
          final n = double.tryParse(NumberParser.toLatin(text));
          if (n == null) return 'validatorNumber'.tr();
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
        _dropdownField<String>(
          label: f.labelKey.tr(),
          icon: f.icon,
          value: _category,
          items: [for (final c in _allCategories) DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp)))],
          onChanged: (v) => setState(() {
            _category = v;
            _customCategory = v == _otherOption;
          }),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementView()));
            },
            icon: Icon(Icons.settings_rounded, size: 14.sp, color: AppTheme.primaryColor),
            label: Text('productFormManageCategories'.tr(), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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

  /// قائمة منسدلة عامة (مقاس، وحدة قياس...) مع دعم "أخرى" الكتابة الحرة.
  Widget _renderDropdown(ProductFieldConfig f) {
    final current = _dropdownValues[f.key];
    final items = <DropdownMenuItem<String>>[
      for (final o in f.options) DropdownMenuItem(value: o, child: Text(o, style: TextStyle(fontSize: 13.sp))),
      if (f.allowCustom && !f.options.contains('أخرى'))
        DropdownMenuItem(value: 'أخرى', child: Text('أخرى', style: TextStyle(fontSize: 13.sp))),
      // قيمة قديمة غير موجودة في القائمة → نعرضها لمنع خطأ Assertion.
      if (current != null && current.isNotEmpty && !f.options.contains(current))
        DropdownMenuItem(value: current, child: Text(current, style: TextStyle(fontSize: 13.sp))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(f.key),
          initialValue: current,
          isExpanded: true,
          decoration: productFormDecoration(context, label: f.labelKey.tr(), icon: f.icon, required: f.required),
          items: items,
          validator: (v) => f.required && (v == null || v.isEmpty) ? 'validatorRequired'.tr() : null,
          onChanged: (v) => setState(() {
            _dropdownTouched.add(f.key);
            _dropdownValues[f.key] = v;
            _customFlags[f.key] = v == 'أخرى';
          }),
          style: TextStyle(fontSize: 13.5.sp, color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(16.r),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: AppTheme.primaryColor),
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

  Widget _profitPreview() {
    final cost = double.tryParse(NumberParser.toLatin(_ctrl(ProductFieldKeys.costPrice).text));
    final price = double.tryParse(NumberParser.toLatin(_ctrl(ProductFieldKeys.price).text));
    if (cost == null || price == null || cost <= 0 || price <= 0) return const SizedBox.shrink();
    final profit = price - cost;
    final margin = price > 0 ? (profit / price * 100) : 0;
    final positive = profit >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: positive ? const Color(0xFFECFDF5) : AppTheme.dangerSoft, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: positive ? AppTheme.successDark.withValues(alpha: 0.14) : AppTheme.danger.withValues(alpha: 0.14))),
      child: Row(children: [
        Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16.sp, color: positive ? AppTheme.successDark : AppTheme.danger),
        SizedBox(width: 8.w),
        Expanded(child: Text(positive ? 'ربح ${_num(profit)} ج.م • هامش ${margin.toStringAsFixed(1)}%' : 'خسارة ${_num(profit.abs())} ج.م', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: positive ? AppTheme.successDark : AppTheme.danger))),
        Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: positive ? AppTheme.successDark : AppTheme.danger, borderRadius: BorderRadius.circular(20.r)), child: Text(positive ? 'مربح' : 'خسارة', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 6.w),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 18.sp, color: color)),
      ),
    );
  }

  Widget _dropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged, IconData? icon}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: productFormDecoration(context, label: label, icon: icon),
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13.5.sp, color: Theme.of(context).colorScheme.onSurface),
      borderRadius: BorderRadius.circular(16.r),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: AppTheme.primaryColor),
    );
  }

  static String _num(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
