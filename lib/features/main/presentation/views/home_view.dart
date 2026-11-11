import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shop_image_view.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../products/presentation/views/product_form_view.dart';
import '../../../dashboard/presentation/states/dashboard_state.dart';
import '../widgets/home_recent_movements.dart';
import '../../../notifications/presentation/view_model/activity_cubit.dart';
import '../../../sales/presentation/cubit/sales_list_state.dart';
import '../../../notifications/presentation/view_model/activity_state.dart';
 import '../../../notifications/presentation/views/notifications_view.dart';

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
            p.errorMessage != c.errorMessage,
        builder: (context, state) {
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
                  child: _HeaderBar(state: state, onOpenDrawer: onOpenDrawer)
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1 - صافي مبيعات اليوم
                      _NetSalesCard(state: state)
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      SizedBox(height: 14.h),
                      // 2 - الرصيد الحالي = صافي المبيعات - المصروفات
                      _CurrentBalanceCard(state: state)
                          .animate()
                          .fadeIn(delay: 140.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      _SubscriptionBanner()
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0),
                      if (state.status == DashboardStatus.failure) ...[
                        SizedBox(height: 12.h),
                        _ErrorHint(state: state),
                      ],
                      SizedBox(height: 20.h),
                      // 3 - الإجراءات السريعة (محسّنة)
                      _SectionTitle('homeQuickActions'.tr()),
                      SizedBox(height: 10.h),
                      _QuickActionsGrid(onNavigateTab: onNavigateTab)
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

/* ───────────────────── Header: الشعار + الاسم + الإشعارات ───────────────────── */

class _HeaderBar extends StatelessWidget {
  final DashboardState state;
  final VoidCallback? onOpenDrawer;
  const _HeaderBar({required this.state, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final date = DateFormat('EEEE d MMMM', context.locale.languageCode)
        .format(DateTime.now());

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, topPad + 8.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
        ),
      ),
      child: Row(
        children: [
          // زر القائمة (Drawer)
          InkWell(
            onTap: onOpenDrawer ??
                () {
                  final scaffold = Scaffold.maybeOf(context);
                  scaffold?.openDrawer();
                },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              ),
              child: Icon(Icons.menu_rounded, size: 20.sp, color: isDark ? Colors.white : AppTheme.ink),
            ),
          ),
          SizedBox(width: 8.w),
          // صورة المحل
          ShopImageView(
            imageUrl: state.shopImageUrl,
            size: 44.w,
            borderRadius: 14,
            fallbackIcon: Icons.storefront_rounded,
            withShadow: true,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.shopName.isEmpty ? 'appName'.tr() : state.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11.sp,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.mutedGray),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.slateGray,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // الإشعارات مع عدّاد
          BlocBuilder<ActivityCubit, ActivityState>(
            builder: (context, activity) {
              final unread = activity.unreadCount;
              return InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsView())),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 22.sp,
                          color: isDark ? Colors.white : AppTheme.ink),
                      if (unread > 0)
                        Positioned(
                          top: 6.h,
                          right: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: unread > 9 ? 5.w : 0, vertical: 2.h),
                            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(unread > 99 ? '99+' : '$unread',
                                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                            ),
                          ),
                        )
                      else if (state.lowStockCount > 0)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: AppTheme.warningAmber,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.darkSurfaceAlt : Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ───────────────────── 1- صافي مبيعات اليوم ───────────────────── */

class _NetSalesCard extends StatelessWidget {
  final DashboardState state;
  const _NetSalesCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final currency = 'currencyEGP'.tr();
    final net = state.todayNetSales;
    final sales = state.todaySalesTotal;
    final returns = state.todayReturnsTotal;
    final hasReturns = state.todayReturnsCount > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2A86), AppTheme.primaryColor, Color(0xFF4A7CFF)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -30.h,
              left: -30.w,
              child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(
              bottom: -40.h,
              right: -20.w,
              child: Container(
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E))),
                        SizedBox(width: 6.w),
                        Text('homeNetSales'.tr(),
                            style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r)),
                    child: Text('homeToday'.tr(),
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmt(net),
                        style: TextStyle(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1.2)),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 7.h),
                      child: Text(currency,
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.90))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        hasReturns
                            ? 'المبيعات ${_fmt(sales)} - المرتجعات ${_fmt(returns)}'
                            : 'إجمالي مبيعات اليوم ${_fmt(sales)} $currency',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/* ───────────────────── 2- الرصيد الحالي ───────────────────── */

