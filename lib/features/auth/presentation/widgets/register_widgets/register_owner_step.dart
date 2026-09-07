import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        const RegisterSectionTitle(
          title: 'بياناتك الشخصية',
          subtitle: 'هذه البيانات تستخدم للدخول وإدارة حسابك',
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
      label: 'الاسم بالكامل',
      hint: 'أحمد محمد',
      icon: Icons.person_outline_rounded,
      validator: _required('اكتب الاسم'),
    );
  }

  Widget _buildEmailField() {
    return RegisterTextField(
      controller: emailController,
      label: 'البريد الإلكتروني',
      hint: 'example@email.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'اكتب البريد الإلكتروني';
        }
        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'البريد الإلكتروني غير صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return RegisterTextField(
      controller: phoneController,
      label: 'رقم الهاتف',
      hint: '01xxxxxxxxx',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: RegisterConstants.validateEgyptianPhone,
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return RegisterPasswordField(
      controller: passwordController,
      label: 'كلمة المرور',
      obscure: context.select(
        (RegisterCubit cubit) => cubit.state.obscurePassword,
      ),
      onToggle: context.read<RegisterCubit>().togglePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'اكتب كلمة المرور';
        if (!PasswordStrengthIndicator.isStrong(value)) {
          return 'كلمة المرور غير كافية';
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
      label: 'تأكيد كلمة المرور',
      obscure: context.select(
        (RegisterCubit cubit) => cubit.state.obscureConfirmPassword,
      ),
      onToggle: context.read<RegisterCubit>().toggleConfirmPassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'أكد كلمة المرور';
        if (value != passwordController.text) {
          return 'كلمتا المرور غير متطابقتين';
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
