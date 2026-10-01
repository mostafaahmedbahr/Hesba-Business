import '../../../../common_imports.dart';
import 'expense_category_meta.dart';

/// بحث + فلاتر التصنيفات (بأيقونات).
class ExpenseListSearch extends StatefulWidget {
  final String query;
  final String categoryFilter;
  final List<String> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const ExpenseListSearch({
    super.key,
    required this.query,
    required this.categoryFilter,
    required this.categories,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  State<ExpenseListSearch> createState() => _ExpenseListSearchState();
}

/// كنترولر البحث + chips التصنيفات.
class _ExpenseListSearchState extends State<ExpenseListSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
        child: TextField(
          controller: _controller,
          onChanged: widget.onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 13.5.sp),
          decoration: InputDecoration(
            hintText: 'ابحث بالعنوان أو التصنيف أو الملاحظة',
            hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.search_rounded, size: 18.sp, color: const Color(0xFFE11D48))),
            suffixIcon: widget.query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.sp),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearchChanged('');
                    },
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
      SizedBox(height: 12.h),
      SizedBox(
        height: 38.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.categories.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, i) {
            final cat = widget.categories[i];
            final selected = cat == widget.categoryFilter;
            final color = cat == 'الكل' ? const Color(0xFFE11D48) : expenseCatColor(cat);
            return ChoiceChip(
              avatar: cat == 'الكل'
                  ? null
                  : Icon(expenseCatIcon(cat), size: 14.sp, color: selected ? Colors.white : color),
              label: Text(cat, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
              selected: selected,
              onSelected: (_) => widget.onFilterChanged(cat),
              selectedColor: color,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: selected ? color : const Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              showCheckmark: false,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
            );
          },
        ),
      ),
    ]);
  }
}
