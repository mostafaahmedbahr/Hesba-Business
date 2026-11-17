import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// عنوان صغير لحقل داخل فورم «إضافة مديونية».
class AddDebtSheetLabel extends StatelessWidget {
  final String text;
  const AddDebtSheetLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w800,
        color: AppTheme.slateGray,
      ),
    );
  }
}
