import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/urge_technique.dart';
import 'techniques.dart';
import 'urge_controller.dart';
import 'urge_providers.dart';

/// The urge toolkit flow. This is the one place [AppColors.brandBerry] appears:
/// berry means "urge", nothing else.
class UrgeFlowScreen extends ConsumerStatefulWidget {
  const UrgeFlowScreen({super.key});

  @override
  ConsumerState<UrgeFlowScreen> createState() => _UrgeFlowScreenState();
}

enum _Step { intensityStart, choose, technique, intensityEnd, celebrate }

class _UrgeFlowScreenState extends ConsumerState<UrgeFlowScreen> {
  _Step _step = _Step.intensityStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(urgeControllerProvider);
    final controller = ref.read(urgeControllerProvider.notifier);

    return Theme(
      // Tint the flow's interactive accents berry — its exclusive home.
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(primary: AppColors.brandBerry),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.urgeTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: switch (_step) {
              _Step.intensityStart => _IntensityStep(
                  title: l10n.urgeIntensityStartTitle,
                  value: state.intensityStart,
                  onChanged: controller.setIntensityStart,
                  buttonLabel: l10n.urgeStart,
                  onNext: () async {
                    await controller.start();
                    if (mounted) setState(() => _step = _Step.choose);
                  },
                ),
              _Step.choose => _ChooseTechnique(
                  onSelected: (t) {
                    controller.selectTechnique(t);
                    setState(() => _step = _Step.technique);
                  },
                ),
              _Step.technique => _TechniqueRunner(
                  technique: state.technique!,
                  onNext: () => setState(() => _step = _Step.intensityEnd),
                ),
              _Step.intensityEnd => _IntensityStep(
                  title: l10n.urgeIntensityEndTitle,
                  value: state.intensityEnd,
                  onChanged: controller.setIntensityEnd,
                  buttonLabel: l10n.urgeFinish,
                  busy: state.isSaving,
                  onNext: () async {
                    await controller.complete();
                    if (mounted) setState(() => _step = _Step.celebrate);
                  },
                ),
              _Step.celebrate => _Celebrate(
                  from: state.intensityStart,
                  to: state.intensityEnd,
                ),
            },
          ),
        ),
      ),
    );
  }
}

/// A labelled 1–10 intensity slider with a primary action button.
class _IntensityStep extends StatelessWidget {
  const _IntensityStep({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.buttonLabel,
    required this.onNext,
    this.busy = false,
  });

  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final String buttonLabel;
  final VoidCallback onNext;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          '$value',
          style: theme.textTheme.displayLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.urgeScaleLow, style: theme.textTheme.bodySmall),
            Text(l10n.urgeScaleHigh, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : onNext,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _ChooseTechnique extends StatelessWidget {
  const _ChooseTechnique({required this.onSelected});
  final ValueChanged<UrgeTechnique> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.urgeChooseTechnique, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.3,
            children: [
              for (final t in UrgeTechnique.values)
                _TechniqueTile(
                  technique: t,
                  label: techniqueName(l10n, t),
                  onTap: () => onSelected(t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechniqueTile extends StatelessWidget {
  const _TechniqueTile({
    required this.technique,
    required this.label,
    required this.onTap,
  });

  final UrgeTechnique technique;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(technique.icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueRunner extends StatelessWidget {
  const _TechniqueRunner({required this.technique, required this.onNext});
  final UrgeTechnique technique;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(child: buildTechnique(technique)),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            child: Text(l10n.urgeFinish),
          ),
        ),
      ],
    );
  }
}

class _Celebrate extends ConsumerWidget {
  const _Celebrate({required this.from, required this.to});
  final int from;
  final int to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final int count = ref.watch(wavesRiddenCountProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.urgeCelebrateTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.urgeCelebrateCount(count),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          to < from ? l10n.urgeReductionDown(from, to) : l10n.urgeReductionHeld,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(l10n.urgeClose),
        ),
      ],
    );
  }
}
