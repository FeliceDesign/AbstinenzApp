import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/domain/habit_type_x.dart';
import '../../tracker/presentation/tracker_providers.dart';
import 'onboarding_controller.dart';

/// Localized display name for a habit type.
String habitTypeName(AppLocalizations l10n, HabitType type) => switch (type) {
      HabitType.alcohol => l10n.habitTypeAlcohol,
      HabitType.nicotine => l10n.habitTypeNicotine,
      HabitType.cannabis => l10n.habitTypeCannabis,
      HabitType.sugar => l10n.habitTypeSugar,
      HabitType.gaming => l10n.habitTypeGaming,
      HabitType.porn => l10n.habitTypePorn,
      HabitType.other => l10n.habitTypeOther,
    };

/// Localized default unit label suggestion for a habit type.
String habitTypeDefaultUnit(AppLocalizations l10n, HabitType type) =>
    switch (type) {
      HabitType.alcohol => l10n.unitAlcohol,
      HabitType.nicotine => l10n.unitNicotine,
      HabitType.cannabis => l10n.unitCannabis,
      HabitType.sugar => l10n.unitSugar,
      HabitType.gaming => l10n.unitGaming,
      HabitType.porn => l10n.unitPorn,
      HabitType.other => l10n.unitOther,
    };

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _page = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _unit = TextEditingController();
  int _index = 0;
  static const int _lastStep = 2;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _selectType(HabitType type) {
    final l10n = AppLocalizations.of(context);
    ref.read(onboardingControllerProvider.notifier).setType(type);
    // Prefill name/unit with sensible defaults only if the user hasn't typed.
    if (_name.text.trim().isEmpty) {
      final String name = habitTypeName(l10n, type);
      _name.text = name;
      ref.read(onboardingControllerProvider.notifier).setName(name);
    }
    if (_unit.text.trim().isEmpty) {
      final String unit = habitTypeDefaultUnit(l10n, type);
      _unit.text = unit;
      ref.read(onboardingControllerProvider.notifier).setUnitLabel(unit);
    }
  }

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context);
    if (_index < _lastStep) {
      await _page.nextPage(
        duration: AppMotion.base,
        curve: AppMotion.standard,
      );
      return;
    }
    final bool ok =
        await ref.read(onboardingControllerProvider.notifier).finish();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onbIncomplete)),
      );
    }
    // On success the router redirect moves us to the dashboard automatically.
  }

  void _back() {
    if (_index == 0) return;
    _page.previousPage(duration: AppMotion.base, curve: AppMotion.standard);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    // Can we advance from the current step?
    final bool canProceed = switch (_index) {
      1 => state.type != null && state.name.trim().isNotEmpty,
      _ => true,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: _index, total: _lastStep + 1),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  const _WelcomeStep(),
                  _HabitStep(
                    nameController: _name,
                    unitController: _unit,
                    onSelectType: _selectType,
                  ),
                  const _StartStep(),
                ],
              ),
            ),
            _BottomBar(
              index: _index,
              lastStep: _lastStep,
              isSaving: state.isSaving,
              canProceed: canProceed,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: List.generate(total, (i) {
          final bool done = i <= step;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: AnimatedContainer(
                duration: AppMotion.base,
                height: 4,
                decoration: BoxDecoration(
                  color: done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return _StepScaffold(
      title: l10n.onbWelcomeTitle,
      children: [
        Text(l10n.onbWelcomeBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.onbDisclaimer,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitStep extends ConsumerWidget {
  const _HabitStep({
    required this.nameController,
    required this.unitController,
    required this.onSelectType,
  });

  final TextEditingController nameController;
  final TextEditingController unitController;
  final ValueChanged<HabitType> onSelectType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final HabitType? selected =
        ref.watch(onboardingControllerProvider.select((s) => s.type));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _StepScaffold(
      title: l10n.onbHabitTitle,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final HabitType type in kHabitTypeOrder)
              ChoiceChip(
                avatar: Icon(type.icon, size: 18),
                label: Text(habitTypeName(l10n, type)),
                selected: selected == type,
                onSelected: (_) => onSelectType(type),
              ),
          ],
        ),
        if (selected?.needsMedicalWarning ?? false) ...[
          const SizedBox(height: AppSpacing.lg),
          _WarningCard(text: l10n.onbAlcoholWarning),
        ],
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.onbNameLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.setName,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: unitController,
          decoration: InputDecoration(
            labelText: l10n.onbUnitLabel,
            helperText: l10n.onbUnitHelper,
            border: const OutlineInputBorder(),
          ),
          onChanged: controller.setUnitLabel,
        ),
      ],
    );
  }
}

class _StartStep extends ConsumerWidget {
  const _StartStep();

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final DateTime now = ref.read(clockProvider).now();
    final DateTime current =
        ref.read(onboardingControllerProvider).startedAt;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 20),
      lastDate: now, // future start times are not allowed
    );
    if (date == null || !context.mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!context.mounted) return;
    final DateTime picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    // Clamp to now so a same-day pick can't land in the future.
    ref
        .read(onboardingControllerProvider.notifier)
        .setStartedAt(picked.isAfter(now) ? now : picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final DateTime startedAt =
        ref.watch(onboardingControllerProvider.select((s) => s.startedAt));
    final String locale = Localizations.localeOf(context).toString();

    return _StepScaffold(
      title: l10n.onbStartTitle,
      children: [
        Text(l10n.onbStartBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: Text(
              DateFormat.yMMMEd(locale).add_Hm().format(startedAt),
              style: theme.textTheme.titleLarge,
            ),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () => _pick(context, ref),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => ref
                .read(onboardingControllerProvider.notifier)
                .setStartedAt(ref.read(clockProvider).now()),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: Text(l10n.onbStartNow),
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.lastStep,
    required this.isSaving,
    required this.canProceed,
    required this.onBack,
    required this.onNext,
  });

  final int index;
  final int lastStep;
  final bool isSaving;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isLast = index == lastStep;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (index > 0)
            TextButton(onPressed: onBack, child: Text(l10n.onbBack)),
          const Spacer(),
          FilledButton(
            onPressed: (canProceed && !isSaving) ? onNext : null,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLast ? l10n.onbFinish : l10n.onbNext),
          ),
        ],
      ),
    );
  }
}
