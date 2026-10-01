import '../../../../common_imports.dart';

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
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: Icon(Icons.delete_rounded, size: 26.sp, color: const Color(0xFFE11D48)),
            ),
            SizedBox(height: 12.h),
            Text('حذف المصروف؟', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text(
              'هل أنت متأكد من حذف "$title"؟ لا يمكن التراجع.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: const Color(0xFF64748B), height: 1.5),
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
                  child: const Text('إلغاء'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
