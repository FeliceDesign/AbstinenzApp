import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/calendar_day.dart';
import 'calendar_cell.dart';
import 'calendar_providers.dart';
import 'day_detail_sheet.dart';

/// A Monday date used only to render localized weekday short labels (Mon..Sun).
final DateTime _refMonday = DateTime(2024, 1, 1);

/// Large centre page so the month pager can swipe far in either direction.
const int _basePage = 100000;

/// The calendar tab: a month heatmap (swipe between months), a habit selector
/// for multi-habit users, a compact year overview, and a per-day detail sheet.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final PageController _pager = PageController(initialPage: _basePage);
  late DateTime _thisMonth;
  int _page = _basePage;
  int? _habitId;
  bool _yearView = false;
  late int _year;

  @override
  void initState() {
    super.initState();
    final DateTime now = ref.read(clockProvider).now();
    _thisMonth = monthStart(now.year, now.month);
    _year = now.year;
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) => addMonths(_thisMonth, page - _basePage);

  void _openMonth(DateTime month) {
    final int page = _basePage + monthsBetween(_thisMonth, month);
    setState(() {
      _yearView = false;
      _page = page;
    });
    // The month pager only exists once the month view rebuilds, so jump after
    // this frame — jumping now would target a controller with no clients.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pager.hasClients) _pager.jumpToPage(page);
    });
  }

  Future<void> _openDay(int habitId, DateTime day) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => DayDetailSheet(habitId: habitId, day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Habit> habits =
        ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];

    if (habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navCalendar)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.calNoHabit,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final int habitId = habits.any((Habit h) => h.id == _habitId)
        ? _habitId!
        : habits.first.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCalendar),
        actions: <Widget>[
          if (habits.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: l10n.calSelectHabit,
              initialValue: habitId,
              onSelected: (int id) => setState(() => _habitId = id),
              itemBuilder: (_) => <PopupMenuEntry<int>>[
                for (final Habit h in habits)
                  PopupMenuItem<int>(value: h.id, child: Text(h.name)),
              ],
            ),
          IconButton(
            tooltip: _yearView ? l10n.calShowMonth : l10n.calShowYear,
            icon: Icon(
              _yearView
                  ? Icons.calendar_view_month_rounded
                  : Icons.calendar_today_rounded,
            ),
            onPressed: () => setState(() => _yearView = !_yearView),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _yearView
            ? _YearView(
                habitId: habitId,
                year: _year,
                onPickYear: (int delta) => setState(() => _year += delta),
                onPickMonth: (int month) =>
                    _openMonth(monthStart(_year, month)),
              )
            : _MonthView(
                habitId: habitId,
                month: _monthForPage(_page),
                pager: _pager,
                onPageChanged: (int p) => setState(() => _page = p),
                monthForPage: _monthForPage,
                onStep: (int delta) {
                  _pager.animateToPage(
                    _page + delta,
                    duration: AppMotion.base,
                    curve: AppMotion.standard,
                  );
                },
                onTapDay: (DateTime day) => _openDay(habitId, day),
              ),
      ),
    );
  }
}

// --- Month view --------------------------------------------------------------

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.habitId,
    required this.month,
    required this.pager,
    required this.onPageChanged,
    required this.monthForPage,
    required this.onStep,
    required this.onTapDay,
  });

  final int habitId;
  final DateTime month;
  final PageController pager;
  final ValueChanged<int> onPageChanged;
  final DateTime Function(int page) monthForPage;
  final ValueChanged<int> onStep;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    return Column(
      children: <Widget>[
        _MonthHeader(
          label: toBeginningOfSentenceCase(
                DateFormat.yMMMM(locale).format(month),
              ) ??
              '',
          onPrev: () => onStep(-1),
          onNext: () => onStep(1),
        ),
        const _WeekdayHeader(),
        // Expanded + LayoutBuilder: the grid is sized to the space it's given
        // (six rows, seven columns), so the month view never overflows on small
        // screens and needs no inner scrolling.
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double aspect = (c.maxWidth / 7) / (c.maxHeight / 6);
              return PageView.builder(
                controller: pager,
                onPageChanged: onPageChanged,
                itemBuilder: (BuildContext context, int page) => _MonthGrid(
                  habitId: habitId,
                  month: monthForPage(page),
                  aspectRatio: aspect,
                  onTapDay: onTapDay,
                ),
              );
            },
          ),
        ),
        const _Legend(),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  DateFormat.E(locale).format(addDays(_refMonday, i)),
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.habitId,
    required this.month,
    required this.aspectRatio,
    required this.onTapDay,
  });

  final int habitId;
  final DateTime month;
  final double aspectRatio;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CalendarDay> days =
        ref.watch(calendarMonthProvider(habitId, month.year, month.month));
    // Monday-first leading blanks.
    final int leading = DateTime(month.year, month.month, 1).weekday - 1;

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: aspectRatio <= 0 ? 1 : aspectRatio,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        for (int i = 0; i < leading; i++) const SizedBox.shrink(),
        for (final CalendarDay d in days)
          CalendarCell(
            day: d,
            onTap: d.inFuture ? null : () => onTapDay(d.date),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    Widget item(Color color, String label, {bool ring = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: ring ? Colors.transparent : color,
                borderRadius: BorderRadius.circular(4),
                border: ring ? Border.all(color: color, width: 1.5) : null,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: <Widget>[
          item(AppColors.brandGold, l10n.legendClean),
          item(theme.colorScheme.outline, l10n.legendRelapse),
          item(AppColors.brandSky, l10n.legendCheckin, ring: true),
        ],
      ),
    );
  }
}

// --- Year view ---------------------------------------------------------------

class _YearView extends StatelessWidget {
  const _YearView({
    required this.habitId,
    required this.year,
    required this.onPickYear,
    required this.onPickMonth,
  });

  final int habitId;
  final int year;
  final ValueChanged<int> onPickYear;
  final ValueChanged<int> onPickMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _MonthHeader(
          label: '$year',
          onPrev: () => onPickYear(-1),
          onNext: () => onPickYear(1),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(AppSpacing.lg),
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.8,
            children: <Widget>[
              for (int m = 1; m <= 12; m++)
                _MiniMonth(
                  habitId: habitId,
                  year: year,
                  month: m,
                  onTap: () => onPickMonth(m),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMonth extends ConsumerWidget {
  const _MiniMonth({
    required this.habitId,
    required this.year,
    required this.month,
    required this.onTap,
  });

  final int habitId;
  final int year;
  final int month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String locale = Localizations.localeOf(context).toString();
    final ThemeData theme = Theme.of(context);
    final List<CalendarDay> days =
        ref.watch(calendarMonthProvider(habitId, year, month));
    final int leading = DateTime(year, month, 1).weekday - 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            toBeginningOfSentenceCase(
                  DateFormat.MMM(locale).format(DateTime(year, month)),
                ) ??
                '',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                for (int i = 0; i < leading; i++) const SizedBox.shrink(),
                for (final CalendarDay d in days) _MiniCell(day: d),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCell extends StatelessWidget {
  const _MiniCell({required this.day});
  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (day.status) {
      DayStatus.clean => AppColors.brandGold.withValues(
          alpha: <double>[0.25, 0.45, 0.70, 1.0][warmthTier(day.cleanRun)],
        ),
      DayStatus.relapse => scheme.surfaceContainerHighest,
      DayStatus.none => scheme.surfaceContainerLow,
    };
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: day.status == DayStatus.relapse
            ? Border.all(color: scheme.outline, width: 0.5)
            : null,
      ),
    );
  }
}
