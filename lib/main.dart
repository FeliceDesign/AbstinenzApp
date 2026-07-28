import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/prefs/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load prefs before runApp so onboarding/theme state is available
  // synchronously (no first-frame flicker or loading spinner).
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Initialize local notifications up front and ask for permission once.
  final NotificationService notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const CleanTrackerApp(),
    ),
  );
}
