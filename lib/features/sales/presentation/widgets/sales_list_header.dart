import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../cubit/sales_list_state.dart';

/// هيدر المبيعات (رقم hero متحرك + إحصائيات زجاجية).
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
      expandedHeight: 216.h,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      title: Text('navSales'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0A1F5C), Color(0xFF1A4FD6), Color(0xFF6D9BFF)],
            ),
          ),
          child: Stack(children: [
            // توهجات ناعمة.
            Positioned(top: -60.h, right: -40.w, child: _Orb(size: 190.w, opacity: 0.16)),
            Positioned(bottom: -70.h, left: -50.w, child: Container(width: 210.w, height: 210.w, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF5A623).withValues(alpha: 0.14)))),
            Positioned(top: 70.h, left: 40.w, child: _Orb(size: 90.w, opacity: 0.10)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 38.h, 18.w, 14.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  // شارة العنوان + عدد الفواتير.
                  Row(children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long_rounded, size: 12.sp, color: Colors.white),
                        SizedBox(width: 5.w),
                        Text(count == 0 ? 'لا توجد مبيعات' : '$count فاتورة', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                      ]),
                    ),
                    const Spacer(),
                    if (onAdd != null)
                      InkWell(
                        onTap: () { HapticFeedback.lightImpact(); onAdd!(); },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 5))],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, size: 16.sp, color: AppTheme.primaryColor),
                            SizedBox(width: 4.w),
                            Text('بيع جديد', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                          ]),
                        ),
                      ),
                  ]),
                  SizedBox(height: 8.h),
                  // الرقم الكبير (يتحرك عند التغير).
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: totalValue),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmtPrice(value), style: TextStyle(fontSize: 44.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1.2)),
                          SizedBox(width: 8.w),
                          Padding(
                            padding: EdgeInsets.only(bottom: 7.h),
                            child: Text('ج.م', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.88))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text('إجمالي المبيعات', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.80))),
                  SizedBox(height: 10.h),
                  // شارة النهاردة.
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 26.w, height: 26.w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(8.r)), child: Icon(Icons.today_rounded, size: 14.sp, color: Colors.white)),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          todayCount == 0 ? 'مفيش مبيعات النهاردة لسه' : 'النهاردة: $todayCount ${todayCount == 1 ? 'فاتورة' : 'فواتير'} • ${fmtPrice(todayValue)} ج.م',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// دائرة توهج بيضاء.
class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
    );
  }
}