class _CurrentBalanceCard extends StatelessWidget {
  final DashboardState state;
  const _CurrentBalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = 'currencyEGP'.tr();
    final sales = state.todaySalesTotal;
    final returns = state.todayReturnsTotal;
    final expenses = state.todayExpensesTotal;
    final netSales = state.todayNetSales; // sales - returns
    final balance = netSales - expenses; // الرصيد الحالي
    final isNegative = balance < 0;
    final isZero = balance == 0;

    return InkWell(
      borderRadius: BorderRadius.circular(24.r),
      onTap: () => _showBreakdown(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isNegative
                        ? [AppTheme.danger, AppTheme.roseLight]
                        : isZero
                            ? [AppTheme.slateGray, AppTheme.mutedGray]
                            : [AppTheme.successDark, const Color(0xFF34D399)]),
                    borderRadius: BorderRadius.circular(13.r),
                    boxShadow: [
                      BoxShadow(
                          color: (isNegative
                                  ? AppTheme.danger
                                  : AppTheme.successDark)
                              .withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(
                      isNegative
                          ? Icons.trending_down_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرصيد الحالي',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.ink)),
                      SizedBox(height: 2.h),
                      Text('المفروض يكون معاك آخر اليوم',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.slateGray,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isNegative
                        ? AppTheme.dangerSoft
                        : isZero
                            ? AppTheme.mist
                            : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: isNegative
                            ? AppTheme.danger.withValues(alpha: 0.12)
                            : isZero
                                ? AppTheme.borderSoft
                                : AppTheme.successDark.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    isNegative
                        ? 'عجز'
                        : isZero
                            ? 'متوازن'
                            : 'متاح',
                    style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isNegative
                            ? AppTheme.danger
                            : isZero
                                ? AppTheme.slateGray
                                : AppTheme.successDark),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(balance.abs()),
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.w900,
                      color: isNegative
                          ? AppTheme.danger
                          : isZero
                              ? (isDark ? Colors.white : AppTheme.ink)
                              : AppTheme.successDark,
                      height: 1,
                      letterSpacing: -1.1,
                    ),
                  ),
                  if (isNegative)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h, right: 4.w),
                      child: Text('-',
                          style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.danger)),
                    ),
                  SizedBox(width: 8.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(currency,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.slateGray)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.canvasLight,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
              ),
              child: Column(
                children: [
                  _miniRow('المبيعات', '+ ${_fmt(sales)}', AppTheme.primaryColor, isDark),
                  SizedBox(height: 8.h),
                  _miniRow('المرتجعات', '- ${_fmt(returns)}', AppTheme.warningAmber, isDark),
                  SizedBox(height: 8.h),
                  _miniRow('المصروفات', '- ${_fmt(expenses)}', AppTheme.danger, isDark),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Divider(
                        height: 1,
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('= الرصيد الحالي',
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.ink)),
                      Text('${_fmt(balance)} $currency',
                          style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w900,
                              color: isNegative
                                  ? AppTheme.danger
                                  : AppTheme.successDark)),
                    ],
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.h),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.touch_app_rounded, size: 13.sp, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray),
            SizedBox(width: 6.w),
            Text('اضغط لعرض تفصيل طرق الدفع', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray)),
          ]),
          ],
        ),
      ),
    );
  }

  /// فتح ديالوج تفصيل الرصيد: مبيعات كل وسيلة دفع + المرتجعات والمصروفات.
  void _showBreakdown(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _BalanceBreakdownDialog(state: state),
    );
  }

  Widget _miniRow(String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            SizedBox(width: 8.w),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
          ],
        ),
        Text('$value ${'currencyEGP'.tr()}',
            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/// ديالوج تفصيل الرصيد: مبيعات النهاردة حسب وسيلة الدفع
/// (نقدي / بطاقة / محفظة / آجل) ثم المرتجعات والمصروفات = الرصيد المعروض.
class _BalanceBreakdownDialog extends StatelessWidget {
  final DashboardState state;
  const _BalanceBreakdownDialog({required this.state});

  /// ترتيب عرض وسائل الدفع المعروفة، ثم أي وسيلة أخرى تظهر بعدها.
  static const _methodOrder = ['cash', 'card', 'mobile_wallet', 'wallet', 'credit'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = 'currencyEGP'.tr();
    final byMethod = state.todaySalesByMethod;
    final returns = state.todayReturnsTotal;
    final expenses = state.todayExpensesTotal;
    final balance = state.todayNetSales - expenses;
    final isNegative = balance < 0;

    final rows = <MapEntry<String, double>>[
      for (final m in _methodOrder)
        if (byMethod[m] != null) MapEntry(m, byMethod[m]!),
      ...byMethod.entries.where((e) => !_methodOrder.contains(e.key)),
    ];

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 18.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + زر الإغلاق.
            Row(children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF6D9BFF)]),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    size: 20.sp, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تفصيل الرصيد',
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.ink)),
                  SizedBox(height: 2.h),
                  Text('مبيعات النهاردة حسب طريقة الدفع',
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.slateGray)),
                ]),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18.sp,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.slateGray),
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            if (rows.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text('لا توجد مبيعات اليوم',
                      style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.slateGray)),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: isDark ? AppTheme.darkBorder : const Color(0xFFE6EAF2)),
                ),
                child: Column(children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) SizedBox(height: 8.h),
                    _MethodRow(
                      label: _labelOf(rows[i].key),
                      amount: rows[i].value,
                      method: rows[i].key,
                      isDark: isDark,
                    ),
                  ],
                ]),
              ),
            if (returns > 0) ...[
              SizedBox(height: 10.h),
              _deductRow('المرتجعات', returns, AppTheme.warningAmber, currency, isDark),
            ],
            if (expenses > 0) ...[
              SizedBox(height: 6.h),
              _deductRow('المصروفات', expenses, AppTheme.danger, currency, isDark),
            ],
            SizedBox(height: 12.h),
            Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft),
            SizedBox(height: 10.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('= الرصيد الحالي',
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.ink)),
              Text('${_fmt(balance)} $currency',
                  style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w900,
                      color: isNegative
                          ? AppTheme.danger
                          : (balance == 0
                              ? (isDark ? Colors.white : AppTheme.ink)
                              : AppTheme.successDark))),
            ]),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Text('تمام',
                    style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// اسم طريقة الدفع بالعربي (نفس شاشة العميل) — الفواتير بلا وسيلة → غير محدد.
  String _labelOf(String method) {
    if (method.isEmpty) return 'غير محدد';
    final label = SalesListState.paymentLabel(method);
    return label.isEmpty ? 'غير محدد' : label;
  }

  Widget _deductRow(String label, double amount, Color color, String currency, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        SizedBox(width: 8.w),
        Text(label,
            style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
      ]),
      Text('- ${_fmt(amount)} $currency',
          style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
    ]);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/// سطر وسيلة دفع داخل الديالوج: أيقونة + الاسم العربي + المبلغ.
