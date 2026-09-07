import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'register_section_title.dart';
import 'register_text_field.dart';

class RegisterShopStep extends StatelessWidget {
  final TextEditingController shopNameController;
  final TextEditingController businessTypeController;
  final TextEditingController shopPhoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;

  const RegisterShopStep({
    super.key,
    required this.shopNameController,
    required this.businessTypeController,
    required this.shopPhoneController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const RegisterSectionTitle(
          title: 'بيانات المحل',
          subtitle:
          'أخبرنا ببعض التفاصيل عن نشاطك',
        ),

        SizedBox(height: 22.h),

        RegisterTextField(
          controller: shopNameController,
          label: 'اسم المحل',
          hint: 'مثال: حسبة ماركت',
          icon: Icons.storefront_outlined,
          validator: _required(
            'اكتب اسم المحل',
          ),
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller:
          businessTypeController,
          label: 'نوع النشاط',
          hint: 'مثال: سوبر ماركت',
          icon: Icons.category_outlined,
          validator: _required(
            'اكتب نوع النشاط',
          ),
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller: shopPhoneController,
          label: 'هاتف المحل',
          hint: '01xxxxxxxxx',
          icon: Icons.phone_outlined,
          keyboardType:
          TextInputType.phone,
          validator: _required(
            'اكتب هاتف المحل',
          ),
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller: addressController,
          label: 'العنوان',
          hint: 'عنوان المحل',
          icon: Icons.location_on_outlined,
          validator: _required(
            'اكتب العنوان',
          ),
        ),

        SizedBox(height: 14.h),

        Row(
          children: [
            Expanded(
              child: RegisterTextField(
                controller: cityController,
                label: 'المدينة',
                hint: 'القاهرة',
                icon: Icons.location_city_outlined,
                validator: _required(
                  'اكتب المدينة',
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: RegisterTextField(
                controller: stateController,
                label: 'المحافظة',
                hint: 'القاهرة',
                icon: Icons.map_outlined,
                validator: _required(
                  'اكتب المحافظة',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? Function(String?) _required(
      String message,
      ) {
    return (value) {
      if (value == null ||
          value.trim().isEmpty) {
        return message;
      }

      return null;
    };
  }
}