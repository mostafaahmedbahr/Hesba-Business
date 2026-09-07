import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/toast.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';
import 'package:hesba/features/auth/presentation/views/register_screen.dart';
import 'package:hesba/features/auth/presentation/views/reset_password_screen.dart';

import '../widgets/login_widgets/login_footer.dart';
import '../widgets/login_widgets/login_form_card.dart';
import '../widgets/login_widgets/login_header.dart';


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _openResetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResetPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: BlocListener<AuthCubit, AuthState>(
        listener: _handleAuthState,
        child: Stack(
          children: [
            const _LoginBackground(),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 32.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520.w,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const LoginHeader(),

                          SizedBox(height: 32.h),

                          LoginFormCard(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onLogin: _onLogin,
                            onForgotPassword: _openResetPassword,
                          ),

                          SizedBox(height: 24.h),

                          LoginFooter(
                            onRegister: _openRegister,
                          ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAuthState(
      BuildContext context,
      AuthState state,
      ) {
    if (state is AuthSuccess) {
      AppToast.success(
        context,
        state.message,
      );
    }

    if (state is AuthError) {
      AppToast.error(
        context,
        state.message,
      );
    }
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100.w,
              right: -80.w,
              child: _GlowCircle(
                size: 280.w,
                color: AppTheme.secondaryColor,
              ),
            ),

            Positioned(
              bottom: -120.w,
              left: -100.w,
              child: _GlowCircle(
                size: 300.w,
                color: Colors.white,
              ),
            ),

            Positioned(
              top: 180.h,
              left: -40.w,
              child: _GlowCircle(
                size: 100.w,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.07),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(
      begin: const Offset(0.7, 0.7),
      end: const Offset(1, 1),
      duration: 1000.ms,
      curve: Curves.easeOutCubic,
    );
  }
}