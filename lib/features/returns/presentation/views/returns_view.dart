import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../data/models/return_model.dart';
import '../cubit/returns_cubit.dart';

class ReturnsView extends StatefulWidget {
  const ReturnsView({super.key});

  @override
  State<ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<ReturnsView> {
  String? _shopId;
  bool _loadingShop = true;

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  Future<void> _loadShopId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingShop = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _shopId = doc.data()?['shopId'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loadingShop = false);
  }

  Future<void> _goToAddReturn() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addReturnView);
    if (mounted) setState(() {});
    if (result == true && mounted) {
      try {
        context.read<DashboardCubit>().refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('navReturns'.tr()),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'returns_fab',
        onPressed: _goToAddReturn,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_return_rounded),
        label: Text('مرتجع جديد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
      body: _loadingShop
          ? const Center(child: CircularProgressIndicator())
          : _shopId == null
              ? _EmptyState(onAdd: _goToAddReturn)
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.returnsCollection)
                      .where('shopId', isEqualTo: _shopId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) return Center(child: Text('حدث خطأ: ${snap.error}'));
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return _EmptyState(onAdd: _goToAddReturn);
                    final rets = docs.map((d) => ReturnModel.fromJson(d.data())).toList();
                    return RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                        itemCount: rets.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, i) => _ReturnCard(ret: rets[i]),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnModel ret;
  const _ReturnCard({required this.ret});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy  hh:mm a', 'ar').format(ret.createdAt);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
                child: Icon(Icons.assignment_return_rounded, size: 18.sp, color: Colors.orange.shade700),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرتجع #${ret.returnId.substring(0, 6)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
                    Text(dateStr, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20.r)),
                    child: Text('${ret.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.orange.shade700)),
                  ),
                  if (ret.discount > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('قبل الخصم ${ret.subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
                    ),
                ],
              ),
            ],
          ),
          if (ret.items.isNotEmpty) ...[
            Divider(height: 20.h),
            ...ret.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}', style: TextStyle(fontSize: 12.sp))),
                      Text('${it.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            if (ret.discount > 0) ...[
              SizedBox(height: 6.h),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('قبل الخصم', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                Text('${ret.subtotal.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, decoration: TextDecoration.lineThrough)),
              ]),
              SizedBox(height: 2.h),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('حصة الخصم', style: TextStyle(fontSize: 11.sp, color: Colors.red.shade600)),
                Text('-${ret.discount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
              ]),
              Divider(height: 12.h),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('المسترد', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                Text('${ret.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.orange.shade700)),
              ]),
            ],
          ],
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20.r)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline_rounded, size: 12.sp, color: Colors.grey.shade700),
              SizedBox(width: 4.w),
              Text(ret.reason, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
            ]),
          ),
          if (ret.note.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text('ملاحظة: ${ret.note}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
          ]
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.assignment_return_rounded, size: 48.sp, color: Colors.orange.shade700),
            ),
            SizedBox(height: 16.h),
            Text('لا توجد مرتجعات بعد', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text('سجل أول مرتجع وسيتم تحديث المخزون وصافي المبيعات تلقائياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مرتجع'),
            ),
          ],
        ),
      ),
    );
  }
}
