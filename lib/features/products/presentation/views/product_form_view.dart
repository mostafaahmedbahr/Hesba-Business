import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<String> _categoriesFor(String? shopType) =>
      AppConstants.productCategoriesByBusinessType[shopType] ?? AppConstants.defaultProductCategories;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name);
    _codeController = TextEditingController(text: p?.code ?? _generateCode(widget.cubit.state.products));
    _costPriceController = TextEditingController(text: p != null ? _num(p.costPrice) : '');
    _priceController = TextEditingController(text: p != null ? _num(p.price) : '');
    _stockController = TextEditingController(text: p != null ? '${p.stock}' : '');
    _lowStockController = TextEditingController(text: p != null ? '${p.lowStockThreshold}' : '5');
    _colorController = TextEditingController(text: p?.color);
    _notesController = TextEditingController(text: p?.notes);
    _imageUrlController = TextEditingController(text: p?.imageUrl);
    _customCategoryController = TextEditingController();
    _customSizeController = TextEditingController();

    if (widget.cubit.state.shopType == null) {
      widget.cubit.loadShopType().then((type) { if (mounted && type != null) setState(() => _categories = _categoriesFor(type)); });
    }

    final savedCategory = p?.category ?? '';
    if (savedCategory.isNotEmpty) {
      if (_categories.contains(savedCategory)) _category = savedCategory;
      else { _category = _otherOption; _customCategory = true; _customCategoryController.text = savedCategory; }
    }
    final savedSize = p?.size ?? '';
    if (savedSize.isNotEmpty) {
      if (AppConstants.productSizes.contains(savedSize)) _size = savedSize;
      else { _size = _otherOption; _customSize = true; _customSizeController.text = savedSize; }
    }
  }

  String get _otherOption => _categories.last;

  @override
  void dispose() {
    _nameController.dispose(); _codeController.dispose(); _costPriceController.dispose(); _priceController.dispose();
    _stockController.dispose(); _lowStockController.dispose(); _colorController.dispose(); _notesController.dispose();
    _imageUrlController.dispose(); _customCategoryController.dispose(); _customSizeController.dispose();
    super.dispose();
  }

  String _generateCode(List<Product> products) {
    var max = 0; final reg = RegExp(r'^PRD-(\d+)$');
    for (final product in products) {
      final m = reg.firstMatch(product.code.trim());
      if (m != null) { final n = int.tryParse(m.group(1)!) ?? 0; if (n > max) max = n; }
    }
    return 'PRD-${(max + 1).toString().padLeft(3, '0')}';
  }

  void _regenerateCode() => setState(() => _codeController.text = _generateCode(widget.cubit.state.products));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final category = _customCategory ? _customCategoryController.text.trim() : (_category ?? '');
    final size = _customSize ? _customSizeController.text.trim() : (_size ?? '');
    final code = _codeController.text.trim();
    final costPrice = double.parse(_toLatin(_costPriceController.text));
    final price = double.parse(_toLatin(_priceController.text));
    final stock = int.parse(_toLatin(_stockController.text));
    final lowStock = int.tryParse(_toLatin(_lowStockController.text)) ?? 5;
    final base = widget.product;
    final bool ok;
    if (_isEdit) {
      ok = await widget.cubit.updateProduct(base!.copyWith(name: _nameController.text.trim(), category: category, code: code, costPrice: costPrice, price: price, stock: stock, lowStockThreshold: lowStock, size: size, color: _colorController.text.trim(), notes: _notesController.text.trim(), imageUrl: _imageUrlController.text.trim()));
    } else {
      ok = await widget.cubit.addProduct(Product(id: '', name: _nameController.text.trim(), category: category, code: code, costPrice: costPrice, price: price, stock: stock, lowStockThreshold: lowStock, size: size, color: _colorController.text.trim(), notes: _notesController.text.trim(), imageUrl: _imageUrlController.text.trim(), shopId: '', ownerId: ''));
    }
    if (!mounted) return;
    if (ok) { HapticFeedback.mediumImpact(); AppToast.success(context, _isEdit ? 'productUpdated'.tr() : 'productSaved'.tr()); Navigator.pop(context); }
    else { setState(() => _saving = false); AppToast.error(context, 'productSaveFailed'.tr()); }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24.r)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64.w, height: 64.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.delete_rounded, color: const Color(0xFFE11D48), size: 28.sp)),
            SizedBox(height: 14.h),
            Text('productDeleteConfirmTitle'.tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text('productDeleteConfirmBody'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            SizedBox(height: 18.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext, false), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('cancel'.tr()))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('productDelete'.tr()))),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    final deleted = await widget.cubit.deleteProduct(widget.product!.id);
    if (!mounted) return;
    if (deleted) { HapticFeedback.heavyImpact(); AppToast.success(context, 'productDeleted'.tr()); Navigator.pop(context); }
    else { setState(() => _deleting = false); AppToast.error(context, 'productDeleteFailed'.tr()); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_isEdit ? 'productFormEdit'.tr() : 'productFormAdd'.tr(), style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.close_rounded, size: 22.sp), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            // معاينة الصورة
            _imagePreviewCard(isDark),
            SizedBox(height: 14.h),

            _SectionCard(icon: Icons.info_outline_rounded, title: 'المعلومات الأساسية', gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)], child: Column(children: [
              _field(controller: _nameController, label: 'productFormName'.tr(), hint: 'productFormNameHint'.tr(), icon: Icons.inventory_2_rounded, required: true, validator: (v) => (v == null || v.trim().isEmpty) ? 'validatorRequired'.tr() : null),
              SizedBox(height: 12.h),
              _dropdownField<String>(label: 'productFormCategory'.tr(), icon: Icons.category_rounded, value: _category, items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 13.sp)))], onChanged: (v) => setState(() { _category = v; _customCategory = v == _otherOption; })),
              if (_customCategory) ...[SizedBox(height: 12.h), _field(controller: _customCategoryController, label: 'productFormCustomCategory'.tr(), hint: 'productFormCategoryHint'.tr(), icon: Icons.edit_rounded, required: true, validator: (v) => (v == null || v.trim().isEmpty) ? 'validatorRequired'.tr() : null)],
              SizedBox(height: 12.h),
              _field(controller: _codeController, label: 'productFormCode'.tr(), hint: 'productFormCodeHint'.tr(), icon: Icons.qr_code_2_rounded, suffixIcon: _iconBtn(Icons.autorenew_rounded, AppTheme.primaryColor, _regenerateCode)),
            ])),

            SizedBox(height: 14.h),
            _SectionCard(icon: Icons.payments_rounded, title: 'التسعير والمخزون', gradient: const [Color(0xFF059669), Color(0xFF34D399)], child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field(controller: _costPriceController, label: 'productFormCostPrice'.tr(), icon: Icons.shopping_cart_rounded, suffix: 'currencyEGP'.tr(), keyboard: _numberKeyboard(decimal: true), required: true, validator: (v) => _positiveNumber(v))),
                SizedBox(width: 10.w),
                Expanded(child: _field(controller: _priceController, label: 'productFormPrice'.tr(), icon: Icons.sell_rounded, suffix: 'currencyEGP'.tr(), keyboard: _numberKeyboard(decimal: true), required: true, validator: (v) => _positiveNumber(v))),
              ]),
              SizedBox(height: 12.h),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field(controller: _stockController, label: 'productFormStock'.tr(), icon: Icons.numbers_rounded, keyboard: _numberKeyboard(), required: true, validator: (v) { if (v == null || v.trim().isEmpty) return 'validatorRequired'.tr(); final n = int.tryParse(_toLatin(v)); if (n == null || n < 0) return 'productsInvalidNumber'.tr(); return null; })),
                SizedBox(width: 10.w),
                Expanded(child: _field(controller: _lowStockController, label: 'productFormLowStock'.tr(), icon: Icons.low_priority_rounded, keyboard: _numberKeyboard(), validator: (v) { if (v == null || v.trim().isEmpty) return null; final n = int.tryParse(_toLatin(v)); if (n == null || n < 0) return 'productsInvalidNumber'.tr(); return null; })),
              ]),
              SizedBox(height: 12.h),
              _profitPreview(),
            ])),

            SizedBox(height: 14.h),
            _SectionCard(icon: Icons.tune_rounded, title: 'التفاصيل', gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)], child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _dropdownField<String>(label: 'productFormSize'.tr(), icon: Icons.straighten_rounded, value: _size, items: [for (final s in AppConstants.productSizes) DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13.sp)))], onChanged: (v) => setState(() { _size = v; _customSize = v == _otherOption; }))),
                SizedBox(width: 10.w),
                Expanded(child: _field(controller: _colorController, label: 'productFormColor'.tr(), hint: 'productFormColorHint'.tr(), icon: Icons.palette_rounded)),
              ]),
              if (_customSize) ...[SizedBox(height: 12.h), _field(controller: _customSizeController, label: 'productFormCustomSize'.tr(), hint: 'productFormSizeHint'.tr(), icon: Icons.edit_rounded, required: true, validator: (v) => (v == null || v.trim().isEmpty) ? 'validatorRequired'.tr() : null)],
            ])),

            SizedBox(height: 14.h),
            _SectionCard(icon: Icons.image_rounded, title: 'الوسائط والملاحظات', gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)], child: Column(children: [
              _field(controller: _imageUrlController, label: 'productFormImageUrl'.tr(), hint: 'productFormImageUrlHint'.tr(), icon: Icons.link_rounded, keyboard: TextInputType.url, onChanged: (_) => setState(() {})),
              SizedBox(height: 12.h),
              _field(controller: _notesController, label: 'productFormNotes'.tr(), hint: 'productFormNotesHint'.tr(), icon: Icons.notes_rounded, maxLines: 3),
            ])),

            SizedBox(height: 22.h),
            SizedBox(
              height: 54.h,
              child: FilledButton(
                onPressed: _saving || _deleting ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))),
                child: _saving ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18.sp), SizedBox(width: 8.w), Text(_isEdit ? 'productFormUpdate'.tr() : 'productFormSave'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800))]),
              ),
            ),
            if (_isEdit) ...[
              SizedBox(height: 10.h),
              SizedBox(height: 50.h, child: OutlinedButton.icon(onPressed: _saving || _deleting ? null : _delete, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE11D48), side: const BorderSide(color: Color(0xFFE11D48)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))), icon: _deleting ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFFE11D48))) : const Icon(Icons.delete_outline_rounded, size: 18), label: Text('productDelete'.tr(), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imagePreviewCard(bool isDark) {
    final url = _imageUrlController.text.trim();
    final hasImage = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderPreview(isDark), loadingBuilder: (c, child, p) => p == null ? child : _placeholderPreview(isDark))
            else
              _placeholderPreview(isDark),
            Positioned(
              top: 10.h, right: 10.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.image_rounded, size: 12.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(hasImage ? 'معاينة الصورة' : 'بدون صورة', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderPreview(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryColor.withValues(alpha: 0.10), const Color(0xFF7C4DFF).withValues(alpha: 0.10)]),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(Icons.inventory_2_rounded, size: 26.sp, color: AppTheme.primaryColor)),
        SizedBox(height: 10.h),
        Text('صورة المنتج', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
        SizedBox(height: 2.h),
        Text('أضف رابط الصورة لمعاينتها هنا', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _profitPreview() {
    final cost = double.tryParse(_toLatin(_costPriceController.text));
    final price = double.tryParse(_toLatin(_priceController.text));
    if (cost == null || price == null || cost <= 0 || price <= 0) return const SizedBox.shrink();
    final profit = price - cost;
    final margin = price > 0 ? (profit / price * 100) : 0;
    final positive = profit >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: positive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: positive ? const Color(0xFF059669).withValues(alpha: 0.14) : const Color(0xFFE11D48).withValues(alpha: 0.14))),
      child: Row(children: [
        Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16.sp, color: positive ? const Color(0xFF059669) : const Color(0xFFE11D48)),
        SizedBox(width: 8.w),
        Expanded(child: Text(positive ? 'ربح ${_num(profit)} ج.م • هامش ${margin.toStringAsFixed(1)}%' : 'خسارة ${_num(profit.abs())} ج.م', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: positive ? const Color(0xFF059669) : const Color(0xFFE11D48)))),
        Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: positive ? const Color(0xFF059669) : const Color(0xFFE11D48), borderRadius: BorderRadius.circular(20.r)), child: Text(positive ? 'مربح' : 'خسارة', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 6.w),
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        borderRadius: BorderRadius.circular(10.r),
        child: Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 18.sp, color: color)),
      ),
    );
  }

  Widget _SectionCard({required IconData icon, required String title, required List<Color> gradient, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Text(title, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ]),
        SizedBox(height: 14.h),
        child,
      ]),
    );
  }

  Widget _dropdownField<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged, IconData? icon}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label: label, icon: icon),
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13.5.sp, color: Theme.of(context).colorScheme.onSurface),
      borderRadius: BorderRadius.circular(16.r),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20.sp, color: AppTheme.primaryColor),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon, String? hint, bool required = false, String? suffix, TextInputType? keyboard, TextInputAction? textInputAction, int maxLines = 1, Widget? suffixIcon, FormFieldValidator<String>? validator, void Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard ?? TextInputType.text,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
      decoration: _decoration(label: label, hint: hint, icon: icon, required: required, suffix: suffix, suffixIcon: suffixIcon),
    );
  }

  InputDecoration _decoration({required String label, String? hint, IconData? icon, bool required = false, String? suffix, Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
      labelStyle: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
      prefixIcon: icon == null ? null : Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: AppTheme.primaryColor)),
      suffixText: suffix,
      suffixStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.6)),
    );
  }

  String? _positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'validatorRequired'.tr();
    final n = double.tryParse(_toLatin(v));
    if (n == null) return 'validatorNumber'.tr();
    if (n <= 0) return 'validatorPositiveNumber'.tr();
    return null;
  }

  static TextInputType _numberKeyboard({bool decimal = false}) => TextInputType.numberWithOptions(decimal: decimal);
}

String _toLatin(String input) => input.replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2').replaceAll('٣', '3').replaceAll('٤', '4').replaceAll('٥', '5').replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8').replaceAll('٩', '9').replaceAll('۰', '0').replaceAll('۱', '1').replaceAll('۲', '2').replaceAll('۳', '3').replaceAll('۴', '4').replaceAll('۵', '5').replaceAll('۶', '6').replaceAll('۷', '7').replaceAll('۸', '8').replaceAll('۹', '9');
String _num(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
