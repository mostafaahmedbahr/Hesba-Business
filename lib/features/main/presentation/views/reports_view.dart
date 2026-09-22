import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../sales/data/models/sale_model.dart';
import '../../../returns/data/models/return_model.dart';

enum ReportPeriod { today, week, month, all }

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today: return 'اليوم';
      case ReportPeriod.week: return '7 أيام';
      case ReportPeriod.month: return '30 يوم';
      case ReportPeriod.all: return 'الكل';
    }
  }
  DateTime get start {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.today: return DateTime(now.year, now.month, now.day);
      case ReportPeriod.week: return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case ReportPeriod.month: return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      case ReportPeriod.all: return DateTime(2020, 1, 1);
    }
  }
  DateTime get end => DateTime.now();
}

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});
  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String? _shopId;
  bool _loadingShop = true;
  ReportPeriod _period = ReportPeriod.week;
  bool _loadingData = false;
  List<SaleModel> _sales = [];
  List<ReturnModel> _returns = [];
  List<ExpenseModel> _expenses = [];

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
    if (mounted) {
      setState(() => _loadingShop = false);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_shopId == null) return;
    setState(() => _loadingData = true);
    try {
      final salesSnap = await FirebaseFirestore.instance.collection(AppConstants.salesCollection).where('shopId', isEqualTo: _shopId).orderBy('createdAt', descending: true).limit(200).get();
      final returnsSnap = await FirebaseFirestore.instance.collection(AppConstants.returnsCollection).where('shopId', isEqualTo: _shopId).orderBy('createdAt', descending: true).limit(200).get();
      final expensesSnap = await FirebaseFirestore.instance.collection(AppConstants.expensesCollection).where('shopId', isEqualTo: _shopId).orderBy('createdAt', descending: true).limit(200).get();
      final sales = salesSnap.docs.map((d) => SaleModel.fromJson(d.data())).where((s) => s.createdAt.isAfter(_period.start.subtract(const Duration(seconds: 1))) && s.createdAt.isBefore(_period.end.add(const Duration(days: 1)))).toList();
      final returns = returnsSnap.docs.map((d) => ReturnModel.fromJson(d.data())).where((r) => r.createdAt.isAfter(_period.start.subtract(const Duration(seconds: 1))) && r.createdAt.isBefore(_period.end.add(const Duration(days: 1)))).toList();
      final expenses = expensesSnap.docs.map((d) => ExpenseModel.fromJson(d.data())).where((e) => e.date.isAfter(_period.start.subtract(const Duration(seconds: 1))) && e.date.isBefore(_period.end.add(const Duration(days: 1)))).toList();
      if (mounted) setState(() { _sales = sales; _returns = returns; _expenses = expenses; _loadingData = false; });
    } catch (e) {
      // fallback بدون فلتر shopId لو الـ index ناقص
      try {
        final salesSnap = await FirebaseFirestore.instance.collection(AppConstants.salesCollection).orderBy('createdAt', descending: true).limit(200).get();
        final returnsSnap = await FirebaseFirestore.instance.collection(AppConstants.returnsCollection).orderBy('createdAt', descending: true).limit(200).get();
        final expensesSnap = await FirebaseFirestore.instance.collection(AppConstants.expensesCollection).orderBy('createdAt', descending: true).limit(200).get();
        final sales = salesSnap.docs.map((d) => SaleModel.fromJson(d.data())).where((s) => s.shopId == _shopId && s.createdAt.isAfter(_period.start.subtract(const Duration(seconds: 1)))).toList();
        final returns = returnsSnap.docs.map((d) => ReturnModel.fromJson(d.data())).where((r) => r.shopId == _shopId && r.createdAt.isAfter(_period.start.subtract(const Duration(seconds: 1)))).toList();
        final expenses = expensesSnap.docs.map((d) => ExpenseModel.fromJson(d.data())).where((e) => e.shopId == _shopId && e.date.isAfter(_period.start.subtract(const Duration(seconds: 1)))).toList();
        if (mounted) setState(() { _sales = sales; _returns = returns; _expenses = expenses; _loadingData = false; });
      } catch (_) {
        if (mounted) setState(() => _loadingData = false);
      }
    }
  }

  void _changePeriod(ReportPeriod p) {
    HapticFeedback.selectionClick();
    setState(() => _period = p);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingShop) return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    if (_shopId == null) return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: Center(child: Text('لم يتم العثور على المتجر', style: TextStyle(color: isDark ? Colors.white : Colors.black))));

    final totalSales = _sales.fold<double>(0, (s, e) => s + e.total);
    final totalReturns = _returns.fold<double>(0, (s, e) => s + e.total);
    final totalExpenses = _expenses.fold<double>(0, (s, e) => s + e.amount);
    final netSales = totalSales - totalReturns;
    final balance = netSales - totalExpenses;
    final countSales = _sales.length;
    final countReturns = _returns.length;
    final countExpenses = _expenses.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, totalSales, netSales, totalReturns, totalExpenses, balance),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                child: _periodChips(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loadingData)
                    _shimmerGrid(isDark)
                  else ...[
                    _salesTrendCard(isDark),
                    SizedBox(height: 14.h),
                    _summaryGrid(totalSales, netSales, totalReturns, totalExpenses, balance, countSales, countReturns, countExpenses, isDark),
                    SizedBox(height: 14.h),
                    _balanceCard(netSales, totalSales, totalReturns, totalExpenses, balance, isDark),
                    SizedBox(height: 14.h),
                    _expensesPieCard(isDark),
                    SizedBox(height: 14.h),
                    _topProductsCard(isDark),
                    SizedBox(height: 14.h),
                    _recentActivityCard(isDark),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double totalSales, double netSales, double totalReturns, double totalExpenses, double balance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      Text('${_period.label} • ${_sales.length} عملية', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    ])),
                    Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Row(children: [Icon(Icons.auto_graph_rounded, size: 13.sp, color: AppTheme.primaryColor), SizedBox(width: 5.w), Text(balance >= 0 ? 'رابح' : 'خسارة', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48)))])),
                  ]),
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(child: _headerGlass(icon: Icons.trending_up_rounded, label: 'صافي المبيعات', value: '${_fmt(netSales)} ج.م')),
                    SizedBox(width: 10.w),
                    Expanded(child: _headerGlass(icon: Icons.account_balance_wallet_rounded, label: 'الرصيد الحالي', value: '${_fmt(balance)} ج.م', danger: balance < 0)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _headerGlass({required IconData icon, required String label, required String value, bool danger = false}) {
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

  Widget _periodChips() {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReportPeriod.values.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final p = ReportPeriod.values[i];
          final selected = p == _period;
          return ChoiceChip(
            label: Text(p.label, style: TextStyle(fontSize: 12.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
            selected: selected,
            onSelected: (_) => _changePeriod(p),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: selected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            showCheckmark: false,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            avatar: selected ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white) : null,
          );
        },
      ),
    );
  }

  Widget _summaryGrid(double totalSales, double netSales, double totalReturns, double totalExpenses, double balance, int cSales, int cReturns, int cExpenses, bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(icon: Icons.payments_rounded, label: 'إجمالي المبيعات', value: '${_fmt(totalSales)} ج.م', subtitle: '$cSales فاتورة', gradient: const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)], isDark: isDark)),
        SizedBox(width: 10.w),
        Expanded(child: _statCard(icon: Icons.trending_up_rounded, label: 'صافي المبيعات', value: '${_fmt(netSales)} ج.م', subtitle: 'بعد المرتجعات', gradient: const [Color(0xFF059669), Color(0xFF34D399)], isDark: isDark)),
      ]),
      SizedBox(height: 10.h),
      Row(children: [
        Expanded(child: _statCard(icon: Icons.assignment_return_rounded, label: 'المرتجعات', value: '${_fmt(totalReturns)} ج.م', subtitle: '$cReturns عملية', gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)], isDark: isDark, alert: cReturns > 0)),
        SizedBox(width: 10.w),
        Expanded(child: _statCard(icon: Icons.savings_rounded, label: 'المصروفات', value: '${_fmt(totalExpenses)} ج.م', subtitle: '$cExpenses مصروف', gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)], isDark: isDark)),
      ]),
    ]);
  }

  Widget _statCard({required IconData icon, required String label, required String value, required String subtitle, required List<Color> gradient, required bool isDark, bool alert = false}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38.w, height: 38.w, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(11.r)), child: Icon(icon, color: Colors.white, size: 18.sp)),
          const Spacer(),
          if (alert) Container(width: 8.w, height: 8.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE11D48))),
        ]),
        SizedBox(height: 12.h),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569))),
        Text(subtitle, style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _balanceCard(double netSales, double totalSales, double totalReturns, double totalExpenses, double balance, bool isDark) {
    final isNeg = balance < 0;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40.w, height: 40.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isNeg ? [const Color(0xFFE11D48), const Color(0xFFFB7185)] : [const Color(0xFF059669), const Color(0xFF34D399)]), borderRadius: BorderRadius.circular(11.r)), child: Icon(isNeg ? Icons.trending_down_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 20.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ملخص الفترة', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('${_period.label} • ${DateFormat('d MMM', 'ar').format(_period.start)} - ${DateFormat('d MMM', 'ar').format(_period.end)}', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: isNeg ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isNeg ? const Color(0xFFE11D48).withValues(alpha: 0.14) : const Color(0xFF059669).withValues(alpha: 0.14))), child: Text(isNeg ? 'عجز' : 'رابح', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isNeg ? const Color(0xFFE11D48) : const Color(0xFF059669)))),
        ]),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
          child: Column(children: [
            _rowMini('المبيعات', '+${_fmt(totalSales)}', const Color(0xFF1A4FD6), isDark),
            SizedBox(height: 8.h),
            _rowMini('المرتجعات', '-${_fmt(totalReturns)}', const Color(0xFFF59E0B), isDark),
            SizedBox(height: 8.h),
            _rowMini('المصروفات', '-${_fmt(totalExpenses)}', const Color(0xFFE11D48), isDark),
            Divider(height: 20.h, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('الرصيد النهائي', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text('${_fmt(balance)} ج.م', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: isNeg ? const Color(0xFFE11D48) : const Color(0xFF059669))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _rowMini(String label, String value, Color color, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Container(width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), SizedBox(width: 8.w), Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)))]),
      Text('$value ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: color)),
    ]);
  }

  Widget _salesTrendCard(bool isDark) {
    final days = _last7Days();
    final salesByDay = <String, double>{};
    for (final d in days) {
      final key = DateFormat('dd/MM', 'ar').format(d);
      salesByDay[key] = 0;
    }
    for (final s in _sales) {
      final key = DateFormat('dd/MM', 'ar').format(s.createdAt);
      if (salesByDay.containsKey(key)) salesByDay[key] = (salesByDay[key] ?? 0) + s.total;
    }
    final spots = <FlSpot>[];
    final labels = salesByDay.keys.toList();
    double maxY = 0;
    for (int i = 0; i < labels.length; i++) {
      final v = salesByDay[labels[i]] ?? 0;
      if (v > maxY) maxY = v;
      spots.add(FlSpot(i.toDouble(), v));
    }
    if (maxY == 0) maxY = 100;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A4FD6), Color(0xFF4A7BFF)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.show_chart_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اتجاه المبيعات', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text('آخر 7 أيام', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20.r)), child: Text('${_sales.length} عملية', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669)))),
        ]),
        SizedBox(height: 16.h),
        SizedBox(
          height: 160.h,
          child: spots.every((s) => s.y == 0)
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bar_chart_rounded, size: 32.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مبيعات في هذه الفترة', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))]))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: maxY / 4, verticalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9), strokeWidth: 1), getDrawingVerticalLine: (v) => FlLine(color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : const Color(0xFFF8FAFC), strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, meta) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return SideTitleWidget(meta: meta, child: Text(labels[i], style: TextStyle(fontSize: 9.sp, color: const Color(0xFF94A3B8)))) ;})),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, interval: maxY / 4, getTitlesWidget: (v, meta) => Text(_fmtCompact(v), style: TextStyle(fontSize: 9.sp, color: const Color(0xFF94A3B8))))),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0, maxX: (labels.length - 1).toDouble(), minY: 0, maxY: maxY * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: AppTheme.primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppTheme.primaryColor)),
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.18), AppTheme.primaryColor.withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      ),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _expensesPieCard(bool isDark) {
    final byCat = <String, double>{};
    for (final e in _expenses) byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    final total = byCat.values.fold<double>(0, (s, v) => s + v);
    final colors = [const Color(0xFFE11D48), const Color(0xFF2563EB), const Color(0xFFF59E0B), const Color(0xFF059669), const Color(0xFF7C3AED), const Color(0xFF06B6D4)];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFFB7185)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المصروفات حسب التصنيف', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(total == 0 ? 'لا توجد مصروفات' : 'إجمالي ${_fmt(total)} ج.م', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
          ])),
        ]),
        SizedBox(height: 16.h),
        if (byCat.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.h), child: Column(children: [Icon(Icons.donut_large_rounded, size: 36.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مصروفات في هذه الفترة', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))])))
        else
          Row(children: [
            SizedBox(
              width: 140.w, height: 140.w,
              child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42.r,
                sections: List.generate(byCat.length, (i) {
                  final entry = byCat.entries.elementAt(i);
                  final pct = total == 0 ? 0 : entry.value / total * 100;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entry.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 22.r,
                    titleStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  );
                }),
              )),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                children: List.generate(byCat.length, (i) {
                  final entry = byCat.entries.elementAt(i);
                  final pct = total == 0 ? 0 : entry.value / total * 100;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(children: [
                      Container(width: 10.w, height: 10.w, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i % colors.length])),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(entry.key, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF334155)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${_fmt(entry.value)}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      SizedBox(width: 4.w),
                      Text('(${pct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                    ]),
                  );
                }),
              ),
            ),
          ]),
      ]),
    );
  }

  Widget _topProductsCard(bool isDark) {
    final productQty = <String, double>{};
    final productRevenue = <String, double>{};
    for (final s in _sales) {
      for (final it in s.items) {
        productQty[it.productName] = (productQty[it.productName] ?? 0) + it.quantity;
        productRevenue[it.productName] = (productRevenue[it.productName] ?? 0) + it.total;
      }
    }
    final sorted = productQty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.star_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Text('الأكثر مبيعاً', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const Spacer(),
          Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20.r)), child: Text('${top.length} منتج', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)))),
        ]),
        SizedBox(height: 14.h),
        if (top.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.h), child: Column(children: [Icon(Icons.inventory_2_outlined, size: 32.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مبيعات', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))])))
        else
          Column(
            children: List.generate(top.length, (i) {
              final e = top[i];
              final rev = productRevenue[e.key] ?? 0;
              return Container(
                margin: EdgeInsets.only(bottom: i == top.length - 1 ? 0 : 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Container(width: 32.w, height: 32.w, decoration: BoxDecoration(gradient: LinearGradient(colors: i == 0 ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)] : [const Color(0xFF64748B), const Color(0xFF94A3B8)]), shape: BoxShape.circle), child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white)))),
                  SizedBox(width: 10.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    Text('${_fmt(rev)} ج.م • ${e.value.toStringAsFixed(e.value % 1 == 0 ? 0 : 1)} قطعة', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
                  ])),
                  Icon(Icons.trending_up_rounded, size: 16.sp, color: const Color(0xFF059669)),
                ]),
              );
            }),
          ),
      ]),
    );
  }

  Widget _recentActivityCard(bool isDark) {
    final all = <Map<String, dynamic>>[];
    for (final s in _sales.take(3)) all.add({'type': 'sale', 'title': s.items.isEmpty ? 'فاتورة' : s.items.first.productName, 'amount': s.total, 'date': s.createdAt, 'color': const Color(0xFF059669), 'icon': Icons.point_of_sale_rounded});
    for (final r in _returns.take(2)) all.add({'type': 'return', 'title': r.items.isEmpty ? r.reason : r.items.first.productName, 'amount': -r.total, 'date': r.createdAt, 'color': const Color(0xFFF59E0B), 'icon': Icons.assignment_return_rounded});
    for (final e in _expenses.take(2)) all.add({'type': 'expense', 'title': e.title, 'amount': -e.amount, 'date': e.date, 'color': const Color(0xFFE11D48), 'icon': Icons.savings_rounded});
    all.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recent = all.take(5).toList();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.history_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Text('آخر الحركات', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ]),
        SizedBox(height: 14.h),
        if (recent.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.h), child: Text('لا توجد حركات', style: TextStyle(color: const Color(0xFF94A3B8)))))
        else
          Column(
            children: recent.map((m) => Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                  child: Row(children: [
                    Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: (m['color'] as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)), child: Icon(m['icon'] as IconData, size: 16.sp, color: m['color'] as Color)),
                    SizedBox(width: 10.w),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      Text(DateFormat('dd MMM • hh:mm a', 'ar').format(m['date'] as DateTime), style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                    ])),
                    Text('${(m['amount'] as double) >= 0 ? '+' : ''}${_fmt(m['amount'] as double)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: (m['amount'] as double) >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                  ]),
                )).toList(),
          ),
      ]),
    );
  }

  Widget _shimmerGrid(bool isDark) {
    return Column(children: [
      Row(children: [Expanded(child: _shimmerBox(90.h, isDark)), SizedBox(width: 10.w), Expanded(child: _shimmerBox(90.h, isDark))]),
      SizedBox(height: 10.h),
      Row(children: [Expanded(child: _shimmerBox(90.h, isDark)), SizedBox(width: 10.w), Expanded(child: _shimmerBox(90.h, isDark))]),
      SizedBox(height: 14.h),
      _shimmerBox(120.h, isDark),
      SizedBox(height: 14.h),
      _shimmerBox(180.h, isDark),
    ]);
  }

  Widget _shimmerBox(double h, bool isDark) => Container(height: h, decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(18.r)));

  List<DateTime> _last7Days() => List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  String _fmtCompact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return v.toInt().toString();
  }
}
