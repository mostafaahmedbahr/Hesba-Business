import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/router/app_routes.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/profile/data/repos/account_repo.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_brand.dart';
import '../widgets/splash_footer.dart';
import '../widgets/splash_loader.dart';
import '../widgets/splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
    print('[Splash] isLoggedIn: $isLoggedIn');
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
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SplashBackground(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const SplashLogo().animate().fadeIn(duration: 700.ms, curve: Curves.easeOut).scale(begin: const Offset(.75, .75), end: const Offset(1, 1), duration: 900.ms, curve: Curves.easeOutBack),
                  SizedBox(height: 28.h),
                  const SplashBrand().animate().fadeIn(delay: 300.ms, duration: 700.ms).slideY(begin: .25, end: 0, delay: 300.ms, duration: 700.ms, curve: Curves.easeOutCubic),
                  SizedBox(height: 35.h),
                  const SplashLoader().animate().fadeIn(delay: 650.ms, duration: 500.ms),
                  const Spacer(flex: 3),
                  const SplashFooter().animate().fadeIn(delay: 900.ms, duration: 500.ms),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
