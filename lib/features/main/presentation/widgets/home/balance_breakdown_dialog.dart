import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/states/dashboard_state.dart';
import '../../../../sales/presentation/cubit/sales_list_state.dart';
import 'home_amount_format.dart';

/// ديالوج تفصيل الرصيد: مبيعات النهاردة حسب وسيلة الدفع
/// (نقدي / بطاقة / محفظة / آجل) ثم المرتجعات والمصروفات = الرصيد المعروض.
class BalanceBreakdownDialog extends StatelessWidget {
  final DashboardState state;
  const BalanceBreakdownDialog({super.key, required this.state});

  /// ترتيب عرض وسائل الدفع المعروفة، ثم أي وسيلة أخرى تظهر بعدها.
  static const _methodOrder = ['cash', 'card', 'mobile_wallet', 'wallet', 'credit'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = 'currencyEGP'.tr();
    final byMethod = state.todaySalesByMethod;
    final returns = state.todayReturnsTotal;
    final expenses = state.todayExpensesTotal;
    final balance = state.todayNetSales - expenses;
    final isNegative = balance < 0;

    final rows = <MapEntry<String, double>>[
      for (final m in _methodOrder)
        if (byMethod[m] != null) MapEntry(m, byMethod[m]!),
      ...byMethod.entries.where((e) => !_methodOrder.contains(e.key)),
    ];

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 18.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + زر الإغلاق.
            Row(children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF6D9BFF)]),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 20.sp, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تفصيل الرصيد'.tr(),
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.ink)),
                  SizedBox(height: 2.h),
                  Text('مبيعات النهاردة حسب طريقة الدفع'.tr(),
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.slateGray)),
                ]),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18.sp,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.slateGray),
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            if (rows.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text('لا توجد مبيعات اليوم'.tr(),
                      style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.slateGray)),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: isDark ? AppTheme.darkBorder : const Color(0xFFE6EAF2)),
                ),
                child: Column(children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) SizedBox(height: 8.h),
                    _MethodRow(
                      label: _labelOf(rows[i].key),
                      amount: rows[i].value,
                      method: rows[i].key,
                      isDark: isDark,
                    ),
                  ],
                ]),
              ),
            if (returns > 0) ...[
              SizedBox(height: 10.h),
              _deductRow('المرتجعات'.tr(), returns, AppTheme.warningAmber, currency, isDark),
            ],
            if (expenses > 0) ...[
              SizedBox(height: 6.h),
              _deductRow('المصروفات'.tr(), expenses, AppTheme.danger, currency, isDark),
            ],
            SizedBox(height: 12.h),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            SizedBox(height: 10.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('= الرصيد الحالي'.tr(),
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.ink)),
              Text('${formatHomeAmount(balance)} $currency',
                  style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w900,
                      color: isNegative
                          ? AppTheme.danger
                          : (balance == 0
                              ? (isDark ? Colors.white : AppTheme.ink)
                              : AppTheme.successDark))),
            ]),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text('تمام'.tr(),
                    style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// اسم طريقة الدفع بالعربي (نفس شاشة العميل) — الفواتير بلا وسيلة → غير محدد.
  String _labelOf(String method) {
    if (method.isEmpty) return 'غير محدد'.tr();
    final label = SalesListState.paymentLabel(method);
    return label.isEmpty ? 'غير محدد'.tr() : label;
  }

  Widget _deductRow(String label, double amount, Color color, String currency, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        SizedBox(width: 8.w),
        Text(label,
            style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
      ]),
      Text('- ${formatHomeAmount(amount)} $currency',
          style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

/// سطر وسيلة دفع داخل الديالوج: أيقونة + الاسم العربي + المبلغ.
class _MethodRow extends StatelessWidget {
  final String label;
  final double amount;
  final String method;
  final bool isDark;
  const _MethodRow(
      {required this.label, required this.amount, required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (method) {
      'cash' => (Icons.payments_rounded, AppTheme.successDark),
      'card' => (Icons.credit_card_rounded, AppTheme.primaryColor),
      'mobile_wallet' || 'wallet' => (
          Icons.account_balance_wallet_rounded,
          AppTheme.violetDeep
        ),
      'credit' => (Icons.schedule_rounded, AppTheme.amberDeep),
      _ => (Icons.payment_rounded, AppTheme.slateGray),
    };

    return Row(children: [
      Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 17.sp, color: color),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.ink)),
      ),
      Text('${formatHomeAmount(amount)} ${'currencyEGP'.tr()}',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}
