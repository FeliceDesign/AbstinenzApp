import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reserved notification id for the single daily mood/check-in reminder. Kept
/// far above the milestone ids (which are small database row ids) so the two
/// never collide and the milestone coordinator can cancel its own ids without
/// touching this one.
const int kDailyReminderId = 1000000;

/// A milestone notification to fire at an absolute instant.
class ScheduledMilestone {
  const ScheduledMilestone({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  /// Stable notification id (so it can be cancelled/replaced).
  final int id;
  final String title;
  final String body;

  /// The exact instant the milestone is reached.
  final DateTime when;
}

/// Thin wrapper around `flutter_local_notifications`.
///
/// All calls are guarded and swallow platform errors, so the app (and widget
/// tests, where no platform channel exists) never crash on notification issues.
/// Milestones are scheduled at their exact future instant via [tz] using UTC —
/// the fire instant is what matters, not the displayed wall-clock zone, so no
/// device-timezone lookup is needed.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Requests the OS notification permission (Android 13+, iOS). Safe to call
  /// more than once.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('NotificationService.requestPermission failed: $e');
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Milestones',
          channelDescription: 'Notifications when you reach a milestone',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Cancels [cancelIds], then schedules every future item in [items].
  Future<void> reschedule(
    List<ScheduledMilestone> items, {
    required List<int> cancelIds,
  }) async {
    if (!_ready) return;
    try {
      for (final int id in cancelIds) {
        await _plugin.cancel(id);
      }
      final DateTime now = DateTime.now();
      for (final ScheduledMilestone m in items) {
        if (!m.when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          m.id,
          m.title,
          m.body,
          tz.TZDateTime.from(m.when, tz.UTC),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.reschedule failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll failed: $e');
    }
  }

  NotificationDetails get _reminderDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription:
              'A nightly nudge to log your mood and check-in',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Schedules a reminder that repeats every day at [hour]:[minute] (device
  /// wall-clock). Cancels any previous reminder first, so calling it again just
  /// moves the time.
  ///
  /// The device's IANA timezone is not resolved here (that would need an extra
  /// plugin), so the daily repeat is anchored to the UTC instant of the next
  /// local occurrence and matched on its time component. That fires at the
  /// chosen wall-clock time and can drift by an hour across a daylight-saving
  /// change; it self-corrects the next time this is called (app launch or a
  /// settings change), which is accurate enough for a nightly nudge.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(kDailyReminderId);
      final DateTime now = DateTime.now();
      DateTime firstLocal =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (!firstLocal.isAfter(now)) {
        firstLocal = firstLocal.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        kDailyReminderId,
        title,
        body,
        tz.TZDateTime.from(firstLocal.toUtc(), tz.UTC),
        _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleDailyReminder failed: $e');
    }
  }

  /// Cancels the daily reminder (when the user turns it off).
  Future<void> cancelDailyReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(kDailyReminderId);
    } catch (e) {
      debugPrint('NotificationService.cancelDailyReminder failed: $e');
    }
  }
}

/// The app-wide notification service. The default instance is un-initialized
/// (its methods no-op) so tests never touch a platform channel; `main` overrides
/// it with an initialized instance.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
