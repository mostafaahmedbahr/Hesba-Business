import '../../../../common_imports.dart';

/// عنوان سكشن (أيقونة + اسم + عداد).
class CategorySectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final List<Color> gradient;

  const CategorySectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: Colors.white, size: 17.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        if (count.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: gradient.first.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: gradient.first.withValues(alpha: 0.16)),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: gradient.first,
              ),
            ),
          ),
      ],
    );
  }
}
