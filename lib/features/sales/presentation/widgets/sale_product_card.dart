import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/models/product.dart';
import '../../../../core/theme/app_theme.dart';

/// كارت صنف (بحث مخزون + stepper كمية + سعر).
class SaleProductCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final VoidCallback onDelete;
  final List<Product> availableProducts;
  final Product? selectedProduct;
  final ValueChanged<Product?> onProductSelected;
  final VoidCallback onChanged;
  final int index;

  const SaleProductCard({
    super.key,
    required this.nameController,
    required this.quantityController,
    required this.priceController,
    required this.onDelete,
    required this.availableProducts,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.onChanged,
    this.index = 0,
  });

  /// يزود / ينقص الكمية من الـ stepper.
  void _step(double delta, double maxStock) {
    final current = double.tryParse(quantityController.text) ?? 0;
    var next = current + delta;
    if (next < 0.5) next = 0.5;
    if (maxStock > 0 && next > maxStock) next = maxStock;
    quantityController.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 1);
    onChanged();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxStock = (selectedProduct?.stock ?? 0).toDouble();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: selectedProduct != null
              ? AppTheme.primaryColor.withValues(alpha: 0.25)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الصنف + المخزون + حذف.
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text('${index + 1}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              SizedBox(width: 8.w),
              if (selectedProduct != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: (selectedProduct!.isOutOfStock ? const Color(0xFFE11D48) : const Color(0xFF059669)).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    selectedProduct!.isOutOfStock ? 'خلصان' : 'متاح: ${selectedProduct!.stock}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: selectedProduct!.isOutOfStock ? const Color(0xFFE11D48) : const Color(0xFF059669),
                    ),
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded, size: 17.sp, color: const Color(0xFFE11D48)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // بحث المنتج.
          Autocomplete<Product>(
            displayStringForOption: (p) => p.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return availableProducts.take(6);
              }
              final q = textEditingValue.text.toLowerCase();
              return availableProducts.where((p) =>
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          leading: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(Icons.inventory_2_rounded, size: 18.sp, color: AppTheme.primaryColor),
                          ),
                          title: Text(p.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${p.price.toStringAsFixed(0)} ج.م • مخزون: ${p.stock}',
                            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
                          ),
                          trailing: p.isLowStock
                              ? Icon(Icons.warning_amber_rounded, size: 16.sp, color: Colors.orange)
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
              textController.text = nameController.text;
              textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: textController.text.length));
              textController.addListener(() {
                if (nameController.text != textController.text) {
                  nameController.text = textController.text;
                  onChanged();
                }
              });
              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود...',
                  hintStyle: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF94A3B8)),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(8.w),
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.search_rounded, size: 17.sp, color: AppTheme.primaryColor),
                  ),
                  suffixIcon: textController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 17.sp),
                          onPressed: () {
                            textController.clear();
                            nameController.clear();
                            onProductSelected(null);
                            onChanged();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'اختار المنتج' : null,
              );
            },
            onSelected: (product) {
              nameController.text = product.name;
              priceController.text =
                  product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2);
              if (quantityController.text.isEmpty) {
                quantityController.text = '1';
              }
              onProductSelected(product);
              onChanged();
            },
          ),

          if (selectedProduct != null && selectedProduct!.category.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              selectedProduct!.category,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
          SizedBox(height: 12.h),

          // الكمية (stepper) + السعر.
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _StepBtn(icon: Icons.remove_rounded, onTap: () => _step(-1, maxStock)),
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                          onChanged: (_) => onChanged(),
                          validator: (v) {
                            final q = double.tryParse(v ?? '');
                            if (q == null || q <= 0) return '!';
                            if (selectedProduct != null && q > selectedProduct!.stock) {
                              return 'المتاح ${selectedProduct!.stock}';
                            }
                            return null;
                          },
                        ),
                      ),
                      _StepBtn(icon: Icons.add_rounded, onTap: () => _step(1, maxStock)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'السعر',
                    suffixText: 'ج.م',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18.sp, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.6),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    if (p == null || p <= 0) return '!';
                    return null;
                  },
                ),
              ),
            ],
          ),

          // إجمالي السطر.
          Builder(builder: (context) {
            final q = double.tryParse(quantityController.text) ?? 0;
            final p = double.tryParse(priceController.text) ?? 0;
            final lineTotal = q * p;
            if (lineTotal <= 0) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '= ${lineTotal.toStringAsFixed(2)} ج.م',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// زرار + / - للكمية.
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 17.sp, color: AppTheme.primaryColor),
      ),
    );
  }
}
