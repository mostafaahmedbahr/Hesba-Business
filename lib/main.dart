import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hesba/common_imports.dart';
import 'package:hesba/core/router/notification_router.dart';
import 'package:hesba/core/services/app_logger.dart';
import 'package:hesba/core/services/user_role_service.dart';
import 'package:hesba/features/expenses/data/repos/expenses_repo.dart';
import 'package:hesba/features/notifications/data/repos/activity_repo.dart';
import 'package:hesba/features/notifications/presentation/view_model/activity_cubit.dart';
import 'package:hesba/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:hesba/features/settings/presentation/states/settings_state.dart';

 Future<void> main() async {
  await runZonedGuarded(() async {
    // لازم تهيئة الـ binding داخل نفس الـ zone اللي بتستدعي فيها runApp،
    // وإلا هيحصل Zone mismatch (الـ binding اتهيأ في zone مختلف).
    WidgetsFlutterBinding.ensureInitialized();
    // لازم يتنادى قبل runApp عشان اللغة المحفوظة تتحمّل من SharedPreferences
    // قبل ما EasyLocalization يبني الـ controller. بدونه بيفضل startLocale
    // (العربية) هو اللي بيشتغل كل مرة حتى لو المستخدم اختار الإنجليزية.
    await EasyLocalization.ensureInitialized();
    // التقاط كل خطأ غير ملتقط (FlutterError + async) في سجل واحد.
    AppLogger.installGlobalHandlers();
    await    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // تحصين تشغيلي — كلاهما best-effort: فشل أيهما ما يمنع opening التطبيق.
    await _initOperationalHardening();
    await NotificationService().initialize(onTap: _handleNotificationTap);
    await initDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // مزامنة المصروفات المتكررة: يسجل تلقائيًا أي موعد فات (أو يوصل)
    // ويعيد ضبط التذكيرات — يعمل في الخلفية بأمان.
    unawaited(_syncRecurringExpensesSafely());
    // تحميل الدور قبل تشغيل الـ router عشان حظر مسارات الموظف يشتغل
    // من أول إطار حتى لو جاء الـ navigation من إشعار أو deep link.
    if (FirebaseAuth.instance.currentUser != null) {
      await sl<UserRoleService>().load();
    }
    runApp(TranslationProvider(child: const HesbaApp()));
  }, (error, stackTrace) {
    AppLogger.error(
      'خطأ غير متزامن غير ملتقط',
      context: 'zone',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

/// تهيئة App Check و Crashlytics بأمان.
///
/// App Check: play integrity في الإنتاج، debug provider في التطوير. التفعيل
/// في Console خارجي — هنا نُجهّز العميل فقط بدون فرض القواعد (لا نكسر التطبيق).
/// Crashlytics: كل أحداث AppLogger من مستوى warning فأعلى تُرسل كـ non-fatal.
Future<void> _initOperationalHardening() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
    );
  } catch (logErr, logSt) {
    AppLogger.nonFatal('main.dart', logErr, logSt,
        severity: LoggingSeverity.warning);
  }

  try {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);
    AppLogger.remoteReporter = (entry) async {
      try {
        await FirebaseCrashlytics.instance.recordError(
          entry.error ?? entry.message,
          entry.stackTrace,
          reason: '[${entry.severity.name}] ${entry.message}',
          information: entry.context == null ? <Object>[] : <Object>[entry.context!],
          fatal: false,
        );
      } catch (_) {
        // الإبلاغ نفسه لازم ما يرميش أبدًا.
      }
    };
  } catch (logErr, logSt) {
    AppLogger.nonFatal('main.dart', logErr, logSt,
        severity: LoggingSeverity.warning);
  }
}

/// مزامنة المصروفات المتكررة بدون رمي أي خطأ (best effort عند الإقلاع).
Future<void> _syncRecurringExpensesSafely() async {
  try {
    await sl<ExpensesRepo>().syncRecurringExpenses();
  } catch (logErr, logSt) {
    AppLogger.nonFatal('main.dart', logErr, logSt, severity: LoggingSeverity.warning);
    // فشل المزامنة ما يمنعش التطبيق يفتح — هتتعمل تاني عند فتح شاشة المصاريف.
  }
}

/// Fired when the user taps any notification (operation push, scheduled
/// reminder, test notification or FCM). Opens the screen the notification
/// came from — see `core/router/notification_router.dart`. If a user is not
/// signed in we do nothing; the splash/login flow takes over.
Future<void> _handleNotificationTap(String? payload) async {
  if (FirebaseAuth.instance.currentUser == null) return;

  // The handler can fire before MaterialApp exists (cold start). Retry until
  // the navigator is ready (bounded) so the tap is never dropped.
  for (var attempt = 0; attempt < 30; attempt++) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      // payload → الشاشة اللي الإشعار جه منها (شوف notification_router.dart).
      openNotificationPayload(navigator, payload);
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(repo: sl())..load(),
        ),
        // سجل العمليات شأن عام — لازم يبقى فوق الـ Navigator
        // عشان كل الشاشات (حتى الـ push) تشوفه.
        BlocProvider(
          create: (_) => ActivityCubit(repo: sl<ActivityRepo>()),
        ),
      ],
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