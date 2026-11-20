import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/states/settings_state.dart';
import 'drawer_icon_colors.dart';

/// سويتش الوضع الليلي.
class DrawerThemeTile extends StatelessWidget {
  final bool isDark;
  const DrawerThemeTile({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final darkMode = state.themeMode == ThemeMode.dark;
        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          leading: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(color: DrawerIconColor.theme.of(isDark).withValues(alpha: isDark ? 0.20 : 0.12), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: DrawerIconColor.theme.of(isDark), size: 18.sp),
          ),
          title: Text('moreDarkMode'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.ink)),
          trailing: Switch(
            value: darkMode,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        );
      },
    );
  }
}
