import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../cubit/reports_state.dart';

/// شرائح الفترات (اليوم / 7 / 30 / الكل).
class ReportsPeriodChips extends StatelessWidget {
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onChanged;
  const ReportsPeriodChips({super.key, required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReportPeriod.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final p = ReportPeriod.values[i];
          final selected = p == period;
          return ChoiceChip(
            label: Text(p.label, style: TextStyle(fontSize: 12.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
            selected: selected,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onChanged(p);
            },
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: selected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            showCheckmark: false,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            avatar: selected ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white) : null,
          );
        },
      ),
    );
  }
}
