import '../../../../common_imports.dart';
import '../../data/models/debt_model.dart';

/// أتار شخص: أول حرفين من الاسم داخل دائرة بتدرج لوني —
/// العملاء أزرق، والموردين بنفسجي.
class PersonAvatar extends StatelessWidget {
  final String name;
  final bool isSupplier;
  final double size;

  const PersonAvatar({
    super.key,
    required this.name,
    this.isSupplier = false,
    this.size = 46,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    String first(String s) =>
        s.isEmpty ? '' : String.fromCharCode(s.runes.first);
    if (parts.length == 1) {
      final p = parts.first;
      return p.runes.take(2).map(String.fromCharCode).join();
    }
    return (first(parts[0]) + first(parts[1])).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = isSupplier
        ? const [Color(0xFF7C3AED), Color(0xFFA78BFA)]
        : const [Color(0xFF1A4FD6), Color(0xFF4A7BFF)];
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular((size * 0.36).r),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: (size * 0.36).sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// شارة حالة السداد (غير مدفوع / سداد جزئي / مدفوع).
class DebtStatusBadge extends StatelessWidget {
  final DebtStatus status;

  const DebtStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      DebtStatus.unpaid => (
          'غير مدفوع',
          AppTheme.danger,
          AppTheme.dangerSoft,
        ),
      DebtStatus.partial => (
          'سداد جزئي',
          AppTheme.amberDeep,
          const Color(0xFFFEF3C7),
        ),
      DebtStatus.paid => (
          'مدفوع',
          AppTheme.successDark,
          const Color(0xFFDCFCE7),
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة الاتجاه: «ليّا فلوس» (أخضر) أو «عليّ فلوس» (أحمر).
class DirectionPill extends StatelessWidget {
  final bool isReceivable;

  const DirectionPill({super.key, required this.isReceivable});

  @override
  Widget build(BuildContext context) {
    final fg = isReceivable ? AppTheme.successDark : AppTheme.danger;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        isReceivable ? 'ليّا فلوس' : 'عليّ فلوس',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

/// شريط تقدم السداد (نسبة المدفوع من الأصل).
class PaymentProgress extends StatelessWidget {
  final double ratio; // 0..1
  final bool isReceivable;

  const PaymentProgress({
    super.key,
    required this.ratio,
    required this.isReceivable,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isReceivable ? AppTheme.primaryColor : AppTheme.danger;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: SizedBox(
        height: 5.h,
        child: Stack(
          children: [
            Container(
              color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
            ),
            FractionallySizedBox(
              widthFactor: ratio.clamp(0, 1),
              child: Container(color: fill),
            ),
          ],
        ),
      ),
    );
  }
}
