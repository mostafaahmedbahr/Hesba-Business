import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';

/// سويتش اللغة (عربي / English).
class DrawerLanguageTile extends StatelessWidget {
  final bool isDark;
  const DrawerLanguageTile({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isEnglish = context.locale.languageCode == 'en';
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(color: const Color(0xFF00ACC1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
        child: Icon(Icons.language_rounded, color: const Color(0xFF00ACC1), size: 18.sp),
      ),
      title: Text('moreLanguage'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.ink)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isEnglish ? 'English' : 'العربية', style: TextStyle(fontSize: 12.sp, color: AppTheme.slateGray, fontWeight: FontWeight.w600)),
          SizedBox(width: 6.w),
          Switch(
            value: isEnglish,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (_) => context.setLocale(Locale(isEnglish ? 'ar' : 'en')),
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
    );
  }
}
