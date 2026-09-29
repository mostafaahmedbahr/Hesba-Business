import '../../../../common_imports.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(
      this.text,
      this.isDark, {
        super.key,
      });

  final String? text;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 6.h,
      ),
      child: Text(
        text ?? '',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: isDark == true
              ? AppTheme.darkTextSecondary
              : const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}