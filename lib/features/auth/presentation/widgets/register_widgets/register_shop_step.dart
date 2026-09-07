import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

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
        RegisterSectionTitle(
          title: 'shopTitle'.tr(),
          subtitle: 'shopSubtitle'.tr(),
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
      label: 'shopName'.tr(),
      hint: 'shopNameHint'.tr(),
      icon: Icons.storefront_outlined,
      validator: _required('shopNameEmpty'.tr()),
    );
  }

  Widget _buildBusinessTypeDropdown() {
    return RegisterDropdown(
      label: 'shopBusinessType'.tr(),
      hint: 'shopBusinessHint'.tr(),
      icon: Icons.category_outlined,
      controller: widget.businessTypeController,
      items: RegisterConstants.businessTypes,
      validator: _required('shopBusinessEmpty'.tr()),
    );
  }

  Widget _buildShopPhoneField() {
    return RegisterTextField(
      controller: widget.shopPhoneController,
      label: 'shopPhone'.tr(),
      hint: 'shopPhoneHint'.tr(),
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: RegisterConstants.validateEgyptianPhone,
    );
  }

  Widget _buildAddressField() {
    return RegisterTextField(
      controller: widget.addressController,
      label: 'shopAddress'.tr(),
      hint: 'shopAddressHint'.tr(),
      icon: Icons.location_on_outlined,
      validator: _required('shopAddressEmpty'.tr()),
    );
  }

  Widget _buildGovernorateDropdown() {
    return RegisterDropdown(
      label: 'shopGovernorate'.tr(),
      hint: 'shopGovernorateHint'.tr(),
      icon: Icons.map_outlined,
      controller: widget.stateController,
      items: RegisterConstants.governorates,
      validator: _required('shopGovernorateEmpty'.tr()),
    );
  }

  Widget _buildCityDropdown() {
    return RegisterDropdown(
      label: 'shopCity'.tr(),
      hint: _availableCenters.isEmpty
          ? 'shopCityHintEmpty'.tr()
          : 'shopCityHint'.tr(),
      icon: Icons.location_city_outlined,
      controller: widget.cityController,
      items: _availableCenters,
      validator: _required('shopCityEmpty'.tr()),
    );
  }

  static String? Function(String?) _required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }
}
