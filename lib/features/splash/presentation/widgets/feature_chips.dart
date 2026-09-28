import '../../../../common_imports.dart';

/// Small glass chips highlighting core value props — sales / stock / reports.
class FeatureChips extends StatelessWidget {
  final bool isDark;
  const FeatureChips({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.point_of_sale_rounded, const Color(0xFF1A4FD6)),
      (Icons.inventory_2_rounded, const Color(0xFFF59E0B)),
      (Icons.bar_chart_rounded, const Color(0xFF059669)),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : items[i].$2.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: items[i].$2.withValues(alpha: 0.18),
                  blurRadius: 14.r,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(items[i].$1, size: 20.sp, color: items[i].$2),
          ),
          if (i < items.length - 1) ...[
            Container(
              width: 22.w,
              height: 1.5.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                color: (isDark ? Colors.white : AppTheme.primaryColor)
                    .withValues(alpha: 0.22),
              ),
            ),
          ],
        ],
      ],
    );
  }
}