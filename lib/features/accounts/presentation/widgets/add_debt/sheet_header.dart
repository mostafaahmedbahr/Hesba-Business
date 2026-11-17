import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// هيدر «إضافة مديونية»: المقبض + الأيقونة + العنوان + زر الإغلاق.
class AddDebtSheetHeader extends StatelessWidget {
  final bool isDark;

  const AddDebtSheetHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.ink;

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 4.h),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.paleSlate,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مديونية جديدة',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'التاريخ يُسجَّل تلقائيًا عند الحفظ',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.slateGray,
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
