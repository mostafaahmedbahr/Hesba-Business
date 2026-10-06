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
          return const Center(child: CircularProgressIndicator());
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final c in cards) SizedBox(width: 170, child: _StatCard(stat: c))],
            ),
            const SizedBox(height: 24),
            Text('الاشتراكات خلال 12 شهر', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 220, child: _BarCard(data: s.subscriptionsByMonth)),
            const SizedBox(height: 24),
            Text('المحلات الجديدة شهريًا', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 220, child: _BarCard(data: s.shopsByMonth)),
            const SizedBox(height: 24),
            Text('إيرادات الاشتراكات', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 220, child: _BarCard(data: s.revenueByMonth)),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: stat.color ?? AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text('${stat.value}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(stat.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BarCard extends StatelessWidget {
  const _BarCard({required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList()..sort();
    final last = keys.take(12).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: last.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : BarChart(
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < last.length; i++)
                      BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (data[last[i]] ?? 0).toDouble(), color: AppTheme.primaryColor)]),
                  ],
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
    );
  }
}
