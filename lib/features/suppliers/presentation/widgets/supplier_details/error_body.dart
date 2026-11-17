import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_message.dart';

/// جسم الخطأ في تفاصيل المورد: أيقونة + رسالة + زر إعادة المحاولة.
class SupplierDetailsErrorBody extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const SupplierDetailsErrorBody({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46.sp,
              color: AppTheme.danger,
            ),
            SizedBox(height: 12.h),
            Text(
              translateError(errorMessage),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.violetDeep,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('suppliersRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
