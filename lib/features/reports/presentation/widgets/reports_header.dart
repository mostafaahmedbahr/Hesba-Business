import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../cubit/reports_state.dart';

/// هيدر التقارير (صافي + رصيد + حالة رابح/عجز).
class ReportsHeader extends StatelessWidget {
  final ReportsState state;
  const ReportsHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loading = state.isFirstLoading && state.sales.isEmpty;
    final balance = state.balance;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 196.h,
      backgroundColor: const Color(0xFF1A4FD6),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      title: Text('navReports'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF7C4DFF)])),
          child: Stack(children: [
            Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            Positioned(top: 90.h, right: 30.w, child: Container(width: 60.w, height: 60.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 12.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(children: [
                    Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))), child: Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22.sp)),
                    SizedBox(width: 12.w),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('التقارير والتحليل', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(
                        loading ? 'جاري التحميل...' : '${state.period.label} • ${state.sales.length} عملية',
                        style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                      ),
                    ])),
                    if (!loading)
                      InkWell(
                        onTap: () => HapticFeedback.selectionClick(),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                          child: Row(children: [
                            Icon(Icons.auto_graph_rounded, size: 13.sp, color: AppTheme.primaryColor),
                            SizedBox(width: 5.w),
                            Text(balance >= 0 ? 'رابح' : 'خسارة', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                          ]),
                        ),
                      ),
                  ]),
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(
                      child: loading
                          ? _GlassSkeleton()
                          : _HeaderGlass(icon: Icons.trending_up_rounded, label: 'صافي المبيعات', value: '${fmtReport(state.netSales)} ج.م'),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: loading
                          ? _GlassSkeleton()
                          : _HeaderGlass(icon: Icons.account_balance_wallet_rounded, label: 'الرصيد الحالي', value: '${fmtReport(balance)} ج.م', danger: balance < 0),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// خانة زجاجية (أيقونة + رقم).
class _HeaderGlass extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool danger;
  const _HeaderGlass({required this.icon, required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: danger ? const Color(0xFFFFD1D1) : Colors.white)),
        ])),
      ]),
    );
  }
}

/// هيكل لامع مكان الأرقام أثناء التحميل.
class _GlassSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14.r)),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10.r))),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 60.w, height: 8.h, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6.r))),
            SizedBox(height: 6.h),
            Container(width: 90.w, height: 12.h, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.30), borderRadius: BorderRadius.circular(6.r))),
          ]),
        ),
      ]),
    );
  }
}
