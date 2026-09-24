import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/states/dashboard_state.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/views/expenses_view.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../../notifications/presentation/cubit/activity_cubit.dart';
import '../../../notifications/presentation/cubit/activity_state.dart';
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
                      _RecentMovementsSection(onNavigateTab: onNavigateTab)
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
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
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
                color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Icon(Icons.menu_rounded, size: 20.sp, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          SizedBox(width: 8.w),
          // الشعار
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.storefront_rounded,
                color: Colors.white, size: 20.sp),
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
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                            : const Color(0xFF94A3B8)),
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
                                : const Color(0xFF64748B),
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
                    color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 22.sp,
                          color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      if (unread > 0)
                        Positioned(
                          top: 6.h,
                          right: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: unread > 9 ? 5.w : 0, vertical: 2.h),
                            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
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
                              color: const Color(0xFFF59E0B),
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
          colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7CFF)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A4FD6).withValues(alpha: 0.28),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
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
                      ? [const Color(0xFFE11D48), const Color(0xFFFB7185)]
                      : isZero
                          ? [const Color(0xFF64748B), const Color(0xFF94A3B8)]
                          : [const Color(0xFF059669), const Color(0xFF34D399)]),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                        color: (isNegative
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF059669))
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
                                : const Color(0xFF0F172A))),
                    SizedBox(height: 2.h),
                    Text('المفروض يكون معاك آخر اليوم',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isNegative
                      ? const Color(0xFFFEF2F2)
                      : isZero
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: isNegative
                          ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                          : isZero
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF059669).withValues(alpha: 0.12)),
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
                          ? const Color(0xFFE11D48)
                          : isZero
                              ? const Color(0xFF64748B)
                              : const Color(0xFF059669)),
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
                        ? const Color(0xFFE11D48)
                        : isZero
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF059669),
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
                            color: const Color(0xFFE11D48))),
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
                              : const Color(0xFF64748B))),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _miniRow('المبيعات', '+ ${_fmt(sales)}', const Color(0xFF1A4FD6), isDark),
                SizedBox(height: 8.h),
                _miniRow('المرتجعات', '- ${_fmt(returns)}', const Color(0xFFF59E0B), isDark),
                SizedBox(height: 8.h),
                _miniRow('المصروفات', '- ${_fmt(expenses)}', const Color(0xFFE11D48), isDark),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Divider(
                      height: 1,
                      color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('= الرصيد الحالي',
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    Text('${_fmt(balance)} $currency',
                        style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w900,
                            color: isNegative
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF059669))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
          accent: const Color(0xFFDBE6FF)),
      _QAData(
          icon: Icons.add_shopping_cart_rounded,
          label: 'homeAddProduct'.tr(),
          subtitle: 'أضف للمنتجات',
          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
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
          gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
          accent: const Color(0xFFFFE4E8)),
    ];
    return Column(children: [
      Row(children: [
        Expanded(
            child: _QA(
                data: actions[0],
                onTap: () async {
                  final r = await Navigator.pushNamed(context, AppRoutes.addSaleView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (_) {}
                  }
                }).animate().fadeIn(delay: 0.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QA(
                data: actions[1],
                onTap: () {
                  if (onNavigateTab != null) { onNavigateTab!(1); } else { Navigator.pushNamed(context, AppRoutes.dashboard, arguments: {'initialTab': 1}); }
                }).animate().fadeIn(delay: 70.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
      ]),
      SizedBox(height: 10.h),
      Row(children: [
        Expanded(
            child: _QA(
                data: actions[2],
                onTap: () {
                  if (onNavigateTab != null) { onNavigateTab!(3); } else { Navigator.pushNamed(context, AppRoutes.returnsView).then((r) { if (r == true && context.mounted) { try { context.read<DashboardCubit>().refresh(); } catch (_) {} } }); }
                }).animate().fadeIn(delay: 140.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QA(
                data: actions[3],
                onTap: () {
                  if (onNavigateTab != null) { onNavigateTab!(5); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesView(shopId: ''))); }
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
            border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
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
              Text(data.label, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A), letterSpacing: -0.2)),
              SizedBox(height: 3.h),
              Text(data.subtitle, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8))),
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

class _RecentMovementsSection extends StatefulWidget {
  final void Function(int index)? onNavigateTab;
  const _RecentMovementsSection({this.onNavigateTab});
  @override
  State<_RecentMovementsSection> createState() => _RecentMovementsSectionState();
}

class _RecentMovementsSectionState extends State<_RecentMovementsSection> {
  String? _shopId;
  bool _loadingShop = true;

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { if (mounted) setState(() => _loadingShop = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _shopId = doc.data()?['shopId'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loadingShop = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('آخر الحركات',
                style: TextStyle(fontSize: 15.5.sp, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Text('اليوم', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_loadingShop)
          _shimmerList(isDark)
        else if (_shopId == null)
          _emptyShop(isDark)
        else
          Column(children: [
            _LastSaleCard(shopId: _shopId!, onNavigateTab: widget.onNavigateTab),
            SizedBox(height: 10.h),
            _LastReturnCard(shopId: _shopId!, onNavigateTab: widget.onNavigateTab),
            SizedBox(height: 10.h),
            _LastExpenseCard(shopId: _shopId!, onNavigateTab: widget.onNavigateTab),
          ]),
      ],
    );
  }

  Widget _shimmerList(bool isDark) {
    return Column(children: List.generate(3, (_) => Container(
      height: 78.h,
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Center(child: SizedBox(width: 22.w, height: 22.w, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.primaryColor))),
    )));
  }

  Widget _emptyShop(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(Icons.store_outlined, color: Colors.grey.shade400),
        SizedBox(width: 10.w),
        Expanded(child: Text('لم يتم العثور على المحل', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600))),
      ]),
    );
  }
}

class _LastSaleCard extends StatelessWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastSaleCard({required this.shopId, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.salesCollection)
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, const Color(0xFF1A4FD6));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _RecentEmpty(
            isDark: isDark,
            icon: Icons.point_of_sale_rounded,
            gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
            title: 'آخر مبيع',
            subtitle: 'لا يوجد مبيعات اليوم',
            actionLabel: 'بيع جديد',
            onTap: () => Navigator.pushNamed(context, AppRoutes.addSaleView),
          );
        }
        final sale = SaleModel.fromJson(docs.first.data());
        final time = _timeAgo(sale.createdAt);
        return _RecentCard(
          isDark: isDark,
          icon: Icons.point_of_sale_rounded,
          gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
          title: 'آخر مبيع',
          subtitle: sale.items.isEmpty ? 'فاتورة #${sale.saleId.substring(0, 6)}' : '${sale.items.first.productName}${sale.items.length > 1 ? ' +${sale.items.length - 1}' : ''}',
          time: time,
          amount: '+${_fmt(sale.total)} ${'currencyEGP'.tr()}',
          amountColor: const Color(0xFF059669),
          onTap: () {
            HapticFeedback.selectionClick();
            if (onNavigateTab != null) { onNavigateTab!(2); } else { Navigator.pushNamed(context, AppRoutes.dashboard, arguments: {'initialTab': 2}); }
          },
        );
      },
    );
  }
}

