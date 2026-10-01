import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../cubit/reports_state.dart';

/// كارت الأكثر مبيعاً (top 5).
class ReportsTopProducts extends StatelessWidget {
  final ReportsState state;
  const ReportsTopProducts({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = state.topProducts;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.star_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Text('الأكثر مبيعاً', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const Spacer(),
          Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20.r)), child: Text('${top.length} منتج', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)))),
        ]),
        SizedBox(height: 14.h),
        if (top.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.h), child: Column(children: [Icon(Icons.inventory_2_outlined, size: 32.sp, color: const Color(0xFFCBD5E1)), SizedBox(height: 8.h), Text('لا توجد مبيعات', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF94A3B8)))])))
        else
          Column(
            children: List.generate(top.length, (i) {
              final e = top[i];
              return Container(
                margin: EdgeInsets.only(bottom: i == top.length - 1 ? 0 : 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Container(width: 32.w, height: 32.w, decoration: BoxDecoration(gradient: LinearGradient(colors: i == 0 ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)] : [const Color(0xFF64748B), const Color(0xFF94A3B8)]), shape: BoxShape.circle), child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.white)))),
                  SizedBox(width: 10.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    Text('${fmtReport(e.revenue)} ج.م • ${e.qty.toStringAsFixed(e.qty % 1 == 0 ? 0 : 1)} قطعة', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
                  ])),
                  Icon(Icons.trending_up_rounded, size: 16.sp, color: const Color(0xFF059669)),
                ]),
              );
            }),
          ),
      ]),
    );
  }
}

/// كارت آخر الحركات.
class ReportsRecentActivity extends StatelessWidget {
  final ReportsState state;
  const ReportsRecentActivity({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recent = state.recentActivity;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)), boxShadow: AppTheme.cardShadow(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.history_rounded, color: Colors.white, size: 18.sp)),
          SizedBox(width: 10.w),
          Text('آخر الحركات', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ]),
        SizedBox(height: 14.h),
        if (recent.isEmpty)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.h), child: Text('لا توجد حركات', style: TextStyle(color: const Color(0xFF94A3B8)))))
        else
          Column(
            children: recent.map((m) {
              final kind = m['kind'] as int;
              final color = kind == 0 ? const Color(0xFF059669) : kind == 1 ? const Color(0xFFF59E0B) : const Color(0xFFE11D48);
              final icon = kind == 0 ? Icons.point_of_sale_rounded : kind == 1 ? Icons.assignment_return_rounded : Icons.savings_rounded;
              final amount = m['amount'] as double;
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, size: 16.sp, color: color)),
                  SizedBox(width: 10.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    Text(DateFormat('dd MMM • hh:mm a', 'ar').format(m['date'] as DateTime), style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                  ])),
                  Text('${amount >= 0 ? '+' : ''}${fmtReport(amount)} ج.م', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: amount >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                ]),
              );
            }).toList(),
          ),
      ]),
    );
  }
}
