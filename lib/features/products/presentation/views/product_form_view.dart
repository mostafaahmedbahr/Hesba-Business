import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../cubit/products_cubit.dart';

class ProductFormView extends StatefulWidget {
  final ProductsCubit cubit;
  final Product? product;

  const ProductFormView({super.key, required this.cubit, this.product});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockController;
  late final TextEditingController _colorController;
  late final TextEditingController _notesController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _customSizeController;

  String? _category;
  String? _size;
  bool _customCategory = false;
  bool _customSize = false;
  late List<String> _categories = _categoriesFor(widget.cubit.state.shopType);

  bool _saving = false;
  bool _deleting = false;

  bool get _isEdit => widget.product != null;

  /// Sub-categories relevant to the shop business type (e.g. clothing shop ->
  /// t-shirt, pants, ...). Falls back to a generic list.
  List<String> _categoriesFor(String? shopType) =>
      AppConstants.productCategoriesByBusinessType[shopType] ??
      AppConstants.defaultProductCategories;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p?.name);
    _codeController = TextEditingController(
      text: p?.code ?? _generateCode(widget.cubit.state.products),
    );
    _costPriceController = TextEditingController(
      text: p != null ? _num(p.costPrice) : '',
    );
    _priceController = TextEditingController(
      text: p != null ? _num(p.price) : '',
    );
    _stockController = TextEditingController(text: p != null ? '${p.stock}' : '');
    _lowStockController = TextEditingController(
      text: p != null ? '${p.lowStockThreshold}' : '5',
    );
    _colorController = TextEditingController(text: p?.color);
    _notesController = TextEditingController(text: p?.notes);
    _imageUrlController = TextEditingController(text: p?.imageUrl);
    _customCategoryController = TextEditingController();
    _customSizeController = TextEditingController();

    if (widget.cubit.state.shopType == null) {
      widget.cubit.loadShopType().then((type) {
        if (mounted && type != null) {
          setState(() => _categories = _categoriesFor(type));
        }
      });
    }

    // Category dropdown: if the product's saved category is not in the
    // preset list, show it via the 'أخرى' option.
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

    final savedSize = p?.size ?? '';
    if (savedSize.isNotEmpty) {
      if (AppConstants.productSizes.contains(savedSize)) {
        _size = savedSize;
      } else {
        _size = _otherOption;
        _customSize = true;
        _customSizeController.text = savedSize;
      }
    }
  }

  String get _otherOption => _categories.last;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _costPriceController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    _customCategoryController.dispose();
    _customSizeController.dispose();
    super.dispose();
  }

  /// Builds a code like "PRD-004" from the highest existing code number.
  String _generateCode(List<Product> products) {
    var max = 0;
    final reg = RegExp(r'^PRD-(\d+)$');
    for (final product in products) {
      final match = reg.firstMatch(product.code.trim());
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'PRD-${(max + 1).toString().padLeft(3, '0')}';
  }

  void _regenerateCode() {
    setState(
      () => _codeController.text = _generateCode(widget.cubit.state.products),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final category = _customCategory
        ? _customCategoryController.text.trim()
        : (_category ?? '');
    final size =
        _customSize ? _customSizeController.text.trim() : (_size ?? '');
    final code = _codeController.text.trim();
    final costPrice = double.parse(_toLatin(_costPriceController.text));
    final price = double.parse(_toLatin(_priceController.text));
    final stock = int.parse(_toLatin(_stockController.text));
    final lowStock = int.tryParse(_toLatin(_lowStockController.text)) ?? 5;

    final base = widget.product;
    final bool ok;
    if (_isEdit) {
      ok = await widget.cubit.updateProduct(
        base!.copyWith(
          name: _nameController.text.trim(),
          category: category,
          code: code,
          costPrice: costPrice,
          price: price,
          stock: stock,
          lowStockThreshold: lowStock,
          size: size,
          color: _colorController.text.trim(),
          notes: _notesController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
        ),
      );
    } else {
      ok = await widget.cubit.addProduct(
        Product(
          id: '',
          name: _nameController.text.trim(),
          category: category,
          code: code,
          costPrice: costPrice,
          price: price,
          stock: stock,
          lowStockThreshold: lowStock,
          size: size,
          color: _colorController.text.trim(),
          notes: _notesController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          shopId: '',
          ownerId: '',
        ),
      );
    }

    if (!mounted) return;
    if (ok) {
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text('productDeleteConfirmTitle'.tr()),
        content: Text('productDeleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('productDelete'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    final deleted = await widget.cubit.deleteProduct(widget.product!.id);
    if (!mounted) return;
    if (deleted) {
      AppToast.success(context, 'productDeleted'.tr());
      Navigator.pop(context);
    } else {
      setState(() => _deleting = false);
      AppToast.error(context, 'productDeleteFailed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'productFormEdit'.tr() : 'productFormAdd'.tr(),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          children: [
            _field(
              controller: _nameController,
              label: 'productFormName'.tr(),
              hint: 'productFormNameHint'.tr(),
              icon: Icons.inventory_2_rounded,
              required: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'validatorRequired'.tr()
                  : null,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 14.h),
            _dropdownField<String>(
              label: 'productFormCategory'.tr(),
              icon: Icons.category_rounded,
              value: _category,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() {
                _category = v;
                _customCategory = v == _otherOption;
              }),
            ),
            if (_customCategory) ...[
              SizedBox(height: 12.h),
              _field(
                controller: _customCategoryController,
                label: 'productFormCustomCategory'.tr(),
                hint: 'productFormCategoryHint'.tr(),
                icon: Icons.edit_rounded,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'validatorRequired'.tr()
                    : null,
                textInputAction: TextInputAction.next,
              ),
            ],
            SizedBox(height: 14.h),
            _field(
              controller: _codeController,
              label: 'productFormCode'.tr(),
              hint: 'productFormCodeHint'.tr(),
              icon: Icons.qr_code_2_rounded,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                onPressed: _regenerateCode,
                tooltip: 'productsCodeGenerate'.tr(),
                icon: const Icon(Icons.autorenew_rounded),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    controller: _costPriceController,
                    label: 'productFormCostPrice'.tr(),
                    icon: Icons.shopping_cart_rounded,
                    suffix: 'currencyEGP'.tr(),
                    keyboard: _numberKeyboard(decimal: true),
                    required: true,
                    validator: (v) => _positiveNumber(v),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _field(
                    controller: _priceController,
                    label: 'productFormPrice'.tr(),
                    icon: Icons.sell_rounded,
                    suffix: 'currencyEGP'.tr(),
                    keyboard: _numberKeyboard(decimal: true),
                    required: true,
                    validator: (v) => _positiveNumber(v),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    controller: _stockController,
                    label: 'productFormStock'.tr(),
                    icon: Icons.numbers_rounded,
                    keyboard: _numberKeyboard(),
                    required: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'validatorRequired'.tr();
                      }
                      final n = int.tryParse(_toLatin(v));
                      if (n == null || n < 0) {
                        return 'productsInvalidNumber'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _field(
                    controller: _lowStockController,
                    label: 'productFormLowStock'.tr(),
                    icon: Icons.low_priority_rounded,
                    keyboard: _numberKeyboard(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(_toLatin(v));
                      if (n == null || n < 0) {
                        return 'productsInvalidNumber'.tr();
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _dropdownField<String>(
                    label: 'productFormSize'.tr(),
                    icon: Icons.straighten_rounded,
                    value: _size,
                    items: [
                      for (final s in AppConstants.productSizes)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() {
                      _size = v;
                      _customSize = v == _otherOption;
                    }),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _field(
                    controller: _colorController,
                    label: 'productFormColor'.tr(),
                    hint: 'productFormColorHint'.tr(),
                    icon: Icons.palette_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            if (_customSize) ...[
              SizedBox(height: 12.h),
              _field(
                controller: _customSizeController,
                label: 'productFormCustomSize'.tr(),
                hint: 'productFormSizeHint'.tr(),
                icon: Icons.edit_rounded,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'validatorRequired'.tr()
                    : null,
                textInputAction: TextInputAction.next,
              ),
            ],
            SizedBox(height: 14.h),
            _field(
              controller: _imageUrlController,
              label: 'productFormImageUrl'.tr(),
              hint: 'productFormImageUrlHint'.tr(),
              icon: Icons.link_rounded,
              keyboard: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 14.h),
            _field(
              controller: _notesController,
              label: 'productFormNotes'.tr(),
              hint: 'productFormNotesHint'.tr(),
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              height: 54.h,
              child: ElevatedButton(
                onPressed: _saving || _deleting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit
                            ? 'productFormUpdate'.tr()
                            : 'productFormSave'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (_isEdit) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 54.h,
                child: OutlinedButton.icon(
                  onPressed: _saving || _deleting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  icon: _deleting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFE53935),
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    'productDelete'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(
        theme,
        label: label,
        icon: icon,
      ),
      items: items,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14.sp,
        color: theme.colorScheme.onSurface,
      ),
      borderRadius: BorderRadius.circular(16.r),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    String? suffix,
    TextInputType? keyboard,
    TextInputAction? textInputAction,
    int maxLines = 1,
    Widget? suffixIcon,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboard ?? TextInputType.text,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      decoration: _decoration(
        theme,
        label: label,
        hint: hint,
        icon: icon,
        required: required,
        suffix: suffix,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _decoration(
    ThemeData theme, {
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    String? suffix,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixText: suffix,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 1.6,
        ),
      ),
    );
  }

  String? _positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'validatorRequired'.tr();
    final n = double.tryParse(_toLatin(v));
    if (n == null) return 'validatorNumber'.tr();
    if (n <= 0) return 'validatorPositiveNumber'.tr();
    return null;
  }

  static TextInputType _numberKeyboard({bool decimal = false}) =>
      TextInputType.numberWithOptions(decimal: decimal);
}

/// Converts Arabic-Indic / Persian digits to Latin digits.
String _toLatin(String input) {
  return input
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll('۰', '0')
      .replaceAll('۱', '1')
      .replaceAll('۲', '2')
      .replaceAll('۳', '3')
      .replaceAll('۴', '4')
      .replaceAll('۵', '5')
      .replaceAll('۶', '6')
      .replaceAll('۷', '7')
      .replaceAll('۸', '8')
      .replaceAll('۹', '9');
}

String _num(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}