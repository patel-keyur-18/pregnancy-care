import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/delete_all_data.dart';
import 'package:navmaas/features/backup/data/backup_log.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Me → "Delete all data" (ARCHITECTURE §13): what goes, when she last
/// backed up, "Back up first", and a red "Delete everything". Afterwards
/// the app starts again at onboarding.
Future<void> showDeleteAllData(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _DeleteAllDataDialog(),
);

class _DeleteAllDataDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_DeleteAllDataDialog> createState() => _DeleteState();
}

class _DeleteState extends ConsumerState<_DeleteAllDataDialog> {
  bool _working = false;
  bool _failed = false;

  Future<void> _delete() async {
    setState(() {
      _working = true;
      _failed = false;
    });
    final navigator = Navigator.of(context);
    try {
      await ref.read(deleteAllDataProvider)();
      navigator.pop();
    } on Object {
      if (mounted) {
        setState(() {
          _working = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = ref.watch(lastBackupProvider).value;
    return AlertDialog(
      title: Semantics(header: true, child: Text(l10n.deleteAllTitle)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(l10n.deleteAllBody),
            Text(
              last == null
                  ? l10n.noBackupYet
                  : l10n.lastBackup(DateFormat('EEE d MMM').format(last)),
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_failed)
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.deleteAllFailed,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working
              ? null
              : () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  unawaited(router.push('/backup'));
                },
          child: Text(l10n.backUpFirst),
        ),
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _working ? null : _delete,
          child: Text(_working ? l10n.deleting : l10n.deleteEverything),
        ),
      ],
    );
  }
}
