import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/domain/onboarding_gate.dart';
import '../../savings/presentation/savings_providers.dart';
import 'settings_providers.dart';

/// Settings: appearance, the calorie toggle, safety/privacy info, and the
/// double-confirmed "delete all data" action.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ThemeMode mode = ref.watch(themeModeSettingProvider);
    final bool calories = ref.watch(caloriesEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            _SectionTitle(text: l10n.setAppearance),
            SegmentedButton<ThemeMode>(
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(l10n.setThemeSystem),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(l10n.setThemeLight),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(l10n.setThemeDark),
                ),
              ],
              selected: <ThemeMode>{mode},
              showSelectedIcon: false,
              onSelectionChanged: (Set<ThemeMode> s) =>
                  ref.read(themeModeSettingProvider.notifier).set(s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(text: l10n.setCounters),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.setShowCalories),
              value: calories,
              onChanged: (bool v) =>
                  ref.read(caloriesEnabledProvider.notifier).set(value: v),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(text: l10n.setSafety),
            _InfoCard(
              icon: Icons.medical_information_outlined,
              title: l10n.setDisclaimerTitle,
              body: l10n.onbDisclaimer,
            ),
            _InfoCard(
              icon: Icons.warning_amber_rounded,
              title: l10n.setMedicalTitle,
              body: l10n.onbAlcoholWarning,
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_rounded),
                title: Text(l10n.helpTitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/help'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(text: l10n.setPrivacy),
            _InfoCard(
              icon: Icons.lock_outline_rounded,
              title: l10n.setPrivacyTitle,
              body: l10n.setPrivacyBody,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(text: l10n.setData),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(l10n.setDeleteTitle),
                subtitle: Text(l10n.setDeleteBody),
                onTap: () => _deleteAll(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Text(
                l10n.appTitle,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final bool first = await _confirm(
      context,
      title: l10n.setDeleteTitle,
      body: l10n.setDeleteConfirm1,
      confirmLabel: l10n.setDeleteContinue,
    );
    if (!first || !context.mounted) return;

    final bool second = await _confirm(
      context,
      title: l10n.setDeleteConfirm2Title,
      body: l10n.setDeleteConfirm2,
      confirmLabel: l10n.setDeleteButton,
      destructive: true,
    );
    if (!second) return;

    await ref.read(dataRepositoryProvider).wipeAll();
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(onboardingGateProvider).reset();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
