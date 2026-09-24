import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../expenses/presentation/views/expenses_view.dart';
import 'reports_view.dart';

/// Wrapper يجمع التقارير والمصروفات في TabBar واحد
/// index 0 = التقارير | index 1 = المصروفات
class ReportsExpensesView extends StatefulWidget {
  final int initialTab;
  const ReportsExpensesView({super.key, this.initialTab = 0});

  @override
  State<ReportsExpensesView> createState() => _ReportsExpensesViewState();
}

class _ReportsExpensesViewState extends State<ReportsExpensesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void didUpdateWidget(covariant ReportsExpensesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 8.h, 16.w, 8.h),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1A4FD6),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A4FD6).withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
              labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              unselectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  height: 36.h,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.bar_chart_rounded, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('navReports'.tr()),
                  ]),
                ),
                Tab(
                  height: 36.h,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.savings_rounded, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('navExpenses'.tr()),
                  ]),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ReportsView(),
              ExpensesView(),
            ],
          ),
        ),
      ],
    );
  }
}
