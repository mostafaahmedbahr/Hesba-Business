import 'package:easy_localization/easy_localization.dart';
import '../../../../../common_imports.dart';
import '../add_sale_button.dart';

/// شريط الحفظ الثابت (إجمالي + حفظ) في شاشة إضافة بيع.
class AddSaleBottomBar extends StatelessWidget {
  final double total;
  final bool loading;
  final VoidCallback onSave;

  const AddSaleBottomBar({
    super.key,
    required this.total,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.hairline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'saleTotalLabel'.tr(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.mutedGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'saleTotalAmount'.tr(namedArgs: {
                        'total': total.toStringAsFixed(
                            total == total.roundToDouble() ? 0 : 2),
                        'currency': 'currencyEGP'.tr(),
                      }),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.successDark,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: AddSaleButton(
                loading: loading,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}