import 'package:easy_localization/easy_localization.dart';
import '../../../../common_imports.dart';

/// تأكيد تسجيل الخروج.
class DrawerLogoutDialog extends StatelessWidget {
  const DrawerLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFE53935)])),
              child: Icon(Icons.logout_rounded, size: 32.sp, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text('moreLogoutTitle'.tr(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('moreLogoutMessage'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B), height: 1.5)),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: Text('dialogCancel'.tr()))),
              SizedBox(width: 10.w),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)), child: Text('moreLogout'.tr()))),
            ]),
          ],
        ),
      ),
    );
  }
}
