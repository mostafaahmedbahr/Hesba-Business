import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';

import 'register_header.dart';
import 'register_steps.dart';
import 'register_navigation.dart';

import 'register_owner_step.dart';
import 'register_shop_step.dart';
import 'register_extra_step.dart';

/// كارت إنشاء الحساب: هيدر ملوّن + مؤشر خطوات + مساحة النموذج + أزرار.
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
    required this.shopImageUrlController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RegisterHeader(),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 26.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RegisterSteps(),
                  SizedBox(height: 26.h),
                  BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _stepView(state.step),
                      );
                    },
                  ),
                  SizedBox(height: 26.h),
                  RegisterNavigation(
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
                  SizedBox(height: 18.h),
                  const _LoginFooter(),
                  SizedBox(height: 10.h),
                  const _PrivacyFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepView(int step) {
    final stepWidget = _step(step);
    // الخطوتان الأولى والثانية حقول — نحطهم على لوحة خفيفة،
    // والخطوة الثالثة فيها كروت جاهزة فتُترك كما هي.
    if (step == 2) return stepWidget;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppTheme.slatePale.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.borderSoft.withValues(alpha: 0.7)),
      ),
      child: stepWidget,
    );
  }

  Widget _step(int step) {
    switch (step) {
      case 0:
        return RegisterOwnerStep(
          key: const ValueKey('owner'),
          ownerNameController: ownerNameController,
          emailController: emailController,
          phoneController: phoneController,
          passwordController: passwordController,
          confirmPasswordController: confirmPasswordController,
        );

      case 1:
        return RegisterShopStep(
          key: const ValueKey('shop'),
          shopNameController: shopNameController,
          businessTypeController: businessTypeController,
          shopPhoneController: shopPhoneController,
          addressController: addressController,
          cityController: cityController,
          stateController: stateController,
        );

      case 2:
        return RegisterExtraStep(
          key: const ValueKey('extra'),
          shopImageUrlController: shopImageUrlController,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لديك حساب بالفعل؟',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
        ),
        SizedBox(width: 4.w),
        InkWell(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (_) => false,
          ),
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  static const String _privacyPolicyUrl =
      'https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'بإنشائك حسابًا فأنت توافق على ',
            style: TextStyle(fontSize: 11.5.sp, color: Colors.grey.shade500),
          ),
          InkWell(
            onTap: () async {
              try {
                await launchUrl(
                  Uri.parse(_privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                // لا نمنع التسجيل لمجرد تعذر فتح الرابط — السياسة متاحة دائمًا بالرابط.
              }
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
              child: Text(
                'سياسة الخصوصية',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
