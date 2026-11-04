import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/services/cloudinary_image_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/shop_image_upload.dart';
import '../../../../../core/utils/toast.dart';

/// حقل صورة المنتج: اختيار من المعرض/الكاميرا + رفع Cloudinary + معاينة + حذف.
class ProductFormImageField extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<String> onChanged;

  const ProductFormImageField({
    super.key,
    required this.imageUrl,
    required this.onChanged,
  });

  @override
  State<ProductFormImageField> createState() => _ProductFormImageFieldState();
}

class _ProductFormImageFieldState extends State<ProductFormImageField> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final source = await pickShopImageSource(
      context,
      titleKey: 'productFormImageSource',
    );
    if (source == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await sl<CloudinaryImageService>().uploadProductImage(
        source: source,
      );
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        widget.onChanged(url);
        AppToast.success(context, 'productFormImageUploaded'.tr());
      }
    } on CloudinaryUploadException catch (e) {
      if (mounted) {
        AppToast.error(context, shopImageUploadErrorMessage(e));
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'shopImageFailed'.tr());
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove() {
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = widget.imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 150.h,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasImage
                  ? AppTheme.primaryColor.withValues(alpha: 0.35)
                  : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              width: hasImage ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _placeholder(isDark),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: _roundBtn(
                        icon: Icons.delete_rounded,
                        color: AppTheme.danger,
                        onTap: _remove,
                      ),
                    ),
                  ],
                )
              : _placeholder(isDark),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: _uploading
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Icon(
                    hasImage
                        ? Icons.swap_horiz_rounded
                        : Icons.add_a_photo_rounded,
                    size: 17.sp,
                  ),
            label: Text(
              _uploading
                  ? 'productFormImageUploading'.tr()
                  : (hasImage
                        ? 'productFormImageChange'.tr()
                        : 'productFormImageAdd'.tr()),
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 34.sp,
            color: isDark ? AppTheme.mutedGray : AppTheme.borderSoft,
          ),
          SizedBox(height: 6.h),
          Text(
            'productFormImageHint'.tr(),
            style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, size: 17.sp, color: color),
        ),
      ),
    );
  }
}
