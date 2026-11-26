import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../expense_category_meta.dart';
import 'package:easy_localization/easy_localization.dart';

/// هيدر الإضافة (رجوع + مبلغ حي).
class ExpenseAddHeader extends StatelessWidget {
  final double amount;
  final String category;
  final DateTime date;
  final bool isEditing;

  const ExpenseAddHeader({
    super.key,
    required this.amount,
    required this.category,
    required this.date,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 178.h,
      backgroundColor: AppTheme.danger,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 19.sp,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isEditing ? 'تعديل المصروف'.tr() : 'مصروف جديد'.tr(),
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF5F0A22), AppTheme.danger, Color(0xFFFF7A93)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50.h,
                left: -30.w,
                child: Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -60.h,
                right: -40.w,
                child: Container(
                  width: 170.w,
                  height: 170.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 52.h, 18.w, 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قيمة المصروف'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    amount.toStringAsFixed(
                                      amount % 1 == 0 ? 0 : 2,
                                    ),
                                    style: TextStyle(
                                      fontSize: 36.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  SizedBox(width: 7.w),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 5.h),
                                    child: Text(
                                      'ج.م'.tr(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              category.isEmpty
                                  ? Icons.category_outlined
                                  : expenseCatIcon(category),
                              size: 17.sp,
                              color: Colors.white,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              category.isEmpty ? 'التصنيف'.tr() : category,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
