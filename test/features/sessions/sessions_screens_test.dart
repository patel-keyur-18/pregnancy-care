import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';

import '../../helpers.dart';

const _story = '''
# The little lamp

In a quiet village by the river,
an old woman kept a small lamp.

Every evening she lit it.''';

Future<void> _pregnancy(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

/// A pregnancy plus [files] (name → text) already in the library.
Future<void> Function(AppDatabase) _seed(
  Directory library, [
  Map<String, String> files = const {},
]) => (db) async {
  await _pregnancy(db);
  final repo = LibraryRepository(db, directory: () async => library);
  for (final MapEntry(key: name, value: text) in files.entries) {
    await repo.import(name, Stream.value(utf8.encode(text)));
  }
};

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Lets real file reads and writes (outside fake time) finish, a step at a
/// time, then redraws.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Finder get _list => find.byType(Scrollable).first;

void main() {
  late Directory library;
  setUp(() => library = Directory.systemTemp.createTempSync('navmaas_lib'));
  tearDown(() => library.deleteSync(recursive: true));

  testWidgets('empty library: path invites adding; Add imports a book', (
    tester,
  ) async {
    final asked = <List<String>>[];
    await pumpApp(
      tester,
      library: library,
      seed: _seed(library),
      pickFile: (extensions) async {
        asked.add(extensions);
        return (
          name: 'evening_stories.txt',
          bytes: Stream.value(utf8.encode(_story)),
        );
      },
    );
    await _tab(tester, 'Sessions');
    expect(find.text('Garbhasanskar path'), findsOneWidget);
    expect(find.text('Week 24 · day 5'), findsOneWidget);
    expect(find.text('Add a book'), findsOneWidget);
    expect(find.text('Add audio'), findsOneWidget);
    expect(find.text("Write today's letter"), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A book (PDF or text)'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(asked.single, ['pdf', 'txt', 'md']);
    expect(find.text('evening stories'), findsOneWidget);
    expect(find.text('Text you added'), findsOneWidget);
    expect(find.text('15 min · evening stories'), findsOneWidget);
  });

  testWidgets('a 15-minute reading session is logged end to end', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      library: library,
      seed: _seed(library, {'evening_stories.md': _story}),
    );
    // Today's plan offers the reading.
    await tester.scrollUntilVisible(find.text('Garbhasanskar reading'), 200);
    expect(find.text('0 of 2 done'), findsOneWidget); // reading and walk

    await _tab(tester, 'Sessions');
    await tester.tap(find.text('evening stories'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(find.text('The little lamp'), findsOneWidget);
    expect(
      find.text(
        'In a quiet village by the river, an old woman kept a small lamp.',
      ),
      findsOneWidget,
    );
    expect(find.text('15:00 left'), findsOneWidget);

    // Pause stops the clock.
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(minutes: 3));
    expect(find.text('15:00 left'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump(const Duration(minutes: 15));
    expect(find.text('Goal reached'), findsOneWidget);

    await tester.tap(find.text('Finish · log 15 min'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    final sessions = (await tester.runAsync(
      () => db.select(db.sessions).get(),
    ))!;
    expect(sessions.single.type, SessionType.reading);
    expect(sessions.single.durationSec, 15 * 60);

    // Ticked on Today; counted on Journey.
    await _tab(tester, 'Today');
    await tester.scrollUntilVisible(find.text('Garbhasanskar reading'), 200);
    expect(find.text('1 of 2 done'), findsOneWidget);
    await _tab(tester, 'Journey');
    await tester.scrollUntilVisible(
      find.text('reading session'),
      300,
      scrollable: _list,
    );
    expect(find.text('reading session'), findsOneWidget);
  });

  testWidgets('a printed book: reading is ticked by hand on Today', (
    tester,
  ) async {
    final db = await pumpApp(tester, library: library, seed: _seed(library));
    // No book in the library: the reading still shows, with a tick.
    await tester.scrollUntilVisible(find.text('15 min · your book'), 200);
    expect(find.text('0 of 2 done'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mark done: Garbhasanskar reading'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 done'), findsOneWidget);
    var sessions = (await tester.runAsync(() => db.select(db.sessions).get()))!;
    expect(
      (sessions.single.type, sessions.single.durationSec),
      (SessionType.reading, 15 * 60),
    );
    expect(sessions.single.libraryItemId, isNull);

    // Unticking takes it back.
    await tester.tap(find.bySemanticsLabel('Done: Garbhasanskar reading'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 2 done'), findsOneWidget);
    sessions = (await tester.runAsync(() => db.select(db.sessions).get()))!;
    expect(sessions.single.deletedAt, isNotNull);

    // Counted on Journey once ticked again.
    await tester.tap(find.bySemanticsLabel('Mark done: Garbhasanskar reading'));
    await tester.pumpAndSettle();
    await _tab(tester, 'Journey');
    await tester.scrollUntilVisible(
      find.text('reading session'),
      300,
      scrollable: _list,
    );
    expect(find.text('reading session'), findsOneWidget);
  });

  testWidgets('library: going back keeps Finished; ⋯ opens rename / remove', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      library: library,
      seed: (db) async {
        await _seed(library, {'short.txt': _story})(db);
        final repo = LibraryRepository(db, directory: () async => library);
        final item = (await repo.watchItems().first).single;
        await repo.setProgress(item.id, position: 1000, total: 1000);
        await repo.setProgress(item.id, position: 0, total: 1000);
      },
    );
    await _tab(tester, 'Sessions');
    await tester.scrollUntilVisible(find.text('short'), 200, scrollable: _list);
    expect(find.text('Text you added · Finished'), findsOneWidget);
    final item = (await tester.runAsync(
      () => db.select(db.libraryItems).getSingle(),
    ))!;
    expect((item.position, item.furthest), (0, 1000));

    await tester.ensureVisible(find.byTooltip('Rename or remove'));
    await tester.tap(find.byTooltip('Rename or remove'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    await tester.tap(find.text('Remove from library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from library').last);
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(find.text('short'), findsNothing);
  });

  testWidgets('links: add, open in their app, edit and remove', (tester) async {
    final opened = <Uri>[];
    var canOpen = true;
    final db = await pumpApp(
      tester,
      library: library,
      seed: _seed(library),
      openLink: (uri) async {
        opened.add(uri);
        return canOpen;
      },
    );
    await _tab(tester, 'Sessions');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube, YouTube Music or Spotify'), findsOneWidget);
    await tester.tap(find.text('A link'));
    await tester.pumpAndSettle();
    expect(find.text('Add a link'), findsOneWidget);

    // Only YouTube, YouTube Music and Spotify, and a title.
    await tester.enterText(find.byType(TextField).last, 'example.com/song');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Add a title.'), findsOneWidget);
    expect(
      find.text('Paste a YouTube, YouTube Music or Spotify link.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'Lullaby playlist');
    await tester.enterText(
      find.byType(TextField).last,
      'open.spotify.com/playlist/abc',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Lullaby playlist'), findsNWidgets(2), reason: 'Listen');
    expect(find.text('Spotify · opens outside Navmaas'), findsOneWidget);
    var link = (await tester.runAsync(
      () => db.select(db.mediaLinks).getSingle(),
    ))!;
    expect(link.url, 'https://open.spotify.com/playlist/abc');

    // A tap opens it outside Navmaas.
    await tester.tap(find.text('Spotify · opens outside Navmaas'));
    await tester.pumpAndSettle();
    expect(opened.single, Uri.parse('https://open.spotify.com/playlist/abc'));
    canOpen = false;
    await tester.tap(find.text('Lullaby playlist').first);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't open this link."), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the snackbar goes
    await tester.pumpAndSettle();

    // ⋯ → Edit link.
    await tester.tap(find.byTooltip('Rename or remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Evening raga');
    await tester.enterText(
      find.byType(TextField).last,
      'https://music.youtube.com/playlist?list=x',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube Music · opens outside Navmaas'), findsOneWidget);
    link = (await tester.runAsync(() => db.select(db.mediaLinks).getSingle()))!;
    expect(link.title, 'Evening raga');

    // ⋯ → Remove.
    await tester.tap(find.byTooltip('Rename or remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from library'));
    await tester.pumpAndSettle();
    expect(find.text('This removes the link from Navmaas.'), findsOneWidget);
    await tester.tap(find.text('Remove from library').last);
    await tester.pumpAndSettle();
    expect(find.text('Evening raga'), findsNothing);
    expect(find.text('Add audio'), findsOneWidget);
  });

  testWidgets('Listen with nothing added offers audio or a link', (
    tester,
  ) async {
    await pumpApp(tester, library: library, seed: _seed(library));
    await _tab(tester, 'Sessions');
    await tester.tap(find.text('Add audio'));
    await tester.pumpAndSettle();
    expect(find.text('Audio (MP3, M4A, AAC or WAV)'), findsOneWidget);
    expect(find.text('A link'), findsOneWidget);
    expect(find.text('A book (PDF or text)'), findsNothing);
  });

  testWidgets('audio: Replace file keeps the title, swaps the file', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      library: library,
      seed: _seed(library, {'om_chanting.mp3': 'old'}),
      pickFile: (extensions) async {
        expect(extensions, ['mp3', 'm4a', 'aac', 'wav']);
        return (name: 'new_take.m4a', bytes: Stream.value(utf8.encode('new')));
      },
    );
    final before = (await tester.runAsync(
      () => db.select(db.libraryItems).getSingle(),
    ))!;
    await _tab(tester, 'Sessions');
    await tester.scrollUntilVisible(
      find.text('om chanting').last,
      200,
      scrollable: _list,
    );
    await tester.longPress(find.text('om chanting').last);
    await tester.pumpAndSettle();
    expect(find.text('Choose a new audio file; the title stays'), findsOne);
    await tester.tap(find.text('Replace file'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    final after = (await tester.runAsync(
      () => db.select(db.libraryItems).getSingle(),
    ))!;
    expect(after.title, 'om chanting');
    expect(after.fileName, endsWith('.m4a'));
    expect(after.durationSec, isNull);
    expect(File('${library.path}/${after.fileName}').readAsStringSync(), 'new');
    expect(File('${library.path}/${before.fileName}').existsSync(), isFalse);
  });

  testWidgets('reader: night colours by switch, and the place is kept', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      library: library,
      seed: _seed(library, {
        'long.txt': List.generate(80, (i) => 'Paragraph $i.').join('\n\n'),
      }),
    );
    await _tab(tester, 'Sessions');
    await tester.tap(find.text('long'));
    await tester.pumpAndSettle();
    await _settleIo(tester);

    Color background() =>
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor!;
    expect(background(), const Color(0xFFF6EEDF), reason: 'paper by day');
    await tester.tap(find.text('Night reading'));
    await tester.pump();
    expect(background(), const Color(0xFF1E1913));
    await tester.tap(find.byTooltip('Switch to paper colours'));
    await tester.pump();
    expect(background(), const Color(0xFFF6EEDF));

    await tester.drag(find.text('Paragraph 0.'), const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    final item = (await tester.runAsync(
      () => db.select(db.libraryItems).getSingle(),
    ))!;
    expect(item.total, 1000);
    expect(item.position, greaterThan(0));
    expect(find.textContaining('% read'), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.sessions).get()),
      isEmpty,
      reason: 'under a minute is not logged',
    );
  });

  testWidgets('listen: plays, sleep timer, screen off and wake', (
    tester,
  ) async {
    final audio = FakeAudio();
    await pumpApp(
      tester,
      audio: audio,
      library: library,
      seed: _seed(library, {'om_chanting.mp3': 'not really audio'}),
    );
    await _tab(tester, 'Sessions');
    expect(find.text('Audio you added · offline'), findsOneWidget);
    await tester.tap(find.text('om chanting').last); // the library row
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(audio.opened, hasLength(1));
    expect(audio.current.playing, isTrue);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Forward 15 seconds'));
    await tester.pumpAndSettle();
    expect(audio.current.position, const Duration(seconds: 15));

    await tester.tap(find.text('Sleep timer · off'));
    await tester.pumpAndSettle();
    expect(find.text('Sleep timer · 10 min'), findsOneWidget);
    await tester.pump(const Duration(minutes: 10));
    await tester.pumpAndSettle();
    expect(audio.current.playing, isFalse);
    expect(find.text('Sleep timer · off'), findsOneWidget);

    await tester.tap(find.text('Screen off — keep listening'));
    await tester.pumpAndSettle();
    expect(find.text('om chanting is playing'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Wake screen')));
    await tester.pumpAndSettle();
    expect(find.text('Listening'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    // The library now knows the length.
    expect(find.text('Audio you added · 10 min · offline'), findsOneWidget);
  });

  testWidgets('letters: write, reread, edit and remove', (tester) async {
    final db = await pumpApp(tester, library: library, seed: _seed(library));
    await _tab(tester, 'Sessions');
    await tester.tap(find.text('Talk to baby'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Talk to your baby in writing'), findsOneWidget);

    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dear little one, hello.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Dear little one, hello.'), findsOneWidget);

    await tester.tap(find.text('Dear little one, hello.'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dear little one, hi.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Dear little one, hi.'), findsOneWidget);
    final rows = (await tester.runAsync(() => db.select(db.letters).get()))!;
    expect(rows.single.body, 'Dear little one, hi.');

    await tester.tap(find.text('Dear little one, hi.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove letter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove letter').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Talk to your baby in writing'), findsOneWidget);
  });

  testWidgets('activity of the day opens in a sheet', (tester) async {
    await pumpApp(tester, library: library, seed: _seed(library));
    await _tab(tester, 'Sessions');
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text("Today's activity"), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text("Today's activity"), findsNothing);
  });

  testWidgets('long press: rename and remove a library item', (tester) async {
    await pumpApp(
      tester,
      library: library,
      seed: _seed(library, {'a_book.txt': 'Hello.'}),
    );
    await _tab(tester, 'Sessions');
    await tester.longPress(find.text('a book'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Evening stories');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Evening stories'), findsOneWidget);

    await tester.longPress(find.text('Evening stories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from library').last);
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(find.text('Evening stories'), findsNothing);
    expect(library.listSync(), isEmpty);
  });

  testWidgets('Me: night reading after 9 pm can be switched off', (
    tester,
  ) async {
    final db = await pumpApp(tester, library: library, seed: _seed(library));
    await _tab(tester, 'Me');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final value = await tester.runAsync(
      () => SettingsRepository(db).watch(SettingKeys.nightReading).first,
    );
    expect(value, 'false');
  });
}
