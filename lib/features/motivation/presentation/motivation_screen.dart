import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/database.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/color_field_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../tracker/presentation/tracker_providers.dart';
import '../domain/benefit_presets.dart';
import 'motivation_l10n.dart';
import 'motivation_providers.dart';

/// Manage screen for motivations: why / benefits / consequences.
class MotivationScreen extends ConsumerWidget {
  const MotivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.motivationTitle),
          actions: [
            IconButton(
              tooltip: l10n.futureLetterTitle,
              icon: const Icon(Icons.mail_outline_rounded),
              onPressed: () => context.push('/future-letter'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabWhy),
              Tab(text: l10n.tabBenefits),
              Tab(text: l10n.tabConsequences),
            ],
          ),
        ),
        // top: false — the AppBar (with its TabBar) already handles the top
        // inset; this adds the missing bottom inset so the "add" button and the
        // last list item clear the system navigation bar.
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _KindTab(kind: MotivationKind.why),
              _BenefitsTab(),
              _KindTab(kind: MotivationKind.consequence),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic reorderable list for `why` and `consequence`.
class _KindTab extends ConsumerWidget {
  const _KindTab({required this.kind});
  final MotivationKind kind;

  String _hint(AppLocalizations l10n) => switch (kind) {
        MotivationKind.why => l10n.motHintWhy,
        MotivationKind.consequence => l10n.motHintConsequence,
        MotivationKind.benefit => l10n.motHintBenefit,
      };

  String _empty(AppLocalizations l10n) => switch (kind) {
        MotivationKind.why => l10n.motEmptyWhy,
        MotivationKind.consequence => l10n.motEmptyConsequence,
        MotivationKind.benefit => l10n.motEmptyBenefit,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(motivationRepositoryProvider);
    final itemsAsync = ref.watch(motivationsByKindProvider(kind));

    return Column(
      children: [
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.genericError)),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      _empty(l10n),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return ReorderableListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                // onReorderItem gives an already-adjusted newIndex (the item at
                // oldIndex is treated as removed), so no manual correction.
                onReorderItem: (oldIndex, newIndex) {
                  final ids = items.map((m) => m.id).toList();
                  final moved = ids.removeAt(oldIndex);
                  ids.insert(newIndex, moved);
                  repo.reorder(ids);
                },
                itemBuilder: (context, i) {
                  final m = items[i];
                  // Emotional, personal statements sit on warm colour fields
                  // (style guide): clay for a "why", deep wine for a
                  // consequence. Berry stays reserved for the urge flow.
                  final Color fill = kind == MotivationKind.consequence
                      ? AppPalette.scale800
                      : AppColors.brandClay;
                  return _MotivationTile(
                    key: ValueKey(m.id),
                    motivation: m,
                    fill: fill,
                    onTap: () => _edit(context, ref, m),
                    onTogglePin: () => repo.setPinned(m.id, !m.isPinned),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.motAdd),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final text = await _showEntryDialog(
      context,
      hint: _hint(
        AppLocalizations.of(context),
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      await ref.read(motivationRepositoryProvider).add(
            kind: kind,
            content: text.trim(),
            isPinned: kind == MotivationKind.why,
          );
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Motivation m) async {
    final result = await _showEntryDialog(
      context,
      initial: m.content,
      hint: _hint(AppLocalizations.of(context)),
      showDelete: true,
    );
    if (result == null) return;
    final repo = ref.read(motivationRepositoryProvider);
    if (result == _deleteSentinel) {
      await repo.delete(m.id);
    } else if (result.trim().isNotEmpty) {
      await repo.updateContent(m.id, result.trim());
    }
  }
}

class _BenefitsTab extends ConsumerWidget {
  const _BenefitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(motivationRepositoryProvider);
    final itemsAsync =
        ref.watch(motivationsByKindProvider(MotivationKind.benefit));
    final habitsAsync = ref.watch(activeHabitsProvider);
    final locale = Localizations.localeOf(context).toString();

    // Preset suggestions based on the first active habit's type.
    final HabitType? type = habitsAsync.valueOrNull?.firstOrNull?.type;
    final presetKeys =
        type == null ? const <String>[] : benefitPresetKeys(type);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.genericError)),
      data: (items) {
        final existing = items.map((m) => m.content).toSet();
        final available = presetKeys
            .map((k) => benefitPresetLabel(l10n, k))
            .where((label) => !existing.contains(label))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (available.isNotEmpty) ...[
              Text(l10n.motPresetsTitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final label in available)
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: Text(label),
                      onPressed: () => repo.add(
                        kind: MotivationKind.benefit,
                        content: label,
                      ),
                    ),
                ],
              ),
              const Divider(height: AppSpacing.xxl),
            ],
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.motEmptyBenefit,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final m in items)
              CheckboxListTile(
                value: m.noticedAt != null,
                onChanged: (v) => repo.setNoticed(m.id, noticed: v ?? false),
                title: Text(m.content),
                subtitle: m.noticedAt != null
                    ? Text(
                        l10n.motNoticedOn(
                          DateFormat.yMMMd(locale).format(m.noticedAt!),
                        ),
                      )
                    : null,
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => repo.delete(m.id),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final text = await _showEntryDialog(
                    context,
                    hint: l10n.motHintBenefit,
                  );
                  if (text != null && text.trim().isNotEmpty) {
                    await repo.add(
                      kind: MotivationKind.benefit,
                      content: text.trim(),
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.motAdd),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MotivationTile extends StatelessWidget {
  const _MotivationTile({
    required this.motivation,
    required this.fill,
    required this.onTap,
    required this.onTogglePin,
    super.key,
  });

  final Motivation motivation;
  final Color fill;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Color faint = Colors.white.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ColorFieldCard(
        fill: fill,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: motivation.isPinned ? l10n.motUnpin : l10n.motPin,
              icon: Icon(
                motivation.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                color: motivation.isPinned ? Colors.white : faint,
              ),
              onPressed: onTogglePin,
            ),
            Expanded(
              child: Text(
                motivation.content,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.drag_handle_rounded, color: faint),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

const String _deleteSentinel = ' __delete__';

/// Shared add/edit dialog. Returns the new text, [_deleteSentinel] to delete,
/// or null on cancel.
Future<String?> _showEntryDialog(
  BuildContext context, {
  String initial = '',
  required String hint,
  bool showDelete = false,
}) {
  final controller = TextEditingController(text: initial);
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        if (showDelete)
          TextButton(
            onPressed: () => Navigator.pop(context, _deleteSentinel),
            child: Text(l10n.motDelete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.motCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l10n.motSave),
        ),
      ],
    ),
  );
}
