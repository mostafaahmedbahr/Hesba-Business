import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/utils/toast.dart';
import '../../../data/repos/auth_repo.dart';
import '../../cubit/forgot_password_cubit.dart';
import '../../states/forgot_password_state.dart';
import 'login_text_field.dart';

/// Dialog that emails a password reset link to the account owner.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  final String initialEmail;

  static Future<void> show(BuildContext context, {String initialEmail = ''}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => ForgotPasswordCubit(authRepo: sl<AuthRepo>()),
        child: ForgotPasswordDialog(initialEmail: initialEmail),
      ),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
      listener: _handleState,
      builder: (context, state) {
        final isLoading = state.status == ForgotPasswordStatus.loading;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          contentPadding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 10.h),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B4D9C).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF0B4D9C),
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'forgotPasswordTitle'.tr(),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'forgotPasswordDesc'.tr(),
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 18.h),
                LoginTextField(
                  controller: emailController,
                  label: 'loginEmail'.tr(),
                  hint: 'loginEmailHint'.tr(),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'loginEmailEmpty'.tr();
                    }
                    if (!value.contains('@')) {
                      return 'loginEmailInvalid'.tr();
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 18.h),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(
              height: 44.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4D9C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'forgotPasswordSend'.tr(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleState(BuildContext context, ForgotPasswordState state) {
    if (state.status == ForgotPasswordStatus.success) {
      AppToast.success(context, 'forgotPasswordSent'.tr());
      Navigator.pop(context);
    } else if (state.status == ForgotPasswordStatus.failure) {
      AppToast.error(context, (state.errorMessage ?? 'forgotPasswordFailed').tr());
    }
  }

  void _send() {
    if (!formKey.currentState!.validate()) return;
    context
        .read<ForgotPasswordCubit>()
        .sendResetEmail(email: emailController.text.trim());
  }
}
