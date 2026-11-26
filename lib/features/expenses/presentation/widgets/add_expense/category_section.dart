import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../expense_category_meta.dart';
import 'category_chip.dart';
import 'package:easy_localization/easy_localization.dart';

/// قسم التصنيف: شبكة الاختيارات + تحذير عند عدم الاختيار.
class ExpenseCategorySection extends StatelessWidget {
  final String category;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const ExpenseCategorySection({
    super.key,
    required this.category,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 9.w,
          runSpacing: 9.h,
          children: [
            for (final cat in AppConstants.expenseCategories)
              ExpenseCategoryChip(
                label: cat,
                icon: expenseCatIcon(cat),
                color: expenseCatColor(cat),
                selected: category == cat,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(cat);
                },
              ),
          ],
        ),
        if (category.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: 8.h,
              right: 4.w,
            ),
            child: Text(
              'اختار التصنيف الأول'.tr(),
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
          ),
      ],
    );
  }
}
