import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/future_letter_store.dart';

/// Free-text "letter to my future self", readable and editable any time.
class FutureLetterScreen extends ConsumerStatefulWidget {
  const FutureLetterScreen({super.key});

  @override
  ConsumerState<FutureLetterScreen> createState() => _FutureLetterScreenState();
}

class _FutureLetterScreenState extends ConsumerState<FutureLetterScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(futureLetterStoreProvider).text,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.futureLetterTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: TextField(
            controller: _controller,
            // Persist on every change — cheap and never loses the letter.
            onChanged: (v) => ref.read(futureLetterStoreProvider).save(v),
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: l10n.futureLetterHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
