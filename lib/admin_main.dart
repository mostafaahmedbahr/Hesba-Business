import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'package:hesba/features/admin/presentation/views/admin_login_view.dart';
import 'package:hesba/features/admin/presentation/views/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  runApp(const AdminApp());
}

/// The shell/login switch usable both as the web app's home and from the
/// customer app's drawer (a MaterialApp already exists in the client app).
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminAuthCubit(repo: sl<AdminRepo>())..checkSession(),
      child: BlocBuilder<AdminAuthCubit, AdminAuthState>(
        builder: (context, state) {
          if (state is AdminAuthAuthenticated) {
            return const AdminShell();
          }
          if (state is AdminAuthLoading || state is AdminAuthInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const AdminLoginView();
        },
      ),
    );
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hesba Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
      home: const AdminHome(),
    );
  }
}
