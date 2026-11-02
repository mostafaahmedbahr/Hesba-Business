import 'dart:math' as math;

import 'package:hesba/features/admin/presentation/views/admin_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_nav_cubit.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AdminSpace.lg),
            children: [
              for (var i = 0; i < 6; i++) ...[
                adminSkeleton(context),
                if (i != 5) const SizedBox(height: AdminSpace.sm),
              ],
            ],
          );
        }
        if (state is AdminDashboardError) {
          return adminError(state.message, () => context.read<AdminDashboardCubit>().load());
        }
        if (state is! AdminDashboardLoaded) return const SizedBox();
        final s = state;
        final p = s.profitSummary;
        void go(int i) => context.read<AdminNavCubit>().select(i);
        final cards = <Widget>[
          AdminStatCard(icon: Icons.storefront_outlined, label: 'المحلات', value: AdminFmt.number(s.shops), onTap: () => go(1)),
          AdminStatCard(
              icon: Icons.check_circle_outline, label: 'اشتراكات نشطة', value: AdminFmt.number(s.active), color: AdminColors.success, onTap: () => go(2)),
          AdminStatCard(
              icon: Icons.hourglass_bottom_outlined, label: 'فترة تجريبية', value: AdminFmt.number(s.trial), color: AdminColors.info, onTap: () => go(2)),
          AdminStatCard(
              icon: Icons.cancel_outlined, label: 'اشتراكات منتهية', value: AdminFmt.number(s.expired), color: AdminColors.error, onTap: () => go(2)),
          AdminStatCard(
              icon: Icons.pending_actions_outlined, label: 'طلبات معلقة', value: AdminFmt.number(s.pending), color: AdminColors.warning, onTap: () => go(3)),
          AdminStatCard(
              icon: Icons.inventory_2_outlined, label: 'المنتجات', value: AdminFmt.number(s.products), color: AppTheme.primaryColor, onTap: () => go(4)),
          AdminStatCard(
              icon: Icons.point_of_sale_outlined, label: 'عدد المبيعات', value: AdminFmt.number(s.sales), color: AdminColors.success, onTap: () => go(5)),
          AdminStatCard(
              icon: Icons.money_off_outlined, label: 'المصروفات', value: AdminFmt.number(s.expenses), color: AdminColors.error, onTap: () => go(6)),
          AdminStatCard(
            icon: Icons.trending_up_rounded,
            label: 'إجمالي الأرباح',
            value: AdminFmt.money(p.profit),
            color: AppTheme.successColor,
            subtitle: p.capped
                ? 'أحدث ${AdminFmt.number(p.salesCounted)} عملية بيع'
                : 'كل المحلات • ${AdminFmt.number(p.salesCounted)} عملية بيع',
            onTap: () => go(5),
          ),
          AdminStatCard(
            icon: Icons.payments_outlined,
            label: 'إيرادات المبيعات',
            value: AdminFmt.money(p.revenue),
            color: AppTheme.violetDeep,
            subtitle: 'التكلفة: ${AdminFmt.money(p.cost)}',
            onTap: () => go(5),
          ),
        ];
        return RefreshIndicator(
          onRefresh: () => context.read<AdminDashboardCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(AdminSpace.lg),
            children: [
              const AdminPageHeader(
                title: 'لوحة التحكم',
                description: 'نظرة عامة على أداء النظام — اضغط على أي بطاقة للانتقال للقسم',
              ),
              const SizedBox(height: AdminSpace.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final cols = wide ? 4 : 2;
                  const spacing = AdminSpace.md;
                  final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [for (final c in cards) SizedBox(width: width, child: c)],
                  );
                },
              ),
              const SizedBox(height: AdminSpace.xxl),
              _ChartsGrid(s: s),
            ],
          ),
        );
      },
    );
  }
}

