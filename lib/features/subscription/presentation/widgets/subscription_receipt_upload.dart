import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/shop_image_upload.dart';

/// Last step of the purchase: attach the transfer screenshot.
class SubscriptionReceiptUpload extends StatelessWidget {
  const SubscriptionReceiptUpload({
    super.key,
    required this.receiptUrl,
    required this.uploading,
    required this.onPick,
  });

  final String? receiptUrl;
  final bool uploading;
  final ValueChanged<ImageSource> onPick;

  Future<void> _chooseSource(BuildContext context) async {
    final source = await pickShopImageSource(context, titleKey: 'receiptSource');
    if (source != null) onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = receiptUrl != null;

    return InkWell(
      onTap: uploading ? null : () => _chooseSource(context),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: done
              ? AppTheme.successColor.withValues(alpha: 0.06)
              : theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: done
                ? AppTheme.successColor.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: uploading
            ? Row(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'receiptUploading'.tr(),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (done) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        receiptUrl!,
                        width: 46.w,
                        height: 46.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.receipt_long_rounded,
                          size: 26.sp,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ] else
                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        size: 20.sp,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done ? 'receiptUploaded'.tr() : 'receiptTitle'.tr(),
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            color: done
                                ? AppTheme.successColor
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          done
                              ? 'receiptChange'.tr()
                              : 'receiptHint'.tr(),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    done ? Icons.swap_horiz_rounded : Icons.add_a_photo_rounded,
                    size: 20.sp,
                    color: theme.hintColor,
                  ),
                ],
              ),
      ),
    );
  }
}
