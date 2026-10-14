import '../../../../common_imports.dart';

/// أسباب المرتجع (chips اختيار واحد).
class ReturnReasonChips extends StatelessWidget {
  final List<String> reasons;
  final String? selected;
  final ValueChanged<String> onSelected;

  const ReturnReasonChips({
    super.key,
    required this.reasons,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final r in reasons)
          ChoiceChip(
            label: Text(
              r,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: selected == r ? FontWeight.w800 : FontWeight.w600,
                color: selected == r
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
            selected: selected == r,
            onSelected: (_) => onSelected(r),
            selectedColor: AppTheme.warningAmber,
            backgroundColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
            side: BorderSide(
              color: selected == r
                  ? AppTheme.warningAmber
                  : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            showCheckmark: false,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          ),
      ],
    );
  }
}
