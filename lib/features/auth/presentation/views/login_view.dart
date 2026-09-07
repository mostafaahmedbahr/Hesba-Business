import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/auth_repo.dart';
import '../cubit/login_cubit.dart';
import '../states/login_state.dart';
import '../widgets/login_widgets/login_form.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(authRepo: sl<AuthRepo>()),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420.w),
                child: LoginForm(
                  formKey: formKey,
                  emailController: emailController,
                  passwordController: passwordController,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleState(BuildContext context, LoginState state) {
    print('[LoginView] _handleState() called. Status: ${state.status}');
    if (state.status == LoginStatus.success) {
      print('[LoginView] Login SUCCESS — showing toast & navigating to login (placeholder)');
      AppToast.success(context, 'تم تسجيل الدخول بنجاح');
      // TODO: navigate to dashboard when ready
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } else if (state.status == LoginStatus.failure) {
      print('[LoginView] Login FAILURE — showing error toast: ${state.errorMessage}');
      AppToast.error(context, state.errorMessage ?? 'حدث خطأ');
    }
  }
}
