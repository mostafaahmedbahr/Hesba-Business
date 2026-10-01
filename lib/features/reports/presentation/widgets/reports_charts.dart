import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../common_imports.dart';
import '../cubit/reports_state.dart';

/// كارت اتجاه المبيعات (خط 7 أيام).
class ReportsTrendCard extends StatelessWidget {
  final ReportsState state;
  const ReportsTrendCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = last7Days();
    final byDay = state.salesByDay(days, (d) => DateFormat('dd/MM', 'ar').format(d));
    final labels = byDay.keys.toList();
    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < labels.length; i++) {
      final v = byDay[labels[i]] ?? 0;
      if (v > maxY) maxY = v;
      spots.add(FlSpot(i.toDouble(), v));
    }
    if (maxY == 0) maxY = 100;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A4FD6), Color(0xFF4A7BFF)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.show_chart_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اتجاه المبيعات', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('آخر 7 أيام', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20.r)), child: Text('${state.sales.length} عملية', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669)))),
        ]),
        SizedBox(height: 16.h),
        SizedBox(
          height: 160.h,
          child: spots.every((s) => s.y == 0)
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bar_chart_rounded, size: 32.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مبيعات في هذه الفترة', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))]))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: maxY / 4, verticalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9), strokeWidth: 1), getDrawingVerticalLine: (v) => FlLine(color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : const Color(0xFFF8FAFC), strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, meta) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return SideTitleWidget(meta: meta, child: Text(labels[i], style: TextStyle(fontSize: 9.sp, color: const Color(0xFF94A3B8)))); })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, interval: maxY / 4, getTitlesWidget: (v, meta) => Text(fmtCompact(v), style: TextStyle(fontSize: 9.sp, color: const Color(0xFF94A3B8))))),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: (labels.length - 1).toDouble(), minY: 0, maxY: maxY * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppTheme.primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppTheme.primaryColor)),
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.18), AppTheme.primaryColor.withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      ),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}

/// كارت المصروفات حسب التصنيف (دائرة).
class ReportsExpensesPie extends StatelessWidget {
  final ReportsState state;
  const ReportsExpensesPie({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final byCat = state.expensesByCategory;
    final total = byCat.values.fold<double>(0, (s, v) => s + v);
    const colors = [Color(0xFFE11D48), Color(0xFF2563EB), Color(0xFFF59E0B), Color(0xFF059669), Color(0xFF7C3AED), Color(0xFF06B6D4)];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFFB7185)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المصروفات حسب التصنيف', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(total == 0 ? 'لا توجد مصروفات' : 'إجمالي ${fmtReport(total)} ج.م', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
          ])),
        ]),
        SizedBox(height: 16.h),
        if (byCat.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.h), child: Column(children: [Icon(Icons.donut_large_rounded, size: 36.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مصروفات في هذه الفترة', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))])))
        else
          Row(children: [
            SizedBox(
              width: 140.w, height: 140.w,
              child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42.r,
                sections: List.generate(byCat.length, (i) {
                  final entry = byCat.entries.elementAt(i);
                  final pct = total == 0 ? 0 : entry.value / total * 100;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 22.r,
                    titleStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  );
                }),
              )),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                children: List.generate(byCat.length, (i) {
                  final entry = byCat.entries.elementAt(i);
                  final pct = total == 0 ? 0 : entry.value / total * 100;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(children: [
                      Container(width: 10.w, height: 10.w, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i % colors.length])),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(entry.key, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(fmtReport(entry.value), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      SizedBox(width: 4.w),
                      Text('(${pct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                    ]),
                  );
                }),
              ),
            ),
          ]),
      ]),
    );
  }
}
