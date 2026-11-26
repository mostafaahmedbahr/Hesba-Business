import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/number_parser.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/utils/dynamic_text.dart';

/// معاينة الربح/الخسارة اللحظية في قسم التسعير:
/// تاخد نص السعر والتكلفة زي ما هما في الحقول، وتحسب الفرق والهامش.
///
/// لو أي قيمة مش رقم صالح أو ≤ صفر بترجع `SizedBox.shrink()`.
class ProductProfitPreview extends StatelessWidget {
  final String costText;
  final String priceText;
  const ProductProfitPreview({
    super.key,
    required this.costText,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    final cost = double.tryParse(NumberParser.toLatin(costText));
    final price = double.tryParse(NumberParser.toLatin(priceText));
    if (cost == null || price == null || cost <= 0 || price <= 0) {
      return const SizedBox.shrink();
    }
    final profit = price - cost;
    final margin = price > 0 ? (profit / price * 100) : 0;
    final positive = profit >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFECFDF5) : AppTheme.dangerSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: positive
              ? AppTheme.successDark.withValues(alpha: 0.14)
              : AppTheme.danger.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16.sp,
            color: positive ? AppTheme.successDark : AppTheme.danger,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              positive
                  ? uiTr('ربح ${_num(profit)} ج.م • هامش ${margin.toStringAsFixed(1)}%')
                  : uiTr('خسارة ${_num(profit.abs())} ج.م'),
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: positive ? AppTheme.successDark : AppTheme.danger,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: positive ? AppTheme.successDark : AppTheme.danger,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              positive ? 'مربح'.tr() : 'خسارة'.tr(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
