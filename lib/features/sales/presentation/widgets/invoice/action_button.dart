import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

/// زرار إرسال ملوّن (واتساب / مشاركة).
class InvoiceActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  /// عليه دوّارة التحميل (الزرار اللي اتضغط عليه).
  final bool busy;

  /// معطّل من غير تحميل (لما زرار تاني شغّال).
  final bool blocked;
  final VoidCallback onTap;
  const InvoiceActionButton({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.busy,
    this.blocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: (busy || blocked) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18.sp),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
    );
  }
}
