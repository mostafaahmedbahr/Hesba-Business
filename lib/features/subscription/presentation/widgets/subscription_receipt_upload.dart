import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/shop_image_upload.dart';
import '../../../../core/widgets/loading_widget.dart';

/// Last step of the purchase: attach the transfer screenshot.
class SubscriptionReceiptUpload extends StatelessWidget {
  const SubscriptionReceiptUpload({
    super.key,
    required this.receiptUrl,
    this.receiptPath,
    required this.uploading,
    required this.onPick,
  });

  final String? receiptUrl;
  final String? receiptPath;
  final bool uploading;
  final ValueChanged<ImageSource> onPick;

  Future<void> _chooseSource(BuildContext context) async {
    final source = await pickShopImageSource(context, titleKey: 'receiptSource');
    if (source != null) onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = receiptUrl != null || receiptPath != null;

    return InkWell(
      onTap: uploading ? null : () => _chooseSource(context),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: done
                ? [
                    AppTheme.successColor.withValues(alpha: 0.08),
                    AppTheme.successColor.withValues(alpha: 0.03),
                  ]
                : [
                    theme.cardTheme.color ?? Colors.white,
                    (theme.cardTheme.color ?? Colors.white),
                  ],
          ),
          border: Border.all(
            color: done
                ? AppTheme.successColor.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (done ? AppTheme.successColor : Colors.black)
                  .withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: uploading
            ? Row(
                children: [
                  const LoadingWidget(size: 16, compact: true),
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
                      child: receiptPath != null
                          ? Image.file(
                              File(receiptPath!),
                              width: 46.w,
                              height: 46.w,
                              fit: BoxFit.cover,
                              cacheWidth: 200,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.receipt_long_rounded,
                                size: 26.sp,
                                color: AppTheme.successColor,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: receiptUrl!,
                              width: 46.w,
                              height: 46.w,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              errorWidget: (_, _, _) => Icon(
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
