import '../../../../common_imports.dart';
import 'drawer_header.dart';
import 'drawer_items_list.dart';
import 'drawer_logout_button.dart';

/// Drawer التطبيق (تركيب بس — كل جزء في كلاس منفصل).
class AppDrawer extends StatelessWidget {
  final void Function(int bottomIndex, {int? subTab})? onNavigateTab;
  final VoidCallback? onOpenReturns;
  const AppDrawer({super.key, this.onNavigateTab, this.onOpenReturns});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      width: 300.w,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(24.r),
          bottomEnd: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            CustomDrawerHeader(isDark: isDark),
            DrawerItemsList(
              isDark: isDark,
              onNavigateTab: onNavigateTab,
              onOpenReturns: onOpenReturns,
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: const DrawerLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}
