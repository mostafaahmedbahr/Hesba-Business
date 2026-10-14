import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/data/repos/dashboard_repo.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/views/expenses_view.dart';
import '../../../returns/data/models/return_model.dart';
import '../../../sales/data/models/sale_model.dart';

/// "آخر الحركات" section of the home page (last sale / return / expense).
///
/// Extracted from `home_view.dart`: owns its shopId lookup, its three
/// Firestore streams (via [DashboardRepo]) and its own loading/empty states,
/// so the dashboard page stays a thin composition layer.
class RecentMovementsSection extends StatefulWidget {
  final void Function(int index)? onNavigateTab;
  const RecentMovementsSection({this.onNavigateTab});
  @override
  State<RecentMovementsSection> createState() => RecentMovementsSectionState();
}

class RecentMovementsSectionState extends State<RecentMovementsSection> {
  String? _shopId;
  bool _loadingShop = true;

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    try {
      _shopId = await sl<DashboardRepo>().getShopId();
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
            Text('homeRecentTitle'.tr(),
                style: TextStyle(fontSize: 15.5.sp, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Text('homeToday'.tr(), style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
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
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
      child: Center(child: SizedBox(width: 22.w, height: 22.w, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.primaryColor))),
    )));
  }

  Widget _emptyShop(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
      child: Row(children: [
        Icon(Icons.store_outlined, color: Colors.grey.shade400),
        SizedBox(width: 10.w),
        Expanded(child: Text('homeNoShop'.tr(), style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600))),
      ]),
    );
  }
}

class _LastSaleCard extends StatefulWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastSaleCard({required this.shopId, this.onNavigateTab});

  @override
  State<_LastSaleCard> createState() => _LastSaleCardState();
}

class _LastSaleCardState extends State<_LastSaleCard> {
  // Created once: dashboard ticks rebuild the page but must NOT resubscribe.
  late final Stream<SaleModel?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = sl<DashboardRepo>().watchLastSale(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<SaleModel?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, AppTheme.primaryColor);
        }
        final sale = snap.data;
        if (sale == null) {
          return RecentEmpty(
            isDark: isDark,
            icon: Icons.point_of_sale_rounded,
            gradient: const [AppTheme.primaryColor, AppTheme.brightBlue],
            title: 'homeLastSale'.tr(),
            subtitle: 'homeNoSalesToday'.tr(),
            actionLabel: 'homeNewSale'.tr(),
            onTap: () async {
              if (!await SubscriptionGate.ensureCanModify(context)) return;
              if (!context.mounted) return;
              Navigator.pushNamed(context, AppRoutes.addSaleView);
            },
          );
        }
        final time = _timeAgo(sale.createdAt, context.locale.languageCode);
        return recentCard(
          isDark: isDark,
          icon: Icons.point_of_sale_rounded,
          gradient: const [AppTheme.primaryColor, AppTheme.brightBlue],
          title: 'homeLastSale'.tr(),
          subtitle: sale.items.isEmpty ? _shortInvoiceId(sale.saleId) : '${sale.items.first.productName}${sale.items.length > 1 ? ' +${sale.items.length - 1}' : ''}',
          time: time,
          amount: '+${_fmt(sale.total)} ${'currencyEGP'.tr()}',
          amountColor: AppTheme.successDark,
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.onNavigateTab != null) { widget.onNavigateTab!(2); } else { Navigator.pushNamed(context, AppRoutes.dashboard, arguments: {'initialTab': 2}); }
          },
        );
      },
    );
  }
}

class _LastReturnCard extends StatefulWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastReturnCard({required this.shopId, this.onNavigateTab});

  @override
  State<_LastReturnCard> createState() => _LastReturnCardState();
}

class _LastReturnCardState extends State<_LastReturnCard> {
  // Created once: dashboard ticks rebuild the page but must NOT resubscribe.
  late final Stream<ReturnModel?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = sl<DashboardRepo>().watchLastReturn(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<ReturnModel?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, AppTheme.warningAmber);
        }
        final ret = snap.data;
        if (ret == null) {
          return RecentEmpty(
            isDark: isDark,
            icon: Icons.assignment_return_rounded,
            gradient: const [AppTheme.warningAmber, AppTheme.goldLight],
            title: 'homeLastReturn'.tr(),
            subtitle: 'homeNoReturnsToday'.tr(),
            actionLabel: 'homeAddReturn'.tr(),
              onTap: () {
                if (widget.onNavigateTab != null) { widget.onNavigateTab!(3); } else { Navigator.pushNamed(context, AppRoutes.returnsView); }
              },
          );
        }
        final time = _timeAgo(ret.createdAt, context.locale.languageCode);
        return recentCard(
          isDark: isDark,
          icon: Icons.assignment_return_rounded,
          gradient: const [AppTheme.warningAmber, AppTheme.goldLight],
          title: 'homeLastReturn'.tr(),
          subtitle: ret.items.isEmpty ? (ret.reason.isEmpty ? 'homeReturnFallback'.tr() : ret.reason) : '${ret.items.first.productName}${ret.items.length > 1 ? ' +${ret.items.length - 1}' : ''}',
          time: time,
          amount: '-${_fmt(ret.total)} ${'currencyEGP'.tr()}',
          amountColor: AppTheme.danger,
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.onNavigateTab != null) { widget.onNavigateTab!(3); } else { Navigator.pushNamed(context, AppRoutes.returnsView); }
          },
        );
      },
    );
  }
}

