import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// لوجو طريقة الدفع (صورة البراند الحقيقية من assets).
/// الصور متسعة في كارت أبيض/داكن حسب لون خلفية اللوجو، ومع Fallback مرسوم
/// بالـ Flutter لو الملف مش موجود (عشان التطبيق ما ينهارش).
class PaymentBrandLogo extends StatelessWidget {
  const PaymentBrandLogo({
    super.key,
    required this.id,
    this.size = 44,
  });

  final String id;
  final double size;

  static const String instapay = 'instapay';
  static const String vodafoneCash = 'vodafone_cash';
  static const String etisalatCash = 'etisalat_cash';

  /// كل صورة في مكانها: إنستاباي مع إنستاباي، إلخ.
  static String? imageOf(String id) => switch (id) {
        instapay => 'assets/images/instapay.jpg',
        vodafoneCash => 'assets/images/vodafone-cash.jpg',
        etisalatCash => 'assets/images/etisalat-cash.png',
        _ => null,
      };

  static Color colorOf(String id) => switch (id) {
        instapay => const Color(0xFF6B2D91),
        vodafoneCash => const Color(0xFFE60000),
        etisalatCash => const Color(0xFF0B0B0B),
        _ => AppTheme.primaryColor,
      };

  static List<Color> gradientOf(String id) => switch (id) {
        instapay => const [Color(0xFF4A1D75), Color(0xFF9B4FC4)],
        vodafoneCash => const [Color(0xFFB80000), Color(0xFFF01818)],
        etisalatCash => const [Color(0xFF111111), Color(0xFF333333)],
        _ => [AppTheme.primaryColor, AppTheme.brightBlue],
      };

  /// خلفية الكارت: أبيض للوجوهات البيضاء، وأسود للوجو الأسود (اتصالات كاش)
  /// عشان الحدود ما تبانش حوله.
  static Color surfaceOf(String id) => switch (id) {
        etisalatCash => const Color(0xFF0B0B0B),
        _ => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.26;
    final image = imageOf(id);
    final darkSurface = id == etisalatCash;
    final padding = id == vodafoneCash ? size * 0.05 : size * 0.10;

    return Container(
      width: size * 1.25,
      height: size,
      decoration: BoxDecoration(
        color: surfaceOf(id),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: darkSurface
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.hairline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorOf(id).withValues(alpha: darkSurface ? 0.22 : 0.14),
            blurRadius: size * 0.34,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: image == null
              ? _BrandGlyph(id: id, size: size)
              : Image.asset(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _BrandGlyph(id: id, size: size),
                ),
        ),
      ),
    );
  }
}

/// Fallback مرسوم بالـ Flutter لو صورة البراند مش موجودة.
class _BrandGlyph extends StatelessWidget {
  const _BrandGlyph({required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (id) {
      PaymentBrandLogo.instapay => _InstaPayMark(size: size),
      PaymentBrandLogo.vodafoneCash => _VodafoneMark(size: size),
      PaymentBrandLogo.etisalatCash => _EtisalatMark(size: size),
      _ => Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
    };
  }
}

class _InstaPayMark extends StatelessWidget {
  const _InstaPayMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'IP',
        style: TextStyle(
          color: const Color(0xFF6B2D91),
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VodafoneMark extends StatelessWidget {
  const _VodafoneMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'V',
        style: TextStyle(
          color: const Color(0xFFE60000),
          fontSize: size * 0.40,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EtisalatMark extends StatelessWidget {
  const _EtisalatMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'e',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
