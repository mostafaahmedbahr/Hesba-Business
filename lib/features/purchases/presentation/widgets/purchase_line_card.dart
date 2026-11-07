import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/stock_purchase_state.dart';

/// كارت سطر في فاتورة الشراء: اختيار منتج + عرض المخزون/التكلفة الحالية +
/// كمية واردة وسعر شراء الوحدة + إجمالي السطر.
///
/// الكونترولرات مملوكة لل Kart (بلا setState) والنصوص الخام تُرسل للـ Cubit
/// عبر callbacks — إعادة البناء كلها من BlocBuilder على الحالة.
class PurchaseLineCard extends StatefulWidget {
  final int index;
  final PurchaseLine line;
  final List<Product> products;
  final ValueChanged<Product?> onProductSelected;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<String> onCostChanged;
  final VoidCallback? onDelete;
  final bool canDelete;

  const PurchaseLineCard({
    super.key,
    required this.index,
    required this.line,
    required this.products,
    required this.onProductSelected,
    required this.onQtyChanged,
    required this.onCostChanged,
    this.onDelete,
    this.canDelete = true,
  });

  @override
  State<PurchaseLineCard> createState() => _PurchaseLineCardState();
}

class _PurchaseLineCardState extends State<PurchaseLineCard> {
  late final TextEditingController _qtyController;
  late final TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.line.qtyText);
    _costController = TextEditingController(text: widget.line.costText);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  String _num(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  void _selectProduct(Product? product) {
    if (product == null) {
      widget.onProductSelected(null);
      return;
    }
    // اقتراح سعر شراء الوحدة الحالي لو الحقل فاضي.
    if (_costController.text.trim().isEmpty) {
      _costController.text = _num(product.costPrice);
      widget.onCostChanged(_costController.text);
    }
    widget.onProductSelected(product);
  }

  InputDecoration _decoration({
    required bool isDark,
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
      labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      prefixIcon: Container(
        margin: EdgeInsets.all(8.w),
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: AppTheme.successDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 16.sp, color: AppTheme.successDark),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppTheme.successDark, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppTheme.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = widget.line;
    final hasProduct = line.hasProduct;
    final inlineError =
        hasProduct ? line.validationErrorKey : null; // رسالة تحت السطر
    final lineTotal = line.lineTotal;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: hasProduct
              ? AppTheme.successDark.withValues(alpha: 0.25)
              : (isDark ? AppTheme.darkBorder : AppTheme.hairline),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم السطر + حالة + حذف.
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.successDark, AppTheme.mintLight],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (hasProduct)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.successDark.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    line.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successDark,
                    ),
                  ),
                ),
              const Spacer(),
              if (widget.canDelete)
                InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 17.sp,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // اختيار المنتج (بحث بالاسم/الكود/القسم).
          Autocomplete<Product>(
            displayStringForOption: (p) => p.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return widget.products.take(6);
              }
              final q = textEditingValue.text.toLowerCase();
              return widget.products.where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q));
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topCenter,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14.r),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 220.h),
                    child: ListView.separated(
                      padding: EdgeInsets.all(6.w),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => Divider(height: 1.h),
                      itemBuilder: (context, index) {
                        final p = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          leading: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: AppTheme.successDark.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 18.sp,
                              color: AppTheme.successDark,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${'purchaseCurrentStock'.tr()}: ${p.stockLabel} — '
                            '${'purchaseCurrentCost'.tr()}: ${_num(p.costPrice)} ${'currencyEGP'.tr()}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.slateGray,
                            ),
                          ),
                          trailing: p.isLowStock
                              ? Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16.sp,
                                  color: Colors.orange,
                                )
                              : null,
                          onTap: () => onSelected(p),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                decoration: _decoration(
                  isDark: isDark,
                  label: 'saleChooseProduct'.tr(),
                  hint: 'productSearchHint'.tr(),
                  icon: Icons.search_rounded,
                ).copyWith(
                  suffixIcon: textController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 17.sp),
                          onPressed: () {
                            textController.clear();
                            _costController.clear();
                            widget.onCostChanged('');
                            widget.onProductSelected(null);
                          },
                        )
                      : null,
                ),
              );
            },
            onSelected: _selectProduct,
          ),

          // المخزون/التكلفة الحالية وقت الاختيار.
          if (hasProduct) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _InfoChip(
                  icon: Icons.inventory_2_rounded,
                  label:
                      '${'purchaseCurrentStock'.tr()}: ${line.currentStock == line.currentStock.roundToDouble() ? line.currentStock.toStringAsFixed(0) : line.currentStock.toStringAsFixed(1)}',
                  isDark: isDark,
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label:
                      '${'purchaseCurrentCost'.tr()}: ${_num(line.currentCost)} ${'currencyEGP'.tr()}',
                  isDark: isDark,
                ),
              ],
            ),
          ],

          SizedBox(height: 12.h),

          // الكمية الواردة + سعر شراء الوحدة.
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                  decoration: _decoration(
                    isDark: isDark,
                    label: 'purchaseQtyLabel'.tr(),
                    hint: '0',
                    icon: Icons.pin_outlined,
                  ),
                  onChanged: widget.onQtyChanged,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                  decoration: _decoration(
                    isDark: isDark,
                    label: 'purchaseUnitCostLabel'.tr(),
                    hint: '0',
                    icon: Icons.payments_outlined,
                    suffixText: 'currencyEGP'.tr(),
                  ),
                  onChanged: widget.onCostChanged,
                ),
              ),
            ],
          ),

          // رسالة تحقق داخلية للسطر.
          if (inlineError != null) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 13.sp,
                  color: AppTheme.danger,
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    inlineError.tr(namedArgs: {'row': '${widget.index + 1}'}),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // إجمالي السطر.
          if (lineTotal > 0) ...[
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.successDark.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'productLineTotal'.tr(namedArgs: {
                      'total': lineTotal % 1 == 0
                          ? lineTotal.toStringAsFixed(0)
                          : lineTotal.toStringAsFixed(2),
                      'currency': 'currencyEGP'.tr(),
                    }),
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// شريحة معلومة صغيرة (مخزون/تكلفة حالية).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppTheme.slateGray),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.slateGray,
            ),
          ),
        ],
      ),
    );
  }
}
