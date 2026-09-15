import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../sales/data/models/sale_model.dart';
import '../widgets/main_app_bar.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
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

  Future<void> _goToAddSale() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addSaleView);
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
      appBar: MainAppBar(title: 'navSales'.tr()),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_fab',
        onPressed: _goToAddSale,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('بيع جديد', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
      body: _loadingShop
          ? const Center(child: CircularProgressIndicator())
          : _shopId == null
              ? _EmptyState(
                  onAdd: _goToAddSale,
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.salesCollection)
                      .where('shopId', isEqualTo: _shopId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('حدث خطأ: ${snap.error}'));
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _EmptyState(
                        onAdd: _goToAddSale,
                      );
                    }
                    final sales = docs.map((d) => SaleModel.fromJson(d.data())).toList();
                    return RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, i) => _SaleCard(sale: sales[i]),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy  hh:mm a', 'ar').format(sale.createdAt);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.receipt_long_rounded, size: 18.sp, color: AppTheme.primaryColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فاتورة #${sale.saleId.substring(0, 6)}',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
                    Text(dateStr, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text('${sale.total.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppTheme.successColor)),
              ),
            ],
          ),
          if (sale.items.isNotEmpty) ...[
            Divider(height: 20.h),
            ...sale.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}',
                              style: TextStyle(fontSize: 12.sp))),
                      Text('${it.total.toStringAsFixed(2)} ج.م',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            if (sale.discount > 0) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('قبل الخصم', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
                    Text('${sale.subtotal.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, decoration: TextDecoration.lineThrough)),
                  ]),
                  SizedBox(height: 4.h),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('الخصم', style: TextStyle(fontSize: 11.sp, color: Colors.red.shade600)),
                    Text('-${sale.discount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
                  ]),
                  Divider(height: 12.h),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('المدفوع (دخل حسابك)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                    Text('${sale.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppTheme.successColor)),
                  ]),
                ]),
              ),
            ],
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              _paymentChip(sale.paymentMethod),
              const Spacer(),
              if (sale.discount > 0)
                Text('خصم ${sale.discount.toStringAsFixed(0)} ج.م',
                    style: TextStyle(fontSize: 11.sp, color: Colors.red.shade600)),
            ],
          ),
          if (sale.note.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text('ملاحظة: ${sale.note}', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
          ],
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.addReturnView,
                  arguments: {'originalSaleId': sale.saleId},
                );
              },
              icon: Icon(Icons.assignment_return_rounded, size: 16.sp, color: Colors.orange.shade700),
              label: Text('إرجاع من هذه الفاتورة', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.shade300),
                backgroundColor: Colors.orange.withValues(alpha: 0.06),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _paymentChip(String method) {
    String label;
    IconData icon;
    switch (method) {
      case 'cash':
        label = 'نقدي';
        icon = Icons.money_rounded;
        break;
      case 'card':
        label = 'بطاقة';
        icon = Icons.credit_card_rounded;
        break;
      case 'mobile_wallet':
      case 'wallet':
        label = 'محفظة';
        icon = Icons.account_balance_wallet_rounded;
        break;
      default:
        label = method;
        icon = Icons.payment_rounded;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.grey.shade700),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700)),
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
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 48.sp, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 16.h),
            Text('لا توجد مبيعات بعد',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text('ابدأ بتسجيل أول عملية بيع وتابع أرباحك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة بيع جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
