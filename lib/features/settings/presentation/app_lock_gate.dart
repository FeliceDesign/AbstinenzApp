import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/auth_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_providers.dart';

/// Wraps the app. When the optional app lock is on, the content is hidden
/// behind an unlock screen until the user authenticates (biometric or device
/// passcode). Unlocks last for the app session.
///
/// When the lock is off (the default, and in tests) it renders the child
/// straight through and never touches the auth plugin.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _unlocked = false;
  bool _prompting = false;
  bool _autoTried = false;

  Future<void> _unlock() async {
    if (_prompting) return;
    setState(() => _prompting = true);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool ok =
        await ref.read(authServiceProvider).authenticate(l10n.lockReason);
    if (!mounted) return;
    setState(() {
      _prompting = false;
      if (ok) _unlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(appLockEnabledProvider);
    if (!enabled || _unlocked) return widget.child;

    // Prompt automatically the first time the lock is shown.
    if (!_autoTried && !_prompting) {
      _autoTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _unlock();
      });
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.lockTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _prompting ? null : _unlock,
                child: _prompting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.lockUnlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
