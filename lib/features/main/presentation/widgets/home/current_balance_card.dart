import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/states/dashboard_state.dart';
import 'balance_breakdown_dialog.dart';
import 'home_amount_format.dart';

/// كارت "الرصيد الحالي".tr() = صافي المبيعات - المصروفات، مع تفصيل عند الضغط.
class CurrentBalanceCard extends StatelessWidget {
  final DashboardState state;
  const CurrentBalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = 'currencyEGP'.tr();
    final sales = state.todaySalesTotal;
    final returns = state.todayReturnsTotal;
    final expenses = state.todayExpensesTotal;
    final netSales = state.todayNetSales; // sales - returns
    final balance = netSales - expenses; // الرصيد الحالي
    final isNegative = balance < 0;
    final isZero = balance == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: () => _showBreakdown(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isNegative
                        ? [AppTheme.danger, AppTheme.roseLight]
                        : isZero
                            ? [AppTheme.slateGray, AppTheme.mutedGray]
                            : [AppTheme.successDark, const Color(0xFF34D399)]),
                    borderRadius: BorderRadius.circular(13.r),
                    boxShadow: [
                      BoxShadow(
                          color: (isNegative
                                  ? AppTheme.danger
                                  : AppTheme.successDark)
                              .withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(
                      isNegative
                          ? Icons.trending_down_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرصيد الحالي'.tr(),
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.ink)),
                      SizedBox(height: 2.h),
                      Text('المفروض يكون معاك آخر اليوم'.tr(),
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.slateGray,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isNegative
                        ? AppTheme.dangerSoft
                        : isZero
                            ? AppTheme.mist
                            : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: isNegative
                            ? AppTheme.danger.withValues(alpha: 0.12)
                            : isZero
                                ? AppTheme.borderSoft
                                : AppTheme.successDark.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    isNegative
                        ? 'عجز'.tr()
                        : isZero
                            ? 'متوازن'.tr()
                            : 'متاح'.tr(),
                    style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isNegative
                            ? AppTheme.danger
                            : isZero
                                ? AppTheme.slateGray
                                : AppTheme.successDark),
                  ),
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
                  Text(
                    formatHomeAmount(balance.abs()),
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.w900,
                      color: isNegative
                          ? AppTheme.danger
                          : isZero
                              ? (isDark ? Colors.white : AppTheme.ink)
                              : AppTheme.successDark,
                      height: 1,
                      letterSpacing: -1.1,
                    ),
                  ),
                  if (isNegative)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h, right: 4.w),
                      child: Text('-',
                          style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.danger)),
                    ),
                  SizedBox(width: 8.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(currency,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.slateGray)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              ),
              child: Column(
                children: [
                  _miniRow('المبيعات'.tr(), '+ ${formatHomeAmount(sales)}', AppTheme.primaryColor, isDark),
                  SizedBox(height: 8.h),
                  _miniRow('المرتجعات'.tr(), '- ${formatHomeAmount(returns)}', AppTheme.warningAmber, isDark),
                  SizedBox(height: 8.h),
                  _miniRow('المصروفات'.tr(), '- ${formatHomeAmount(expenses)}', AppTheme.danger, isDark),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Divider(
                        height: 1,
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('= الرصيد الحالي'.tr(),
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.ink)),
                      Text('${formatHomeAmount(balance)} $currency',
                          style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w900,
                              color: isNegative
                                  ? AppTheme.danger
                                  : AppTheme.successDark)),
                    ],
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.h),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.touch_app_rounded, size: 13.sp, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray),
            SizedBox(width: 6.w),
            Text('اضغط لعرض تفصيل طرق الدفع'.tr(), style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray)),
          ]),
          ],
        ),
      ),
    );
  }

  /// فتح ديالوج تفصيل الرصيد: مبيعات كل وسيلة دفع + المرتجعات والمصروفات.
  void _showBreakdown(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BalanceBreakdownDialog(state: state),
    );
  }

  Widget _miniRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            SizedBox(width: 8.w),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
          ],
        ),
        Text('$value ${'currencyEGP'.tr()}',
            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
