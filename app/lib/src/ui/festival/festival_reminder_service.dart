import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../calendar/festival.dart';

/// Schedules a 24-hour-before reminder notification for each upcoming festival.
///
/// Uses the same [FlutterLocalNotificationsPlugin] instance as
/// [VerseNotificationService] so the plugin is only initialised once
/// (handled by the caller via [initialize]).
///
/// Notification IDs 4000–4099 are reserved for festival reminders.
class FestivalReminderService {
  FestivalReminderService._();
  static final FestivalReminderService instance = FestivalReminderService._();

  static const _channelId   = 'gita_festivals';
  static const _channelName = 'Hindu Festivals';
  static const _channelDesc = 'Reminders 24 hours before Hindu festivals.';

  /// Notification ID base for festival reminders (IDs 4000..4099).
  static const _idBase = 4000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings  = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: darwinSettings),
    );

    _initialized = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Cancels all previous festival reminders and schedules new ones for
  /// each festival in [festivals] that has a reminder time in the future.
  Future<void> scheduleAll(List<Festival> festivals) async {
    await initialize();

    // Clear previous festival notifications
    for (var i = _idBase; i < _idBase + 100; i++) {
      await _plugin.cancel(i);
    }

    var id = _idBase;
    for (final festival in festivals) {
      final reminderTime =
          festival.date.subtract(const Duration(hours: 24));
      if (!reminderTime.isAfter(DateTime.now())) continue;

      final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

      await _plugin.zonedSchedule(
        id++,
        'Tomorrow: ${festival.name}',
        festival.significance,
        tzTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority:   Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
