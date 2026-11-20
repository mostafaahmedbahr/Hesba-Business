import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/cubit/shop_location_cubit.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/shop_location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/auth_repo.dart';
import '../cubit/register_cubit.dart';
import '../states/register_state.dart';
import '../widgets/register_widgets/register_form.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RegisterCubit(authRepo: sl<AuthRepo>())),
        BlocProvider(
          create: (_) => ShopLocationCubit(locationService: sl<ShopLocationService>()),
        ),
      ],
      child: const _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  const _RegisterBody();

  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  final formKey = GlobalKey<FormState>();

  final ownerNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final shopNameController = TextEditingController();
  final businessTypeController = TextEditingController();

  final shopPhoneController = TextEditingController();

  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  final shopImageUrlController = TextEditingController();

  @override
  void dispose() {
    ownerNameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    passwordController.dispose();
    confirmPasswordController.dispose();

    shopNameController.dispose();
    businessTypeController.dispose();
    shopPhoneController.dispose();

    addressController.dispose();
    cityController.dispose();
    stateController.dispose();

    shopImageUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<RegisterCubit, RegisterState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.primaryLight,
        body: AuthBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  16.h,
                  16.w,
                  16.h + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 520.w),
                  child: RegisterForm(
                    formKey: formKey,
                    ownerNameController: ownerNameController,
                    emailController: emailController,
                    phoneController: phoneController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    shopNameController: shopNameController,
                    businessTypeController: businessTypeController,
                    shopPhoneController: shopPhoneController,
                    addressController: addressController,
                    cityController: cityController,
                    stateController: stateController,
                    shopImageUrlController: shopImageUrlController,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleState(BuildContext context, RegisterState state) {
    if (state.status == RegisterStatus.success) {
      AppToast.success(context, 'registerSuccess'.tr());
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } else if (state.status == RegisterStatus.failure) {
      AppToast.error(context, state.errorMessage ?? 'registerError'.tr());
    }
  }
}
