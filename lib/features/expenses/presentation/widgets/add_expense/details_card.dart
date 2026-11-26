import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import 'big_amount_field.dart';
import 'field.dart';
import 'package:easy_localization/easy_localization.dart';

/// كارت «التفاصيل»: المبلغ الكبير + العنوان + اسم المحل.
class ExpenseDetailsCard extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController titleController;
  final TextEditingController shopNameController;
  final bool isDark;
  final VoidCallback onChanged;
  final String Function(String) toLatin;

  const ExpenseDetailsCard({
    super.key,
    required this.amountController,
    required this.titleController,
    required this.shopNameController,
    required this.isDark,
    required this.onChanged,
    required this.toLatin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.hairline,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          ExpenseBigAmountField(
            controller: amountController,
            isDark: isDark,
            onChanged: onChanged,
            toLatin: toLatin,
          ),
          SizedBox(height: 12.h),
          ExpenseField(
            controller: titleController,
            label: 'عنوان المصروف *'.tr(),
            hint: 'مثال: إيجار شهر يناير'.tr(),
            icon: Icons.title_rounded,
            isDark: isDark,
            onChanged: onChanged,
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                ? 'العنوان مطلوب'.tr()
                : null,
          ),
          SizedBox(height: 12.h),
          ExpenseField(
            controller: shopNameController,
            label: 'اسم المحل'.tr(),
            hint: 'اسم المحل (اختياري)'.tr(),
            icon: Icons.storefront_rounded,
            isDark: isDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
