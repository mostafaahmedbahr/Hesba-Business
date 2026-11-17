import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// أزرار أسفل فورم المنتج: حفظ/تحديث أساسي + زر حذف (في وضع التعديل فقط).
///
/// الأزرار بتتعطل تلقائياً أثناء الحفظ/الحذف، واللودر بيظهر مكان الأيقونة.
class ProductFormActionsBar extends StatelessWidget {
  final bool isEdit;
  final bool saving;
  final bool deleting;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  const ProductFormActionsBar({
    super.key,
    required this.isEdit,
    required this.saving,
    required this.deleting,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final busy = saving || deleting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 54.h,
          child: FilledButton(
            onPressed: busy ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
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
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEdit ? Icons.check_rounded : Icons.add_rounded,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isEdit ? 'productFormUpdate'.tr() : 'productFormSave'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (isEdit) ...[
          SizedBox(height: 10.h),
          SizedBox(
            height: 50.h,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              icon: deleting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.danger,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                'productDelete'.tr(),
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