class _LastExpenseCard extends StatefulWidget {
  final String shopId;
  final void Function(int index)? onNavigateTab;
  const _LastExpenseCard({required this.shopId, this.onNavigateTab});

  @override
  State<_LastExpenseCard> createState() => _LastExpenseCardState();
}

class _LastExpenseCardState extends State<_LastExpenseCard> {
  // Created once: dashboard ticks rebuild the page but must NOT resubscribe.
  late final Stream<ExpenseModel?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = sl<DashboardRepo>().watchLastExpense(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<ExpenseModel?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _recentSkeleton(isDark, AppTheme.danger);
        }
        final exp = snap.data;
        if (exp == null) {
          return RecentEmpty(
            isDark: isDark,
            icon: Icons.savings_rounded,
            gradient: const [AppTheme.danger, AppTheme.roseLight],
            title: 'homeLastExpense'.tr(),
            subtitle: 'homeNoExpensesToday'.tr(),
            actionLabel: 'homeAddExpense'.tr(),
            onTap: () {
              if (widget.onNavigateTab != null) { widget.onNavigateTab!(5); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesView(shopId: widget.shopId))); }
            },
          );
        }
        final time = _timeAgo(exp.date, context.locale.languageCode);
        return recentCard(
          isDark: isDark,
          icon: Icons.savings_rounded,
          gradient: const [AppTheme.danger, AppTheme.roseLight],
          title: 'homeLastExpense'.tr(),
          subtitle: exp.title.isEmpty ? exp.category : exp.title,
          time: time,
          amount: '-${_fmt(exp.amount)} ${'currencyEGP'.tr()}',
          amountColor: AppTheme.danger,
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.onNavigateTab != null) { widget.onNavigateTab!(5); } else { Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesView(shopId: widget.shopId))); }
          },
        );
      },
    );
  }
}

Widget recentCard({
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
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
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
                Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray)),
                SizedBox(height: 2.h),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.ink)),
                SizedBox(height: 2.h),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 11.sp, color: AppTheme.mutedGray),
                  SizedBox(width: 4.w),
                  Text(time, style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray)),
                ]),
              ]),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: amountColor)),
                SizedBox(height: 4.h),
                Icon(Icons.chevron_left_rounded, size: 18.sp, color: AppTheme.paleSlate),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class RecentEmpty extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  const RecentEmpty({required this.isDark, required this.icon, required this.gradient, required this.title, required this.subtitle, required this.actionLabel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline, style: BorderStyle.solid),
      ),
      child: Row(children: [
        Container(width: 46.w, height: 46.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(13.r)), child: Icon(icon, color: Colors.white, size: 22.sp)),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.slateGray)),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : AppTheme.mutedGray)),
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
    decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
    child: Center(child: SizedBox(width: 18.w, height: 18.w, child: CircularProgressIndicator(strokeWidth: 2.2, color: accent))),
  );
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

/// Short invoice label that never throws on short ids.
String _shortInvoiceId(String saleId) {
  final short = saleId.length > 6 ? saleId.substring(0, 6) : saleId;
  return 'homeInvoiceNumber'.tr(namedArgs: {'id': short});
}

/// Arabic plural rules (1/2/3-10/11+) with English fallbacks.
String _ago(int n, String one, String two, String few, String many) {
  if (n == 1) return one.tr();
  if (n == 2) return two.tr();
  if (n <= 10) return few.tr(namedArgs: {'n': '$n'});
  return many.tr(namedArgs: {'n': '$n'});
}

String _timeAgo(DateTime dt, String locale) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'timeNow'.tr();
  if (diff.inMinutes < 60) {
    return _ago(diff.inMinutes, 'timeMinuteAgo', 'timeTwoMinutesAgo',
        'timeMinutesAgo', 'timeMinutesManyAgo');
  }
  if (diff.inHours < 24) {
    return _ago(diff.inHours, 'timeHourAgo', 'timeTwoHoursAgo',
        'timeHoursAgo', 'timeHoursManyAgo');
  }
  if (diff.inDays == 1) return 'timeYesterday'.tr();
  if (diff.inDays < 7) {
    if (diff.inDays == 2) return 'timeTwoDaysAgo'.tr();
    return 'timeDaysAgo'.tr(namedArgs: {'n': '${diff.inDays}'});
  }
  return DateFormat('d MMM', locale).format(dt);
}
