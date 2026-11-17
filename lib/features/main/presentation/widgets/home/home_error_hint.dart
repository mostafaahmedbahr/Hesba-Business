import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../../dashboard/presentation/states/dashboard_state.dart';

/// شريط خطأ بسيط يظهر لما تحميل بيانات الداشبورد يفشل، مع زر إعادة المحاولة.
class HomeErrorHint extends StatelessWidget {
  final DashboardState state;
  const HomeErrorHint({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, size: 18.sp, color: AppTheme.errorColor),
        SizedBox(width: 8.w),
        Expanded(child: Text(state.errorMessage ?? 'homeNoData'.tr(), style: TextStyle(fontSize: 11.5.sp, color: AppTheme.errorColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => context.read<DashboardCubit>().loadDashboardData(),
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(20.r)),
              child: Text('homeLoadRetry'.tr(), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
      ]),
    );
  }
}
