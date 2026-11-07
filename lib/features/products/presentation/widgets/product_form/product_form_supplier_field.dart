import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../../common_imports.dart';
import '../../../../../core/models/product.dart';
import '../../../../suppliers/data/models/supplier_model.dart';
import '../../../../suppliers/data/repos/suppliers_repo.dart';
import '../../../../suppliers/presentation/widgets/supplier_picker_sheet.dart';
import '../../../../suppliers/presentation/views/supplier_details_view.dart';
import 'product_form_section.dart';

/// حقل المورد داخل نموذج المنتج (إضافة/تعديل).
///
/// - يعرض المورد المختار (اسم + رقم) أو "بدون مورد".
/// - الضغط يفتح قائمة الاختيار (بحث + إضافة مورد جديد + مسح).
/// - لا يسمح بأسماء حرة: الاختيار من قائمة موردي المحل فقط.
class ProductSupplierField extends StatefulWidget {
  final String? supplierId;
  final String? supplierName;
  final Product? existing;
  final ValueChanged<String?>? onCleared;
  final ValueChanged<SupplierModel> onSelected;

  const ProductSupplierField({
    super.key,
    this.supplierId,
    this.supplierName,
    this.existing,
    this.onCleared,
    required this.onSelected,
  });

  @override
  State<ProductSupplierField> createState() => _ProductSupplierFieldState();
}

class _ProductSupplierFieldState extends State<ProductSupplierField> {
  /// رقم المورد المختار (يُقرأ مرة واحدة لعرضه بجانب الاسم).
  String _phone = '';
  bool _loadingPhone = false;

  @override
  void initState() {
    super.initState();
    _resolvePhone();
  }

  @override
  void didUpdateWidget(covariant ProductSupplierField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supplierId != widget.supplierId) {
      _phone = '';
      _resolvePhone();
    }
  }

  Future<void> _resolvePhone() async {
    final id = widget.supplierId;
    if (id == null || id.isEmpty || _loadingPhone) return;
    _loadingPhone = true;
    try {
      final supplier = await sl<SuppliersRepo>().getSupplierById(id);
      if (!mounted) return;
      setState(() => _phone = supplier?.phone ?? '');
    } catch (_) {
      // الرقم اختياري — لو مقدرناش نقرأه بنعرض الاسم بس.
    } finally {
      _loadingPhone = false;
    }
  }

  Future<void> _openPicker() async {
    HapticFeedback.selectionClick();
    final result = await SupplierPickerSheet.show(context);
    if (result == null || !mounted) return; // إلغاء.
    if (result.supplier == null) {
      // "بدون مورد" صراحةً.
      setState(() => _phone = '');
      widget.onCleared?.call(null);
      return;
    }
    setState(() => _phone = result.supplier!.phone);
    widget.onSelected(result.supplier!);
  }

  void _viewSupplier() {
    final id = widget.supplierId;
    if (id == null || id.isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierDetailsView(supplierId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected =
        widget.supplierId != null && widget.supplierId!.trim().isNotEmpty;
    final name = (widget.supplierName ?? '').trim();

    return ProductFormSectionCard(
      icon: Icons.local_shipping_rounded,
      titleKey: 'supplierProductSection',
      gradient: const [AppTheme.violetDeep, AppTheme.violetSoft],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceAlt : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: selected
                      ? AppTheme.violetDeep.withValues(alpha: 0.45)
                      : (isDark ? AppTheme.darkBorder : AppTheme.hairline),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [
                                AppTheme.violetDeep,
                                AppTheme.violetSoft,
                              ],
                            )
                          : null,
                      color: selected
                          ? null
                          : AppTheme.mutedGray.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 17.sp,
                      color: selected ? Colors.white : AppTheme.slateGray,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected && name.isNotEmpty
                              ? name
                              : 'supplierPickerClear'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? (isDark ? Colors.white : AppTheme.ink)
                                : AppTheme.mutedGray,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          selected && _phone.isNotEmpty
                              ? _phone
                              : 'supplierProductHint'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.mutedGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    IconButton(
                      tooltip: 'supplierProductView'.tr(),
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18.sp,
                        color: AppTheme.violetDeep,
                      ),
                      onPressed: _viewSupplier,
                    ),
                  if (selected)
                    IconButton(
                      tooltip: 'supplierPickerClear'.tr(),
                      icon: Icon(
                        Icons.link_off_rounded,
                        size: 18.sp,
                        color: AppTheme.danger,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _phone = '');
                        widget.onCleared?.call(null);
                      },
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22.sp,
                      color: AppTheme.mutedGray,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                size: 13.sp,
                color: selected ? AppTheme.successDark : AppTheme.mutedGray,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  selected
                      ? 'supplierProductLinked'.tr()
                      : 'supplierProductOptional'.tr(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.mutedGray,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
