import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/sessions/data/letter_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Letters to baby ("Talk to baby"), newest first. Not drawn in the
/// prototype; built from its card and list styles (DESIGN_SYSTEM §8).
class LettersScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final letters = ref.watch(lettersProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lettersTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          24,
        ),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
            onPressed: () => context.go('/sessions/letters/edit'),
            icon: NmIcon(
              NavmaasIcon.pencil,
              size: 18,
              strokeWidth: 2.2,
              color: scheme.onPrimary,
            ),
            label: Text(l10n.writeLetter),
          ),
          const SizedBox(height: 14),
          if (letters.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.lettersEmpty,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          for (final letter in letters)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () =>
                    context.go('/sessions/letters/edit', extra: letter.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        formatDate(letter.createdAt.toLocal()),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                      Text(
                        letter.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.reading.copyWith(
                          fontSize: 16,
                          height: 24 / 16,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Write a new letter, or reread and edit one.
class EditLetterScreen extends ConsumerStatefulWidget {
  const new({this.letterId, super.key});

  final String? letterId;

  @override
  ConsumerState<EditLetterScreen> createState() => _EditLetterScreenState();
}

class _EditLetterScreenState extends ConsumerState<EditLetterScreen> {
  final _body = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (pregnancy == null || _body.text.trim().isEmpty) return;
    await ref
        .read(letterRepositoryProvider)
        .save(pregnancy.id, _body.text, id: widget.letterId);
    if (mounted) context.pop();
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.removeLetter),
        content: Text(l10n.removeLetterNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.removeLetter),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(letterRepositoryProvider).remove(widget.letterId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final letters = ref.watch(lettersProvider);
    if (!_loaded && widget.letterId != null && letters.hasValue) {
      _loaded = true;
      _body.text =
          letters.value!
              .where((l) => l.id == widget.letterId)
              .firstOrNull
              ?.body ??
          '';
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editLetter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          24,
        ),
        children: [
          TextField(
            controller: _body,
            autofocus: widget.letterId == null,
            minLines: 10,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(20000)],
            style: AppTheme.reading.copyWith(color: scheme.onSurface),
            decoration: InputDecoration(hintText: l10n.letterHint),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
            onPressed: _save,
            child: Text(l10n.saveButton),
          ),
          if (widget.letterId != null) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _remove,
                child: Text(l10n.removeLetter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
