import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// Displays the shop photo stored in Cloudinary with an icon fallback when the
/// shop has no photo yet or the URL cannot be loaded.
class ShopImageView extends StatelessWidget {
  const ShopImageView({
    super.key,
    required this.imageUrl,
    required this.size,
    this.borderRadius = 14,
    this.fallbackIcon = Icons.storefront_rounded,
    this.fallbackIconSize = 20,
    this.withShadow = false,
  });

  final String imageUrl;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = imageUrl.trim();
    final uri = Uri.tryParse(url);
    final hasImage =
        url.isNotEmpty && uri != null && uri.isScheme('https');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: hasImage ? null : AppTheme.primaryGradient,
        color: hasImage ? (isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9)) : null,
        borderRadius: BorderRadius.circular(borderRadius.r),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 250),
              placeholder: (_, _) => Center(
                child: SizedBox(
                  width: size * 0.28,
                  height: size * 0.28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => _fallback(fallbackIconSize),
            )
          : _fallback(fallbackIconSize),
    );
  }

  Widget _fallback(double iconSize) {
    return Center(
      child: Icon(fallbackIcon, size: iconSize.sp, color: Colors.white),
    );
  }
}