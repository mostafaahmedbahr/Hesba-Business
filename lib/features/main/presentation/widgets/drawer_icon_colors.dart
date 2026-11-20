import '../../../../common_imports.dart';

/// لون أيقونة كل صفحة في الـ Drawer بنسختين: فاتح / داكن.
///
/// النسخة «الداكنة» أفتح شوية (أقرب لـ 400) عشان الأيقونة تبان واضحة
/// على خلفية الـ Drawer الداكنة، والنسخة الفاتحة أغمق (600/700) عشان
/// تبان على الخلفية البيضاء. كده اللون ثابت لكل صفحة ومع ذلك بيحترم الثيم.
class DrawerIconColor {
  const DrawerIconColor(this.light, this.dark);

  final Color light;
  final Color dark;

  Color of(bool isDark) => isDark ? dark : light;

  /// العمليات
  static const returns = DrawerIconColor(AppTheme.warningAmber, Color(0xFFFBBF24));
  static const expenses = DrawerIconColor(AppTheme.danger, Color(0xFFFB7185));
  static const notifications = DrawerIconColor(Color(0xFF0891B2), Color(0xFF22D3EE));

  /// إدارة المتجر
  static const accounts = DrawerIconColor(AppTheme.primaryColor, AppTheme.brightBlue);
  static const staff = DrawerIconColor(AppTheme.violetDeep, Color(0xFFA78BFA));
  static const suppliers = DrawerIconColor(Color(0xFF0D9488), Color(0xFF2DD4BF));
  static const categories = DrawerIconColor(AppTheme.successDark, Color(0xFF34D399));

  /// الحساب
  static const profile = DrawerIconColor(AppTheme.primaryColor, AppTheme.brightBlue);
  static const editProfile = DrawerIconColor(Color(0xFFEA580C), Color(0xFFFB923C));
  static const password = DrawerIconColor(Color(0xFF4F46E5), Color(0xFF818CF8));

  /// الإعدادات والدعم
  static const theme = DrawerIconColor(Color(0xFF059669), Color(0xFF34D399));
  static const language = DrawerIconColor(Color(0xFF0891B2), Color(0xFF22D3EE));
  static const contact = DrawerIconColor(Color(0xFF0284C7), Color(0xFF38BDF8));
  static const privacy = DrawerIconColor(AppTheme.slateGray, Color(0xFF94A3B8));

  /// منطقة الخطر
  static const danger = DrawerIconColor(AppTheme.danger, Color(0xFFFB7185));
}
