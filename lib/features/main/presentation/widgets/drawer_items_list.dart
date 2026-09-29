import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';
import '../../../categories/presentation/views/category_management_view.dart';
import '../../../contact/presentation/views/contact_us_view.dart';
import '../../../notifications/presentation/views/notifications_view.dart';
import '../../../profile/presentation/views/change_password_view.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../profile/presentation/views/update_profile_view.dart';
import 'drawer_language_tile.dart';
import 'drawer_theme_tile.dart';
import 'drawer_tile.dart';
import 'section_label.dart';

/// عناصر الـ Drawer (تركيب بس).
class DrawerItemsList extends StatelessWidget {
  final bool isDark;
  final void Function(int bottomIndex, {int? subTab})? onNavigateBottom;

  const DrawerItemsList({super.key, required this.isDark, this.onNavigateBottom});

  /// يفتح صفحة فوق الـ Drawer.
  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        children: [
          SectionLabel('العمليات', isDark),
          CustomDrawerTile(
            icon: Icons.receipt_long_rounded,
            label: 'navSales'.tr(),
            color: const Color(0xFF1A4FD6),
            onTap: () {
              Navigator.pop(context);
              onNavigateBottom?.call(2, subTab: 0);
            },
          ),
          CustomDrawerTile(
            icon: Icons.assignment_return_rounded,
            label: 'navReturns'.tr(),
            color: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.pop(context);
              onNavigateBottom?.call(2, subTab: 1);
            },
          ),
          CustomDrawerTile(
            icon: Icons.savings_rounded,
            label: 'navExpenses'.tr(),
            color: const Color(0xFFE11D48),
            onTap: () {
              Navigator.pop(context);
              onNavigateBottom?.call(3, subTab: 1);
            },
          ),
          CustomDrawerTile(
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
          SectionLabel('إدارة المتجر', isDark),
          CustomDrawerTile(
            icon: Icons.category_rounded,
            label: 'إدارة الأقسام',
            color: const Color(0xFF059669),
            onTap: () => _open(context, const CategoryManagementView()),
          ),
          CustomDrawerTile(
            icon: Icons.notifications_active_rounded,
            label: 'moreNotificationsTitle'.tr(),
            color: const Color(0xFF00ACC1),
            onTap: () => _open(context, const NotificationsView()),
          ),
          SizedBox(height: 10.h),
          Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
          SizedBox(height: 10.h),
          SectionLabel('moreAccount'.tr(), isDark),
          CustomDrawerTile(
            icon: Icons.person_rounded,
            label: 'moreProfile'.tr(),
            color: const Color(0xFF1A4FD6),
            onTap: () => _open(context, const ProfileView()),
          ),
          CustomDrawerTile(
            icon: Icons.edit_rounded,
            label: 'moreEditProfile'.tr(),
            color: const Color(0xFFF5A623),
            onTap: () => _open(context, const UpdateProfileView()),
          ),
          CustomDrawerTile(
            icon: Icons.lock_reset_rounded,
            label: 'moreChangePassword'.tr(),
            color: const Color(0xFF7C4DFF),
            onTap: () => _open(context, const ChangePasswordView()),
          ),
          SizedBox(height: 10.h),
          Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
          SizedBox(height: 10.h),
          SectionLabel('morePreferences'.tr(), isDark),
          DrawerThemeTile(isDark: isDark),
          DrawerLanguageTile(isDark: isDark),
          SizedBox(height: 10.h),
          Divider(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB), height: 1),
          SizedBox(height: 10.h),
          CustomDrawerTile(
            icon: Icons.headset_mic_rounded,
            label: 'moreContactUs'.tr(),
            color: const Color(0xFF00ACC1),
            onTap: () => _open(context, const ContactUsView()),
          ),
        ],
      ),
    );
  }
}
