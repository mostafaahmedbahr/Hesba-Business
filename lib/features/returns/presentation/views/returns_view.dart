import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../data/models/return_model.dart';

class ReturnsView extends StatefulWidget {
  const ReturnsView({super.key});
  @override
  State<ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<ReturnsView> {
  String? _shopId;
  bool _loadingShop = true;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filterReason = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _goToAddReturn() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.pushNamed(context, AppRoutes.addReturnView);
    if (mounted) setState(() {});
    if (result == true && mounted) { try { context.read<DashboardCubit>().refresh(); } catch (_) {} }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingShop) return const _LoadingView();
    if (_shopId == null) return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: _EmptyState(onAdd: _goToAddReturn));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'returns_fab',
        onPressed: _goToAddReturn,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('مرتجع جديد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
      ).animate().scale(delay: 400.ms),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.returnsCollection)
            .where('shopId', isEqualTo: _shopId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const _LoadingView();
          if (snap.hasError) return _buildError(context, '${snap.error}');
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return _EmptyStateScaffold(onAdd: _goToAddReturn);

          final rets = docs.map((d) => ReturnModel.fromJson(d.data())).toList();
          double totalValue = 0;
          for (final r in rets) totalValue += r.total;
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayRets = rets.where((r) => r.createdAt.isAfter(todayStart)).toList();
          final todayValue = todayRets.fold<double>(0, (s, r) => s + r.total);

          final q = _query.trim().toLowerCase();
          final filtered = rets.where((r) {
            final matchesSearch = q.isEmpty ||
                r.returnId.toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.items.any((it) => it.productName.toLowerCase().contains(q));
            final matchesReason = _filterReason == 'الكل' || r.reason == _filterReason;
            return matchesSearch && matchesReason;
          }).toList();

          final reasons = <String>{'الكل'};
          for (final r in rets) if (r.reason.isNotEmpty) reasons.add(r.reason);

          return CustomScrollView(
            slivers: [
              _buildHeader(context, rets.length, totalValue, todayRets.length, todayValue, onAdd: _goToAddReturn),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        style: TextStyle(fontSize: 13.5.sp),
                        decoration: InputDecoration(
                          hintText: 'ابحث بكود المرتجع أو المنتج أو السبب',
                          hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.search_rounded, size: 18.sp, color: const Color(0xFFD97706))),
                          suffixIcon: _query.isEmpty ? null : IconButton(icon: Icon(Icons.close_rounded, size: 18.sp), onPressed: () { _searchController.clear(); setState(() => _query = ''); }),
                          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: reasons.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, i) {
                          final reason = reasons.elementAt(i);
                          final selected = reason == _filterReason;
                          return ChoiceChip(
                            label: Text(reason, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
                            selected: selected,
                            onSelected: (_) => setState(() => _filterReason = reason),
                            selectedColor: const Color(0xFFF59E0B),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            side: BorderSide(color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                            showCheckmark: false,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
              // زر إضافة فاتورة مرتجع جديدة بارز
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: _AddReturnCTA(onTap: _goToAddReturn),
                ),
              ),
              if (filtered.isEmpty)
                SliverToBoxAdapter(child: _buildNoResults(context))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) => _ReturnCard(ret: filtered[index]).animate(delay: (40 * index).ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count, double totalValue, int todayCount, double todayValue, {VoidCallback? onAdd}) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 192.h,
      backgroundColor: const Color(0xFFF59E0B),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      title: count > 0
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Text('navReturns'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 8.w),
              Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Text('$count', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309)))),
            ])
          : Text('navReturns'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFBBF24)])),
          child: Stack(children: [
            Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Flexible(child: Text('navReturns'.tr(), style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 20.w, height: 20.w, decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle), child: Icon(Icons.numbers_rounded, size: 11.sp, color: Colors.white)),
                            SizedBox(width: 6.w),
                            Text('$count', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFB45309))),
                          ]),
                        ),
                      ]),
                      SizedBox(height: 4.h),
                      Text(count == 0 ? 'لا يوجد مرتجعات' : '$count مرتجع • إجمالي ${_fmt(totalValue)} ${'currencyEGP'.tr()}', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    SizedBox(width: 10.w),
                    if (onAdd != null)
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13.r),
                        elevation: 0,
                        child: InkWell(
                          onTap: () { HapticFeedback.lightImpact(); onAdd(); },
                          borderRadius: BorderRadius.circular(13.r),
                          child: Container(
                            width: 42.w, height: 42.w,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(13.r)),
                            child: Icon(Icons.add_rounded, size: 22.sp, color: const Color(0xFFD97706)),
                          ),
                        ),
                      ),
                  ])),
                  SizedBox(height: 10.h),
                  Row(children: [
                    Expanded(child: _headerGlass(icon: Icons.payments_rounded, label: 'إجمالي المرتجعات', value: '${_fmt(totalValue)} ${'currencyEGP'.tr()}')),
                    SizedBox(width: 10.w),
                    Expanded(child: _headerGlass(icon: Icons.today_rounded, label: 'مرتجعات اليوم', value: todayCount > 0 ? '$todayCount • ${_fmt(todayValue)}' : '0', danger: todayCount > 0)),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: danger ? const Color(0xFFFFF3B0) : Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: danger ? const Color(0xFFFFF3B0) : Colors.white)),
        ])),
      ]),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: const Color(0xFFFB923C))),
        SizedBox(height: 12.h),
        Text('لا توجد نتائج', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _buildError(BuildContext context, String err) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Container(padding: EdgeInsets.all(22.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.error_outline_rounded, size: 28.sp, color: const Color(0xFFE11D48))),
      SizedBox(height: 12.h),
      Text('حدث خطأ: $err', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
    ]))));
  }
}

