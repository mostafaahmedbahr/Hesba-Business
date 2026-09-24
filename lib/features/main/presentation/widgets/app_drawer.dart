import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/states/profile_state.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../profile/presentation/views/update_profile_view.dart';
import '../../../profile/presentation/views/change_password_view.dart';
import '../../../contact/presentation/views/contact_us_view.dart';
import '../../../notifications/presentation/views/notifications_view.dart';
import '../../../categories/presentation/views/category_management_view.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/states/settings_state.dart';

/// Drawer عصري يحمل كل ما خرج من الـ BottomNav
/// + المرتجعات/المصروفات للوصول السريع + إعدادات المتجر
class AppDrawer extends StatelessWidget {
  final void Function(int bottomIndex, {int? subTab})? onNavigateBottom;
  const AppDrawer({super.key, this.onNavigateBottom});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      width: 300.w,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(24.r),
          bottomEnd: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(isDark: isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                children: [
                  _sectionLabel('العمليات', isDark),
                  _drawerTile(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: 'navSales'.tr(),
                    color: const Color(0xFF1A4FD6),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateBottom?.call(2, subTab: 0);
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.assignment_return_rounded,
                    label: 'navReturns'.tr(),
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateBottom?.call(2, subTab: 1);
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.savings_rounded,
                    label: 'navExpenses'.tr(),
                    color: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateBottom?.call(3, subTab: 1);
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.bar_chart_rounded,
                    label: 'navReports'.tr(),
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateBottom?.call(3, subTab: 0);
                    },
                  ),
                  SizedBox(height: 10.h),
                  Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
                  SizedBox(height: 10.h),
                  _sectionLabel('إدارة المتجر', isDark),
                  _drawerTile(
                    context,
                    icon: Icons.category_rounded,
                    label: 'إدارة الأقسام',
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.notifications_active_rounded,
                    label: 'moreNotificationsTitle'.tr(),
                    color: const Color(0xFF00ACC1),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView()));
                    },
                  ),
                  SizedBox(height: 10.h),
                  Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
                  SizedBox(height: 10.h),
                  _sectionLabel('moreAccount'.tr(), isDark),
                  _drawerTile(
                    context,
                    icon: Icons.person_rounded,
                    label: 'moreProfile'.tr(),
                    color: const Color(0xFF1A4FD6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.edit_rounded,
                    label: 'moreEditProfile'.tr(),
                    color: const Color(0xFFF5A623),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateProfileView()));
                    },
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.lock_reset_rounded,
                    label: 'moreChangePassword'.tr(),
                    color: const Color(0xFF7C4DFF),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordView()));
                    },
                  ),
                  SizedBox(height: 10.h),
                  Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
                  SizedBox(height: 10.h),
                  _sectionLabel('morePreferences'.tr(), isDark),
                  _themeTile(context, isDark),
                  _languageTile(context, isDark),
                  SizedBox(height: 10.h),
                  Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
                  SizedBox(height: 10.h),
                  _drawerTile(
                    context,
                    icon: Icons.headset_mic_rounded,
                    label: 'moreContactUs'.tr(),
                    color: const Color(0xFF00ACC1),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsView()));
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: _LogoutTile(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      title: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      trailing: Icon(Icons.chevron_left_rounded, size: 18.sp, color: const Color(0xFFCBD5E1)),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    );
  }

  Widget _themeTile(BuildContext context, bool isDark) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final darkMode = state.themeMode == ThemeMode.dark;
        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          leading: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: const Color(0xFF2E7D32), size: 18.sp),
          ),
          title: Text('moreDarkMode'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          trailing: Switch(
            value: darkMode,
            activeColor: const Color(0xFF1A4FD6),
            onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        );
      },
    );
  }

  Widget _languageTile(BuildContext context, bool isDark) {
    final isEnglish = context.locale.languageCode == 'en';
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(color: const Color(0xFF00ACC1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(Icons.language_rounded, color: const Color(0xFF00ACC1), size: 18.sp),
      ),
      title: Text('moreLanguage'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isEnglish ? 'English' : 'العربية', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          SizedBox(width: 6.w),
          Switch(
            value: isEnglish,
            activeColor: const Color(0xFF1A4FD6),
            onChanged: (_) => context.setLocale(Locale(isEnglish ? 'ar' : 'en')),
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final bool isDark;
  const _DrawerHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          final name = profile?.ownerName ?? '...';
          final email = profile?.email ?? '';
          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7BFF)],
              ),
              borderRadius: BorderRadiusDirectional.only(bottomEnd: Radius.circular(24.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.28))),
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 28.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 2.h),
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w600)),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                        child: Text('حسبة • Hesba', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
                      ),
                    ],
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

class _LogoutTile extends StatelessWidget {
  final bool isDark;
  const _LogoutTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>()),
      child: Builder(
        builder: (context) {
          return SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black54,
                  builder: (ctx) => _LogoutDialog(isDark: isDark),
                );
                if (confirmed != true) return;
                if (!context.mounted) return;
                final ok = await context.read<ProfileCubit>().logout();
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('moreLogoutFailed'.tr())));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.22)),
                backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('moreLogout'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
            ),
          );
        },
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final bool isDark;
  const _LogoutDialog({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFE53935)])),
              child: Icon(Icons.logout_rounded, size: 32.sp, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text('moreLogoutTitle'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('moreLogoutMessage'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B), height: 1.5)),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: Text('dialogCancel'.tr()))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)), child: Text('moreLogout'.tr()))),
            ]),
          ],
        ),
      ),
    );
  }
}
