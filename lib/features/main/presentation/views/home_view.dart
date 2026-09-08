import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboard/presentation/states/dashboard_state.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              await context.read<DashboardCubit>().loadDashboardData();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroHeader(state: state).animate().fadeIn(
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(20.w),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionHeader(
                        title: 'homeOverview'.tr(),
                        trailing: _TodayChip(),
                      ),
                      SizedBox(height: 14.h),
                      _OverviewGrid(state: state, onRetry: _retry),
                      if (state.status == DashboardStatus.failure)
                        _buildErrorHint(context, state),
                      if (state.lowStockCount > 0) ...[
                        SizedBox(height: 20.h),
                        _LowStockBanner(count: state.lowStockCount),
                      ],
                      SizedBox(height: 24.h),
                      _SectionTitle('homeQuickActions'.tr()),
                      SizedBox(height: 14.h),
                      _QuickActionsGrid(),
                      SizedBox(height: 16.h),
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

  void _retry(BuildContext context) {
    context.read<DashboardCubit>().loadDashboardData();
  }

  Widget _buildErrorHint(BuildContext context, DashboardState state) {
    return SizedBox(
      height: 32.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              state.errorMessage ?? 'homeNoData'.tr(),
              style: TextStyle(fontSize: 11.sp, color: AppTheme.errorColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          InkWell(
            onTap: () => _retry(context),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'homeLoadRetry'.tr(),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Header                                         */
/* -------------------------------------------------------------------------- */

class _HeroHeader extends StatelessWidget {
  final DashboardState state;

  const _HeroHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Glow decorations
          Positioned(
            top: -70.h,
            left: -60.w,
            child: _Glow(
              size: 220.w,
              color: AppTheme.primaryLight,
              opacity: 0.25,
            ),
          ),
          Positioned(
            bottom: -100.h,
            right: -50.w,
            child: _Glow(
              size: 240.w,
              color: AppTheme.secondaryColor,
              opacity: 0.12,
            ),
          ),
          Positioned(
            top: 90.h,
            right: 20.w,
            child: _Glow(
              size: 90.w,
              color: Colors.white,
              opacity: 0.08,
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(
              20.w,
              MediaQuery.of(context).padding.top + 12.h,
              20.w,
              28.h,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2D8A),
                  Color(0xFF1A4FD6),
                  Color(0xFF3B6FF5),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36.r),
                bottomRight: Radius.circular(36.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopRow(),
                SizedBox(height: 28.h),
                _buildNetSalesCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopRow() {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 26.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'homeWelcome'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                state.shopName.isEmpty ? 'appName'.tr() : state.shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetSalesCard() {
    final currency = 'currencyEGP'.tr();
    final netSales = state.todayNetSales;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24.r,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'homeNetSales'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _TodayBadge(),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _formatNumber(netSales),
                          style: TextStyle(
                            fontSize: 38.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        currency,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Glow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity * 0.8),
              blurRadius: 60.r,
              spreadRadius: 10.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'homeToday'.tr(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final today = DateFormat('EEEE d MMMM', locale).format(DateTime.now());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 13.sp,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 6.w),
          Text(
            today,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Section headers                                */
/* -------------------------------------------------------------------------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Overview grid                                  */
/* -------------------------------------------------------------------------- */

class _OverviewGrid extends StatelessWidget {
  final DashboardState state;
  final void Function(BuildContext) onRetry;

  const _OverviewGrid({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loading = state.status == DashboardStatus.loading;
    final surface = Theme.of(context).colorScheme.surface;
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.grey.withValues(alpha: 0.14);

    const gap = 14.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                surface: surface,
                shadow: shadow,
                gradient: const [Color(0xFF1A4FD6), Color(0xFF3B6FF5)],
                icon: Icons.payments_rounded,
                value: loading
                    ? '—'
                    : '${_format(state.todaySalesTotal)} ${'currencyEGP'.tr()}',
                label: 'homeSalesToday'.tr(),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                surface: surface,
                shadow: shadow,
                gradient: const [Color(0xFFF5A623), Color(0xFFFFC24B)],
                icon: Icons.receipt_long_rounded,
                value: loading
                    ? '—'
                    : '${_format(state.todayExpensesTotal)} ${'currencyEGP'.tr()}',
                label: 'homeExpensesToday'.tr(),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                surface: surface,
                shadow: shadow,
                gradient: const [Color(0xFF2E9E44), Color(0xFF4CAF50)],
                icon: Icons.inventory_2_rounded,
                value: loading ? '—' : '${state.productsCount}',
                label: 'homeProducts'.tr(),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                surface: surface,
                shadow: shadow,
                gradient: const [Color(0xFFE53935), Color(0xFFFF6B6B)],
                icon: Icons.warning_amber_rounded,
                value: loading ? '—' : '${state.lowStockCount}',
                label: 'homeLowStock'.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _StatTile extends StatelessWidget {
  final Color surface;
  final Color shadow;
  final List<Color> gradient;
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.surface,
    required this.shadow,
    required this.gradient,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : const Color(0xFF1A1A2E);
    final labelColor = isDark
        ? AppTheme.darkTextSecondary
        : Colors.grey.shade600;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 18.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 12.r,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(height: 14.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Low stock banner                               */
/* -------------------------------------------------------------------------- */

class _LowStockBanner extends StatelessWidget {
  final int count;

  const _LowStockBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final grad = const [Color(0xFFFF8F3D), Color(0xFFFF6B2C)];

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('homeTapSeeProducts'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [grad[0].withValues(alpha: 0.14), grad[1].withValues(alpha: 0.1)],
          ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: grad[0].withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: grad,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: const Icon(
                Icons.inventory_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${'homeLowStockCount'.tr()}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: grad[1],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'homeLowStockBanner'.tr(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: grad[1].withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: grad[1],
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Quick actions                                  */
/* -------------------------------------------------------------------------- */

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.point_of_sale_rounded,
        label: 'homeNewSale'.tr(),
        gradient: const [Color(0xFF1A4FD6), Color(0xFF3B6FF5)],
      ),
      _QuickActionData(
        icon: Icons.add_shopping_cart_rounded,
        label: 'homeAddProduct'.tr(),
        gradient: const [Color(0xFFF5A623), Color(0xFFFFC24B)],
      ),
      _QuickActionData(
        icon: Icons.replay_circle_filled_rounded,
        label: 'homeReturn'.tr(),
        gradient: const [Color(0xFF7C4DFF), Color(0xFFB388FF)],
      ),
      _QuickActionData(
        icon: Icons.savings_rounded,
        label: 'homeExpense'.tr(),
        gradient: const [Color(0xFFE91E63), Color(0xFFFF5C8A)],
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                data: actions[0],
                onTap: () => _comingSoon(context),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _QuickAction(
                data: actions[1],
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.w),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                data: actions[2],
                onTap: () => _comingSoon(context),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _QuickAction(
                data: actions[3],
                onTap: () => _comingSoon(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('loginComingSoon'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final List<Color> gradient;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.gradient,
  });
}

class _QuickAction extends StatelessWidget {
  final _QuickActionData data;
  final VoidCallback onTap;

  const _QuickAction({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : data.gradient.first.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 16.r,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.first.withValues(alpha: 0.4),
                    blurRadius: 16.r,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: 26.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}