class _AddReturnCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _AddReturnCTA({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.28), width: 1.2),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFFFFBEB), isDark ? AppTheme.darkSurface : Colors.white]),
            boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(width: 48.w, height: 48.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(14.r), boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(Icons.add_rounded, size: 24.sp, color: Colors.white)),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إضافة فاتورة مرتجع جديدة', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              SizedBox(height: 3.h),
              Text('سجل مرتجع جديد وسيتم تحديث المخزون تلقائياً', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ])),
            Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: const Color(0xFFFEF3C7), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 16.sp, color: const Color(0xFFD97706))),
          ]),
        ),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnModel ret;
  const _ReturnCard({required this.ret});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy  hh:mm a', 'ar').format(ret.createdAt);
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () { HapticFeedback.selectionClick(); },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44.w, height: 44.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.assignment_return_rounded, size: 20.sp, color: Colors.white)),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مرتجع #${ret.returnId.length >= 6 ? ret.returnId.substring(0, 6) : ret.returnId}', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                SizedBox(height: 2.h),
                Row(children: [Icon(Icons.access_time_rounded, size: 11.sp, color: const Color(0xFF94A3B8)), SizedBox(width: 4.w), Text(dateStr, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)))]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.14))), child: Text('-${ret.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48)))),
                if (ret.discount > 0) Padding(padding: EdgeInsets.only(top: 4.h), child: Text('قبل ${ret.subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8), decoration: TextDecoration.lineThrough))),
              ]),
            ]),
            if (ret.items.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9)),
              SizedBox(height: 10.h),
              ...ret.items.map((it) => Padding(padding: EdgeInsets.only(bottom: 6.h), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Row(children: [Container(width: 6.w, height: 6.w, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF59E0B))), SizedBox(width: 8.w), Expanded(child: Text('${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis))])),
                Text('${it.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              ]))),
              if (ret.discount > 0) ...[
                SizedBox(height: 8.h),
                Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))), child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('قبل الخصم', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))), Text('${ret.subtotal.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, decoration: TextDecoration.lineThrough, color: const Color(0xFF64748B)))]),
                  SizedBox(height: 6.h),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('حصة الخصم', style: TextStyle(fontSize: 11.sp, color: const Color(0xFFE11D48))), Text('-${ret.discount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFE11D48)))]),
                  Divider(height: 16.h, color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('المسترد', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))), Text('${ret.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFFF59E0B)))]),
                ])),
              ],
            ],
            SizedBox(height: 12.h),
            Wrap(spacing: 8.w, runSpacing: 6.h, children: [
              Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFFDBA74))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info_outline_rounded, size: 12.sp, color: const Color(0xFFD97706)), SizedBox(width: 5.w), Text(ret.reason, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)))])),
              if (ret.originalSaleId != null) Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFBFDBFE))), child: Text('مرتبط بفاتورة', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF2563EB)))),
            ]),
            if (ret.note.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(width: double.infinity, padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12.r)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.notes_rounded, size: 14.sp, color: const Color(0xFF94A3B8)), SizedBox(width: 6.w), Expanded(child: Text(ret.note, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))))])),
            ],
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 96.w, height: 96.w, decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withValues(alpha: 0.16), const Color(0xFFFBBF24).withValues(alpha: 0.16)]), shape: BoxShape.circle), child: Icon(Icons.assignment_return_rounded, size: 44.sp, color: const Color(0xFFD97706))),
      SizedBox(height: 16.h),
      Text('لا توجد مرتجعات بعد', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      SizedBox(height: 8.h),
      Text('سجل أول مرتجع وسيتم تحديث المخزون وصافي المبيعات تلقائياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.5)),
      SizedBox(height: 20.h),
      SizedBox(width: double.infinity, height: 50.h, child: FilledButton.icon(onPressed: onAdd, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))), icon: const Icon(Icons.add_rounded), label: Text('إضافة مرتجع', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800)))),
    ])));
  }
}

class _EmptyStateScaffold extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyStateScaffold({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      _HeaderEmpty(onAdd: onAdd),
      SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onAdd: onAdd)),
    ]);
  }
}

class _HeaderEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const _HeaderEmpty({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 192.h,
      backgroundColor: const Color(0xFFF59E0B),
      flexibleSpace: FlexibleSpaceBar(background: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFBBF24)])), child: SafeArea(bottom: false, child: Padding(padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
        Row(children: [
          Expanded(child: Text('navReturns'.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white))),
          Material(color: Colors.white, borderRadius: BorderRadius.circular(12.r), child: InkWell(onTap: onAdd, borderRadius: BorderRadius.circular(12.r), child: Container(width: 36.w, height: 36.w, child: Icon(Icons.add_rounded, color: const Color(0xFFD97706))))),
        ]),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(child: _HeaderGlassEmpty(icon: Icons.payments_rounded, label: 'إجمالي المرتجعات', value: '0 ج.م')),
          SizedBox(width: 10.w),
          Expanded(child: _HeaderGlassEmpty(icon: Icons.today_rounded, label: 'مرتجعات اليوم', value: '0')),
        ]),
      ]))))),
    );
  }
}

Widget _HeaderGlassEmpty({required IconData icon, required String label, required String value}) {
  return Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))), child: Row(children: [Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: Colors.white)), SizedBox(width: 8.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600)), Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white))]))]));
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 36.w, height: 36.w, child: CircularProgressIndicator(strokeWidth: 3, color: const Color(0xFFF59E0B))), SizedBox(height: 12.h), Text('جاري تحميل المرتجعات...', style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
