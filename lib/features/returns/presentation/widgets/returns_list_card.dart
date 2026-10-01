import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../data/models/return_model.dart';

/// كارت مرتجع مختصر — ضغطة تفتح التفاصيل.
class ReturnsListCard extends StatefulWidget {
  final ReturnModel ret;
  const ReturnsListCard({super.key, required this.ret});

  @override
  State<ReturnsListCard> createState() => _ReturnsListCardState();
}

/// حالة الفتح/القفل للكارت.
class _ReturnsListCardState extends State<ReturnsListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ret = widget.ret;
    final dateStr = DateFormat('dd/MM/yyyy  •  hh:mm a', 'ar').format(ret.createdAt);
    final idShort = ret.returnId.length >= 6 ? ret.returnId.substring(0, 6) : ret.returnId;
    final itemsLabel = ret.items.isEmpty
        ? (ret.reason.isEmpty ? 'مرتجع' : ret.reason)
        : ret.items.length == 1
            ? ret.items.first.productName
            : '${ret.items.first.productName} +${ret.items.length - 1}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _expanded ? const Color(0xFFF59E0B).withValues(alpha: 0.35) : (isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الملخص الدائم.
                Row(children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(13.r)),
                    child: Icon(Icons.assignment_return_rounded, size: 21.sp, color: Colors.white),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مرتجع #$idShort', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        SizedBox(height: 3.h),
                        Text('$itemsLabel • $dateStr', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('-${ret.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48), height: 1)),
                      Text('ج.م', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                  SizedBox(width: 6.w),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 22.sp, color: const Color(0xFF94A3B8)),
                  ),
                ]),
                // التفاصيل (تظهر بالضغطة).
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _Details(ret: ret, isDark: isDark),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل المرتجع (أصناف + سبب + ملاحظة).
class _Details extends StatelessWidget {
  final ReturnModel ret;
  final bool isDark;
  const _Details({required this.ret, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...ret.items.map((it) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.productName} × ${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('${it.total.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    ],
                  ),
                )),
            Row(children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFFDBA74))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.info_outline_rounded, size: 12.sp, color: const Color(0xFFD97706)),
                  SizedBox(width: 5.w),
                  Text(ret.reason.isEmpty ? 'بدون سبب' : ret.reason, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
                ]),
              ),
              if (ret.originalSaleId != null) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Text('مرتبط بفاتورة', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(dateTimeLabel(ret.createdAt), style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF94A3B8))),
            ]),
            if (ret.note.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(ret.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5.sp, color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
            ],
          ],
        ),
      ),
    );
  }
}

/// وقت مختصر (اليوم / أمس / تاريخ).
String dateTimeLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  final time = DateFormat('hh:mm a', 'ar').format(dt);
  if (diff == 0) return 'اليوم • $time';
  if (diff == 1) return 'أمس • $time';
  return '${DateFormat('dd/MM', 'ar').format(dt)} • $time';
}
