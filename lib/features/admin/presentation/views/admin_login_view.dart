import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_login_cubit.dart';

class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminLoginCubit(repo: sl<AdminRepo>()),
      child: const _AdminLoginBody(),
    );
  }
}

class _AdminLoginBody extends StatefulWidget {
  const _AdminLoginBody();
  @override
  State<_AdminLoginBody> createState() => _AdminLoginBodyState();
}

class _AdminLoginBodyState extends State<_AdminLoginBody> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: BlocConsumer<AdminLoginCubit, AdminLoginState>(
                    listener: (context, state) {
                      if (state is AdminLoginSuccess) {
                        context.read<AdminAuthCubit>().checkSession();
                      } else if (state is AdminLoginDenied) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('هذا الحساب لا يملك صلاحية الإدارة')),
                        );
                      } else if (state is AdminLoginFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message)),
                        );
                      }
                    },
                    builder: (context, state) {
                      final loading = state is AdminLoginLoading;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined, size: 56, color: AppTheme.primaryColor),
                          const SizedBox(height: 12),
                          Text('Hesba Admin', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                            validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'كلمة المرور'),
                            validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AdminLoginCubit>().login(
                                              _email.text.trim(),
                                              _password.text,
                                            );
                                      }
                                    },
                              child: loading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('دخول'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
