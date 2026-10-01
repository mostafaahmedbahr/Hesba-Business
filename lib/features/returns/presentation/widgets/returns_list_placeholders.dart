import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';

/// لودر القائمة.
class ReturnsListLoading extends StatelessWidget {
  const ReturnsListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget(message: 'جاري تحميل المرتجعات...');
  }
}

/// فاضي (مفيش مرتجعات خالص).
class ReturnsListEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const ReturnsListEmpty({super.key, required this.onAdd});

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
              decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withValues(alpha: 0.16), const Color(0xFFFBBF24).withValues(alpha: 0.16)]), shape: BoxShape.circle),
              child: Icon(Icons.assignment_return_rounded, size: 44.sp, color: const Color(0xFFD97706)),
            ),
            SizedBox(height: 16.h),
            Text('لا توجد مرتجعات بعد', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            SizedBox(height: 8.h),
            Text('سجل أول مرتجع وسيتم تحديث المخزون تلقائياً', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.5)),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                icon: const Icon(Icons.add_rounded),
                label: Text('إضافة مرتجع', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مفيش نتائج مطابقة للبحث.
class ReturnsListNoResults extends StatelessWidget {
  const ReturnsListNoResults({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: const Color(0xFFFB923C))),
        SizedBox(height: 12.h),
        Text('لا توجد نتائج', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }
}

/// خطأ التحميل.
class ReturnsListError extends StatelessWidget {
  final String message;
  const ReturnsListError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.error_outline_rounded, size: 28.sp, color: const Color(0xFFE11D48))),
              SizedBox(height: 12.h),
              Text('حدث خطأ: $message', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5.sp, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            ],
          ),
        ),
      ),
    );
  }
}

/// مفيش محل مربوط.
class ReturnsListNoShop extends StatelessWidget {
  const ReturnsListNoShop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('المرتجعات'), centerTitle: true),
      body: Center(
        child: Text(
          'لم يتم العثور على المتجر',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}
