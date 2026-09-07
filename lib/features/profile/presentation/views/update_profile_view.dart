import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../../data/repos/account_repo.dart';
import '../cubit/profile_cubit.dart';
import '../states/profile_state.dart';
import '../widgets/app_scaffold.dart';

class UpdateProfileView extends StatefulWidget {
  const UpdateProfileView({super.key});

  @override
  State<UpdateProfileView> createState() => _UpdateProfileViewState();
}

class _UpdateProfileViewState extends State<UpdateProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تعديل البيانات',
      body: BlocProvider(
        create: (_) => ProfileCubit(repo: sl<AccountRepo>())..loadProfile(),
        child: BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            final p = state.profile;
            if (p != null && !_loading) {
              // Pre-fill once profile loads
              if (_nameController.text.isEmpty &&
                  _phoneController.text.isEmpty) {
                _nameController.text = p.ownerName;
                _phoneController.text = p.phone;
              }
            }
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.status == ProfileStatus.loading &&
                  state.profile == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(20.w),
                  children: [
                    _buildField(
                      context,
                      controller: _nameController,
                      label: 'الاسم بالكامل',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'اكتب الاسم' : null,
                    ),
                    SizedBox(height: 14.h),
                    _buildField(
                      context,
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'اكتب الهاتف';
                        final re = RegExp(r'^01[0125][0-9]{8}$');
                        if (!re.hasMatch(v.trim())) {
                          return 'رقم هاتف مصري غير صحيح';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 26.h),
                    _buildSaveButton(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: _loading ? null : () => _save(context),
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
                'حفظ التعديلات',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await context.read<ProfileCubit>().updateProfile(
          ownerName: _nameController.text,
          phone: _phoneController.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      AppToast.success(context, 'تم حفظ التعديلات بنجاح');
      Navigator.pop(context);
    } else {
      AppToast.error(context, error);
    }
  }
}
