import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'media_link_repository.g.dart';

/// Links she saved to YouTube, YouTube Music and Spotify (E2).
class MediaLinkRepository {
  const new(this._db);

  final AppDatabase _db;

  /// Most recently opened first, then newest (like the library).
  Stream<List<MediaLink>> watchAll() =>
      (_db.select(_db.mediaLinks)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.desc(t.lastOpenedAt),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .watch();

  Future<void> add({required String title, required Uri url}) => _db
      .into(_db.mediaLinks)
      .insert(
        MediaLinksCompanion.insert(title: title.trim(), url: url.toString()),
      );

  Future<void> edit(String id, {required String title, required Uri url}) =>
      _write(
        id,
        MediaLinksCompanion(
          title: Value(title.trim()),
          url: Value(url.toString()),
        ),
      );

  Future<void> remove(String id) =>
      _write(id, MediaLinksCompanion(deletedAt: Value(clockNow())));

  Future<void> markOpened(String id) =>
      _write(id, MediaLinksCompanion(lastOpenedAt: Value(clockNow())));

  Future<void> _write(String id, MediaLinksCompanion row) =>
      (_db.update(_db.mediaLinks)..where((t) => t.id.equals(id))).write(
        row.copyWith(updatedAt: Value(clockNow())),
      );
}

@riverpod
MediaLinkRepository mediaLinkRepository(Ref ref) =>
    MediaLinkRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<MediaLink>> mediaLinks(Ref ref) =>
    ref.watch(mediaLinkRepositoryProvider).watchAll();

/// Opens [uri] in the app that handles it (YouTube, Spotify), or the
/// browser; false when nothing could. Faked in widget tests.
typedef OpenLink = Future<bool> Function(Uri uri);

@riverpod
OpenLink openLink(Ref ref) => (uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
};