class _LastReturnCard extends StatelessWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastReturnCard({required this.shopId, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.returnsCollection)
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, const Color(0xFFF59E0B));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _RecentEmpty(
            isDark: isDark,
            icon: Icons.assignment_return_rounded,
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            title: 'آخر مرتجع',
            subtitle: 'لا يوجد مرتجعات اليوم ✓',
            actionLabel: 'إضافة مرتجع',
            onTap: () {
              if (onNavigateTab != null) { onNavigateTab!(3); } else { Navigator.pushNamed(context, AppRoutes.returnsView); }
            },
          );
        }
        final ret = ReturnModel.fromJson(docs.first.data());
        final time = _timeAgo(ret.createdAt);
        return _RecentCard(
          isDark: isDark,
          icon: Icons.assignment_return_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          title: 'آخر مرتجع',
          subtitle: ret.items.isEmpty ? (ret.reason.isEmpty ? 'مرتجع' : ret.reason) : '${ret.items.first.productName}${ret.items.length > 1 ? ' +${ret.items.length - 1}' : ''}',
          time: time,
          amount: '-${_fmt(ret.total)} ${'currencyEGP'.tr()}',
          amountColor: const Color(0xFFE11D48),
          onTap: () {
            HapticFeedback.selectionClick();
            if (onNavigateTab != null) { onNavigateTab!(3); } else { Navigator.pushNamed(context, AppRoutes.returnsView); }
          },
        );
      },
    );
  }
}

