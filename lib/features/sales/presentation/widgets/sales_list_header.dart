import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../cubit/sales_list_state.dart';

/// هيدر المبيعات (عدد + إجمالي + النهاردة).
class SalesListHeader extends StatelessWidget {
  final int count;
  final double totalValue;
  final int todayCount;
  final double todayValue;
  final VoidCallback? onAdd;

  const SalesListHeader({
    super.key,
    required this.count,
    required this.totalValue,
    required this.todayCount,
    required this.todayValue,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 192.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      title: count > 0
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Text('navSales'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 8.w),
              Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)), child: Text('$count', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor))),
            ])
          : Text('navSales'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D2A86), Color(0xFF1A4FD6), Color(0xFF4A7BFF)])),
          child: Stack(children: [
            Positioned(top: -40.h, left: -30.w, child: Container(width: 140.w, height: 140.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
            Positioned(bottom: -30.h, right: -20.w, child: Container(width: 180.w, height: 180.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 36.h, 16.w, 12.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Flexible(child: Text('navSales'.tr(), style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 20.w, height: 20.w, decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: Icon(Icons.numbers_rounded, size: 11.sp, color: Colors.white)),
                            SizedBox(width: 6.w),
                            Text('$count', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                          ]),
                        ),
                      ]),
                      SizedBox(height: 4.h),
                      Text(count == 0 ? 'لا توجد مبيعات' : '$count فاتورة • إجمالي ${fmtPrice(totalValue)} ج.م', style: TextStyle(fontSize: 11.sp, color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    SizedBox(width: 10.w),
                    if (onAdd != null)
                      Material(color: Colors.white, borderRadius: BorderRadius.circular(13.r), child: InkWell(onTap: () { HapticFeedback.lightImpact(); onAdd!(); }, borderRadius: BorderRadius.circular(13.r), child: SizedBox(width: 42.w, height: 42.w, child: Icon(Icons.add_rounded, size: 22.sp, color: AppTheme.primaryColor)))),
                  ])),
                  SizedBox(height: 10.h),
                  Row(children: [
                    Expanded(child: SalesHeaderStat(icon: Icons.payments_rounded, label: 'إجمالي المبيعات', value: '${fmtPrice(totalValue)} ج.م')),
                    SizedBox(width: 10.w),
                    Expanded(child: SalesHeaderStat(icon: Icons.today_rounded, label: 'مبيعات اليوم', value: todayCount > 0 ? '$todayCount • ${fmtPrice(todayValue)}' : '0')),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// رقم زجاجي جوه الهيدر.
class SalesHeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SalesHeaderStat({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
      child: Row(children: [
        Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: Colors.white)),
        SizedBox(width: 8.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
        ])),
      ]),
    );
  }
}
