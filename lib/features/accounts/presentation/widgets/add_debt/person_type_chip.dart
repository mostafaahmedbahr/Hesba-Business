import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/person_model.dart';

/// شارة نوع الشخص (عميل / مورد / الاثنين).
class AddDebtPersonTypeChip extends StatelessWidget {
  final String type;
  const AddDebtPersonTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      PersonModel.typeSupplier => ('مورد', AppTheme.violetDeep),
      PersonModel.typeBoth => ('عميل ومورد', AppTheme.amberDeep),
      _ => ('عميل', AppTheme.primaryColor),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
