import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// زر حفظ المديونية (يتبدّل إلى مؤشر تحميل أثناء الحفظ).
class AddDebtSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const AddDebtSaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppTheme.primaryColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: saving
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                'حفظ المديونية'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}
