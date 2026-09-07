import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/toast.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/states/profile_state.dart';
import '../../../profile/presentation/views/change_password_view.dart';
import '../../../profile/presentation/views/contact_us_view.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../../profile/presentation/views/update_profile_view.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/states/settings_state.dart';
import '../widgets/main_app_bar.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'المزيد'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            const _ProfileCard(),
            SizedBox(height: 20.h),
            _SectionCard('الحساب', [
              MoreItem(
                icon: Icons.person_rounded,
                label: 'البروفايل',
                color: const Color(0xFF1A4FD6),
                onTap: () => _navigateTo(context, const ProfileView()),
              ),
              MoreItem(
                icon: Icons.edit_rounded,
                label: 'تعديل البيانات',
                color: const Color(0xFFF5A623),
                onTap: () => _navigateTo(context, const UpdateProfileView()),
              ),
              MoreItem(
                icon: Icons.lock_reset_rounded,
                label: 'تغيير كلمة المرور',
                color: const Color(0xFF7C4DFF),
                onTap: () => _navigateTo(context, const ChangePasswordView()),
              ),
            ]),
            SizedBox(height: 20.h),
            const _ThemeLanguageCard(),
            SizedBox(height: 20.h),
            _SectionCard('الدعم', [
              MoreItem(
                icon: Icons.headset_mic_rounded,
                label: 'تواصل معنا',
                color: const Color(0xFF00ACC1),
                onTap: () => _navigateTo(context, const ContactUsView()),
              ),
            ]),
            SizedBox(height: 24.h),
            const _LogoutButton(),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          final name = profile?.ownerName ?? '';
          final email = profile?.email ?? '';
          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  _avatar(context, name),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? '—' : name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          email.isEmpty ? '—' : email,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(BuildContext context, String name) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person_rounded, color: primary, size: 30.sp),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _ThemeLanguageCard extends StatelessWidget {
  const _ThemeLanguageCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'التفضيلات',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            children: [
              const _ThemeItem(),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const _LanguageItem(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;
        return MoreItem(
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          label: 'الوضع الليلي',
          color: const Color(0xFF2E7D32),
          trailing: Switch(
            value: isDark,
            activeColor: const Color(0xFF1A4FD6),
            onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
          ),
        );
      },
    );
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isEnglish = state.locale.languageCode == 'en';
        return MoreItem(
          icon: Icons.language_rounded,
          label: 'اللغة',
          color: const Color(0xFF00ACC1),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEnglish ? 'English' : 'العربية',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Switch(
                value: isEnglish,
                activeColor: const Color(0xFF1A4FD6),
                onChanged: (_) {
                  context.read<SettingsCubit>().setLocale(
                        Locale(isEnglish ? 'ar' : 'en'),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(repo: sl<AccountRepo>()),
      child: Builder(
        builder: (context) {
          return SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                foregroundColor: const Color(0xFFE53935),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await context.read<ProfileCubit>().logout();
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } else {
      AppToast.error(context, 'فشل تسجيل الخروج');
    }
  }
}

class MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MoreItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_left_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
