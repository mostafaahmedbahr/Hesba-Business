import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/states/dashboard_state.dart';
import '../widgets/home/current_balance_card.dart';
import '../widgets/home/home_error_hint.dart';
import '../widgets/home/home_header_bar.dart';
import '../widgets/home/home_section_title.dart';
import '../widgets/home/net_sales_card.dart';
import '../widgets/home/quick_actions_grid.dart';
import '../widgets/home/subscription_banner.dart';
import '../widgets/home_recent_movements.dart';

/// صفحة الـ Home: طبقة تركيب (composition) فقط — الـ widgets نفسها في
/// `presentation/widgets/home/`.
class HomeView extends StatelessWidget {
  final void Function(int index)? onNavigateTab;
  final VoidCallback? onOpenDrawer;
  const HomeView({super.key, this.onNavigateTab, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        // Rebuild only when displayed data actually changes — otherwise every
        // cubit tick replays the entry animations and rebuilds the slivers.
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.shopName != c.shopName ||
            p.shopImageUrl != c.shopImageUrl ||
            p.todaySalesTotal != c.todaySalesTotal ||
            p.todayReturnsTotal != c.todayReturnsTotal ||
            p.todayReturnsCount != c.todayReturnsCount ||
            p.todayNetSales != c.todayNetSales ||
            p.todayExpensesTotal != c.todayExpensesTotal ||
            p.todaySalesByMethod != c.todaySalesByMethod ||
            p.productsCount != c.productsCount ||
            p.lowStockCount != c.lowStockCount ||
            p.errorMessage != c.errorMessage ||
            p.hasLoaded != c.hasLoaded,
        builder: (context, state) {
          // أول تحميل للهوم بس: نعرض اللودر الموحد من core على الشاشة كاملة.
          // التحديثات اللي بعدين بتفضل عرض البيانات الحالية.
          if (state.status == DashboardStatus.loading && !state.hasLoaded) {
            return LoadingWidget(message: 'homeLoading'.tr());
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onRefresh: () async =>
                context.read<DashboardCubit>().loadDashboardData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeaderBar(state: state, onOpenDrawer: onOpenDrawer)
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1 - صافي مبيعات اليوم
                      NetSalesCard(state: state)
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      SizedBox(height: 14.h),
                      // 2 - الرصيد الحالي = صافي المبيعات - المصروفات
                      CurrentBalanceCard(state: state)
                          .animate()
                          .fadeIn(delay: 140.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      const SubscriptionBanner()
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      if (state.status == DashboardStatus.failure) ...[
                        SizedBox(height: 12.h),
                        HomeErrorHint(state: state),
                      ],
                      SizedBox(height: 20.h),
                      // 3 - الإجراءات السريعة (محسّنة)
                      HomeSectionTitle('homeQuickActions'.tr()),
                      SizedBox(height: 10.h),
                      QuickActionsGrid(onNavigateTab: onNavigateTab)
                          .animate()
                          .fadeIn(delay: 180.ms, duration: 420.ms),
                      SizedBox(height: 22.h),
                      // 4 - آخر الحركات (مبيع / مرتجع / مصروف) — تنقل عبر الـ BottomNav
                      RecentMovementsSection(onNavigateTab: onNavigateTab)
                          .animate()
                          .fadeIn(delay: 220.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