class _LastExpenseCard extends StatelessWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastExpenseCard({required this.shopId, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.expensesCollection)
          .where('shopId', isEqualTo: shopId)
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, const Color(0xFFE11D48));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _RecentEmpty(
            isDark: isDark,
            icon: Icons.savings_rounded,
            gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
            title: 'آخر مصروف',
            subtitle: 'لا يوجد مصروفات اليوم',
            actionLabel: 'إضافة مصروف',
            onTap: () {
              if (onNavigateTab != null) { onNavigateTab!(5); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesView(shopId: shopId))); }
            },
          );
        }
        final exp = ExpenseModel.fromJson(docs.first.data());
        final time = _timeAgo(exp.date);
        return _RecentCard(
          isDark: isDark,
          icon: Icons.savings_rounded,
          gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
          title: 'آخر مصروف',
          subtitle: exp.title.isEmpty ? exp.category : exp.title,
          time: time,
          amount: '-${_fmt(exp.amount)} ${'currencyEGP'.tr()}',
          amountColor: const Color(0xFFE11D48),
          onTap: () {
            HapticFeedback.selectionClick();
            if (onNavigateTab != null) { onNavigateTab!(5); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesView(shopId: shopId))); }
          },
        );
      },
    );
  }
}

Widget _RecentCard({
  required bool isDark,
  required IconData icon,
  required List<Color> gradient,
  required String title,
  required String subtitle,
  required String time,
  required String amount,
  required Color amountColor,
  required VoidCallback onTap,
}) {
  return Material(
    color: isDark ? AppTheme.darkSurface : Colors.white,
    borderRadius: BorderRadius.circular(18.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46.w, height: 46.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
                SizedBox(height: 2.h),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                SizedBox(height: 2.h),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 11.sp, color: const Color(0xFF94A3B8)),
                  SizedBox(width: 4.w),
                  Text(time, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                ]),
              ]),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: amountColor)),
                SizedBox(height: 4.h),
                Icon(Icons.chevron_left_rounded, size: 18.sp, color: const Color(0xFFCBD5E1)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  const _RecentEmpty({required this.isDark, required this.icon, required this.gradient, required this.title, required this.subtitle, required this.actionLabel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), style: BorderStyle.solid),
      ),
      child: Row(children: [
        Container(width: 46.w, height: 46.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(13.r)), child: Icon(icon, color: Colors.white, size: 22.sp)),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8))),
        ])),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(color: gradient.first.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: gradient.first.withValues(alpha: 0.18))),
              child: Text(actionLabel, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: gradient.first))),
        ),
      ]),
    );
  }
}

Widget _recentSkeleton(bool isDark, Color accent) {
  return Container(
    height: 74.h,
    decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
    child: Center(child: SizedBox(width: 18.w, height: 18.w, child: CircularProgressIndicator(strokeWidth: 2.2, color: accent))),
  );
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String _timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return DateFormat('d MMM', 'ar').format(dt);
}
