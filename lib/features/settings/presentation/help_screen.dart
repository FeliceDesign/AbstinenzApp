import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/safety/help_contacts.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Help & emergency contacts. Non-alarming tone; one tap dials a number.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            Text(l10n.helpIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xl),
            for (final HelpContact c in kHelpContactsDe)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.call_rounded),
                  title: Text(_label(l10n, c.labelKey)),
                  subtitle: Text(c.number),
                  onTap: () => _dial(context, c.number),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.onbDisclaimer, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _dial(BuildContext context, String number) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Uri uri = Uri(scheme: 'tel', path: number);
    try {
      final bool ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emergencyCallError)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emergencyCallError)),
        );
      }
    }
  }

  String _label(AppLocalizations l10n, String key) => switch (key) {
        'helpTelefonseelsorge1' => l10n.helpTelefonseelsorge1,
        'helpTelefonseelsorge2' => l10n.helpTelefonseelsorge2,
        'helpSuchtHotline' => l10n.helpSuchtHotline,
        'helpEmergency' => l10n.helpEmergency,
        _ => key,
      };
}
