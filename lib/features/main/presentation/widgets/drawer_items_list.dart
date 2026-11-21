import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common_imports.dart';
import '../../../categories/presentation/views/category_management_view.dart';
import '../../../contact/presentation/views/contact_us_view.dart';
import '../../../accounts/presentation/views/accounts_view.dart';
import '../../../suppliers/presentation/views/suppliers_view.dart';
import '../../../notifications/presentation/views/notifications_view.dart';
import '../../../profile/presentation/views/change_password_view.dart';
import '../../../profile/presentation/views/delete_account_view.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../profile/presentation/views/update_profile_view.dart';
import 'drawer_admin_card.dart';
import 'drawer_icon_colors.dart';
import 'drawer_language_tile.dart';
import 'drawer_theme_tile.dart';
import 'drawer_tile.dart';
import 'section_label.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:hesba/core/services/user_role_service.dart';

/// عناصر الـ Drawer (تركيب بس — من غير المبيعات).
///
/// التقسيم:
///   ١. العمليات         (مرتجعات / مصروفات / إشعارات)
///   ٢. إدارة المتجر     (حسابات / موظفين / موردين / أقسام)
///   ٣. الحساب           (بروفايل / تعديل / كلمة مرور)
///   ٤. الإعدادات والدعم (ثيم / لغة / تواصل / خصوصية)
///   ٥. لوحة الإدارة     (بطاقة مميزة)
///   ٦. منطقة الخطر      (حذف الحساب)
///
/// كل صفحة ليها لونها الخاص من [DrawerIconColor]، مع نسخة أفتح للوضع الداكن.
class DrawerItemsList extends StatelessWidget {
  final bool isDark;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onOpenReturns;
  final VoidCallback? onOpenExpenses;

  const DrawerItemsList({
    super.key,
    required this.isDark,
    this.onNavigateTab,
    this.onOpenReturns,
    this.onOpenExpenses,
  });

  /// يفتح صفحة فوق الـ Drawer.
  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static const String _privacyPolicyUrl =
      'https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5';

  /// يفتح سياسة الخصوصية في المتصفح الخارجي (متطلب نشر Play).
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    Navigator.pop(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(_privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('تعذر فتح سياسة الخصوصية — راجع الرابط من المتصفح')),
        );
      }
    } catch (logErr, logSt) {
      AppLogger.nonFatal('features/main/presentation/widgets/drawer_items_list.dart', logErr, logSt, severity: LoggingSeverity.warning);
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر فتح سياسة الخصوصية — راجع الرابط من المتصفح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        children: [
          // ١. العمليات
          SectionLabel('drawerOperations'.tr(), isDark),
          CustomDrawerTile(
            icon: Icons.assignment_return_rounded,
            label: 'navReturns'.tr(),
            color: DrawerIconColor.returns.of(isDark),
            onTap: () {
              Navigator.pop(context);
              onOpenReturns?.call();
            },
          ),
          CustomDrawerTile(
            icon: Icons.savings_rounded,
            label: 'navExpenses'.tr(),
            color: DrawerIconColor.expenses.of(isDark),
            onTap: () {
              Navigator.pop(context);
              onOpenExpenses?.call();
            },
          ),
          CustomDrawerTile(
            icon: Icons.notifications_active_rounded,
            label: 'moreNotifications'.tr(),
            color: DrawerIconColor.notifications.of(isDark),
            onTap: () => _open(context, const NotificationsView()),
          ),

          // ٢. إدارة المتجر
          SectionLabel('drawerStoreManagement'.tr(), isDark),
          CustomDrawerTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'drawerAccounts'.tr(),
            color: DrawerIconColor.accounts.of(isDark),
            onTap: () => _open(context, const AccountsView()),
          ),
          CustomDrawerTile(
            icon: Icons.badge_outlined,
            label: 'drawerStaffAccounts'.tr(),
            color: DrawerIconColor.staff.of(isDark),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.staffManagement);
            },
          ),
          CustomDrawerTile(
            icon: Icons.local_shipping_rounded,
            label: 'suppliersSection'.tr(),
            color: DrawerIconColor.suppliers.of(isDark),
            onTap: () => _open(context, const SuppliersView()),
          ),
          CustomDrawerTile(
            icon: Icons.category_rounded,
            label: 'drawerCategoryManagement'.tr(),
            color: DrawerIconColor.categories.of(isDark),
            onTap: () => _open(context, const CategoryManagementView()),
          ),

          // ٣. الحساب
          SectionLabel('moreAccount'.tr(), isDark),
          CustomDrawerTile(
            icon: Icons.person_rounded,
            label: 'moreProfile'.tr(),
            color: DrawerIconColor.profile.of(isDark),
            onTap: () => _open(context, const ProfileView()),
          ),
          CustomDrawerTile(
            icon: Icons.edit_rounded,
            label: 'moreEditProfile'.tr(),
            color: DrawerIconColor.editProfile.of(isDark),
            onTap: () => _open(context, const UpdateProfileView()),
          ),
          CustomDrawerTile(
            icon: Icons.lock_reset_rounded,
            label: 'moreChangePassword'.tr(),
            color: DrawerIconColor.password.of(isDark),
            onTap: () => _open(context, const ChangePasswordView()),
          ),

          // ٤. الإعدادات والدعم
          SectionLabel('drawerSettingsSupport'.tr(), isDark),
          DrawerThemeTile(isDark: isDark),
          DrawerLanguageTile(isDark: isDark),
          CustomDrawerTile(
            icon: Icons.headset_mic_rounded,
            label: 'moreContactUs'.tr(),
            color: DrawerIconColor.contact.of(isDark),
            onTap: () => _open(context, const ContactUsView()),
          ),
          CustomDrawerTile(
            icon: Icons.privacy_tip_outlined,
            label: 'morePrivacyPolicy'.tr(),
            color: DrawerIconColor.privacy.of(isDark),
            onTap: () => _openPrivacyPolicy(context),
          ),

          // ٥. لوحة الإدارة — للأدمن فقط. القواعد تمنع غير الأدمن فعليًا،
          // لكن إخفاء البطاقة يقلّل سطح الهجوم ويمنع تضليل المستخدمين.
          if (sl<UserRoleService>().isAdmin) ...[
            SectionLabel('drawerAdminPanel'.tr(), isDark),
            const DrawerAdminCard(),
          ],

          // ٦. منطقة الخطر
          SectionLabel('drawerDangerZone'.tr(), isDark),
          CustomDrawerTile(
            icon: Icons.delete_forever_rounded,
            label: 'moreDeleteAccount'.tr(),
            color: DrawerIconColor.danger.of(isDark),
            isDestructive: true,
            onTap: () => _open(context, const DeleteAccountView()),
          ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
