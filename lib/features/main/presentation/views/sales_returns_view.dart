import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import 'sales_view.dart';
import '../../../returns/presentation/views/returns_view.dart';

/// Wrapper يجمع المبيعات والمرتجعات في TabBar واحد
/// index 0 = المبيعات | index 1 = المرتجعات
class SalesReturnsView extends StatefulWidget {
  final int initialTab;
  const SalesReturnsView({super.key, this.initialTab = 0});

  @override
  State<SalesReturnsView> createState() => _SalesReturnsViewState();
}

class _SalesReturnsViewState extends State<SalesReturnsView>
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
  void didUpdateWidget(covariant SalesReturnsView oldWidget) {
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

  void switchTo(int index) => _tabController.animateTo(index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Top segmented TabBar - يظهر فوق محتوى الـ Sales/Returns
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
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3)),
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
                    Icon(Icons.receipt_long_rounded, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('navSales'.tr()),
                  ]),
                ),
                Tab(
                  height: 36.h,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.assignment_return_rounded, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('navReturns'.tr()),
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
              SalesView(),
              ReturnsView(),
            ],
          ),
        ),
      ],
    );
  }
}