class _MethodRow extends StatelessWidget {
  final String label;
  final double amount;
  final String method;
  final bool isDark;
  const _MethodRow(
      {required this.label, required this.amount, required this.method, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (method) {
      'cash' => (Icons.payments_rounded, AppTheme.successDark),
      'card' => (Icons.credit_card_rounded, AppTheme.primaryColor),
      'mobile_wallet' || 'wallet' => (
          Icons.account_balance_wallet_rounded,
          AppTheme.violetDeep
        ),
      'credit' => (Icons.schedule_rounded, AppTheme.amberDeep),
      _ => (Icons.payment_rounded, AppTheme.slateGray),
    };

    return Row(children: [
      Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 17.sp, color: color),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.ink)),
      ),
      Text('${_fmt(amount)} ${'currencyEGP'.tr()}',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: color)),
    ]);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _ErrorHint extends StatelessWidget {
  final DashboardState state;
  const _ErrorHint({required this.state});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, size: 18.sp, color: AppTheme.errorColor),
        SizedBox(width: 8.w),
        Expanded(child: Text(state.errorMessage ?? 'homeNoData'.tr(), style: TextStyle(fontSize: 11.5.sp, color: AppTheme.errorColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => context.read<DashboardCubit>().loadDashboardData(),
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(20.r)),
              child: Text('homeLoadRetry'.tr(), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
      ]),
    );
  }
}

