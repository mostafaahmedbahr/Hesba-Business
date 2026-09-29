import '../../../../common_imports.dart';

class CustomDrawerTile extends StatelessWidget {
  const CustomDrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final darkMode =
        isDark ?? Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18.sp,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: darkMode
              ? Colors.white
              : const Color(0xFF0F172A),
        ),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        size: 18.sp,
        color: const Color(0xFFCBD5E1),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 2.h,
      ),
    );
  }
}