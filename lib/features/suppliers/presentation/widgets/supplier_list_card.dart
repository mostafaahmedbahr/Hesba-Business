import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/supplier_model.dart';

/// كارت مورد: الاسم + الشركة + الهاتف + المدينة + عدد المنتجات المرتبطة
/// + أزرار الاتصال وواتساب.
class SupplierListCard extends StatelessWidget {
  final SupplierModel supplier;
  final int linkedCount;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const SupplierListCard({
    super.key,
    required this.supplier,
    required this.linkedCount,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.violetDeep;
    final company = supplier.companyName.trim();
    final city = supplier.city.trim();

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE8ECF3),
            ),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, AppTheme.violetSoft],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.26),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.ink,
                          ),
                        ),
                        if (company.isNotEmpty && company != supplier.name) ...[
                          SizedBox(height: 3.h),
                          Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slateGray,
                            ),
                          ),
                        ],
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            Icon(
                              Icons.call_rounded,
                              size: 12.sp,
                              color: AppTheme.mutedGray,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              supplier.phone,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // عدد المنتجات المرتبطة (اختياري — يظهر لو > 0).
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: color.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          size: 11.sp,
                          color: color,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          linkedCount.toString(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // المدينة (لو موجودة) — تحت بدون أي أرقام مالية.
              if (city.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 11.sp,
                        color: AppTheme.mutedGray,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slateGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _CardAction(
                      icon: Icons.call_rounded,
                      label: 'supplierCall'.tr(),
                      color: AppTheme.successDark,
                      onTap: onCall,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _CardAction(
                      icon: Icons.chat_rounded,
                      label: 'supplierWhatsApp'.tr(),
                      color: const Color(0xFF25D366),
                      onTap: onWhatsApp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _CardAction(
                    icon: Icons.chevron_right_rounded,
                    label: '',
                    color: AppTheme.violetDeep,
                    compact: true,
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زرار صغير داخل الكارت (اتصال/واتساب/فتح التفاصيل).
class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(11.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15.sp, color: color),
            if (label.isNotEmpty) ...[
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// يحوّل رسالة `supplierErr*` لنص مقروء للمستخدم.
String supplierErrorText(String? key) => translateError(key);
