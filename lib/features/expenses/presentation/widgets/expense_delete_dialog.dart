import '../../../../common_imports.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// تأكيد حذف مصروف.
class ExpenseDeleteDialog extends StatelessWidget {
  final String title;
  const ExpenseDeleteDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: const BoxDecoration(color: AppTheme.dangerSoft, shape: BoxShape.circle),
              child: Icon(Icons.delete_rounded, size: 26.sp, color: AppTheme.danger),
            ),
            SizedBox(height: 12.h),
            Text('حذف المصروف؟'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text(
              uiTr('هل أنت متأكد من حذف "$title"؟ لا يمكن التراجع.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: AppTheme.slateGray, height: 1.5),
            ),
            SizedBox(height: 18.h),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('إلغاء'.tr()),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('حذف'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
