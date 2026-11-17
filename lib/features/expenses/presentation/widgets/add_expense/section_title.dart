import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// عنوان سكشن صغير.
class ExpenseSectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;

  const ExpenseSectionTitle(this.text, {super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : AppTheme.ink,
      ),
    );
  }
}
