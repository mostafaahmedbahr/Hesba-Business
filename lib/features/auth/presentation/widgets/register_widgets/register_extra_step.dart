import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'register_section_title.dart';
import 'register_text_field.dart';

class RegisterExtraStep extends StatelessWidget {
  final TextEditingController locationUrlController;
  final TextEditingController shopImageUrlController;

  const RegisterExtraStep({
    super.key,
    required this.locationUrlController,
    required this.shopImageUrlController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const RegisterSectionTitle(
          title: 'خطوات أخيرة',
          subtitle:
          'يمكنك إضافة الموقع وصورة المحل',
        ),

        SizedBox(height: 24.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius:
            BorderRadius.circular(18.r),
            border: Border.all(
              color: const Color(0xFFE4ECF7),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 42.sp,
                color:
                const Color(0xFF0B4D9C),
              ),

              SizedBox(height: 10.h),

              Text(
                'صورة المحل',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                'سنضيف رفع الصورة من الجهاز لاحقًا',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 18.h),

        RegisterTextField(
          controller:
          locationUrlController,
          label: 'رابط موقع المحل',
          hint: 'Google Maps URL',
          icon: Icons.location_on_outlined,
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller:
          shopImageUrlController,
          label: 'رابط صورة المحل',
          hint: 'Image URL',
          icon: Icons.image_outlined,
        ),
      ],
    );
  }
}