import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../cubit/reports_state.dart';

/// شبكة الإحصائيات (إجمالي/صافي المبيعات + المرتجعات + المصروفات).
class ReportsSummaryGrid extends StatelessWidget {
  final ReportsState state;
  const ReportsSummaryGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.payments_rounded, label: 'reportsTotalSales'.tr(), value: '${fmtReport(state.totalSales)} ج.م', subtitle: '${state.sales.length} فاتورة', gradient: const [AppTheme.primaryColor, AppTheme.brightBlue], isDark: isDark)),
        SizedBox(width: 10.w),
        Expanded(child: _StatCard(icon: Icons.trending_up_rounded, label: 'reportsNetSales'.tr(), value: '${fmtReport(state.netSales)} ج.م', subtitle: 'بعد المرتجعات', gradient: const [AppTheme.successDark, Color(0xFF34D399)], isDark: isDark)),
      ]),
      SizedBox(height: 10.h),
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.assignment_return_rounded, label: 'reportsTotalReturns'.tr(), value: '${fmtReport(state.totalReturns)} ج.م', subtitle: '${state.returns.length} عملية', gradient: const [AppTheme.warningAmber, AppTheme.goldLight], isDark: isDark, alert: state.returns.isNotEmpty)),
        SizedBox(width: 10.w),
        Expanded(child: _StatCard(icon: Icons.savings_rounded, label: 'reportsTotalExpenses'.tr(), value: '${fmtReport(state.totalExpenses)} ج.م', subtitle: '${state.expenses.length} مصروف', gradient: const [AppTheme.danger, AppTheme.roseLight], isDark: isDark)),
      ]),
    ]);
  }
}

/// كارت رقم واحد.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final List<Color> gradient;
  final bool isDark;
  final bool alert;
  const _StatCard({required this.icon, required this.label, required this.value, required this.subtitle, required this.gradient, required this.isDark, this.alert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38.w, height: 38.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(11.r)), child: Icon(icon, color: Colors.white, size: 18.sp)),
          const Spacer(),
          if (alert) Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.danger)),
        ]),
        SizedBox(height: 12.h),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
        Text(subtitle, style: TextStyle(fontSize: 10.5.sp, color: AppTheme.mutedGray)),
      ]),
    );
  }
}

/// كارت ملخص الفترة (معادلة الرصيد).
class ReportsBalanceCard extends StatelessWidget {
  final ReportsState state;
  const ReportsBalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = state.balance;
    final isNeg = balance < 0;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40.w, height: 40.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isNeg ? [AppTheme.danger, AppTheme.roseLight] : [AppTheme.successDark, const Color(0xFF34D399)]), borderRadius: BorderRadius.circular(11.r)), child: Icon(isNeg ? Icons.trending_down_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 20.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ملخص الفترة', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
            Text('${state.period.label} • ${DateFormat('d MMM', 'ar').format(state.period.start)} - ${DateFormat('d MMM', 'ar').format(state.period.end)}', style: TextStyle(fontSize: 11.sp, color: AppTheme.slateGray)),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: isNeg ? AppTheme.dangerSoft : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isNeg ? AppTheme.danger.withValues(alpha: 0.14) : AppTheme.successDark.withValues(alpha: 0.14))), child: Text(isNeg ? 'عجز' : 'رابح', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isNeg ? AppTheme.danger : AppTheme.successDark))),
        ]),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
          child: Column(children: [
            _MiniRow('reportsTotalSales'.tr(), '+${fmtReport(state.totalSales)}', AppTheme.primaryColor, isDark),
            SizedBox(height: 8.h),
            _MiniRow('reportsTotalReturns'.tr(), '-${fmtReport(state.totalReturns)}', AppTheme.warningAmber, isDark),
            SizedBox(height: 8.h),
            _MiniRow('reportsCogs'.tr(), '-${fmtReport(state.metrics.cogs)}', AppTheme.slateGray, isDark),
            SizedBox(height: 8.h),
            _MiniRow('reportsTotalExpenses'.tr(), '-${fmtReport(state.totalExpenses)}', AppTheme.danger, isDark),
            Divider(height: 20.h, color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('reportsNetProfit'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
              Text('${fmtReport(balance)} ج.م', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isNeg ? AppTheme.danger : AppTheme.successDark)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// سطر معادلة صغير.
class _MiniRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _MiniRow(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
        ]),
        Text('$value ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// كارت الأرباح: تكلفة البضاعة المباعة + إجمالي الربح + صافي الربح،
/// مع تحذير صريح عندما يكون الربح تقديرياً (فواتير قديمة بلا تكلفة).
class ReportsProfitCard extends StatelessWidget {
  final ReportsState state;
  const ReportsProfitCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = state.metrics;
    final netNeg = m.netProfit < 0;
    final margin = m.netMargin;

    // لا نعرض نسبة هامش فوق بيانات ناقصة (تضليل) — نعرض سبب التقريب فقط.
    final String subtitle;
    if (m.isProfitEstimated) {
      subtitle = 'reportsProfitEstimated'.tr();
    } else if (margin != null) {
      subtitle = '${'reportsMargin'.tr()}: ${(margin * 100).toStringAsFixed(0)}%';
    } else {
      subtitle = '';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40.w, height: 40.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 20.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('reportsProfitsTitle'.tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
            if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 11.sp, color: m.isProfitEstimated ? AppTheme.warningAmber : AppTheme.slateGray, fontWeight: FontWeight.w700)),
          ])),
        ]),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
          child: Column(children: [
            _MiniRow('reportsCogs'.tr(), fmtReport(m.cogs), AppTheme.slateGray, isDark),
            SizedBox(height: 8.h),
            _MiniRow('reportsGrossProfit'.tr(), fmtReport(m.grossProfit), AppTheme.primaryColor, isDark),
            Divider(height: 20.h, color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('reportsNetProfit'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
              Text('${fmtReport(m.netProfit)} ج.م', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: netNeg ? AppTheme.danger : AppTheme.successDark)),
            ]),
          ]),
        ),
        if (m.isProfitEstimated) ...[
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.35))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 17.sp, color: const Color(0xFFB45309)),
              SizedBox(width: 8.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('reportsProfitEstimated'.tr(), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309))),
                SizedBox(height: 2.h),
                Text(
                  'reportsProfitEstimatedBody'.tr(args: [
                    '${m.unknownCostLines}',
                    '${(m.costCoverage * 100).toStringAsFixed(0)}%',
                  ]),
                  style: TextStyle(fontSize: 10.5.sp, height: 1.4, color: const Color(0xFF92400E)),
                ),
              ])),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// تحذير "بيانات غير مكتملة" — يظهر فقط لو توقف الجلب قبل آخر صفحة
/// (لا نعرض إجماليات ناقصة على أنها نهائية).
class ReportsIncompleteBanner extends StatelessWidget {
  final ReportsState state;
  const ReportsIncompleteBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.dataComplete) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.35))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.warning_amber_rounded, size: 17.sp, color: const Color(0xFFB45309)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('reportsDataIncomplete'.tr(), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309))),
          SizedBox(height: 2.h),
          Text('reportsDataIncompleteBody'.tr(), style: TextStyle(fontSize: 10.5.sp, height: 1.4, color: const Color(0xFF92400E))),
        ])),
      ]),
    );
  }
}
