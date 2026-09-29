import '../../../../common_imports.dart';
import '../cubit/sales_list_state.dart';

/// بحث + فلاتر الدفع.
class SalesListSearch extends StatefulWidget {
  final String query;
  final String paymentFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const SalesListSearch({
    super.key,
    required this.query,
    required this.paymentFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  State<SalesListSearch> createState() => _SalesListSearchState();
}

/// كنترولر البحث + chips الدفع.
class _SalesListSearchState extends State<SalesListSearch> {
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
            hintText: 'ابحث برقم الفاتورة أو المنتج أو الملاحظة',
            hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.search_rounded, size: 18.sp, color: AppTheme.primaryColor)),
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
        height: 36.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: SalesListState.paymentFilters.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, i) {
            final f = SalesListState.paymentFilters[i];
            final selected = f == widget.paymentFilter;
            return ChoiceChip(
              label: Text(f, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
              selected: selected,
              onSelected: (_) => widget.onFilterChanged(f),
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: selected ? AppTheme.primaryColor : const Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              showCheckmark: false,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
            );
          },
        ),
      ),
    ]);
  }
}
