import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'mood_l10n.dart';

/// A 1..5 mood picker rendered as five faces (colour + face + label, so meaning
/// never rests on colour alone — A11y rule). [value] may be null when unset.
class MoodFacePicker extends StatelessWidget {
  const MoodFacePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (int score = 1; score <= 5; score++)
          _FaceButton(
            score: score,
            selected: value == score,
            label: moodScoreLabel(l10n, score),
            onTap: () => onChanged(score),
          ),
      ],
    );
  }
}

class _FaceButton extends StatelessWidget {
  const _FaceButton({
    required this.score,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int score;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = moodColor(score);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color.withValues(alpha: 0.22) : Colors.transparent,
            border: Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(moodFaceIcon(score), color: color, size: 30),
        ),
      ),
    );
  }
}

/// A generic 1..[max] numeric picker (energy, sleep, urge strength). Shows the
/// number plus an optional [icon]; the value is also exposed to screen readers.
class ScalePicker extends StatelessWidget {
  const ScalePicker({
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.semanticLabel,
    super.key,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final int max;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (int n = 1; n <= max; n++)
          Semantics(
            button: true,
            selected: value == n,
            label: semanticLabel == null ? '$n' : '$semanticLabel $n',
            child: ChoiceChip(
              label: Text('$n'),
              selected: value == n,
              showCheckmark: false,
              onSelected: (_) => onChanged(n),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: value == n
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              selectedColor: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
