import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../../products/data/repos/products_repo.dart';
import '../../../../products/presentation/cubit/products_cubit.dart';
import '../../../../products/presentation/views/product_form_view.dart';
import '../../../../subscription/presentation/subscription_gate.dart';
import 'package:hesba/core/services/app_logger.dart';

/// شبكة "الإجراءات السريعة" في الـ Home: بيع جديد / إضافة منتج / مرتجع / مصروف.
///
/// كل إجراء محروس بـ [SubscriptionGate] وبيعمل refresh للداشبورد لو نجح.
class QuickActionsGrid extends StatelessWidget {
  final void Function(int index)? onNavigateTab;
  const QuickActionsGrid({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
          icon: Icons.point_of_sale_rounded,
          label: 'homeNewSale'.tr(),
          subtitle: 'سجّل فاتورة',
          gradient: const [AppTheme.primaryColor, AppTheme.brightBlue],
          accent: const Color(0xFFDBE6FF)),
      _QuickActionData(
          icon: Icons.add_shopping_cart_rounded,
          label: 'homeAddProduct'.tr(),
          subtitle: 'أضف للمنتجات',
          gradient: const [AppTheme.warningAmber, AppTheme.goldLight],
          accent: const Color(0xFFFFF3D6)),
      _QuickActionData(
          icon: Icons.replay_circle_filled_rounded,
          label: 'homeReturn'.tr(),
          subtitle: 'إرجاع فاتورة',
          gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          accent: const Color(0xFFEDE9FF)),
      _QuickActionData(
          icon: Icons.savings_rounded,
          label: 'homeExpense'.tr(),
          subtitle: 'تسجيل مصروف',
          gradient: const [AppTheme.danger, AppTheme.roseLight],
          accent: const Color(0xFFFFE4E8)),
    ];
    return Column(children: [
      Row(children: [
        Expanded(
            child: _QuickActionButton(
                data: actions[0],
                onTap: () async {
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  if (!context.mounted) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addSaleView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (logErr, logSt) { AppLogger.nonFatal('features/main/presentation/widgets/home/quick_actions_grid.dart', logErr, logSt, severity: LoggingSeverity.warning); }
                  }
                }).animate().fadeIn(delay: 0.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QuickActionButton(
                data: actions[1],
                onTap: () async {
                  // يفتح فورم إضافة منتج مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  if (!context.mounted) return;
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
                    try { context.read<DashboardCubit>().refresh(); } catch (logErr, logSt) { AppLogger.nonFatal('features/main/presentation/widgets/home/quick_actions_grid.dart', logErr, logSt, severity: LoggingSeverity.warning); }
                  }
                }).animate().fadeIn(delay: 70.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
      ]),
      SizedBox(height: 10.h),
      Row(children: [
        Expanded(
            child: _QuickActionButton(
                data: actions[2],
                onTap: () async {
                  // يفتح إضافة مرتجع مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  if (!context.mounted) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addReturnView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (logErr, logSt) { AppLogger.nonFatal('features/main/presentation/widgets/home/quick_actions_grid.dart', logErr, logSt, severity: LoggingSeverity.warning); }
                  }
                }).animate().fadeIn(delay: 140.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
        SizedBox(width: 10.w),
        Expanded(
            child: _QuickActionButton(
                data: actions[3],
                onTap: () async {
                  // يفتح إضافة مصروف مباشرة.
                  if (!await SubscriptionGate.ensureCanModify(context)) return;
                  if (!context.mounted) return;
                  final r = await Navigator.pushNamed(context, AppRoutes.addExpenseView);
                  if (r == true && context.mounted) {
                    try { context.read<DashboardCubit>().refresh(); } catch (logErr, logSt) { AppLogger.nonFatal('features/main/presentation/widgets/home/quick_actions_grid.dart', logErr, logSt, severity: LoggingSeverity.warning); }
                  }
                }).animate().fadeIn(delay: 210.ms).scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1))),
      ]),
    ]);
  }
}

class _QuickActionData {
  final IconData icon; final String label; final String subtitle; final List<Color> gradient; final Color accent;
  const _QuickActionData({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.accent});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionData data; final VoidCallback onTap;
  const _QuickActionButton({required this.data, required this.onTap});
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
