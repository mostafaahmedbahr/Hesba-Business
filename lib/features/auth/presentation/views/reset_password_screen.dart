import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/core/widgets/custom_button.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';
import 'package:hesba/features/auth/presentation/widgets/auth_header.dart';
import 'package:hesba/features/auth/presentation/widgets/email_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetLink() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPassword(
            _emailController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
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
              stops: [0.25, 0.25],
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
                      showLogo: true,
                    ),
                    SizedBox(height: 32.h),
                    _buildFormCard(),
                    SizedBox(height: 24.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'العودة لتسجيل الدخول',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                        ),
                      ),
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
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 48.w,
              color: AppTheme.secondaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'نسيت كلمة المرور؟',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          EmailField(controller: _emailController),
          SizedBox(height: 24.h),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'إرسال رابط الاستعادة',
                isLoading: state is AuthLoading,
                onPressed: _onSendResetLink,
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
      Navigator.pop(context);
    } else if (state is AuthError) {
      AppToast.error(context, state.message);
    }
  }
}
