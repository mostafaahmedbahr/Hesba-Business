import '../../../../common_imports.dart';

/// عنوان قسم داخل الـ Drawer.
/// خط قصير تحت العنوان بيربط المجموعة ببعضها من غير ما نحتاج Divider كامل
/// بين كل قسم والتاني (اللي كان بيخلي القائمة متزحلقة).
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
      padding: EdgeInsetsDirectional.only(
        start: 8.w,
        end: 8.w,
        top: 16.h,
        bottom: 8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text ?? '',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: isDark == true
                  ? AppTheme.darkTextSecondary
                  : AppTheme.slateGray,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 5.h),
          Container(
            width: 22.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ],
      ),
    );
  }
}
