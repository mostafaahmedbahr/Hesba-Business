import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/models/product.dart';

/// كارت منتج (صورة + سعر + مخزون).
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ProductThumb(product: product),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                if (product.isOutOfStock) ProductBadge(label: 'productsOutOfStock'.tr(), color: const Color(0xFFE11D48), icon: Icons.block_rounded)
                else if (product.isLowStock) ProductBadge(label: 'productsLow'.tr(), color: const Color(0xFFF59E0B), icon: Icons.warning_amber_rounded),
              ]),
              SizedBox(height: 6.h),
              if (product.category.isNotEmpty || product.code.isNotEmpty)
                Row(children: [
                  if (product.category.isNotEmpty) Flexible(child: ProductChip(icon: Icons.category_rounded, text: product.category)),
                  if (product.category.isNotEmpty && product.code.isNotEmpty) SizedBox(width: 6.w),
                  if (product.code.isNotEmpty) Flexible(child: ProductChip(icon: Icons.qr_code_rounded, text: product.code)),
                ]),
              if (product.category.isNotEmpty || product.code.isNotEmpty) SizedBox(height: 10.h),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('productsSalePrice'.tr(), style: TextStyle(fontSize: 10.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${_formatPrice(product.price)} ${'currencyEGP'.tr()}', style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                  ),
                  if (product.costPrice > 0) Text('شراء ${_formatPrice(product.costPrice)}', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                ])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                  child: Column(children: [
                    Text('productsStock'.tr(), style: TextStyle(fontSize: 9.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (product.isLowStock) Icon(Icons.warning_amber_rounded, size: 12.sp, color: const Color(0xFFF59E0B)),
                      if (product.isLowStock) SizedBox(width: 3.w),
                      Text('${product.stock}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: product.isOutOfStock ? const Color(0xFFE11D48) : isDark ? Colors.white : const Color(0xFF0F172A))),
                    ]),
                  ]),
                ),
                SizedBox(width: 8.w),
                Container(width: 30.w, height: 30.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.chevron_left_rounded, size: 18.sp, color: AppTheme.primaryColor)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

/// شارة صغيرة (خلصان / منخفض).
class ProductBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const ProductBadge({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10.sp, color: color),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

/// شريحة معلومة (قسم / كود).
class ProductChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const ProductChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11.sp, color: const Color(0xFF64748B)),
        SizedBox(width: 4.w),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
      ]),
    );
  }
}

/// صورة المنتج (أو بديل gradient).
class ProductThumb extends StatelessWidget {
  final Product product;
  const ProductThumb({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 66.w, height: 66.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryColor.withValues(alpha: 0.12), const Color(0xFF7C4DFF).withValues(alpha: 0.12)]),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Icon(Icons.inventory_2_rounded, size: 26.sp, color: AppTheme.primaryColor.withValues(alpha: 0.9)),
    );
    if (product.imageUrl.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: CachedNetworkImage(
        imageUrl: product.imageUrl,
        width: 66.w,
        height: 66.w,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// تنسيق سعر.
String _formatPrice(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
