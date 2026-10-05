import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Tappable shop-photo preview shared by profile editing and registration.
class ShopImagePicker extends StatelessWidget {
  const ShopImagePicker({
    super.key,
    this.isDark = false,
    required this.imageUrl,
    required this.uploading,
    required this.changeLabel,
    required this.uploadingLabel,
    required this.onTap,
  });

  final bool isDark;
  final String imageUrl;
  final bool uploading;
  final String changeLabel;
  final String uploadingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    final uri = Uri.tryParse(normalizedUrl);
    final hasImage = normalizedUrl.isNotEmpty && uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    final label = uploading ? uploadingLabel : changeLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Material(
        color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
        child: InkWell(
          onTap: uploading ? null : onTap,
          child: Ink(
            width: double.infinity,
            height: 138.h,
            child: Stack(fit: StackFit.expand, children: [
              if (hasImage)
                CachedNetworkImage(imageUrl: normalizedUrl, fit: BoxFit.cover, placeholder: (_, _) => const Center(child: CircularProgressIndicator()), errorWidget: (_, _, _) => _placeholder(label))
              else
                _placeholder(label),
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.58), borderRadius: BorderRadius.circular(24.r)),
                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white),
                    SizedBox(width: 6.w),
                    Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white))),
                  ]),
                ),
              ),
              if (uploading) Container(color: Colors.black.withValues(alpha: 0.35), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String label) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.10), const Color(0xFF7C4DFF).withValues(alpha: 0.10)])),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.storefront_rounded, size: 34.sp, color: AppTheme.primaryColor.withValues(alpha: 0.75)),
        SizedBox(height: 8.h),
        Padding(padding: EdgeInsets.symmetric(horizontal: 56.w), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)))),
      ]),
    );
  }
}
