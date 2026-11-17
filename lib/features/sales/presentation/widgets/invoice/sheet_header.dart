import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// هيدر Bottom Sheet الفاتورة: المقبض + الأيقونة + العنوان + زر الإغلاق.
class InvoiceSheetHeader extends StatelessWidget {
  const InvoiceSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // مقبض السحب.
        Container(
          width: 44.w,
          height: 4.h,
          margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // الهيدر.
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 8.w, 6.h),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 20.sp, color: AppTheme.primaryColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'invoiceTitle'.tr(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded,
                    size: 22.sp,
                    color: isDark ? Colors.white70 : AppTheme.slateGray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
