import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xff092D63),
                Color(0xff061B3A),
                Color(0xff04152D),
              ],
            ),
          ),
        ),

        Positioned(
          top: -150,
          right: -100,
          child: _GlowCircle(
            size: 330,
            color: AppTheme.primaryColor,
          )
              .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
              .scale(
            begin: const Offset(.9, .9),
            end: const Offset(1.08, 1.08),
            duration: 4.seconds,
          ),
        ),

        Positioned(
          bottom: -180,
          left: -120,
          child: _GlowCircle(
            size: 380,
            color: AppTheme.secondaryColor,
          )
              .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
              .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 5.seconds,
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).size.height * .28,
          left: -100,
          child: _GlowCircle(
            size: 180,
            color: AppTheme.primaryColor,
            opacity: .08,
          ),
        ),

        const _GridPattern(),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    this.opacity = .13,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: 100,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: .035,
        child: CustomPaint(
          painter: _GridPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = .5;

    const spacing = 45.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}