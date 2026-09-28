import 'dart:ui';
import '../../../../common_imports.dart';

/// Modern 2026 mesh background — theme aware, soft orbs + dot pattern + beam.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF0A1A45),
                      Color(0xFF0D2A86),
                      Color(0xFF071233),
                    ]
                  : const [
                      Color(0xFFFFFFFF),
                      Color(0xFFEBEEFF),
                      Color(0xFFF6F7FB),
                    ],
            ),
          ),
        ),
        // Top light beam
        Positioned(
          top: -120.h,
          left: -60.w,
          right: -60.w,
          child: IgnorePointer(
            child: Container(
              height: 320.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.18),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(200),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1),
                duration: 5.seconds),
          ),
        ),
        // Blue orb top-right
        Positioned(
          top: -110.h,
          right: -90.w,
          child: _BlurOrb(size: 300.sp,
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.55 : 0.35))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(.92, .92), end: const Offset(1.08, 1.08), duration: 4.seconds),
        ),
        // Gold orb bottom-left
        Positioned(
          bottom: -140.h,
          left: -100.w,
          child: _BlurOrb(size: 340.sp,
              color: AppTheme.secondaryColor.withValues(alpha: isDark ? 0.40 : 0.28))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 6.seconds),
        ),
        // Small blue orb center
        Positioned(
          top: MediaQuery.of(context).size.height * .38,
          left: -70.w,
          child: _BlurOrb(size: 170.sp,
              color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.30 : 0.22)),
        ),
        const _DotPattern(),
        // Bottom vignette for footer legibility
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? Colors.black : AppTheme.primaryDark).withValues(alpha: isDark ? 0.35 : 0.06),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _DotPattern extends StatelessWidget {
  const _DotPattern();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Opacity(
        opacity: isDark ? 0.10 : 0.16,
        child: CustomPaint(painter: _DotPainter(isDark: isDark), size: Size.infinite),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final bool isDark;
  _DotPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = isDark ? Colors.white : AppTheme.primaryColor;
    const spacing = 26.0;
    const r = 1.3;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}