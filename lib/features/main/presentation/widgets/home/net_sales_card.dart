import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/states/dashboard_state.dart';
import 'home_amount_format.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// كارت "صافي مبيعات اليوم" — المبيعات ناقص المرتجعات.
class NetSalesCard extends StatelessWidget {
  final DashboardState state;
  const NetSalesCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currency = 'currencyEGP'.tr();
    final net = state.todayNetSales;
    final sales = state.todaySalesTotal;
    final returns = state.todayReturnsTotal;
    final hasReturns = state.todayReturnsCount > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2A86), AppTheme.primaryColor, Color(0xFF4A7CFF)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -30.h,
              left: -30.w,
              child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(
              bottom: -40.h,
              right: -20.w,
              child: Container(
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E))),
                        SizedBox(width: 6.w),
                        Text('homeNetSales'.tr(),
                            style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r)),
                    child: Text('homeToday'.tr(),
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatHomeAmount(net),
                        style: TextStyle(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1.2)),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 7.h),
                      child: Text(currency,
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.90))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        hasReturns
                            ? uiTr('المبيعات ${formatHomeAmount(sales)} - المرتجعات ${formatHomeAmount(returns)}')
                            : uiTr('إجمالي مبيعات اليوم ${formatHomeAmount(sales)} $currency'),
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
