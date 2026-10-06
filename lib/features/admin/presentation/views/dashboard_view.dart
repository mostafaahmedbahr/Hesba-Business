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
              icon: Icons.point_of_sale_outlined, label: 'المبيعات', value: AdminFmt.number(s.sales), color: AdminColors.success, onTap: () => go(5)),
          AdminStatCard(
              icon: Icons.money_off_outlined, label: 'المصروفات', value: AdminFmt.number(s.expenses), color: AdminColors.error, onTap: () => go(6)),
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
        const spacing = AdminSpace.md;
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
    return AdminSection(
      title: title,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      child: SizedBox(
        height: 170,
        child: last.isEmpty
            ? adminEmpty(Icons.bar_chart_outlined, 'لا توجد بيانات')
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
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          return Text(idx % 2 == 0 && idx < last.length ? last[idx].substring(5) : '',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
      ),
    );
  }
}
