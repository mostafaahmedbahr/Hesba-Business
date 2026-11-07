import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../../data/models/supplier_model.dart';
import '../states/suppliers_state.dart';
import '../cubit/suppliers_cubit.dart';
import 'supplier_contact.dart';
import 'supplier_field.dart';
import '../views/supplier_form_view.dart';

/// نتيجة اختيار المورد من قائمة المنتج.
///
/// - [supplier] != null → مورد مختار.
/// - [supplier] == null → المستخدم اختار "بدون مورد" صراحةً.
/// - رجوع الشاشة بدون نتيجة (`null`) → إلغاء بدون تغيير.
class SupplierPickResult {
  final SupplierModel? supplier;
  const SupplierPickResult({this.supplier});
}

/// قائمة اختيار المورد لنموذج المنتج: بحث + اختيار + مسح + اختصار
/// إضافة مورد جديد بدون فقدان بيانات الفورم.
class SupplierPickerSheet extends StatelessWidget {
  const SupplierPickerSheet({super.key});

  /// يفتح القائمة ويرجع نتيجة الاختيار (أو null عند الإلغاء).
  static Future<SupplierPickResult?> show(BuildContext context) {
    return showModalBottomSheet<SupplierPickResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupplierPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuppliersCubit(repo: sl())..init(),
      child: const _SheetBody(),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  /// إضافة مورد جديد ثم اختياره تلقائياً بعد الرجوع.
  Future<void> _addSupplier(BuildContext context) async {
    final created = await Navigator.push<SupplierModel>(
      context,
      MaterialPageRoute(builder: (_) => const SupplierFormView()),
    );
    if (created == null || !context.mounted) return;
    Navigator.pop(context, SupplierPickResult(supplier: created));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        final cubit = context.read<SuppliersCubit>();
        // نتائج البحث عن بعد إن وُجدت، وإلا الفلترة المحلية الفورية.
        final list = state.remoteResults ?? state.filtered;
        return Container(
          constraints: BoxConstraints(maxHeight: 0.82.sh),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب.
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.violetDeep, AppTheme.violetSoft],
                        ),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'supplierPickerTitle'.tr(),
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'suppliersCancel'.tr(),
                      icon: Icon(Icons.close_rounded, size: 20.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: SupplierPickerSearchField(
                  hintKey: 'supplierPickerHint',
                  onChanged: (q) {
                    cubit.setSearch(q);
                    cubit.searchRemote(q);
                  },
                ),
              ),
              SizedBox(height: 6.h),
              Flexible(
                child: state.searching
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppTheme.violetDeep,
                          ),
                        ),
                      )
                    : list.isEmpty
                    ? _Empty(
                        searching: state.remoteResults != null,
                        isDark: isDark,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 8.h),
                        shrinkWrap: true,
                        itemCount: list.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return _ClearTile(
                              isDark: isDark,
                              onTap: () => Navigator.pop(
                                context,
                                const SupplierPickResult(),
                              ),
                            );
                          }
                          final supplier = list[i - 1];
                          return _SupplierTile(
                            supplier: supplier,
                            isDark: isDark,
                            onTap: () => Navigator.pop(
                              context,
                              SupplierPickResult(supplier: supplier),
                            ),
                          );
                        },
                      ),
              ),
              // اختصار إضافة مورد جديد (الفورم اللي وراه بيفضل زي ما هو).
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: FilledButton.icon(
                    onPressed: () => _addSupplier(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.violetDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'suppliersAddNew'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// صف "بدون مورد" (إلغاء الارتباط).
class _ClearTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ClearTile({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.slatePale,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: AppTheme.mutedGray.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(
            Icons.link_off_rounded,
            size: 18.sp,
            color: AppTheme.slateGray,
          ),
        ),
        title: Text(
          'supplierPickerClear'.tr(),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.ink,
          ),
        ),
        subtitle: Text(
          'supplierPickerClearHint'.tr(),
          style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray),
        ),
      ),
    );
  }
}

/// صف مورد (اسم + رقم) مع زرار اتصال.
class _SupplierTile extends StatelessWidget {
  final SupplierModel supplier;
  final bool isDark;
  final VoidCallback onTap;
  const _SupplierTile({
    required this.supplier,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final company = supplier.companyName.trim();
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        leading: Container(
          width: 38.w,
          height: 38.w,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.violetDeep, AppTheme.violetSoft],
            ),
            borderRadius: BorderRadius.all(Radius.circular(11)),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            size: 18.sp,
            color: Colors.white,
          ),
        ),
        title: Text(
          supplier.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.ink,
          ),
        ),
        subtitle: Text(
          company.isNotEmpty && company != supplier.name
              ? '${supplier.phone} • $company'
              : supplier.phone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: AppTheme.slateGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          tooltip: 'supplierCall'.tr(),
          icon: Icon(
            Icons.call_rounded,
            size: 18.sp,
            color: AppTheme.successDark,
          ),
          onPressed: () => SupplierContact.call(context, supplier.phone),
        ),
      ),
    );
  }
}

/// حالة "مفيش نتائج" داخل القائمة.
class _Empty extends StatelessWidget {
  final bool searching;
  final bool isDark;
  const _Empty({required this.searching, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 34.sp,
            color: AppTheme.mutedGray,
          ),
          SizedBox(height: 8.h),
          Text(
            searching
                ? 'suppliersNoResultsTitle'.tr()
                : 'supplierPickerEmpty'.tr(),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.ink,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'supplierPickerEmptyHint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, color: AppTheme.mutedGray),
          ),
        ],
      ),
    );
  }
}

/// يبحث داخل قائمة الاختيار (حقل موحد).
class SupplierPickerSearchField extends StatefulWidget {
  final String hintKey;
  final ValueChanged<String> onChanged;
  const SupplierPickerSearchField({
    super.key,
    required this.hintKey,
    required this.onChanged,
  });

  @override
  State<SupplierPickerSearchField> createState() =>
      _SupplierPickerSearchFieldState();
}

class _SupplierPickerSearchFieldState extends State<SupplierPickerSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ظاهر زر المسح يتبع النص مباشرة عبر ValueListenable — بدون setState
    // (حالة الزر UI محلية بحتة، كل حالة الميزة في الـ Cubit).
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 13.5.sp),
          decoration: supplierFieldDecoration(
            context,
            label: widget.hintKey.tr(),
            icon: Icons.search_rounded,
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.sp),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
        );
      },
    );
  }
}
