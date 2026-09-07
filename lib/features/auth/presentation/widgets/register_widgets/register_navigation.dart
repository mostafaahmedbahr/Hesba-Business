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
                onPressed: isLoading ? null : () => _onPressed(context, isLastStep),
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
    if (isLastStep) {
      _submit(context);
    } else {
      _nextOrValidate(context);
    }
  }

  void _nextOrValidate(BuildContext context) {
    final step = context.read<RegisterCubit>().state.step;

    if (step == 0 && _validateOwnerStep()) {
      context.read<RegisterCubit>().nextStep();
    } else if (step == 1 && _validateShopStep()) {
      context.read<RegisterCubit>().nextStep();
    }
  }

  void _submit(BuildContext context) {
    if (!formKey.currentState!.validate()) return;

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

    context.read<RegisterCubit>().register(
          model: model,
          password: passwordController.text,
        );
  }

  bool _validateOwnerStep() {
    return [
      _required(ownerNameController.text, 'اكتب الاسم'),
      _validateEmail(emailController.text),
      _required(phoneController.text, 'اكتب رقم الهاتف'),
      _validatePassword(passwordController.text),
      _validateConfirmPassword(confirmPasswordController.text),
    ].every((e) => e == null);
  }

  bool _validateShopStep() {
    return [
      _required(shopNameController.text, 'اكتب اسم المحل'),
      _required(businessTypeController.text, 'اكتب نوع النشاط'),
      _required(shopPhoneController.text, 'اكتب هاتف المحل'),
      _required(addressController.text, 'اكتب العنوان'),
      _required(cityController.text, 'اكتب المدينة'),
      _required(stateController.text, 'اكتب المحافظة'),
    ].every((e) => e == null);
  }

  String? _required(String value, String message) {
    return value.trim().isEmpty ? message : null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'اكتب البريد الإلكتروني';
    if (!value.contains('@')) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'اكتب كلمة المرور';
    if (value.length < 6) return '6 أحرف على الأقل';
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'أكد كلمة المرور';
    if (value != passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }
}
