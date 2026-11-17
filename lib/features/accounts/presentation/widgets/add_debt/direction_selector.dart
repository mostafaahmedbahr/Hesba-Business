import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/debt_model.dart';

/// اختيار اتجاه عملية المورد: «عليّ فلوس» / «ليّا فلوس».
class AddDebtDirectionSelector extends StatelessWidget {
  final String direction;
  final ValueChanged<String> onChanged;

  const AddDebtDirectionSelector({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DirectionCard(
            title: 'عليّ فلوس',
            subtitle: 'أدفع للمورد',
            icon: Icons.call_made_rounded,
            color: AppTheme.danger,
            selected: direction == DebtDirection.payable,
            onTap: () => onChanged(DebtDirection.payable),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _DirectionCard(
            title: 'ليّا فلوس',
            subtitle: 'أحصّل من المورد',
            icon: Icons.call_received_rounded,
            color: AppTheme.successDark,
            selected: direction == DebtDirection.receivable,
            onTap: () => onChanged(DebtDirection.receivable),
          ),
        ),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : (isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, size: 17.sp, color: color),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? color
                          : (isDark ? Colors.white : AppTheme.ink),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slateGray,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18.sp, color: color),
          ],
        ),
      ),
    );
  }
}
