import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../cubit/expenses_cubit.dart';
import '../../cubit/expenses_state.dart';

/// شريط الحفظ الثابت أسفل الشاشة (المبلغ الحي + زر الحفظ مع BlocBuilder للتحميل).
class ExpenseSaveBar extends StatelessWidget {
  final bool isDark;
  final double amount;
  final bool isEditing;
  final VoidCallback onSubmit;

  const ExpenseSaveBar({
    super.key,
    required this.isDark,
    required this.amount,
    required this.isEditing,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المبلغ',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)} ج.م',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.danger,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: BlocBuilder<ExpensesCubit, ExpensesState>(
                builder: (ctx, state) {
                  final loading =
                      state.status == ExpensesStatus.loading;
                  return SizedBox(
                    height: 52.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.danger,
                            AppTheme.roseLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        onPressed: loading ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: loading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                    size: 19.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isEditing
                                        ? 'حفظ التعديلات'
                                        : 'إضافة المصروف',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
