import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/views/change_password_view.dart';
import '../../../expenses/presentation/views/add_expense_view.dart';
import '../../../returns/presentation/views/add_return_view.dart';
import '../../../sales/presentation/views/add_sale_view.dart';
import '../../../products/presentation/views/add_stock_purchase_view.dart';

/// الواجهة الوحidade التي يراها الحساب الفرعي. لا تحتوي على أي من
/// تقارير أو أرباح أو بيانات — أربع عمليات إدخال فقط.
class StaffHomeView extends StatelessWidget {
  const StaffHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>()),
      child: const _StaffHomeBody(),
    );
  }
}

class _StaffHomeBody extends StatefulWidget {
  const _StaffHomeBody();

  @override
  State<_StaffHomeBody> createState() => _StaffHomeBodyState();
}

class _StaffHomeBodyState extends State<_StaffHomeBody> {
  @override
  void initState() {
    super.initState();
    _verifyActive();
  }

  /// الحساب الموقوف يُطرد فورًا حتى لو كانت جلسة الدخول ما زالت صالحة.
  Future<void> _verifyActive() async {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await sl<AccountRepo>().getStaffActiveState(uid);
      if (doc == false && mounted) {
        AppToast.warning(context, 'تم إيقاف هذا الحساب');
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        await sl<AccountRepo>().logout();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      }
    } catch (_) {}
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<FirebaseAuth>().currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();
    final label = displayName.isNotEmpty ? displayName : email;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('لوحة الموظف'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'تشخيص الصلاحيات',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: _showDiagnostics,
          ),
          IconButton(
            tooltip: 'تغيير كلمة المرور',
            icon: const Icon(Icons.lock_reset_outlined),
            onPressed: () => _open(context, const ChangePasswordView()),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A1F5C), AppTheme.primaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.badge_outlined, color: Colors.white.withValues(alpha: 0.9), size: 34.sp),
                  SizedBox(height: 12.h),
                  Text(
                    'مرحبًا${label.isEmpty ? '' : '، $label'}',
                    style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'يمكنك تسجيل عمليات البيع والشراء والمرتجع والمصروفات فقط.',
                    style: TextStyle(fontSize: 12.5.sp, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text('العمليات المسموحة',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 12.h),
            _ActionCard(
              icon: Icons.point_of_sale_rounded,
              color: AppTheme.primaryColor,
              title: 'بيع جديد',
              subtitle: 'تسجيل فاتورة بيع',
              onTap: () => _open(context, const AddSaleView(restricted: true)),
            ),
            _ActionCard(
              icon: Icons.inventory_2_outlined,
              color: AppTheme.successDark,
              title: 'شراء مخزون',
              subtitle: 'تسجيل فاتورة شراء وتحديث المخزون',
              onTap: () => _open(context, const AddStockPurchaseView(restricted: true)),
            ),
            _ActionCard(
              icon: Icons.assignment_return_outlined,
              color: AppTheme.warningAmber,
              title: 'مرتجع جديد',
              subtitle: 'تسجيل مرتجع على فاتورة',
              onTap: () => _open(context, const AddReturnView(restricted: true)),
            ),
            _ActionCard(
              icon: Icons.savings_outlined,
              color: AppTheme.danger,
              title: 'مصروف جديد',
              subtitle: 'تسجيل مصروف',
              onTap: () => _open(context, const AddExpenseView(restricted: true)),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا يمكن لهذا الحساب الاطلاع على التقارير أو الأرباح أو بيانات المحل، ولا إضافة منتجات أو تعديلها.',
              style: TextStyle(fontSize: 11.5.sp, color: AppTheme.mutedGray, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// فحص سريع يوضّح للموظف/صاحب المحل سبب رفض القواعد لو حصل.
  Future<void> _showDiagnostics() async {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return;
    final firestore = sl<FirebaseFirestore>();
    final lines = <String>[];
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      lines.add('الدور: ${data['role'] ?? '(مفقود)'}');
      lines.add('رقم صاحب المحل: ${data['ownerId'] ?? '(مفقود)'}');
      lines.add('رقم المحل: ${data['shopId'] ?? '(مفقود)'}');
      lines.add('مفعّل: ${data['isActive'] ?? true}');
      final ownerId = data['ownerId'] as String?;
      if (ownerId != null && ownerId.isNotEmpty) {
        final sub = await firestore
            .collection('users')
            .doc(ownerId)
            .collection('subscription')
            .doc('current')
            .get();
        final s = sub.data() ?? {};
        lines.add('حالة اشتراك صاحب المحل: ${s['status'] ?? '(مفقود)'}');
      }
    } catch (e) {
      lines.add('تعذر القراءة: $e');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تشخيص الصلاحيات'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines
                .map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(l, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج؟'),
        content: const Text('سيتم إغلاق جلسة الموظف على هذا الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProfileCubit>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: color, size: 25.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3.h),
                    Text(subtitle, style: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: AppTheme.mutedGray),
            ],
          ),
        ),
      ),
    );
  }
}
