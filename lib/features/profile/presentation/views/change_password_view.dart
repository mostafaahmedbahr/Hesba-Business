import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../../../auth/presentation/widgets/register_widgets/password_strength_indicator.dart';
import '../../data/repos/account_repo.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/app_scaffold.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'changePasswordTitle'.tr(),
      body: BlocProvider(
        create: (_) => ProfileCubit(repo: sl<AccountRepo>()),
        // الـ Builder يدينا context تحت الـ Provider (عشان الـ read مايضربش).
        child: Builder(
          builder: (innerContext) => Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildPasswordField(
                  label: 'changePasswordCurrent'.tr(),
                  icon: Icons.lock_outline_rounded,
                  controller: _currentController,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'changePasswordCurrentEmpty'.tr() : null,
                ),
                SizedBox(height: 14.h),
                _buildPasswordField(
                  label: 'changePasswordNew'.tr(),
                  icon: Icons.lock_reset_rounded,
                  controller: _newController,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) => _validateNewPassword(v),
                  onChanged: (_) => setState(() {}),
                ),
                // قوة الباسورد live.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _newController,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : PasswordStrengthIndicator(password: value.text),
                ),
                SizedBox(height: 14.h),
                _buildPasswordField(
                  label: 'changePasswordConfirm'.tr(),
                  icon: Icons.verified_user_outlined,
                  controller: _confirmController,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'changePasswordConfirmEmpty'.tr();
                    if (v != _newController.text) {
                      return 'changePasswordMismatch'.tr();
                    }
                    return null;
                  },
                ),
                // تطابق live (علامة صح أول ما يتطابقوا).
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _confirmController,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    final match = value.text == _newController.text;
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            match ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 16.sp,
                            color: match ? const Color(0xFF059669) : const Color(0xFFE11D48),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            match ? 'كلمتا المرور متطابقتان' : 'changePasswordMismatch'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: match ? const Color(0xFF059669) : const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 26.h),
                _buildSubmitButton(innerContext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// تحقق حقيقي: طول + أنواع حروف + مختلف عن الحالي.
  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'changePasswordNewEmpty'.tr();
    if (v.length < 8) return 'changePasswordNewShort'.tr();
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'changePasswordNewUpper'.tr();
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'changePasswordNewLower'.tr();
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'changePasswordNewDigit'.tr();
    if (v == _currentController.text) return 'الجديدة لازم تختلف عن الحالية';
    return null;
  }

  Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext ctx) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: _loading ? null : () => _submit(ctx),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'changePasswordButton'.tr(),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  /// الحفظ بـ context تحت الـ Provider (القديم كان فوقه وبيضرب).
  Future<void> _submit(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await ctx.read<ProfileCubit>().changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      AppToast.success(ctx, 'changePasswordSuccess'.tr());
      Navigator.pop(ctx);
    } else {
      AppToast.error(ctx, error);
    }
  }
}
