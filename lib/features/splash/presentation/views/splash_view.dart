import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_loader.dart';
import '../widgets/splash_logo.dart';
import '../widgets/splash_title.dart';

class SplashView extends StatefulWidget {
  final Widget nextScreen;

  const SplashView({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(
      const Duration(seconds: 3),
      _navigateToNextScreen,
    );
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) {
          return widget.nextScreen;
        },
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            /// Background
            SplashBackground(
              animation: _rippleController,
            ),

            /// Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Logo
                      const SplashLogo(),

                      SizedBox(height: 28.h),

                      /// App name + tagline
                      const SplashTitle(),

                      SizedBox(height: 70.h),

                      /// Loading
                      const SplashLoader(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}