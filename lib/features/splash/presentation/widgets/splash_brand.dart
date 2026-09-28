import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';

 class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);

    return Column(
      children: [
        Text(
          'appName'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 50.sp,
            fontWeight: FontWeight.w900,
            height: 1,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12.h),
        // Tagline in glass pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                blurRadius: 16.r,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront_rounded, size: 12.sp, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'splashTagline'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Gold divider with dot
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 34.w, height: 2.5.h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r), gradient: LinearGradient(colors: [AppTheme.secondaryColor.withValues(alpha: 0.05), AppTheme.secondaryColor]))),
            SizedBox(width: 7.w),
            Container(width: 7.w, height: 7.w, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.goldGradient)),
            SizedBox(width: 7.w),
            Container(width: 34.w, height: 2.5.h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.r), gradient: LinearGradient(colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.05)]))),
          ],
        ),
      ],
    );
  }
}