import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54.w,
          height: 54.w,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius:
            BorderRadius.circular(16.r),
          ),
          child: Image.asset(
            'assets/images/playstore.png',
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.calculate_rounded,
              size: 28.sp,
              color: const Color(0xFF0B4D9C),
            ),
          ),
        ),

        SizedBox(width: 14.w),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'registerTitle'.tr(),
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF102A43),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'registerSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}