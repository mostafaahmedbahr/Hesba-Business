import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';

import 'login_button.dart';
import 'login_text_field.dart';

class LoginFormCard extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const LoginFormCard({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(),

          SizedBox(height: 26.h),

          LoginTextField(
            controller: widget.emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          )
              .animate()
              .fadeIn(
            delay: 350.ms,
            duration: 500.ms,
          )
              .slideX(
            begin: 0.08,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),

          SizedBox(height: 16.h),

          LoginTextField(
            controller: widget.passwordController,
            label: 'كلمة المرور',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onLogin(),
            validator: _validatePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 21.sp,
                color: AppTheme.primaryColor.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
            delay: 450.ms,
            duration: 500.ms,
          )
              .slideX(
            begin: 0.08,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),

          SizedBox(height: 8.h),

          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 6.h,
                ),
              ),
              child: Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return LoginButton(
                isLoading: state is AuthLoading,
                onPressed: widget.onLogin,
              );
            },
          )
              .animate()
              .fadeIn(
            delay: 550.ms,
            duration: 500.ms,
          )
              .slideY(
            begin: 0.15,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Column(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Icon(
            Icons.login_rounded,
            color: AppTheme.primaryColor,
            size: 25.sp,
          ),
        ),

        SizedBox(height: 14.h),

        Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF172033),
            fontFamily: AppTheme.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 5.h),

        Text(
          'أدخل بيانات حسابك للمتابعة',
          style: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF7B8496),
            fontFamily: AppTheme.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'أدخل البريد الإلكتروني';
    }

    if (!value.contains('@')) {
      return 'البريد الإلكتروني غير صالح';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل كلمة المرور';
    }

    return null;
  }
}