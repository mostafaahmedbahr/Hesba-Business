import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/router/app_router.dart';
import 'package:hesba/core/router/app_routes.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/core/utils/translations.dart';
import 'package:hesba/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hesba/features/settings/presentation/states/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initDependencies();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HesbaApp());
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
              title: 'حسبة',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              locale: state.locale,
              supportedLocales: Translations.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection: state.locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child!,
                );
              },
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}

