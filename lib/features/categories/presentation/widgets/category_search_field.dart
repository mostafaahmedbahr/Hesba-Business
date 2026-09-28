import '../../../../common_imports.dart';

/// بحث يفلتر القائمتين (live).
class CategorySearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const CategorySearchField({super.key, required this.onChanged});

  @override
  State<CategorySearchField> createState() => _CategorySearchFieldState();
}

/// كنترولر البحث + زر المسح.
class _CategorySearchFieldState extends State<CategorySearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: TextField(
        controller: _controller,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 13.5.sp),
        decoration: InputDecoration(
          hintText: 'ابحث في الأقسام...',
          hintStyle: TextStyle(
            fontSize: 12.5.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.search_rounded, size: 18.sp, color: AppTheme.primaryColor),
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 18.sp),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }
}
