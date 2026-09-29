import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';
import '../../../profile/data/repos/account_repo.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import 'drawer_logout_dialog.dart';

/// زرار تسجيل الخروج (مع تأكيد).
class DrawerLogoutButton extends StatelessWidget {
  const DrawerLogoutButton({super.key});

  /// يسأل ثم يسجل الخروج أو يعرض خطأ.
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const DrawerLogoutDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().logout();
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('moreLogoutFailed'.tr())));
    }
  }

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
              onPressed: () => _logout(context),
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
