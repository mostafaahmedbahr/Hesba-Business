import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hesba/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/playstore.png',
              width: 150,
              height: 150,
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'حسبة',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                fontFamily: AppTheme.fontFamily,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),

            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'نظام إدارة المحلات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontFamily: AppTheme.fontFamily,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),

            const SizedBox(height: 64),

            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.secondaryColor,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
