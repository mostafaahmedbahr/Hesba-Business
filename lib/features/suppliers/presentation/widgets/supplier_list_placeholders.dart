import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/widgets/loading_widget.dart';

import '../../../../common_imports.dart';

/// لودر قائمة الموردين.
class SupplierListLoading extends StatelessWidget {
  const SupplierListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(message: 'suppliersLoading'.tr());
  }
}

/// فاضي (مفيش موردين خالص).
class SupplierListEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const SupplierListEmpty({super.key, required this.onAdd});

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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.violetDeep.withValues(alpha: 0.12),
                    AppTheme.violetSoft.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                size: 44.sp,
                color: AppTheme.violetDeep,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'suppliersEmptyTitle'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'suppliersEmptySubtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.slateGray,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.violetDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'suppliersAdd'.tr(),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مفيش نتائج مطابقة للبحث.
class SupplierListNoResults extends StatelessWidget {
  final VoidCallback onClear;
  const SupplierListNoResults({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 28.sp,
              color: AppTheme.violetSoft,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'suppliersNoResultsTitle'.tr(),
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.ink,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'suppliersNoResultsSubtitle'.tr(),
            style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray),
          ),
          SizedBox(height: 14.h),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('suppliersClearSearch'.tr()),
          ),
        ],
      ),
    );
  }
}

/// خطأ التحميل (مع إعادة المحاولة).
class SupplierListError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const SupplierListError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: AppTheme.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28.sp,
                  color: AppTheme.danger,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: isDark ? Colors.white : AppTheme.ink,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.violetDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'suppliersRetry'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
