import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/auth_repo.dart';
import '../cubit/register_cubit.dart';
import '../states/register_state.dart';
import '../widgets/register_widgets/register_form.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(authRepo: sl<AuthRepo>()),
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

  final locationUrlController = TextEditingController();
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

    locationUrlController.dispose();
    shopImageUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, RegisterState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900.w),
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
                  locationUrlController: locationUrlController,
                  shopImageUrlController: shopImageUrlController,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleState(BuildContext context, RegisterState state) {
    print('[RegisterView] _handleState() called. Status: ${state.status}');
    if (state.status == RegisterStatus.success) {
      print('[RegisterView] Register SUCCESS — showing toast & navigating to login');
      AppToast.success(context, 'registerSuccess'.tr());
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } else if (state.status == RegisterStatus.failure) {
      print('[RegisterView] Register FAILURE — showing error toast: ${state.errorMessage}');
      AppToast.error(context, state.errorMessage ?? 'registerError'.tr());
    }
  }
}
