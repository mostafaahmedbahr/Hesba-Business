import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, AppTheme.primaryColor, AppTheme.primaryLight],
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: -80.w, right: -60.w, child: _GlowCircle(size: 240.w, color: AppTheme.secondaryColor)),
                Positioned(bottom: -100.w, left: -80.w, child: _GlowCircle(size: 280.w, color: Colors.white)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.07),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 80, spreadRadius: 20)],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
