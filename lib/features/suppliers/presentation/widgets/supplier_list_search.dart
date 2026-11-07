import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';

/// بحث الموردين (بالاسم أو الشركة أو المدينة أو الرقم).
class SupplierListSearch extends StatefulWidget {
  final String query;
  final ValueChanged<String> onSearchChanged;

  const SupplierListSearch({
    super.key,
    required this.query,
    required this.onSearchChanged,
  });

  @override
  State<SupplierListSearch> createState() => _SupplierListSearchState();
}

/// كنترولر البحث + زرار المسح.
class _SupplierListSearchState extends State<SupplierListSearch> {
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
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 13.5.sp),
        decoration: InputDecoration(
          hintText: 'suppliersSearchHint'.tr(),
          hintStyle: TextStyle(
            fontSize: 12.5.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppTheme.violetDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 18.sp,
              color: AppTheme.violetDeep,
            ),
          ),
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
    );
  }
}
