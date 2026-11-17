import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// صندوق تلميح التكرار/الإشعار أسفل اختيار موعد الاستحقاق.
class ExpenseRecurrenceHint extends StatelessWidget {
  final String hint;

  const ExpenseRecurrenceHint({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.amberDeep.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.amberDeep.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 15.sp,
            color: AppTheme.amberDeep,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.amberDeep,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
