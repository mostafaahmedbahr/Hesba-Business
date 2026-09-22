import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';

/// Modern AppBar — surface, large title, subtle bottom border
/// Matches 2026 design system (rounded, no primary flood).
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? actions;
  final Widget? leading;
  final bool showAvatar;
  final bool centerTitle;

  const MainAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showAvatar = false,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return AppBar(
      backgroundColor: bg,
      foregroundColor: titleColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading,
      titleSpacing: leading == null ? 18.w : 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: titleColor,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        if (showAvatar)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12.w),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
          ),
        if (actions != null) ...[
          Padding(
            padding: EdgeInsetsDirectional.only(end: 10.w),
            child: actions!,
          ),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}
