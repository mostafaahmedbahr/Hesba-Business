import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/toast.dart';
import '../../cubit/login_cubit.dart';
import '../../states/login_state.dart';
import 'login_header.dart';
import 'login_text_field.dart';

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoginHeader(),
            SizedBox(height: 28.h),
            _buildEmailField(),
            SizedBox(height: 14.h),
            _buildPasswordField(),
            SizedBox(height: 10.h),
            _buildForgotPassword(),
            SizedBox(height: 24.h),
            _buildLoginButton(),
            SizedBox(height: 18.h),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return LoginTextField(
      controller: widget.emailController,
      label: 'البريد الإلكتروني',
      hint: 'example@email.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'اكتب البريد الإلكتروني';
        }
        if (!value.contains('@')) {
          return 'البريد الإلكتروني غير صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.obscurePassword != curr.obscurePassword,
      builder: (context, state) {
        return LoginTextField(
          controller: widget.passwordController,
          label: 'كلمة المرور',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: state.obscurePassword,
          suffixIcon: IconButton(
            onPressed: context.read<LoginCubit>().togglePassword,
            icon: Icon(
              state.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اكتب كلمة المرور';
            }
            if (value.length < 6) {
              return '6 أحرف على الأقل';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          AppToast.info(context, 'ستتوفر هذه الميزة قريباً');
        },
        child: Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFF0B4D9C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final isLoading = state.status == LoginStatus.loading;
        return SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B4D9C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF0B4D9C).withValues(alpha: 0.5),
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
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟ ',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/register'),
          child: Text(
            'سجّل الآن',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B4D9C),
            ),
          ),
        ),
      ],
    );
  }

  void _onLogin() {
    if (!widget.formKey.currentState!.validate()) return;

    context.read<LoginCubit>().login(
          email: widget.emailController.text,
          password: widget.passwordController.text,
        );
  }
}