class _ChartSpec {
  const _ChartSpec({
    required this.title,
    required this.description,
    required this.icon,
    required this.data,
    required this.color,
    this.money = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Map<String, int> data;
  final Color color;
  final bool money;
}

class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({required this.s});

  final AdminDashboardLoaded s;

  @override
  Widget build(BuildContext context) {
    final charts = <_ChartSpec>[
      _ChartSpec(
        title: 'الاشتراكات الجديدة',
        description: 'عدد الاشتراكات الجديدة المسجلة كل شهر خلال آخر 12 شهرًا',
        icon: Icons.workspace_premium_outlined,
        data: s.subscriptionsByMonth,
        color: AppTheme.primaryColor,
      ),
      _ChartSpec(
        title: 'المحلات الجديدة',
        description: 'عدد المحلات التي انضمت للمنصة كل شهر خلال آخر 12 شهرًا',
        icon: Icons.storefront_outlined,
        data: s.shopsByMonth,
        color: AppTheme.secondaryColor,
      ),
      _ChartSpec(
        title: 'إيرادات الاشتراكات',
        description: 'إجمالي مبالغ الاشتراكات المقبولة شهريًا بالجنيه خلال آخر 12 شهرًا',
        icon: Icons.payments_outlined,
        data: s.revenueByMonth,
        color: AppTheme.violetDeep,
        money: true,
      ),
      _ChartSpec(
        title: 'صافي الأرباح',
        description: 'ربح المحلات الشهري بعد الخصومات (سعر البيع − سعر الشراء) بالجنيه خلال آخر 12 شهرًا',
        icon: Icons.savings_outlined,
        data: s.profitSummary.profitByMonth,
        color: AppTheme.successColor,
        money: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final cols = wide ? 2 : 1;
        const spacing = AdminSpace.md;
        final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final spec in charts)
                  SizedBox(
                    width: cols == 1 ? double.infinity : width,
                    child: _ChartCard(spec: spec),
                  ),
              ],
            ),
            const SizedBox(height: AdminSpace.sm),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 13, color: AdminColors.textMuted(context)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'مرّر المؤشر على أي عمود أو اضغط عليه لعرض الشهر والرقم بالتفصيل.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AdminColors.textMuted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.spec});

  final _ChartSpec spec;

  @override
  Widget build(BuildContext context) {
    final series = _monthlySeries(spec.data);
    final total = series.fold<int>(0, (sum, p) => sum + p.value);
    final average = total / series.length;
    final peak = series.reduce((a, b) => b.value > a.value ? b : a);
    final hasData = series.any((p) => p.value != 0);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconTile(icon: spec.icon, color: spec.color),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.description,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AdminColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'الإجمالي',
                  value: _amount(total, spec.money),
                  valueColor: spec.color,
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _MiniStat(
                  label: 'المتوسط',
                  value: _amount(average, spec.money),
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _MiniStat(
                  label: 'أعلى شهر',
                  value: _amount(peak.value, spec.money),
                  caption: hasData ? peak.fullLabel : 'لا توجد بيانات',
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.lg),
          SizedBox(
            height: 190,
            child: hasData
                ? _MonthlyBars(series: series, color: spec.color, money: spec.money)
                : adminEmpty(Icons.bar_chart_outlined, 'لا توجد بيانات لهذه الفترة'),
          ),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Icon(Icons.date_range_outlined, size: 13, color: AdminColors.textMuted(context)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${series.first.fullLabel} — ${series.last.fullLabel}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AdminColors.textMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.caption, this.valueColor});

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AdminColors.textMuted(context),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: valueColor ?? AdminColors.textPrimary(context),
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AdminColors.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AdminColors.border(context),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.series, required this.color, required this.money});

  final List<_MonthPoint> series;
  final Color color;
  final bool money;

  @override
  Widget build(BuildContext context) {
    final maxValue = series.fold<int>(0, (m, p) => math.max(m, p.value));
    final minValue = series.fold<int>(0, (m, p) => math.min(m, p.value));
    final interval = _axisInterval(math.max(maxValue, -minValue));
    // Always keep zero visible so losing months render below the baseline.
    final topTicks = math.max(1, (maxValue / interval).ceil());
    final bottomTicks = minValue >= 0 ? 0 : (-minValue / interval).ceil();
    final maxY = interval * topTicks;
    final minY = -interval * bottomTicks;
    final average = series.fold<int>(0, (sum, p) => sum + p.value) / series.length;

    var peakIndex = 0;
    for (var i = 0; i < series.length; i++) {
      if (series[i].value > series[peakIndex].value) peakIndex = i;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      color: AdminColors.textMuted(context),
    );
    final barLabelStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AdminColors.textSecondary(context),
    );
    final gridColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = (constraints.maxWidth - 54).clamp(1.0, double.infinity).toDouble();
        final perGroup = plotWidth / series.length;

