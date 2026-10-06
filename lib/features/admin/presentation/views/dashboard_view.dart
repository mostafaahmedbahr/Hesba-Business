import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_dashboard_cubit.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardEmpty) {
          return adminSkeletonList(context);
        }
        if (state is AdminDashboardError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }
        if (state is! AdminDashboardLoaded) return const SizedBox();
        final s = state;
        final cards = <_Stat>[
          _Stat('المحلات', s.shops, Icons.storefront),
          _Stat('النشطة', s.active, Icons.check_circle_outline, AppTheme.successColor),
          _Stat('Free Trial', s.trial, Icons.hourglass_bottom, AppTheme.secondaryColor),
          _Stat('اشتراكات فعالة', s.active, Icons.verified_outlined, AppTheme.primaryColor),
          _Stat('اشتراكات منتهية', s.expired, Icons.cancel_outlined, Colors.redAccent),
          _Stat('طلبات معلقة', s.pending, Icons.pending_actions_outlined, AppTheme.secondaryColor),
          _Stat('المنتجات', s.products, Icons.inventory_2_outlined, AppTheme.primaryColor),
          _Stat('المبيعات', s.sales, Icons.point_of_sale_outlined, AppTheme.successColor),
          _Stat('المصروفات', s.expenses, Icons.money_off_outlined, Colors.redAccent),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final cols = wide ? 3 : 2;
                final spacing = 12.0;
                final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final c in cards) SizedBox(width: width, child: _StatCard(stat: c)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _ChartsGrid(s: s),
          ],
        );
      },
    );
  }
}

class _Stat {
  _Stat(this.label, this.value, this.icon, [this.color]);
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (stat.color ?? AppTheme.primaryColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stat.icon, color: stat.color ?? AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text('${stat.value}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(stat.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({required this.s});
  final AdminDashboardLoaded s;

  @override
  Widget build(BuildContext context) {
    final charts = [
      (title: 'الاشتراكات خلال 12 شهر', data: s.subscriptionsByMonth, color: AppTheme.primaryColor),
      (title: 'المحلات الجديدة شهريًا', data: s.shopsByMonth, color: AppTheme.secondaryColor),
      (title: 'إيرادات الاشتراكات', data: s.revenueByMonth, color: AppTheme.successColor),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final cols = wide ? 2 : 1;
        final spacing = 12.0;
        final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final c in charts)
                  SizedBox(
                    width: cols == 1 ? double.infinity : width,
                    height: 250,
                    child: _BarCard(title: c.title, data: c.data, color: c.color),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({required this.title, required this.data, required this.color});
  final String title;
  final Map<String, int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList()..sort();
    final last = keys.take(12).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: last.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : BarChart(
                      BarChartData(
                        barGroups: [
                          for (var i = 0; i < last.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: (data[last[i]] ?? 0).toDouble(),
                                  color: color,
                                  width: 14,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                        ],
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                return Text(idx % 2 == 0 && idx < last.length ? last[idx].substring(5) : '', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
