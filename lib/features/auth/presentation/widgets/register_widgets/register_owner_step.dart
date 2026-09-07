import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../cubit/register_cubit.dart';
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
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const RegisterSectionTitle(
          title: 'بياناتك الشخصية',
          subtitle:
          'هذه البيانات تستخدم للدخول وإدارة حسابك',
        ),

        SizedBox(height: 22.h),

        RegisterTextField(
          controller: ownerNameController,
          label: 'الاسم بالكامل',
          hint: 'أحمد محمد',
          icon: Icons.person_outline_rounded,
          validator: _required('اكتب الاسم'),
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller: emailController,
          label: 'البريد الإلكتروني',
          hint: 'example@email.com',
          icon: Icons.email_outlined,
          keyboardType:
          TextInputType.emailAddress,
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'اكتب البريد الإلكتروني';
            }

            if (!value.contains('@')) {
              return 'البريد الإلكتروني غير صحيح';
            }

            return null;
          },
        ),

        SizedBox(height: 14.h),

        RegisterTextField(
          controller: phoneController,
          label: 'رقم الهاتف',
          hint: '01xxxxxxxxx',
          icon: Icons.phone_outlined,
          keyboardType:
          TextInputType.phone,
          validator: _required(
            'اكتب رقم الهاتف',
          ),
        ),

        SizedBox(height: 14.h),

        RegisterPasswordField(
          controller: passwordController,
          label: 'كلمة المرور',
          obscure: context
              .select(
                (RegisterCubit cubit) =>
            cubit.state.obscurePassword,
          ),
          onToggle: context
              .read<RegisterCubit>()
              .togglePassword,
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'اكتب كلمة المرور';
            }

            if (value.length < 6) {
              return '6 أحرف على الأقل';
            }

            return null;
          },
        ),

        SizedBox(height: 14.h),

        RegisterPasswordField(
          controller:
          confirmPasswordController,
          label: 'تأكيد كلمة المرور',
          obscure: context.select(
                (RegisterCubit cubit) =>
            cubit.state
                .obscureConfirmPassword,
          ),
          onToggle: context
              .read<RegisterCubit>()
              .toggleConfirmPassword,
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'أكد كلمة المرور';
            }

            if (value !=
                passwordController.text) {
              return 'كلمتا المرور غير متطابقتين';
            }

            return null;
          },
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