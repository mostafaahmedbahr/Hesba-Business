import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../../../sales/data/models/sale_model.dart';

/// اختيار الفاتورة (بحث + قائمة منسدلة غنية).
class ReturnInvoicePicker extends StatelessWidget {
  final List<SaleModel> sales;
  final bool loading;
  final SaleModel? selected;
  final ValueChanged<SaleModel> onSelected;
  final VoidCallback onClear;

  const ReturnInvoicePicker({
    super.key,
    required this.sales,
    required this.loading,
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (loading) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 22.h),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.hairline),
        ),
        child: Center(child: SizedBox(width: 26.w, height: 26.w, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.warningAmber))),
      );
    }
    if (sales.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.warningAmber.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(color: AppTheme.warningAmber.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(Icons.receipt_long_rounded, size: 20.sp, color: AppTheme.amberDeep),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Text('retNoInvoices'.tr(), style: TextStyle(fontSize: 12.sp, height: 1.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.slateGray))),
        ]),
      );
    }
    return Autocomplete<SaleModel>(
      displayStringForOption: (s) {
            final id = s.saleId.length > 6 ? s.saleId.substring(0, 6) : s.saleId;
            return 'retPickerOption'.tr(namedArgs: {'id': id, 'date': DateFormat('dd/MM').format(s.createdAt), 'total': s.total.toStringAsFixed(0), 'currency': 'currencyEGP'.tr()});
          },
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return sales.take(8);
        final q = textEditingValue.text.toLowerCase();
        return sales.where((s) =>
            s.saleId.toLowerCase().contains(q) ||
            s.items.any((it) => it.productName.toLowerCase().contains(q)));
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(14.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: ListView.separated(
                padding: EdgeInsets.all(6.w),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => Divider(height: 1.h),
                itemBuilder: (context, index) {
                  final s = options.elementAt(index);
                  final date = DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(s.createdAt);
                  final isSel = s.saleId == selected?.saleId;
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    tileColor: isSel ? AppTheme.warningAmber.withValues(alpha: 0.08) : null,
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.brightBlue]),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(Icons.receipt_long_rounded, size: 18.sp, color: Colors.white),
                    ),
                    title: Text('retPickerLine'.tr(namedArgs: {'id': s.saleId.length > 6 ? s.saleId.substring(0, 6) : s.saleId, 'total': s.total.toStringAsFixed(0), 'currency': 'currencyEGP'.tr()}), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
                    subtitle: Text('$date • ${s.items.length} ${s.items.length == 1 ? 'saleItemOne'.tr() : 'saleItemsUnit'.tr()}', style: TextStyle(fontSize: 11.sp, color: AppTheme.slateGray)),
                    trailing: isSel ? Icon(Icons.check_circle_rounded, color: AppTheme.successDark, size: 20.sp) : null,
                    onTap: () => onSelected(s),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (selected != null && textController.text.isEmpty) {
          textController.text = 'retInvoiceNumber'.tr(namedArgs: {'id': selected!.saleId.length > 6 ? selected!.saleId.substring(0, 6) : selected!.saleId});
        }
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'retInvoiceSearchHint'.tr(),
            hintStyle: TextStyle(fontSize: 12.5.sp, color: AppTheme.mutedGray),
            prefixIcon: Container(
              margin: EdgeInsets.all(8.w),
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(color: AppTheme.warningAmber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(Icons.search_rounded, size: 17.sp, color: AppTheme.amberDeep),
            ),
            suffixIcon: selected != null
                ? IconButton(icon: Icon(Icons.clear_rounded, size: 17.sp), onPressed: onClear)
                : null,
            filled: true,
            fillColor: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: selected != null ? AppTheme.warningAmber.withValues(alpha: 0.4) : (isDark ? AppTheme.darkBorder : AppTheme.borderSoft)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppTheme.warningAmber, width: 1.6),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
          ),
          validator: (v) => selected == null ? 'retPickInvoice'.tr() : null,
        );
      },
      onSelected: onSelected,
    );
  }
}
