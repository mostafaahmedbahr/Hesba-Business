import '../../../../common_imports.dart';
import '../cubit/category_state.dart';
import 'category_empty_box.dart';
import 'category_section_header.dart';

/// سكشن الافتراضية (عرض فقط).
class CategoryDefaultsSection extends StatelessWidget {
  final CategoryState state;

  const CategoryDefaultsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = state.filteredDefaults;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategorySectionHeader(
            icon: Icons.layers_rounded,
            title: 'الافتراضية',
            count: '${items.length}',
            gradient: const [AppTheme.slateGray, AppTheme.mutedGray],
          ),
          SizedBox(height: 4.h),
          Text(
            'ثابتة حسب نوع نشاطك — للعرض فقط',
            style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray),
          ),
          SizedBox(height: 12.h),
          if (items.isEmpty)
            const CategoryEmptyBox(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              subtitle: 'جرّب كلمة بحث مختلفة',
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final cat in items)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.mist,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_rounded, size: 12.sp, color: AppTheme.slateGray),
                        SizedBox(width: 6.w),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
