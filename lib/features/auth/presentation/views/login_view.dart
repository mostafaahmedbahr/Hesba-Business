import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/user_role_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/exit_guard.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExitGuard(
      child: BlocListener<LoginCubit, LoginState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F7FB),
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
      ),
    );
  }

  Future<void> _handleState(BuildContext context, LoginState state) async {
    if (state.status == LoginStatus.success) {
      await sl<UserRoleService>().reload();
      if (!context.mounted) return;
      final role = sl<UserRoleService>();
      if (!role.isLoaded && role.loadFailed) {
        // فشل تحميل الدور — لا نوجّه (قد يكون موظفًا). نطلب إعادة المحاولة.
        AppToast.error(
          context,
          'تعذر تحميل بيانات حسابك، تحقق من الاتصال وحاول مرة أخرى'.tr(),
        );
        return;
      }
      AppToast.success(context, 'loginSuccess'.tr());
      Navigator.pushNamedAndRemoveUntil(
        context,
        role.isStaff ? AppRoutes.staffHome : AppRoutes.dashboard,
        (_) => false,
      );
    } else if (state.status == LoginStatus.failure) {
      AppToast.error(context, state.errorMessage ?? 'loginError'.tr());
    }
  }
}
