import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class VerseNotificationService {
  static const int _notificationId = 41001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    bool granted = true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = (await android.requestNotificationsPermission()) ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final iosGranted = (await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
      granted = granted && iosGranted;
    }

    return granted;
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    const android = AndroidNotificationDetails(
      'verse_of_day',
      'Verse of the Day',
      channelDescription: 'Daily Bhagavad Gita verse reflection reminders.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      next,
      const NotificationDetails(
        android: android,
        iOS: ios,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(_notificationId);
  }

  void logScheduleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final prefix =
        context == null ? '[VerseNotification]' : '[VerseNotification][$context]';
    debugPrint('$prefix $error');
    if (stackTrace != null) {
      debugPrintStack(label: prefix, stackTrace: stackTrace);
    }
  }
}
