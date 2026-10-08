import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/media_link_repository.dart';
import 'package:navmaas/features/sessions/domain/media_link.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Opens a book in the reader or audio in the player (full screen).
Future<void> openLibraryItem(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item,
) async {
  final repo = ref.read(libraryRepositoryProvider);
  // A backup restored without books and audio lists them, but their files
  // aren't on this phone: choose the same file again.
  if (!(await repo.file(item)).existsSync()) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final again = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fileMissing),
        content: Text(l10n.fileMissingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reimportFile),
          ),
        ],
      ),
    );
    if (again != true) return;
    final picked = await ref.read(pickFileProvider)([
      for (final MapEntry(key: ext, value: kind) in libraryExtensions.entries)
        if (kind == item.kind) ext,
    ]);
    if (picked == null) return;
    await repo.replaceFile(item, picked.bytes);
  }
  if (!context.mounted) return;
  await context.push(
    item.kind == LibraryKind.audio ? '/listen' : '/read',
    extra: item.id,
  );
}

/// Picks a book or an audio file and copies it into the library.
Future<void> addToLibrary(
  BuildContext context,
  WidgetRef ref, {
  required bool audio,
}) async {
  final picked = await ref.read(pickFileProvider)([
    for (final MapEntry(key: ext, value: kind) in libraryExtensions.entries)
      if ((kind == LibraryKind.audio) == audio) ext,
  ]);
  if (picked == null) return;
  final item = await ref
      .read(libraryRepositoryProvider)
      .import(picked.name, picked.bytes);
  if (item == null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).importUnsupported)),
    );
  }
}

/// "Add": a book, audio or a link. From the empty Listen tile
/// ([listenOnly]): audio or a link.
Future<void> showAddToLibrary(
  BuildContext context,
  WidgetRef ref, {
  bool listenOnly = false,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    Widget option(
      NavmaasIcon icon,
      String label,
      VoidCallback onTap, {
      String? subtitle,
    }) => ListTile(
      leading: NmIcon(icon),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () {
        Navigator.pop(sheet);
        onTap();
      },
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.addToLibrary,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (!listenOnly)
              option(
                NavmaasIcon.book,
                l10n.addBookOption,
                () => unawaited(addToLibrary(context, ref, audio: false)),
              ),
            option(
              NavmaasIcon.music,
              l10n.addAudioOption,
              () => unawaited(addToLibrary(context, ref, audio: true)),
            ),
            option(
              NavmaasIcon.external,
              l10n.addLinkOption,
              () => unawaited(showLinkDialog(context, ref)),
              subtitle: l10n.linkServices,
            ),
          ],
        ),
      ),
    );
  },
);

/// Rename, replace (audio) or remove a library item (its ⋯ or a long press).
Future<void> showLibraryItemActions(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final repo = ref.read(libraryRepositoryProvider);

    Future<void> rename() async {
      Navigator.pop(sheet);
      final title = await showDialog<String>(
        context: context,
        builder: (_) => TextEntryDialog(
          title: l10n.renameItem,
          initial: item.title,
          singleLine: true,
        ),
      );
      if (title != null && title.trim().isNotEmpty) {
        await repo.rename(item.id, title);
      }
    }

    Future<void> replace() async {
      Navigator.pop(sheet);
      final picked = await ref.read(pickFileProvider)([
        for (final MapEntry(key: ext, value: kind) in libraryExtensions.entries)
          if (kind == LibraryKind.audio) ext,
      ]);
      if (picked == null) return;
      // Stop it first if it's playing; the player loads the new file next.
      final audio = await ref.read(audioPlaybackProvider.future);
      if (audio.current.itemId == item.id && audio.current.playing) {
        await audio.pause();
      }
      final ok = await repo.replaceAudio(item, picked.name, picked.bytes);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.importUnsupported)));
      }
    }

    Future<void> remove() async {
      Navigator.pop(sheet);
      final ok = await confirmRemove(context);
      if (ok) await repo.remove(item);
    }

    return _ActionsSheet(
      title: item.title,
      actions: [
        (NavmaasIcon.pencil, l10n.renameItem, null, rename),
        if (item.kind == LibraryKind.audio)
          (NavmaasIcon.upload, l10n.replaceFile, l10n.replaceFileNote, replace),
      ],
      onRemove: remove,
    );
  },
);

