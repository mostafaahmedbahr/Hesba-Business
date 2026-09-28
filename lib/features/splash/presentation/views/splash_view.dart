import 'dart:async';
import 'package:hesba/features/profile/data/repos/account_repo.dart';
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

  void _navigateNext() {
    if (!mounted) return;
    final isLoggedIn = sl<AccountRepo>().currentUserId() != null;
    logSuccess('[Splash] isLoggedIn: $isLoggedIn');
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
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


