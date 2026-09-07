import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/theme/app_theme.dart';

class SplashBackground extends StatelessWidget {
  final Animation<double> animation;

  const SplashBackground({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Ripple circles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(
                  3,
                      (index) {
                    return _RippleCircle(
                      animationValue: animation.value,
                      index: index,
                    );
                  },
                ),
              );
            },
          ),
        ),

        /// Top right decoration
        Positioned(
          top: 90.h,
          right: -45.w,
          child: _DecorativeCircle(
            size: 150.w,
            color: AppTheme.secondaryColor.withValues(
              alpha: 0.18,
            ),
          ),
        ),

        /// Bottom left decoration
        Positioned(
          bottom: 180.h,
          left: -35.w,
          child: _DecorativeCircle(
            size: 110.w,
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),

        /// Small decorative glow
        Positioned(
          top: 180.h,
          left: 30.w,
          child: _DecorativeCircle(
            size: 35.w,
            color: AppTheme.secondaryColor.withValues(
              alpha: 0.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RippleCircle extends StatelessWidget {
  final double animationValue;
  final int index;

  const _RippleCircle({
    required this.animationValue,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (animationValue + (index * 0.25)) % 1.0;

    final scale = 0.65 + (progress * 0.55);

    final opacity = (1 - progress) * 0.10;

    final size = 180.w + (index * 80.w);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: math.max(opacity, 0.01),
            ),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    )
        .animate()
        .fadeIn(
      duration: 500.ms,
    )
        .scale(
      begin: const Offset(0.4, 0.4),
      end: const Offset(1, 1),
      duration: 800.ms,
      curve: Curves.elasticOut,
    );
  }
}