/// Asks before removing something from the library; [note] says what
/// goes (default: Navmaas's copy of a file).
Future<bool> confirmRemove(BuildContext context, {String? note}) async {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.removeItem),
          content: Text(note ?? l10n.removeItemNote),
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
              child: Text(l10n.removeItem),
            ),
          ],
        ),
      ) ??
      false;
}

/// Edit or remove a saved link (its ⋯ or a long press).
Future<void> showLinkActions(
  BuildContext context,
  WidgetRef ref,
  MediaLink link,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    return _ActionsSheet(
      title: link.title,
      actions: [
        (
          NavmaasIcon.pencil,
          l10n.editLink,
          null,
          () {
            Navigator.pop(sheet);
            unawaited(showLinkDialog(context, ref, link: link));
          },
        ),
      ],
      onRemove: () async {
        Navigator.pop(sheet);
        final ok = await confirmRemove(context, note: l10n.removeLinkNote);
        if (ok) await ref.read(mediaLinkRepositoryProvider).remove(link.id);
      },
    );
  },
);

/// Opens [link] in YouTube, YouTube Music or Spotify (or the browser).
Future<void> openMediaLink(
  BuildContext context,
  WidgetRef ref,
  MediaLink link,
) async {
  unawaited(ref.read(mediaLinkRepositoryProvider).markOpened(link.id));
  final opened = await ref.read(openLinkProvider)(Uri.parse(link.url));
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).linkOpenFailed)),
    );
  }
}

/// "Add a link", or "Edit link" for [link]; saves on Save.
Future<void> showLinkDialog(
  BuildContext context,
  WidgetRef ref, {
  MediaLink? link,
}) async {
  final saved = await showDialog<({String title, Uri url})>(
    context: context,
    builder: (_) => LinkDialog(link: link),
  );
  if (saved == null) return;
  final repo = ref.read(mediaLinkRepositoryProvider);
  if (link == null) {
    await repo.add(title: saved.title, url: saved.url);
  } else {
    await repo.edit(link.id, title: saved.title, url: saved.url);
  }
}

/// A title and a YouTube, YouTube Music or Spotify link. Owns its
/// controllers (they must outlive the closing animation).
class LinkDialog extends StatefulWidget {
  const new({this.link, super.key});

  final MediaLink? link;

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  late final _title = TextEditingController(text: widget.link?.title);
  late final _url = TextEditingController(text: widget.link?.url);
  String? _titleError;
  String? _urlError;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    final url = parseMediaLink(_url.text);
    setState(() {
      _titleError = title.isEmpty ? l10n.linkTitleNeeded : null;
      _urlError = url == null ? l10n.linkInvalid : null;
    });
    if (title.isNotEmpty && url != null) {
      Navigator.pop(context, (title: title, url: url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Semantics(
        header: true,
        child: Text(widget.link == null ? l10n.addLinkTitle : l10n.editLink),
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          TextField(
            controller: _title,
            autofocus: widget.link == null,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              labelText: l10n.titleLabel,
              errorText: _titleError,
            ),
          ),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            decoration: InputDecoration(
              labelText: l10n.linkLabel,
              errorText: _urlError,
              errorMaxLines: 3,
            ),
          ),
          Text(
            l10n.linkHelp,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

/// A library sheet: the item's name, its [actions] (icon, label, optional
/// note, handler) and a red Remove.
class _ActionsSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.actions,
    required this.onRemove,
  });

  final String title;
  final List<(NavmaasIcon, String, String?, VoidCallback)> actions;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final (icon, label, note, onTap) in actions)
              ListTile(
                leading: NmIcon(icon),
                title: Text(label),
                subtitle: note == null ? null : Text(note),
                onTap: onTap,
              ),
            ListTile(
              leading: NmIcon(NavmaasIcon.close, color: scheme.error),
              title: Text(
                l10n.removeItem,
                style: TextStyle(color: scheme.error),
              ),
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
