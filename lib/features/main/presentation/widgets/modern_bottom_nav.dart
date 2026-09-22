import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

/// Premium floating island bottom nav — 2026
/// • Glass + soft shadow, dark-mode aware
/// • Selected pill animates, dot indicator
/// • 7 items handled with FittedBox to stay crisp on 375px
class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF151D2F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF243146) : const Color(0xFFE5E7EB);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: surface.withValues(alpha: isDark ? 0.92 : 0.96),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: borderColor.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.45)
                        : const Color(0xFF0F2D8A).withValues(alpha: 0.10),
                    blurRadius: 24.r,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 40.r,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        data: _items[i],
                        isSelected: i == currentIndex,
                        isDark: isDark,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  const _NavItemData(this.icon, this.selectedIcon, this.labelKey);
}

const List<_NavItemData> _items = [
  _NavItemData(Icons.home_outlined, Icons.home_rounded, 'navHome'),
  _NavItemData(Icons.category_outlined, Icons.category_rounded, 'navProducts'),
  _NavItemData(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'navSales'),
  _NavItemData(Icons.assignment_return_outlined, Icons.assignment_return_rounded, 'navReturns'),
  _NavItemData(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'navReports'),
  _NavItemData(Icons.savings_outlined, Icons.savings_rounded, 'navExpenses'),
  _NavItemData(Icons.grid_view_outlined, Icons.grid_view_rounded, 'navMore'),
];

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF1A4FD6);
    final inactive = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        splashColor: active.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected
                ? active.withValues(alpha: isDark ? 0.18 : 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22.r),
            border: isSelected
                ? Border.all(color: active.withValues(alpha: 0.14))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 10.w : 0, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isSelected ? active : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: active.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? data.selectedIcon : data.icon,
                  size: 20.sp,
                  color: isSelected ? Colors.white : inactive,
                ),
              ),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? active : inactive,
                    letterSpacing: -0.2,
                  ),
                  child: Text(data.labelKey.tr(), maxLines: 1),
                ),
              ),
              SizedBox(height: 2.h),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: isSelected ? 1 : 0,
                child: Container(
                  width: 16.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: active,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
