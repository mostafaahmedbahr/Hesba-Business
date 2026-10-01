import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../cubit/returns_list_state.dart';

/// هيدر المرتجعات (إجمالي كبير + النهاردة).
class ReturnsListHeader extends StatelessWidget {
  final int count;
  final double totalValue;
  final int todayCount;
  final double todayValue;
  final VoidCallback? onAdd;

  const ReturnsListHeader({
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
      expandedHeight: 210.h,
      backgroundColor: const Color(0xFFF59E0B),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      stretch: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('navReturns'.tr(), style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFFFBBF24)])),
          child: Stack(children: [
            Positioned(top: -50.h, left: -40.w, child: Container(width: 150.w, height: 150.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(bottom: -40.h, right: -30.w, child: Container(width: 170.w, height: 170.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 14.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        count == 0 ? 'لا توجد مرتجعات' : '$count مرتجع',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90)),
                      ),
                    ),
                    if (onAdd != null)
                      InkWell(
                        onTap: () { HapticFeedback.lightImpact(); onAdd!(); },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, size: 16.sp, color: const Color(0xFFB45309)),
                            SizedBox(width: 4.w),
                            Text('مرتجع جديد', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
                          ]),
                        ),
                      ),
                  ]),
                  SizedBox(height: 6.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtReturn(totalValue),
                          style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1),
                        ),
                        SizedBox(width: 8.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text('ج.م • الإجمالي', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88))),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.today_rounded, size: 15.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          todayCount == 0 ? 'مفيش مرتجعات النهاردة' : 'النهاردة: $todayCount • ${fmtReturn(todayValue)} ج.م',
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
