import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/core/widgets/custom_button.dart';
import 'package:hesba/core/widgets/custom_text_field.dart';
import 'package:hesba/core/utils/validators.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';
import 'package:hesba/features/auth/presentation/widgets/auth_header.dart';
import 'package:hesba/features/auth/presentation/widgets/auth_footer.dart';
import 'package:hesba/features/auth/presentation/widgets/email_field.dart';
import 'package:hesba/features/auth/presentation/widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            shopName: _shopNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
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
              stops: [0.2, 0.2],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    const AuthHeader(
                      showLogo: true,
                    ),
                    SizedBox(height: 24.h),
                    _buildFormCard(),
                    SizedBox(height: 24.h),
                    AuthFooter(
                      questionText: 'لديك حساب بالفعل؟ ',
                      actionText: 'تسجيل الدخول',
                      onAction: () => Navigator.pop(context),
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
            'إنشاء حساب جديد',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'أدخل بياناتك لإنشاء حساب',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomTextField(
            controller: _nameController,
            labelText: 'الاسم الكامل',
            prefixIcon: Icons.person_outlined,
            validator: (v) => Validators.required(v, 'أدخل اسمك'),
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: _shopNameController,
            labelText: 'اسم المحل',
            prefixIcon: Icons.store_outlined,
            validator: (v) => Validators.required(v, 'أدخل اسم المحل'),
          ),
          SizedBox(height: 16.h),
          EmailField(controller: _emailController),
          SizedBox(height: 16.h),
          PasswordField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          SizedBox(height: 16.h),
          PasswordField(
            controller: _confirmPasswordController,
            labelText: 'تأكيد كلمة المرور',
            obscureText: true,
            onToggleVisibility: () {},
            validator: (v) => Validators.confirmPassword(
              v,
              _passwordController.text,
            ),
          ),
          SizedBox(height: 24.h),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'إنشاء حساب',
                isLoading: state is AuthLoading,
                onPressed: _onRegister,
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (state is AuthError) {
      AppToast.error(context, state.message);
    }
  }
}
