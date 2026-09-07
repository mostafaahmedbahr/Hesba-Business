import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'governorate_centers.dart';
import 'register_constants.dart';
import 'register_dropdown.dart';
import 'register_section_title.dart';
import 'register_text_field.dart';

class RegisterShopStep extends StatefulWidget {
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
  State<RegisterShopStep> createState() => _RegisterShopStepState();
}

class _RegisterShopStepState extends State<RegisterShopStep> {
  List<String> _availableCenters = [];

  @override
  void initState() {
    super.initState();
    _updateCenters(widget.stateController.text);
    widget.stateController.addListener(_onGovernorateChanged);
  }

  @override
  void dispose() {
    widget.stateController.removeListener(_onGovernorateChanged);
    super.dispose();
  }

  void _onGovernorateChanged() {
    final selected = widget.stateController.text;
    print('[RegisterShopStep] _onGovernorateChanged() called. Selected: "$selected"');
    setState(() => _updateCenters(selected));
    print('[RegisterShopStep] Available centers: $_availableCenters');
    if (widget.cityController.text.isNotEmpty &&
        !_availableCenters.contains(widget.cityController.text)) {
      print('[RegisterShopStep] City "${widget.cityController.text}" not in new centers — clearing');
      widget.cityController.clear();
    }
  }

  void _updateCenters(String governorate) {
    print('[RegisterShopStep] _updateCenters() called for: "$governorate"');
    _availableCenters = GovernorateData.getCenters(governorate);
    print('[RegisterShopStep] _updateCenters() result: ${_availableCenters.length} centers');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegisterSectionTitle(
          title: 'بيانات المحل',
          subtitle: 'أخبرنا ببعض التفاصيل عن نشاطك',
        ),
        SizedBox(height: 22.h),
        _buildShopNameField(),
        SizedBox(height: 14.h),
        _buildBusinessTypeDropdown(),
        SizedBox(height: 14.h),
        _buildShopPhoneField(),
        SizedBox(height: 14.h),
        _buildAddressField(),
        SizedBox(height: 14.h),
        _buildGovernorateDropdown(),
        SizedBox(height: 14.h),
        _buildCityDropdown(),
      ],
    );
  }

  Widget _buildShopNameField() {
    return RegisterTextField(
      controller: widget.shopNameController,
      label: 'اسم المحل',
      hint: 'مثال: حسبة ماركت',
      icon: Icons.storefront_outlined,
      validator: _required('اكتب اسم المحل'),
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return RegisterDropdown(
      label: 'نوع النشاط',
      hint: 'اختر نوع النشاط',
      icon: Icons.category_outlined,
      controller: widget.businessTypeController,
      items: RegisterConstants.businessTypes,
      validator: _required('اختر نوع النشاط'),
    );
  }

  Widget _buildShopPhoneField() {
    return RegisterTextField(
      controller: widget.shopPhoneController,
      label: 'هاتف المحل',
      hint: '01xxxxxxxxx',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: RegisterConstants.validateEgyptianPhone,
    );
  }

  Widget _buildAddressField() {
    return RegisterTextField(
      controller: widget.addressController,
      label: 'العنوان',
      hint: 'عنوان المحل',
      icon: Icons.location_on_outlined,
      validator: _required('اكتب العنوان'),
    );
  }

  Widget _buildGovernorateDropdown() {
    return RegisterDropdown(
      label: 'المحافظة',
      hint: 'اختر المحافظة',
      icon: Icons.map_outlined,
      controller: widget.stateController,
      items: RegisterConstants.governorates,
      validator: _required('اختر المحافظة'),
    );
  }

  Widget _buildCityDropdown() {
    return RegisterDropdown(
      label: 'المدينة / المركز',
      hint: _availableCenters.isEmpty
          ? 'اختر المحافظة أولاً'
          : 'اختر',
      icon: Icons.location_city_outlined,
      controller: widget.cityController,
      items: _availableCenters,
      validator: _required('اختر المدينة'),
    );
  }

  static String? Function(String?) _required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }
}
