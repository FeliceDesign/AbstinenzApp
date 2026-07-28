import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// The "More" tab: a simple menu into secondary features. Grows as later phases
/// land (settings, help, export …).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: Text(l10n.moreMotivation),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/motivation'),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(l10n.futureLetterTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/future-letter'),
          ),
        ],
      ),
    );
  }
}
