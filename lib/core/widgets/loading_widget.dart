import 'package:flutter/material.dart';

/// لودر موحد (دايرة + جملة) — نفس الشكل في كل التطبيق.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = size * 2.2;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              color: const Color(0xFF1A4FD6).withValues(alpha: isDark ? 0.16 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1A4FD6).withValues(alpha: isDark ? 0.35 : 0.18),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: isDark ? const Color(0xFF8FB0FF) : const Color(0xFF0F2D8A),
                  backgroundColor: const Color(0xFF1A4FD6).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F2D8A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingWidget(message: message),
    );
  }
}