        // Keep value labels readable: show all when there is room, then every
        // other bar, otherwise only the peak and the latest month.
        final labelLength = series
                .map((p) => _compact(p.value).length)
                .fold<int>(0, math.max) *
            5.4;
        final allLabels = perGroup >= labelLength + 6;
        final alternateLabels = !allLabels && perGroup * 2 >= labelLength + 6;
        final axisEvery = perGroup >= 34 ? 1 : (perGroup >= 24 ? 2 : 3);

        bool showLabel(int i) {
          if (series[i].value == 0) return false;
          if (allLabels) return true;
          if (alternateLabels) return i.isEven || i == series.length - 1;
          return i == peakIndex || i == series.length - 1;
        }

        return BarChart(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          BarChartData(
            minY: minY,
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            barGroups: [
              for (var i = 0; i < series.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: series[i].value.toDouble(),
                      width: (perGroup * 0.45).clamp(6.0, 22.0).toDouble(),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [color.withValues(alpha: 0.55), color],
                      ),
                      label: BarChartRodLabel(
                        show: showLabel(i),
                        text: _compact(series[i].value),
                        style: barLabelStyle,
                        offset: const Offset(0, 6),
                      ),
                    ),
                  ],
                ),
            ],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) => FlLine(
                color: gridColor,
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: average,
                  color: color.withValues(alpha: 0.45),
                  strokeWidth: 1,
                  dashArray: const [5, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    labelResolver: (_) => 'المتوسط',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 54,
                  interval: interval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(_compact(value), style: axisStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= series.length) return const SizedBox.shrink();
                    if (i % axisEvery != 0) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      space: 5,
                      child: Text(series[i].shortMonth, style: axisStyle),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipMargin: 8,
                tooltipBorderRadius: BorderRadius.circular(8),
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                getTooltipColor: (_) => isDark ? AppTheme.darkSurfaceElevated : AppTheme.ink,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final point = series[group.x];
                  return BarTooltipItem(
                    '${point.fullLabel}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                    children: [
                      TextSpan(
                        text: _amount(point.value, money),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Monthly series helpers ───────────────────────────────────

const _arMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

class _MonthPoint {
  const _MonthPoint({required this.year, required this.month, required this.value});

  final int year;
  final int month;
  final int value;

  String get shortMonth => _arMonths[month - 1];
  String get fullLabel => '${_arMonths[month - 1]} $year';
}

/// Builds a continuous 12-month window (filled with zeros) so the chart shape
/// is always aligned to real months, even when some months have no data.
List<_MonthPoint> _monthlySeries(Map<String, int> data) {
  final now = DateTime.now();
  return List.generate(12, (i) {
    final date = DateTime(now.year, now.month - 11 + i, 1);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return _MonthPoint(year: date.year, month: date.month, value: data[key] ?? 0);
  });
}

/// Picks a "nice" whole-number tick interval for 4 horizontal grid lines.
double _axisInterval(int maxValue) {
  if (maxValue <= 0) return 1;
  final raw = maxValue * 1.12 / 4;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final normalized = raw / magnitude;
  const steps = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0];
  final step = steps.firstWhere((s) => normalized <= s, orElse: () => 10.0);
  final interval = step * magnitude;
  return interval < 1 ? 1 : interval;
}

/// "1,249" / "12.4 ألف" / "1.5 مليون" — compact axis & bar labels.
String _compact(num value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  if (absolute >= 1000000) {
    return '$sign${_trim(absolute / 1000000)} مليون';
  }
  if (absolute >= 10000) {
    return '$sign${_trim(absolute / 1000)} ألف';
  }
  return AdminFmt.number(value);
}

/// Full value for the summary stats, with the currency unit when relevant.
String _amount(num value, bool money) {
  final text = value == value.roundToDouble()
      ? AdminFmt.number(value.round())
      : _trim(value);
  return money ? '$text ج' : text;
}

String _trim(num value) {
  final text = value.toStringAsFixed(value >= 100 ? 0 : 1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

