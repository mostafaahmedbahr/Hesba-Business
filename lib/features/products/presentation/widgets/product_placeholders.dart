import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';

/// لودر القائمة.
class ProductListLoading extends StatelessWidget {
  const ProductListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget(message: 'جاري تحميل المنتجات...');
  }
}

/// فاضي (مفيش منتجات خالص).
class ProductListEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const ProductListEmpty({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 110.w, height: 110.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.10), const Color(0xFF7C4DFF).withValues(alpha: 0.10)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined, size: 52.sp, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
            child: Column(children: [
              Text('productsEmpty'.tr(), style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              SizedBox(height: 8.h),
              Text('productsEmptyHint'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, height: 1.6, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
              SizedBox(height: 18.h),
              SizedBox(width: double.infinity, height: 48.h, child: FilledButton.icon(onPressed: onAdd, style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))), icon: const Icon(Icons.add_rounded), label: Text('productsAdd'.tr(), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)))),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// مفيش نتائج مطابقة للبحث.
class ProductListNoResults extends StatelessWidget {
  const ProductListNoResults({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB))),
      child: Column(children: [
        Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 28.sp, color: const Color(0xFF94A3B8))),
        SizedBox(height: 12.h),
        Text('productsNoResults'.tr(), style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        SizedBox(height: 6.h),
        Text('جرّب كلمة بحث أخرى أو غيّر الفلتر', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
      ]),
    );
  }
}

/// خطأ التحميل (مع إعادة المحاولة).
class ProductListFailure extends StatelessWidget {
  final VoidCallback onRetry;
  const ProductListFailure({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 28.w), child: Container(padding: EdgeInsets.all(22.w), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56.w, height: 56.w, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), shape: BoxShape.circle), child: Icon(Icons.cloud_off_rounded, size: 28.sp, color: const Color(0xFFE11D48))),
      SizedBox(height: 14.h),
      Text('productsLoadFailed'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      SizedBox(height: 16.h),
      SizedBox(width: double.infinity, height: 46.h, child: FilledButton.icon(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), icon: const Icon(Icons.refresh_rounded, size: 18), label: Text('productsRetry'.tr(), style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)))),
    ]))));
  }
}