/* ───────────────────── الإجراءات السريعة ───────────────────── */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 15.5.sp,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface));
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final void Function(int index)? onNavigateTab;
  const _QuickActionsGrid({this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAData(
          icon: Icons.point_of_sale_rounded,
          label: 'homeNewSale'.tr(),
          subtitle: 'سجّل فاتورة',
          gradient: const [AppTheme.primaryColor, AppTheme.brightBlue],
          accent: const Color(0xFFDBE6FF)),
      _QAData(
          icon: Icons.add_shopping_cart_rounded,
          label: 'homeAddProduct'.tr(),
          subtitle: 'أضف للمنتجات',
          gradient: const [AppTheme.warningAmber, AppTheme.goldLight],
          accent: const Color(0xFFFFF3D6)),
      _QAData(
          icon: Icons.replay_circle_filled_rounded,
          label: 'homeReturn'.tr(),
          subtitle: 'إرجاع فاتورة',
          gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          accent: const Color(0xFFEDE9FF)),
      _QAData(
          icon: Icons.savings_rounded,
          label: 'homeExpense'.tr(),
          subtitle: 'تسجيل مصروف',
          gradient: const [AppTheme.danger, AppTheme.roseLight],
          accent: const Color(0xFFFFE4E8)),
    ];
    return Column(children: [
      Row(children: [
        Expanded(
            child: _QA(
                data: actions[0],
                onTap: () async {
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addSaleView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (_) {}
                  }
                }).animate().fadeIn(delay: 0.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QA(
                data: actions[1],
                onTap: () async {
                  // يفتح فورم إضافة منتج مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => ProductsCubit(repo: sl<ProductsRepo>())..init(),
                        child: Builder(
                          builder: (formCtx) => ProductFormView(
                            cubit: formCtx.read<ProductsCubit>(),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (_) {}
                  }
                }).animate().fadeIn(delay: 70.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
      ]),
      SizedBox(height: 10.h),
      Row(children: [
        Expanded(
            child: _QA(
                data: actions[2],
                onTap: () async {
                  // يفتح إضافة مرتجع مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addReturnView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (_) {}
                  }
                }).animate().fadeIn(delay: 140.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QA(
                data: actions[3],
                onTap: () async {
                  // يفتح إضافة مصروف مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addExpenseView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (_) {}
                  }
                }).animate().fadeIn(delay: 210.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
      ]),
    ]);
  }
}

class _QAData {
  final IconData icon; final String label; final String subtitle; final List<Color> gradient; final Color accent;
  const _QAData({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.accent});
}

class _QA extends StatelessWidget {
  final _QAData data; final VoidCallback onTap;
  const _QA({required this.data, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    return Material(
      color: isDark ? surface : Colors.white,
      borderRadius: BorderRadius.circular(22.r),
      elevation: 0,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        borderRadius: BorderRadius.circular(22.r),
        splashColor: data.gradient.first.withValues(alpha: 0.12),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? surface : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 48.w, height: 48.w,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: data.gradient),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [BoxShadow(color: data.gradient.first.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6))]),
                      child: Icon(data.icon, color: Colors.white, size: 23.sp)),
                  const Spacer(),
                  Container(
                    width: 28.w, height: 28.w,
                    decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : data.accent, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_outward_rounded, size: 14.sp, color: data.gradient.first),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(data.label, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? AppTheme.darkTextPrimary : AppTheme.ink, letterSpacing: -0.2)),
              SizedBox(height: 3.h),
              Text(data.subtitle, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : AppTheme.mutedGray)),
              SizedBox(height: 10.h),
              Container(height: 3.h, width: 28.w, decoration: BoxDecoration(gradient: LinearGradient(colors: data.gradient), borderRadius: BorderRadius.circular(10.r))),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────── آخر الحركات: مبيع / مرتجع / مصروف ───────────────────── */

/// Opens the subscription screen. Always visible so the trial countdown and
/// the plans are one tap away.
///
/// The hint text (trial length + cheapest plan price) is read live from the
/// dashboard settings via [AppSettingsService] — editing them there updates
/// this banner on the next refresh.
class _SubscriptionBanner extends StatefulWidget {
  const _SubscriptionBanner();

  @override
  State<_SubscriptionBanner> createState() => _SubscriptionBannerState();
}

class _SubscriptionBannerState extends State<_SubscriptionBanner> {
  @override
  void initState() {
    super.initState();
    // Fetch the latest settings; on success rebuild with live values.
    // refresh() never throws, so no error handling is needed here.
    AppSettingsService.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.current;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
        child: Ink(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(9.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'subscriptionTitle'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'subscriptionHomeHint'.tr(namedArgs: {
                        'days': '${settings.trialDays}',
                        'from': '${settings.monthlyPrice}',
                      }),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 26.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

