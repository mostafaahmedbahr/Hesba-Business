import '../../../../common_imports.dart';

/// بوكس فاضي (أيقونة + سطرين).
class CategoryEmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CategoryEmptyBox({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28.sp, color: const Color(0xFFCBD5E1)),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
