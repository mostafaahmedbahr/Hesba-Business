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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegisterSectionTitle(
          title: 'بيانات إضافية',
          subtitle: 'أضف رابط موقع المحل وصورته',
        ),
        SizedBox(height: 24.h),
        _buildInfoCard(),
        SizedBox(height: 18.h),
        _buildLocationField(),
        SizedBox(height: 14.h),
        _buildImageField(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 42.sp,
            color: const Color(0xFF0B4D9C),
          ),
          SizedBox(height: 10.h),
          Text(
            'صورة المحل وموقعه',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'أضف رابط صورة المحل ورابط الموقع على خرائط جوجل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return RegisterTextField(
      controller: locationUrlController,
      label: 'رابط موقع المحل *',
      hint: 'https://maps.app.goo.gl/...',
      icon: Icons.location_on_outlined,
      keyboardType: TextInputType.url,
      validator: _validateUrl,
    );
  }

  Widget _buildImageField() {
    return RegisterTextField(
      controller: shopImageUrlController,
      label: 'رابط صورة المحل *',
      hint: 'https://...',
      icon: Icons.image_outlined,
      keyboardType: TextInputType.url,
      validator: _validateUrl,
    );
  }

  static String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'أدخل رابط صحيح يبدأ بـ http:// أو https://';
    }
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'رابط غير صالح';
      }
      return null;
    } catch (_) {
      return 'رابط غير صالح';
    }
  }
}
