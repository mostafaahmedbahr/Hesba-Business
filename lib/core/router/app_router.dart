import 'package:flutter/material.dart';

import 'package:hesba/core/router/app_routes.dart';
import 'package:hesba/features/splash/presentation/screens/splash_screen.dart';
import 'package:hesba/features/auth/presentation/views/login_view.dart';
import 'package:hesba/features/auth/presentation/views/register_view.dart';
import 'package:hesba/features/main/presentation/views/main_layout.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginView(), settings);

      case AppRoutes.register:
        return _buildRoute(const RegisterView(), settings);

      case AppRoutes.dashboard:
        return _buildRoute(const MainLayout(), settings);

      // case AppRoutes.resetPassword:
      //   return _buildRoute(const ResetPasswordScreen(), settings);

      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
