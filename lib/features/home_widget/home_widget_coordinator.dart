import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../savings/domain/savings_calculator.dart';
import '../savings/presentation/savings_format.dart';
import '../savings/presentation/savings_providers.dart';
import '../tracker/presentation/tracker_providers.dart';
import 'home_widget_service.dart';

/// A zero-size widget, mounted app-wide behind the nav, that mirrors the live
/// dashboard state into the Android home-screen widgets.
///
/// It re-pushes whenever the watched providers change (so a relapse, a new
/// baseline, or switching habit updates the widgets), and again on app resume
/// so a freshly re-opened app refreshes the surfaces. The heavy lifting — a
/// live, always-accurate day count while the app is closed — is done natively
/// from the stored streak start millis; everything else is a plain string.
class HomeWidgetCoordinator extends ConsumerStatefulWidget {
  const HomeWidgetCoordinator({super.key});

  @override
  ConsumerState<HomeWidgetCoordinator> createState() =>
      _HomeWidgetCoordinatorState();
}

class _HomeWidgetCoordinatorState extends ConsumerState<HomeWidgetCoordinator>
    with WidgetsBindingObserver {
  Map<String, String>? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _last != null) {
      HomeWidgetService.push(_last!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> data = _gather(context, ref);
    if (!mapEquals(data, _last)) {
      _last = data;
      // Push after the frame so we never touch a platform channel mid-build.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => HomeWidgetService.push(data),
      );
    }
    return const SizedBox.shrink();
  }

  Map<String, String> _gather(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final bool de = locale.startsWith('de');
    final DateTime now = ref.watch(clockProvider).now();

    final Map<String, String> data = <String, String>{
      'app_name': l10n.appTitle,
      'urge_title': l10n.urgeFab,
      'urge_sub': de ? 'Tippen für Halt' : 'Tap for support',
      'empty_hint': de ? 'Zum Einrichten tippen' : 'Tap to set up',
      'money_label': l10n.savTileSaved,
    };

    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
    if (habits.isEmpty) {
      data['has_habit'] = 'false';
      data['time_active'] = 'false';
      data['money_has'] = 'false';
      return data;
    }

    data['has_habit'] = 'true';
    final Habit habit = habits.first;
    data['habit_name'] = habit.name;

    final List<QuitAttempt> attempts =
        ref.watch(habitAttemptsProvider(habit.id)).valueOrNull ??
            const <QuitAttempt>[];
    final QuitAttempt? active =
        attempts.where((QuitAttempt a) => a.endedAt == null).firstOrNull;
    if (active != null) {
      final int days = now.difference(active.startedAt).inDays;
      data['time_active'] = 'true';
      data['time_start_millis'] =
          active.startedAt.millisecondsSinceEpoch.toString();
      data['time_days'] = days.toString();
      data['time_label'] = l10n.streakDaysLabel(days);
      data['time_since'] = l10n.dashCleanSince(
        DateFormat.yMMMd(locale).format(active.startedAt),
      );
    } else {
      data['time_active'] = 'false';
    }

    final bool hasBaseline = ref.watch(hasAnyBaselineProvider);
    if (hasBaseline) {
      final money = totalSavings(ref.watch(savingInputsProvider), now).money;
      data['money_has'] = 'true';
      data['money_value'] =
          formatMoney(locale, ref.watch(savingsCurrencyProvider), money);
    } else {
      data['money_has'] = 'false';
    }

    return data;
  }
}
