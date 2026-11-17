import 'package:easy_localization/easy_localization.dart';
import '../../../../../common_imports.dart';
import '../../widgets/sale_summary.dart';

/// قسم الخصم + الملاحظة + الملخص.
class SaleExtrasSection extends StatelessWidget {
  final bool isDark;
  final TextEditingController discountController;
  final TextEditingController noteController;
  final double subtotal;
  final double discount;
  final double total;
  final int itemsCount;
  final VoidCallback onRecalc;

  const SaleExtrasSection({
    super.key,
    required this.isDark,
    required this.discountController,
    required this.noteController,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.itemsCount,
    required this.onRecalc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'saleExtras'.tr(),
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppTheme.ink,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
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
            children: [
              TextFormField(
                controller: discountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'saleDiscountLabel'.tr(),
                  hintText: '0',
                  suffixText: 'currencyEGP'.tr(),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(8.w),
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.discount_rounded,
                        size: 17.sp, color: AppTheme.danger),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryColor, width: 1.6),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final d = double.tryParse(v);
                  if (d == null) return 'saleDiscountInvalid'.tr();
                  if (d < 0) return 'saleDiscountNegative'.tr();
                  return null;
                },
                onChanged: (_) => onRecalc(),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: noteController,
                maxLines: 2,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'saleNoteLabel'.tr(),
                  hintText: 'saleNoteHint'.tr(),
                  hintStyle: TextStyle(fontSize: 12.sp, color: AppTheme.mutedGray),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(8.w),
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: AppTheme.slateGray.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.note_alt_outlined,
                        size: 17.sp, color: AppTheme.slateGray),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.borderSoft,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryColor, width: 1.6),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SaleSummary(
          subtotal: subtotal,
          discount: discount > subtotal
              ? subtotal
              : (discount < 0 ? 0 : discount),
          total: total,
          itemsCount: itemsCount,
        ),
        SizedBox(height: 110.h),
      ],
    );
  }
}