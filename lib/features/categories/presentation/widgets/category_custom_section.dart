import '../../../../common_imports.dart';
import '../cubit/category_state.dart';
import 'category_custom_row.dart';
import 'category_empty_box.dart';
import 'category_section_header.dart';

/// سكشن أقسامك (تتعدل).
class CategoryCustomSection extends StatelessWidget {
  final CategoryState state;

  const CategoryCustomSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = state.filteredCustom;
    final isSearching = state.searchQuery.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CategorySectionHeader(
            icon: Icons.folder_copy_rounded,
            title: 'أقسامك',
            count: '',
            gradient: [Color(0xFF059669), Color(0xFF34D399)],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              '${items.length} قسم مخصص',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
            ),
          ),
          SizedBox(height: 12.h),
          if (items.isEmpty)
            CategoryEmptyBox(
              icon: isSearching ? Icons.search_off_rounded : Icons.inbox_rounded,
              title: isSearching ? 'لا توجد نتائج' : 'لا توجد أقسام مخصصة بعد',
              subtitle: isSearching
                  ? 'جرّب كلمة بحث مختلفة'
                  : 'أضف قسماً من الأعلى ليظهر هنا وفي المنتج',
            )
          else
            Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8.h),
                    child: CategoryCustomRow(name: items[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
