import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/supplier_model.dart';
import 'section_card.dart';

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

/// كارت بيانات المورد (الاسم + الشركة + صفوف البيانات غير الفاضية).
class SupplierInfoCard extends StatelessWidget {
  final SupplierModel supplier;
  final bool isDark;
  const SupplierInfoCard({
    super.key,
    required this.supplier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow(
        Icons.business_outlined,
        'supplierFieldLabelCompany'.tr(),
        supplier.companyName,
      ),
      _InfoRow(
        Icons.call_outlined,
        'supplierFieldLabelPhone'.tr(),
        supplier.phone,
      ),
      _InfoRow(
        Icons.phone_iphone_rounded,
        'supplierFieldLabelSecondaryPhone'.tr(),
        supplier.secondaryPhone,
      ),
      _InfoRow(
        Icons.email_outlined,
        'supplierFieldLabelEmail'.tr(),
        supplier.email,
      ),
      _InfoRow(
        Icons.location_city_outlined,
        'supplierFieldLabelCity'.tr(),
        supplier.city,
      ),
      _InfoRow(
        Icons.place_outlined,
        'supplierFieldLabelAddress'.tr(),
        supplier.address,
      ),
    ].where((r) => r.value.trim().isNotEmpty).toList();

    return SupplierSectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.violetDeep, AppTheme.violetSoft],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 21.sp,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.ink,
                      ),
                    ),
                    if (supplier.companyName.trim().isNotEmpty &&
                        supplier.companyName.trim() !=
                            supplier.name.trim()) ...[
                      SizedBox(height: 2.h),
                      Text(
                        supplier.companyName.trim(),
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppTheme.slateGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            SizedBox(height: 14.h),
            const Divider(height: 1),
            SizedBox(height: 6.h),
            for (final row in rows)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.icon, size: 15.sp, color: AppTheme.violetDeep),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 92.w,
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppTheme.mutedGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value.trim(),
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white : AppTheme.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
