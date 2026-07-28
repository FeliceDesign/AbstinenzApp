import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
}

/// The app-wide notification service. The default instance is un-initialized
/// (its methods no-op) so tests never touch a platform channel; `main` overrides
/// it with an initialized instance.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
