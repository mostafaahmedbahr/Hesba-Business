import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../cubit/register_cubit.dart';
import 'password_strength_indicator.dart';
import 'register_constants.dart';
import 'register_password_field.dart';
import 'register_section_title.dart';
import 'register_text_field.dart';

class RegisterOwnerStep extends StatelessWidget {
  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterOwnerStep({
    super.key,
    required this.ownerNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterSectionTitle(
          title: 'ownerTitle'.tr(),
          subtitle: 'ownerSubtitle'.tr(),
        ),
        SizedBox(height: 22.h),
        _buildNameField(),
        SizedBox(height: 14.h),
        _buildEmailField(),
        SizedBox(height: 14.h),
        _buildPhoneField(),
        SizedBox(height: 14.h),
        _buildPasswordField(context),
        SizedBox(height: 6.h),
        _buildPasswordStrength(),
        SizedBox(height: 14.h),
        _buildConfirmPasswordField(context),
      ],
    );
  }

  Widget _buildNameField() {
    return RegisterTextField(
      controller: ownerNameController,
      label: 'ownerName'.tr(),
      hint: 'ownerNameHint'.tr(),
      icon: Icons.person_outline_rounded,
      validator: _required('ownerNameEmpty'.tr()),
    );
  }

  Widget _buildEmailField() {
    return RegisterTextField(
      controller: emailController,
      label: 'ownerEmail'.tr(),
      hint: 'loginEmailHint'.tr(),
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'ownerEmailEmpty'.tr();
        }
        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'ownerEmailInvalid'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return RegisterTextField(
      controller: phoneController,
      label: 'ownerPhone'.tr(),
      hint: 'ownerPhoneHint'.tr(),
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: RegisterConstants.validateEgyptianPhone,
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return RegisterPasswordField(
      controller: passwordController,
      label: 'ownerPassword'.tr(),
      obscure: context.select(
        (RegisterCubit cubit) => cubit.state.obscurePassword,
      ),
      onToggle: context.read<RegisterCubit>().togglePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'ownerPasswordEmpty'.tr();
        if (!PasswordStrengthIndicator.isStrong(value)) {
          return 'ownerPasswordWeak'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStrength() {
    return ListenableBuilder(
      listenable: passwordController,
      builder: (context, _) {
        if (passwordController.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return PasswordStrengthIndicator(password: passwordController.text);
      },
    );
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    return RegisterPasswordField(
      controller: confirmPasswordController,
      label: 'ownerConfirmPassword'.tr(),
      obscure: context.select(
        (RegisterCubit cubit) => cubit.state.obscureConfirmPassword,
      ),
      onToggle: context.read<RegisterCubit>().toggleConfirmPassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'ownerConfirmEmpty'.tr();
        if (value != passwordController.text) {
          return 'ownerPasswordMismatch'.tr();
        }
        return null;
      },
    );
  }

  static String? Function(String?) _required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }
}
