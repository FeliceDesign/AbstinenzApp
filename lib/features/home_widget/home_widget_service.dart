import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Thin, fully-guarded bridge to the Android home-screen widgets.
///
/// Everything here is a no-op off Android and swallows platform errors, so the
/// rest of the app (and the widget tests, which run with no widget host) never
/// has to care whether a launcher/widget surface exists.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Application id — the widget providers live in this package.
  static const String _package = 'com.cleantracker.clean_tracker';

  /// The four Android [HomeWidgetProvider]s, by simple class name.
  static const List<String> providers = <String>[
    'TimeWidgetProvider',
    'MoneyWidgetProvider',
    'UrgeWidgetProvider',
    'DashboardWidgetProvider',
  ];

  /// URI hosts the widgets fire when tapped (`unbound://<host>`).
  static const String hostUrge = 'urge';
  static const String hostDashboard = 'dashboard';

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Writes the latest [data] and asks every provider to re-render.
  static Future<void> push(Map<String, String> data) async {
    if (!_supported) return;
    try {
      await Future.wait(
        data.entries.map(
          (MapEntry<String, String> e) =>
              HomeWidget.saveWidgetData<String>(e.key, e.value),
        ),
      );
      for (final String name in providers) {
        await HomeWidget.updateWidget(qualifiedAndroidName: '$_package.$name');
      }
    } catch (_) {
      // No widget host available (e.g. under flutter_test) — ignore.
    }
  }

  /// Subscribes to widget taps (both cold-start and while running) and forwards
  /// each launch URI to [onUri].
  static Future<void> registerClickHandler(
    void Function(Uri uri) onUri,
  ) async {
    if (!_supported) return;
    try {
      HomeWidget.widgetClicked.listen(
        (Uri? uri) {
          if (uri != null) onUri(uri);
        },
        onError: (_) {},
      );
      final Uri? launch = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launch != null) onUri(launch);
    } catch (_) {
      // Platform channel unavailable — ignore.
    }
  }
}
