import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/features/records/data/records_repository.dart';
import 'package:navmaas/features/records/presentation/records_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

/// The name a shared copy gets: her label and the file's kind.
String recordShareName(AppLocalizations l10n, Attachment a) {
  final ext = switch (a.mimeType) {
    'application/pdf' => 'pdf',
    'image/png' => 'png',
    'image/heic' => 'heic',
    _ => 'jpg',
  };
  return '${recordLabel(l10n, a)}.$ext';
}

/// One record, decrypted into memory only (M9a). Edit, share a copy (after a
/// warning) or delete from the ⋯ menu.
class RecordScreen extends ConsumerStatefulWidget {
  const new({required this.recordId, super.key});

  final String recordId;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  Future<Uint8List>? _bytes;

  Attachment? get _record => ref
      .read(recordsProvider)
      .value
      ?.where((a) => a.id == widget.recordId)
      .firstOrNull;

  Future<Uint8List> _load(Attachment a) => _bytes ??= ref
      .read(recordsRepositoryProvider.future)
      .then((repo) => repo.bytes(a));

  Future<void> _menu(Attachment a) async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  recordLabel(l10n, a),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.pencil),
              title: Text(l10n.recordEdit),
              subtitle: Text(l10n.recordEditSub),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.share),
              title: Text(l10n.recordShare),
              subtitle: Text(l10n.recordShareSub),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              leading: NmIcon(NavmaasIcon.close, color: scheme.error),
              title: Text(
                l10n.recordDelete,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 0:
        await _edit(a);
      case 1:
        await _share(a);
      case 2:
        await _delete(a);
    }
  }

  Future<void> _edit(Attachment a) async {
    final details = await showDialog<RecordDetailsResult>(
      context: context,
      builder: (_) => RecordDetailsDialog(
        record: a,
        initialCategory: a.category,
        initialDay: recordDay(a),
      ),
    );
    if (details == null) return;
    final repo = await ref.read(recordsRepositoryProvider.future);
    await repo.updateDetails(
      a.id,
      category: details.category,
      title: details.title,
      takenOn: details.takenOn,
    );
  }

  Future<void> _share(Attachment a) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(header: true, child: Text(l10n.recordShareTitle)),
        content: Text(l10n.recordShareBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recordShareButton),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await shareRecordCopy(
      temp: await ref.read(recordsTempDirProvider.future),
      name: recordShareName(l10n, a),
      bytes: await _load(a),
      share: ref.read(shareFileProvider),
    );
  }

  Future<void> _delete(Attachment a) async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(header: true, child: Text(l10n.recordDeleteTitle)),
        content: Text(l10n.recordDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recordDeleteButton),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = await ref.read(recordsRepositoryProvider.future);
    await repo.delete(a);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    ref.watch(recordsProvider);
    final a = _record;
    if (a == null) return const Scaffold();
    final pdf = a.mimeType == 'application/pdf';
    final note = theme.textTheme.bodySmall!.copyWith(color: scheme.outline);
    Widget cantOpen() => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.recordCantOpen, textAlign: TextAlign.center),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(recordLabel(l10n, a)),
            Text(
              '${recordKindWord(l10n, a.category)} · '
              '${formatShortDate(recordDay(a))}',
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.recordMoreTooltip,
            onPressed: () => _menu(a),
            icon: const NmIcon(NavmaasIcon.more, size: 22),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: FutureBuilder<Uint8List>(
                future: _load(a),
                builder: (context, snap) {
                  if (snap.hasError) return cantOpen();
                  final bytes = snap.data;
                  if (bytes == null) return const SizedBox.expand();
                  if (pdf) {
                    return PdfViewer.data(bytes, sourceName: a.id);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          child: Center(
                            child: Image.memory(
                              bytes,
                              errorBuilder: (_, _, _) => cantOpen(),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(l10n.recordPinch, style: note),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Text(
                l10n.recordViewerNote,
                textAlign: TextAlign.center,
                style: note,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
