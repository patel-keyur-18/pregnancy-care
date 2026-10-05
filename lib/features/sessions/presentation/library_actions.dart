import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Opens a book in the reader or audio in the player (full screen).
void openLibraryItem(BuildContext context, LibraryItem item) => context.push(
  item.kind == LibraryKind.audio ? '/listen' : '/read',
  extra: item.id,
);

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

/// "Add": a book or audio.
Future<void> showAddToLibrary(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        Widget option(NavmaasIcon icon, String label, {required bool audio}) =>
            ListTile(
              leading: NmIcon(icon),
              title: Text(label),
              onTap: () {
                Navigator.pop(sheet);
                unawaited(addToLibrary(context, ref, audio: audio));
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
                option(NavmaasIcon.book, l10n.addBookOption, audio: false),
                option(NavmaasIcon.music, l10n.addAudioOption, audio: true),
              ],
            ),
          ),
        );
      },
    );

/// Rename or remove a library item (long press on its row).
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
    final scheme = Theme.of(sheet).colorScheme;
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

    Future<void> remove() async {
      Navigator.pop(sheet);
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.removeItem),
          content: Text(l10n.removeItemNote),
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
      );
      if (ok ?? false) await repo.remove(item);
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                item.title,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const NmIcon(NavmaasIcon.pencil),
              title: Text(l10n.renameItem),
              onTap: rename,
            ),
            ListTile(
              leading: NmIcon(NavmaasIcon.close, color: scheme.error),
              title: Text(
                l10n.removeItem,
                style: TextStyle(color: scheme.error),
              ),
              onTap: remove,
            ),
          ],
        ),
      ),
    );
  },
);
