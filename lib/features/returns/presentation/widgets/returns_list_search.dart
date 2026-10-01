import '../../../../common_imports.dart';

/// بحث + فلاتر الأسباب.
class ReturnsListSearch extends StatefulWidget {
  final String query;
  final String reasonFilter;
  final List<String> reasons;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const ReturnsListSearch({
    super.key,
    required this.query,
    required this.reasonFilter,
    required this.reasons,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  State<ReturnsListSearch> createState() => _ReturnsListSearchState();
}

/// كنترولر البحث + chips الأسباب.
class _ReturnsListSearchState extends State<ReturnsListSearch> {
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
            hintText: 'ابحث بكود المرتجع أو المنتج أو السبب',
            hintStyle: TextStyle(fontSize: 12.5.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            prefixIcon: Container(margin: EdgeInsets.all(8.w), width: 36.w, height: 36.w, decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.search_rounded, size: 18.sp, color: const Color(0xFFD97706))),
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
          itemCount: widget.reasons.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, i) {
            final reason = widget.reasons[i];
            final selected = reason == widget.reasonFilter;
            return ChoiceChip(
              label: Text(reason, style: TextStyle(fontSize: 11.5.sp, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
              selected: selected,
              onSelected: (_) => widget.onFilterChanged(reason),
              selectedColor: const Color(0xFFF59E0B),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB)),
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
