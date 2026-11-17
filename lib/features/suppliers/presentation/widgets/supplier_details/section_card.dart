import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// حاوية موحّدة لأقسام شاشة تفاصيل المورد (تدرّج + ظل + حدود).
class SupplierSectionCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const SupplierSectionCard({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkSurfaceAlt]
              : [Colors.white, const Color(0xFFF7F5FF)],
        ),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.violetDeep.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violetDeep.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
