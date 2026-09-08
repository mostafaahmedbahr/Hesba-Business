import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    );
  }

  /// Initializes FCM and local notifications.
  Future<void> initialize({void Function(String? payload)? onTap}) async {
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

    await _local.initialize(settings);

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
    );
  }

  /// Schedules a repeating minute reminder.
  Future<void> scheduleHourlyReminder({
    required String title,
    required String body,
  }) async {
    await _local.periodicallyShow(
      _reminderNotificationId,
      title,
      body,
      RepeatInterval.everyMinute,
      _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancels the scheduled hourly reminder.
  Future<void> cancelReminders() async {
    await _local.cancel(_reminderNotificationId);
  }
}