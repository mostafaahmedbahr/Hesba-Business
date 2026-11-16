import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/core/theme/app_theme.dart';

import '../../cubit/register_cubit.dart';
import '../../states/register_state.dart';
import '../../../data/models/register_model.dart';
import '../../../../../core/cubit/shop_location_cubit.dart';
import '../../../../../core/utils/toast.dart';

/// أزرار التنقل بين خطوات التسجيل: زر رئيسي ب-gradient وزر رجوع أنيق.
class RegisterNavigation extends StatelessWidget {
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

  const RegisterNavigation({
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
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        final isFirstStep = state.step == 0;
        final isLastStep = state.step == 2;
        final isLoading = state.status == RegisterStatus.loading;

        return Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                flex: 2,
                child: _buildButton(
                  label: 'registerBack'.tr(),
                  isOutlined: true,
                  onPressed: isLoading ? null : cubit.previousStep,
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: _buildButton(
                label: isLastStep ? 'registerSubmit'.tr() : 'registerNext'.tr(),
                isOutlined: false,
                isLoading: isLoading,
                suffixIcon: isLoading
                    ? null
                    : Icon(
                        isLastStep
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18.sp,
                      ),
                onPressed: isLoading
                    ? null
                    : () => _onPressed(context, isLastStep),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required String label,
    required bool isOutlined,
    bool isLoading = false,
    Widget? suffixIcon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54.h,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                textStyle: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(15.r),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          )
                        else if (suffixIcon != null)
                          suffixIcon,
                        if (!isLoading) SizedBox(width: 8.w),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _onPressed(BuildContext context, bool isLastStep) {
    if (isLastStep) {
      _submit(context);
    } else {
      _nextStep(context);
    }
  }

  void _nextStep(BuildContext context) {
    if (!formKey.currentState!.validate()) return;
    context.read<RegisterCubit>().nextStep();
  }

  void _submit(BuildContext context) {
    if (!formKey.currentState!.validate()) return;

    // الموقع بيتحدد من ShopLocationCubit (GPS / خريطة / عنوان يدوي).
    final location = context.read<ShopLocationCubit>().state.location;
    if (location == null || !location.hasAnyData) {
      AppToast.error(context, 'locationRequired'.tr());
      return;
    }

    final now = DateTime.now();
    final model = RegisterModel(
      ownerId: '',
      shopId: '',
      role: 'owner',
      ownerName: ownerNameController.text,
      email: emailController.text,
      phone: phoneController.text,
      shopName: shopNameController.text,
      businessType: businessTypeController.text,
      shopPhone: shopPhoneController.text,
      locationUrl: location.locationUrl,
      latitude: location.latitude,
      longitude: location.longitude,
      locationAddress: location.address,
      shopImageUrl: shopImageUrlController.text,
      address: addressController.text,
      city: cityController.text,
      state: stateController.text,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    context.read<RegisterCubit>().register(
          model: model,
          password: passwordController.text,
        );
  }
}
