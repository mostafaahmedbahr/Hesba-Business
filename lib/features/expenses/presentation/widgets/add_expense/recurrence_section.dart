import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'recurrence.dart';

/// قسم التكرار: شبكة (مرة واحدة / يومي / أسبوعي / شهري).
class ExpenseRecurrenceSection extends StatelessWidget {
  final String recurrence;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const ExpenseRecurrenceSection({
    super.key,
    required this.recurrence,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9.w,
      runSpacing: 9.h,
      children: [
        for (final opt in kExpenseRecurrenceOptions)
          ExpenseRecurrenceChip(
            label: opt.label,
            icon: opt.icon,
            selected: recurrence == opt.value,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(opt.value);
            },
          ),
      ],
    );
  }
}
