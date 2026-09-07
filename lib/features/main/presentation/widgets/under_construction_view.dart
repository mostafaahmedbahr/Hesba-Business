import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A graceful placeholder shown for tabs under construction.
class UnderConstructionView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const UnderConstructionView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4FD6), Color(0xFF3B6FF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A4FD6).withValues(alpha: 0.25),
                  blurRadius: 24.r,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 40.sp, color: Colors.white),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
