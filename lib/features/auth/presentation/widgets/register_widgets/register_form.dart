import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';

import 'register_header.dart';
import 'register_steps.dart';
import 'register_navigation.dart';

import 'register_owner_step.dart';
import 'register_shop_step.dart';
import 'register_extra_step.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final TextEditingController shopNameController;
  final TextEditingController businessTypeController;
  final TextEditingController shopPhoneController;

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;

  final TextEditingController locationUrlController;
  final TextEditingController shopImageUrlController;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.ownerNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.shopNameController,
    required this.businessTypeController,
    required this.shopPhoneController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.locationUrlController,
    required this.shopImageUrlController,
  });

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
        key: formKey,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const RegisterHeader(),

            SizedBox(height: 28.h),

            const RegisterSteps(),

            SizedBox(height: 32.h),

            BlocBuilder<RegisterCubit, RegisterState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                  duration:
                  const Duration(milliseconds: 250),
                  child: _step(state.step),
                );
              },
            ),

            SizedBox(height: 30.h),

            RegisterNavigation(
              formKey: formKey,
              ownerNameController:
              ownerNameController,
              emailController:
              emailController,
              phoneController:
              phoneController,
              passwordController:
              passwordController,
              confirmPasswordController:
              confirmPasswordController,
              shopNameController:
              shopNameController,
              businessTypeController:
              businessTypeController,
              shopPhoneController:
              shopPhoneController,
              addressController:
              addressController,
              cityController:
              cityController,
              stateController:
              stateController,
              locationUrlController:
              locationUrlController,
              shopImageUrlController:
              shopImageUrlController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int step) {
    switch (step) {
      case 0:
        return RegisterOwnerStep(
          key: const ValueKey('owner'),
          ownerNameController:
          ownerNameController,
          emailController:
          emailController,
          phoneController:
          phoneController,
          passwordController:
          passwordController,
          confirmPasswordController:
          confirmPasswordController,
        );

      case 1:
        return RegisterShopStep(
          key: const ValueKey('shop'),
          shopNameController:
          shopNameController,
          businessTypeController:
          businessTypeController,
          shopPhoneController:
          shopPhoneController,
          addressController:
          addressController,
          cityController:
          cityController,
          stateController:
          stateController,
        );

      case 2:
        return RegisterExtraStep(
          key: const ValueKey('extra'),
          locationUrlController:
          locationUrlController,
          shopImageUrlController:
          shopImageUrlController,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}