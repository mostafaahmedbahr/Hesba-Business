import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/local_reminder.dart';

/// Remote (FCM) + local notification service.
///
/// Responsible for:
/// - FCM setup (permissions, token, listeners, background handler)
/// - storing the device token on the user document in Firestore
/// - showing local notifications (foreground FCM + scheduled reminders)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String remindersChannelId = 'hesba_reminders';
  static const String remindersChannelName = 'تذكيرات حسبة';
  static const int _reminderNotificationId = 1001;
  static const int _fcmNotificationId = 1002;

  /// Every device subscribes to this FCM topic, so you can send a
  /// notification from the Firebase Console by targeting the topic
  /// [appTopic] instead of pasting a device token.
  static const String appTopic = 'hesba_all';

  FlutterLocalNotificationsPlugin get local => _local;

  /// Must be called from the top-level background isolate handler.
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    final local = FlutterLocalNotificationsPlugin();
    await local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final title = message.notification?.title ?? 'حسبة';
    final body = message.notification?.body ?? '';
final channel = AndroidNotificationChannel(
      remindersChannelId,
      remindersChannelName,
      importance: Importance.high,
    );
    await local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await local.show(
      _fcmNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'fcm',
    );
  }

  /// Initializes FCM and local notifications.
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    tzdata.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Fired when the user taps a notification that was already shown on
        // screen (scheduled reminder, foreground FCM, test ...) and also when
        // the app cold-starts from one of those taps.
        onTap?.call(response.payload);
      },
    );

    // Cold start via an FCM push (app terminated): handled explicitly because
    // the OS launches us directly, not through a plugin notification.
    await _local.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp == true) {
        onTap?.call(details?.notificationResponse?.payload);
      }
    });

    await Future.wait([
      _createRemindersChannel(),
      _createFcmChannel(),
    ]);

    // FCM listeners
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onTap?.call(message.data['type'] as String?);
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        onTap?.call(message.data['type'] as String?);
      }
    });

    // Token refresh
    _messaging.onTokenRefresh.listen(saveToken);

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(
      NotificationService.backgroundHandler,
    );
  }

  Future<void> _createRemindersChannel() async {
    const channel = AndroidNotificationChannel(
      remindersChannelId,
      remindersChannelName,
      description: 'تنبيهات دورية لتذكيرك بمتابعة محلك',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _createFcmChannel() async {
    const channel = AndroidNotificationChannel(
      'hesba_fcm',
      'إشعارات حسبة',
      description: 'إشعارات وتنبيهات من حسبة',
      importance: Importance.max,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Requests notification permission on the current platform.
  Future<bool> requestPermissions() async {
    bool granted = false;

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }

    final darwin = _local.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      granted = await darwin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  /// Fetches the FCM token, requests permission, and saves the token.
  Future<void> setupFcm() async {
    await _messaging.setAutoInitEnabled(true);
    await requestPermissions();

    // Join the app-wide topic so console sends to the topic always reach
    // this device (no need to paste a token).
    try {
      await _messaging.subscribeToTopic(appTopic);
    } catch (_) {/* best effort */}

    final token = await _messaging.getToken();
    if (token != null) {
      await saveToken(token);
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Returns the current FCM registration token for this device.
  Future<String?> getToken() => _messaging.getToken();

  /// Saves (or removes) the token on the user document (Firestore).
  Future<void> saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmTokensUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title'] ??
        'حسبة';
    final body = message.notification?.body ??
        message.data['body'] ??
        '';

    _local.show(
      _fcmNotificationId,
      title,
      body,
      _fcmDetails(),
      payload: 'fcm',
    );
  }

  NotificationDetails _fcmDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'hesba_fcm',
        'إشعارات حسبة',
        channelDescription: 'إشعارات وتنبيهات من حسبة',
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  NotificationDetails _reminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        remindersChannelId,
        remindersChannelName,
        channelDescription: 'تنبيهات دورية لتذكيرك بمتابعة محلك',
        icon: '@mipmap/ic_launcher',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Shows an immediate local notification (used for the test button).
  Future<void> showReminder({
    required String title,
    required String body,
  }) {
    return _local.show(
      _reminderNotificationId,
      title,
      body,
      _reminderDetails(),
      payload: 'test',
    );
  }

  /// Schedules one daily reminder at a fixed local clock time.
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _local.zonedSchedule(
      id,
      title,
      body,
      _nextDailyTime(hour, minute),
      _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder',
    );
  }

  /// Schedules one weekly reminder on [weekday] (1 = Monday .. 7 = Sunday)
  /// at a fixed local clock time.
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    await _local.zonedSchedule(
      id,
      title,
      body,
      _nextWeeklyTime(weekday, hour, minute),
      _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'reminder',
    );
  }

  /// Cancels one notification by id (no-op if it was never scheduled).
  Future<void> cancelNotification(int id) => _local.cancel(id);

  /// Reconciles one reminders list: cancels the schedule of every reminder in
  /// that list, then re-schedules the enabled ones according to their repeat
  /// type. Each list (public, personal, ...) is reconciled independently and
  /// only touches its own namespace, so kinds never interfere.
  Future<void> syncReminders(List<LocalReminder> reminders) async {
    for (final r in reminders) {
      await _local.cancel(r.id);
    }
    for (final r in reminders) {
      if (!r.enabled) continue;
      if (r.repeat == ReminderRepeat.weekly && r.weekday != null) {
        await scheduleWeeklyReminder(
          id: r.id,
          title: r.title,
          body: r.body,
          hour: r.hour,
          minute: r.minute,
          weekday: r.weekday!,
        );
      } else {
        await scheduleDailyReminder(
          id: r.id,
          title: r.title,
          body: r.body,
          hour: r.hour,
          minute: r.minute,
        );
      }
    }
  }

  /// Returns the next occurrence of [hour]:[minute] in the device's local
  /// clock, expressed in UTC so `matchDateTimeComponents: time` keeps firing at
  /// the local wall-clock time every day (no hardcoded region needed).
  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    final target =
        today.isAfter(now) ? today : today.add(const Duration(days: 1));
    return tz.TZDateTime.from(target.toUtc(), tz.UTC);
  }

  /// Returns the next occurrence of ([weekday], [hour]:[minute]) in the
  /// device's local clock, expressed in UTC for `dayOfWeekAndTime` matching.
  /// [weekday] follows [DateTime.weekday] (1 = Monday .. 7 = Sunday).
  tz.TZDateTime _nextWeeklyTime(int weekday, int hour, int minute) {
    var day = DateTime.now();
    while (day.weekday != weekday) {
      day = day.add(const Duration(days: 1));
    }
    final candidate =
        DateTime(day.year, day.month, day.day, hour, minute);
    final target = candidate.isAfter(DateTime.now())
        ? candidate
        : candidate.add(const Duration(days: 7));
    return tz.TZDateTime.from(target.toUtc(), tz.UTC);
  }
}