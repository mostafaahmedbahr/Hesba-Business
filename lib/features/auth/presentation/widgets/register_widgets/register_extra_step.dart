import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

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
        RegisterSectionTitle(
          title: 'extraTitle'.tr(),
          subtitle: 'extraSubtitle'.tr(),
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
            'extraCardTitle'.tr(),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'extraCardDesc'.tr(),
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
      label: 'extraLocation'.tr(),
      hint: 'https://maps.app.goo.gl/...',
      icon: Icons.location_on_outlined,
      keyboardType: TextInputType.url,
      validator: _validateUrl,
    );
  }

  Widget _buildImageField() {
    return RegisterTextField(
      controller: shopImageUrlController,
      label: 'extraImage'.tr(),
      hint: 'https://...',
      icon: Icons.image_outlined,
      keyboardType: TextInputType.url,
      validator: _validateUrl,
    );
  }

  static String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'extraFieldEmpty'.tr();
    }
    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'extraUrlInvalid'.tr();
    }
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'extraUrlBad'.tr();
      }
      return null;
    } catch (_) {
      return 'extraUrlBad'.tr();
    }
  }
}
