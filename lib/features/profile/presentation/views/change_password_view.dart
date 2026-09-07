import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
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
      title: 'تغيير كلمة المرور',
      body: BlocProvider(
        create: (_) => ProfileCubit(repo: sl<AccountRepo>()),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              _buildPasswordField(
                label: 'كلمة المرور الحالية',
                icon: Icons.lock_outline_rounded,
                controller: _currentController,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'اكتب كلمة المرور الحالية' : null,
              ),
              SizedBox(height: 14.h),
              _buildPasswordField(
                label: 'كلمة المرور الجديدة',
                icon: Icons.lock_reset_rounded,
                controller: _newController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (v) => _validateNewPassword(v),
              ),
              SizedBox(height: 14.h),
              _buildPasswordField(
                label: 'تأكيد كلمة المرور الجديدة',
                icon: Icons.verified_user_outlined,
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أكد كلمة المرور الجديدة';
                  if (v != _newController.text) {
                    return 'كلمتا المرور غير متطابقتين';
                  }
                  return null;
                },
              ),
              SizedBox(height: 26.h),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'اكتب كلمة المرور الجديدة';
    if (v.length < 8) return '8 أحرف على الأقل';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'حرف كبير على الأقل';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'حرف صغير على الأقل';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'رقم واحد على الأقل';
    return null;
  }

  Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: _loading ? null : () => _submit(),
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
            : const Text(
                'تغيير كلمة المرور',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await context.read<ProfileCubit>().changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      AppToast.success(context, 'تم تغيير كلمة المرور بنجاح');
      Navigator.pop(context);
    } else {
      AppToast.error(context, error);
    }
  }
}
