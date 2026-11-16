import 'dart:async';
import 'package:hesba/features/profile/data/repos/account_repo.dart';
import 'package:hesba/core/services/user_role_service.dart';
import '../../../../common_imports.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_body_content.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() {
    _timer = Timer(const Duration(seconds: 3), _navigateNext);
  }

  Future<void> _navigateNext() async {
    final isLoggedIn = sl<AccountRepo>().currentUserId() != null;
    if (!isLoggedIn) {
      sl<UserRoleService>().clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    await sl<UserRoleService>().reload();
    if (!mounted) return;
    final isStaff = sl<UserRoleService>().isStaff;
    logSuccess('[Splash] isLoggedIn: $isLoggedIn, isStaff: $isStaff');
    Navigator.pushReplacementNamed(
      context,
      isStaff ? AppRoutes.staffHome : AppRoutes.dashboard,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1A45) : const Color(0xFFF6F7FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashBackground(),
          const SplashBodyContent(),

        ],
      ),
    );
  }
}


