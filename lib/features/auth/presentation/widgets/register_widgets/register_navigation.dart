import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';
import '../../../data/models/register_model.dart';

class RegisterNavigation extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final TextEditingController shopNameController;
  final TextEditingController businessTypeController;
  final TextEditingController shopPhoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;

  final TextEditingController locationUrlController;
  final TextEditingController shopImageUrlController;

  const RegisterNavigation({
    super.key,
    required this.formKey,
    required this.ownerNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.shopNameController,
    required this.businessTypeController,
    required this.shopPhoneController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.locationUrlController,
    required this.shopImageUrlController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        final isFirstStep = state.step == 0;
        final isLastStep = state.step == 2;
        final isLoading = state.status == RegisterStatus.loading;

        return Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: _buildButton(
                  label: 'رجوع',
                  isLoading: false,
                  isOutlined: true,
                  onPressed: cubit.previousStep,
                ),
              ),
            if (!isFirstStep) SizedBox(width: 12.w),
            Expanded(
              child: _buildButton(
                label: isLastStep ? 'إنشاء حساب' : 'التالي',
                isLoading: isLoading,
                isOutlined: false,
                onPressed: isLoading
                    ? null
                    : () => _onPressed(context, isLastStep),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required String label,
    required bool isLoading,
    required bool isOutlined,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0B4D9C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0B4D9C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B4D9C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
    );
  }

  void _onPressed(BuildContext context, bool isLastStep) {
    print('[RegisterNavigation] _onPressed() called. isLastStep: $isLastStep');
    if (isLastStep) {
      _submit(context);
    } else {
      _nextStep(context);
    }
  }

  void _nextStep(BuildContext context) {
    print('[RegisterNavigation] _nextStep() called');
    if (!formKey.currentState!.validate()) {
      print('[RegisterNavigation] Form validation FAILED — stopping');
      return;
    }
    print('[RegisterNavigation] Form validation PASSED — calling cubit.nextStep()');
    context.read<RegisterCubit>().nextStep();
  }

  void _submit(BuildContext context) {
    print('[RegisterNavigation] _submit() called');
    if (!formKey.currentState!.validate()) {
      print('[RegisterNavigation] Form validation FAILED — stopping');
      return;
    }
    print('[RegisterNavigation] Form validation PASSED');

    final now = DateTime.now();
    final model = RegisterModel(
      ownerId: '',
      shopId: '',
      ownerName: ownerNameController.text,
      email: emailController.text,
      phone: phoneController.text,
      shopName: shopNameController.text,
      businessType: businessTypeController.text,
      shopPhone: shopPhoneController.text,
      locationUrl: locationUrlController.text,
      shopImageUrl: shopImageUrlController.text,
      address: addressController.text,
      city: cityController.text,
      state: stateController.text,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    print('[RegisterNavigation] RegisterModel created:');
    print('  ownerName: ${model.ownerName}');
    print('  email: ${model.email}');
    print('  phone: ${model.phone}');
    print('  shopName: ${model.shopName}');
    print('  businessType: ${model.businessType}');
    print('  shopPhone: ${model.shopPhone}');
    print('  locationUrl: ${model.locationUrl}');
    print('  shopImageUrl: ${model.shopImageUrl}');
    print('  address: ${model.address}');
    print('  city: ${model.city}');
    print('  state: ${model.state}');

    print('[RegisterNavigation] calling cubit.register()...');
    context.read<RegisterCubit>().register(
          model: model,
          password: passwordController.text,
        );
  }
}
