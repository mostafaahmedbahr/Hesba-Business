import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/router/app_router.dart';
import 'package:hesba/core/router/app_routes.dart';
import 'package:hesba/core/services/notification_service.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hesba/features/settings/presentation/states/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize(onTap: _handleNotificationTap);
  await initDependencies();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(TranslationProvider(child: const HesbaApp()));
}

/// Fired when the user taps any notification (FCM push, scheduled reminder or
/// the test notification). If a user is signed in, opens the dashboard; the
/// splash/login flow handles the not-signed-in case.
Future<void> _handleNotificationTap(String? payload) async {
  if (FirebaseAuth.instance.currentUser == null) return;

  // The handler can fire before MaterialApp exists (cold start). Retry until
  // the navigator is ready (bounded) so the tap is never dropped.
  for (var attempt = 0; attempt < 30; attempt++) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

class TranslationProvider extends StatelessWidget {
  final Widget child;

  const TranslationProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      fallbackLocale: const Locale('ar'),
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      saveLocale: true,
      useOnlyLangCode: true,
      child: child,
    );
  }
}

class HesbaApp extends StatelessWidget {
  const HesbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(repo: sl())..load(),
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              key: ValueKey(context.locale),
              navigatorKey: appNavigatorKey,
              title: 'حسبة',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
              builder: (context, child) {
                return Directionality(
                  textDirection: context.locale.languageCode == 'ar'
                      ? ui.TextDirection.rtl
                      : ui.TextDirection.ltr,
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}