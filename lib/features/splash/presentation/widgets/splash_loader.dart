import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';


class SplashLoader extends StatelessWidget {
  const SplashLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Determinate progress synced to the 3s splash timer
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2700),
          curve: Curves.easeInOutCubic,
          builder: (context, value, _) {
            return Column(
              children: [
                SizedBox(
                  width: 170.w,
                  height: 7.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Stack(
                      children: [
                        Container(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : AppTheme.primaryColor.withValues(alpha: 0.10),
                        ),
                        FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A4FD6), Color(0xFF4A7BFF), Color(0xFFF5A623)],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : AppTheme.primaryColor.withValues(alpha: 0.8),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppTheme.fontFamily,
                    fontFeatures: const [],
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14.w,
              height: 14.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.secondaryColor,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.primaryColor.withValues(alpha: 0.10),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'splashLoading'.tr(),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : const Color(0xFF64748B),
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ],
    );
  }
}