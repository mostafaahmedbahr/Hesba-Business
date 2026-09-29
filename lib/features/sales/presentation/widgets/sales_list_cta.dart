import 'package:flutter/services.dart';

import '../../../../common_imports.dart';

/// كارت "فاتورة جديدة" البارز.
class SalesListAddCta extends StatelessWidget {
  final VoidCallback onTap;
  const SalesListAddCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.22), width: 1.2), gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.06), isDark ? AppTheme.darkSurface : Colors.white]), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))]),
          child: Row(children: [
            Container(width: 48.w, height: 48.w, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14.r), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]), child: Icon(Icons.add_rounded, size: 24.sp, color: Colors.white)),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إضافة فاتورة مبيعات جديدة', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              SizedBox(height: 3.h),
              Text('سجل عملية بيع جديدة وسيتم تحديث الرصيد تلقائياً', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B))),
            ])),
            Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 16.sp, color: AppTheme.primaryColor)),
          ]),
        ),
      ),
    );
  }
}
