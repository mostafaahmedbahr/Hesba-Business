import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../states/products_state.dart';

/// هيدر المنتجات (عدد + قيمة مخزون بسعر الشراء والبيع والربح + نواقص).
class ProductListHeader extends StatelessWidget {
  final int count;

  /// إجمالي سعر الشراء للمخزون.
  final double inventoryValue;

  /// إجمالي سعر البيع للمخزون.
  final double saleValue;

  /// الربح الإجمالي المتوقع.
  final double expectedProfit;

  final int lowStockCount;
  final VoidCallback? onAdd;

  const ProductListHeader({
    super.key,
    required this.count,
    required this.inventoryValue,
    required this.saleValue,
    required this.expectedProfit,
    required this.lowStockCount,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 268.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D2A86), AppTheme.primaryColor, AppTheme.brightBlue]),
          ),
          child: Stack(
            children: [
              Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
              Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)))),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 12.h),
                  // FittedBox يمنع أي overflow: لو المحتوى أطول من المساحة
                  // المتاحة (خطوط كبيرة / شريط حالة طويل) يتم تصغيره بأمان.
                  child: LayoutBuilder(
                    builder: (context, constraints) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.topStart,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Text('productsTitle'.tr(), style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 2.h),
                                Text('${count} منتج في المخزون', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.inventory_2_rounded, size: 12.sp, color: Colors.white),
                                  SizedBox(width: 5.w),
                                  Text('productsCount'.tr(args: ['$count']), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                                ]),
                              ),
                              if (onAdd != null) ...[
                                SizedBox(width: 8.w),
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: InkWell(
                                    onTap: () { HapticFeedback.lightImpact(); onAdd!(); },
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      width: 36.w, height: 36.w,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
                                      child: Icon(Icons.add_rounded, size: 20.sp, color: AppTheme.primaryColor),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ),
                          SizedBox(height: 8.h),
                          InventoryValueCard(
                            purchaseValue: inventoryValue,
                            saleValue: saleValue,
                            expectedProfit: expectedProfit,
                          ),
                          SizedBox(height: 6.h),
                          ProductHeaderStat(icon: Icons.warning_amber_rounded, label: 'productsLowStock'.tr(), value: lowStockCount > 0 ? '$lowStockCount' : '0', danger: lowStockCount > 0),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رقم زجاجي جوه الهيدر.
class ProductHeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool danger;
  const ProductHeaderStat({super.key, required this.icon, required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: danger ? const Color(0xFFFFD54F) : Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: danger ? const Color(0xFFFFD54F) : Colors.white)),
        ])),
      ]),
    );
  }
}

/// بطاقة "قيمة المخزون": إجمالي سعر الشراء + إجمالي سعر البيع + الربح المتوقع.
class InventoryValueCard extends StatelessWidget {
  final double purchaseValue;
  final double saleValue;
  final double expectedProfit;

  const InventoryValueCard({
    super.key,
    required this.purchaseValue,
    required this.saleValue,
    required this.expectedProfit,
  });

  @override
  Widget build(BuildContext context) {
    final profitColor = expectedProfit >= 0
        ? const Color(0xFF86EFAC) // ربح — أخضر فاتح.
        : const Color(0xFFFFD54F); // خسارة — أصفر تحذيري.

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8.r)),
            child: Icon(Icons.inventory_2_rounded, size: 14.sp, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Text('productsInventoryValue'.tr(), style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        SizedBox(height: 6.h),
        Row(children: [
          _valueColumn(
            label: 'productsPurchaseValue'.tr(),
            value: purchaseValue,
            color: Colors.white,
          ),
          _separator(),
          _valueColumn(
            label: 'productsSaleValue'.tr(),
            value: saleValue,
            color: Colors.white,
          ),
          _separator(),
          _valueColumn(
            label: 'productsExpectedProfit'.tr(),
            value: expectedProfit,
            color: profitColor,
          ),
        ]),
      ]),
    );
  }

  Widget _valueColumn({required String label, required double value, required Color color}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
        SizedBox(height: 2.h),
        Text(
          '${fmtProduct(value)} ${'currencyEGP'.tr()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: color),
        ),
      ]),
    );
  }

  Widget _separator() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.w),
    child: Container(width: 1, height: 30.h, color: Colors.white.withValues(alpha: 0.18)),
  );
}
