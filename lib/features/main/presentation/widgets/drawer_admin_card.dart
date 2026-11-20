import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import 'package:hesba/admin_main.dart' show AdminHome;

/// بطاقة مميزة للوحة الإدارة — مش كـ ListTile عادي،
/// عشان يبان إنه تغيير سياق من تاجر لـ Admin.
class DrawerAdminCard extends StatelessWidget {
  const DrawerAdminCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHome()),
            );
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D2A86),
                  AppTheme.primaryColor,
                  AppTheme.brightBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'drawerAdminPanel'.tr(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'drawerAdminSubtitle'.tr(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
