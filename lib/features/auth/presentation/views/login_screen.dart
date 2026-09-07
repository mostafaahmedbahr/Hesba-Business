import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/core/widgets/custom_button.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';
import 'package:hesba/features/auth/presentation/widgets/auth_header.dart';
import 'package:hesba/features/auth/presentation/widgets/auth_footer.dart';
import 'package:hesba/features/auth/presentation/widgets/email_field.dart';
import 'package:hesba/features/auth/presentation/widgets/password_field.dart';
import 'package:hesba/features/auth/presentation/views/register_screen.dart';
import 'package:hesba/features/auth/presentation/views/reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _navigateToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: _handleAuthState,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.backgroundColor,
              ],
              stops: [0.3, 0.3],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    const AuthHeader(
                      title: 'حسبة',
                      subtitle: 'نظام إدارة المحلات',
                    ),
                    SizedBox(height: 40.h),
                    _buildFormCard(),
                    SizedBox(height: 24.h),
                    AuthFooter(
                      questionText: 'ليس لديك حساب؟ ',
                      actionText: 'إنشاء حساب',
                      onAction: _navigateToRegister,
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          EmailField(controller: _emailController),
          SizedBox(height: 16.h),
          PasswordField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _navigateToResetPassword,
              child: Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'تسجيل الدخول',
                isLoading: state is AuthLoading,
                onPressed: _onLogin,
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthSuccess) {
      AppToast.success(context, state.message);
    } else if (state is AuthError) {
      AppToast.error(context, state.message);
    }
  }
}
