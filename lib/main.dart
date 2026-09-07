import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/auth/data/repos_impl/auth_repo_impl.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:hesba/features/auth/presentation/view_model/auth_states.dart';
import 'package:hesba/features/auth/presentation/views/login_screen.dart';
import 'package:hesba/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HesbaApp());
}

class HesbaApp extends StatelessWidget {
  const HesbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepoImpl(),
      child: BlocProvider(
        create: (context) => AuthCubit(context.read<AuthRepoImpl>()),
        child: MaterialApp(
          title: 'حسبة',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Dashboard - قيد الإنشاء'),
            ),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
