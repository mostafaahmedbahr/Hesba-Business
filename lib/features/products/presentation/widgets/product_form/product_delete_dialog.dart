import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// ديالوج تأكيد حذف منتج (عنوان + وصف + زرين إلغاء/حذف).
///
/// يُرجع `true` عند تأكيد الحذف عبر `Navigator.pop(context, true)`.
class ProductDeleteDialog extends StatelessWidget {
  const ProductDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_rounded,
                color: AppTheme.danger,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'productDeleteConfirmTitle'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8.h),
            Text(
              'productDeleteConfirmBody'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('cancel'.tr()),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('productDelete'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
