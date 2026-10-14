import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';

/// لودر القائمة.
class ExpenseListLoading extends StatelessWidget {
  const ExpenseListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget(message: 'جاري تحميل المصروفات...');
  }
}

/// فاضي (مفيش مصروفات خالص).
class ExpenseListEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const ExpenseListEmpty({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.danger.withValues(alpha: 0.12), AppTheme.roseLight.withValues(alpha: 0.12)]), shape: BoxShape.circle),
              child: Icon(Icons.savings_rounded, size: 44.sp, color: AppTheme.danger),
            ),
            SizedBox(height: 16.h),
            Text('لا توجد مصروفات مسجلة', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.ink)),
            SizedBox(height: 8.h),
            Text('ابدأ بإضافة أول مصروف وتابع رصيدك بدقة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: AppTheme.slateGray, height: 1.5)),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                icon: const Icon(Icons.add_rounded),
                label: Text('إضافة مصروف', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مفيش نتائج مطابقة للبحث (مع مسح الفلتر).
class ExpenseListNoResults extends StatelessWidget {
  final VoidCallback onClear;
  const ExpenseListNoResults({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFFE4E6), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: AppTheme.roseLight)),
        SizedBox(height: 12.h),
        Text('لا توجد نتائج', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.ink)),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray)),
        SizedBox(height: 14.h),
        OutlinedButton(onPressed: onClear, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), child: const Text('مسح الفلتر')),
      ]),
    );
  }
}

/// خطأ التحميل (مع إعادة المحاولة).
class ExpenseListError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ExpenseListError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: AppTheme.dangerSoft, shape: BoxShape.circle), child: Icon(Icons.error_outline_rounded, size: 28.sp, color: AppTheme.danger)),
              SizedBox(height: 12.h),
              Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.white : AppTheme.ink)),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
