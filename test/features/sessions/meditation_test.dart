import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';

import '../../helpers.dart';

late Directory _library;

/// Week 24; [audio] adds one audio file to her library.
Future<void> Function(AppDatabase) _seed({bool audio = false}) => (db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  if (audio) {
    await LibraryRepository(
      db,
      directory: () async => _library,
    ).import('om_chanting.mp3', Stream.value(utf8.encode('not really audio')));
  }
};

/// Lets real file reads finish (they run outside fake time).
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _openMeditation(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavmaasTabBar),
      matching: find.text('Sessions'),
    ),
  );
  await tester.pumpAndSettle();
  final tile = find.text('Meditation');
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<List<Session>> _sessions(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.sessions).get()))!;

void main() {
  setUp(() => _library = Directory.systemTemp.createTempSync('navmaas_med'));
  tearDown(() => _library.deleteSync(recursive: true));

  testWidgets('the timer plays as one track and is logged from one minute', (
    tester,
  ) async {
    final audio = FakeAudio();
    final db = await pumpApp(tester, audio: audio, seed: _seed());
    await _openMeditation(tester);
    expect(find.text('A soft bell at the start and the end'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    await _tap(tester, find.text('5 min'));
    expect(find.text('5:00'), findsOneWidget);

    // Under a minute: nothing is logged.
    await _tap(tester, find.text('Start'));
    expect(audio.opened, [meditationTimerId(5)]);
    expect(audio.current.playing, isTrue);
    expect(find.text('Breathe softly'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await _tap(tester, find.text('Finish'));
    expect(find.text('Start'), findsOneWidget, reason: 'back to the choice');
    expect(await _sessions(tester, db), isEmpty);

    // Two minutes, paused once.
    await _tap(tester, find.text('Start'));
    await tester.pump(const Duration(minutes: 2));
    // The fake doesn't move on by itself; the real track does.
    await audio.seek(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(find.text('3:00'), findsOneWidget, reason: 'time left');
    await _tap(tester, find.text('Pause'));
    expect(find.text('Paused'), findsOneWidget);
    final logged = (await _sessions(tester, db)).single;
    expect(logged.type, SessionType.meditation);
    expect(logged.libraryItemId, isNull);
    expect(logged.durationSec, inInclusiveRange(120, 125));
  });

  testWidgets('with the screen off it keeps time and is logged', (
    tester,
  ) async {
    final audio = FakeAudio();
    final db = await pumpApp(tester, audio: audio, seed: _seed());
    await _openMeditation(tester);
    await _tap(tester, find.text('Start'));
    await _tap(tester, find.text('Screen off — keep meditating'));
    expect(find.text('Meditation · 10 min left'), findsOneWidget);
    expect(
      find.text('Rest your eyes. The bell will ring at the end.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(minutes: 3));
    expect(audio.current.playing, isTrue, reason: 'the track plays on');
    await _tap(tester, find.bySemanticsLabel(RegExp('^Wake screen')));
    await _tap(tester, find.text('Finish'));
    final logged = (await _sessions(tester, db)).single;
    expect(
      (logged.type, logged.durationSec >= 180),
      (SessionType.meditation, true),
    );
  });

  testWidgets('her own audio plays as meditation and is logged so', (
    tester,
  ) async {
    final audio = FakeAudio();
    final db = await pumpApp(
      tester,
      audio: audio,
      library: _library,
      seed: _seed(audio: true),
    );
    await _openMeditation(tester);
    await _tap(tester, find.text('Or use your own audio'));
    await _settleIo(tester);
    final item = (await tester.runAsync(
      () => db.select(db.libraryItems).getSingle(),
    ))!;
    expect(audio.opened, [meditationAudioId(item.id)]);
    expect(find.text('Meditation'), findsOneWidget, reason: 'Listen header');
    await tester.pump(const Duration(minutes: 2));
    await _tap(tester, find.byTooltip('Pause'));
    final logged = (await _sessions(tester, db)).single;
    expect(
      (logged.type, logged.libraryItemId),
      (SessionType.meditation, item.id),
    );
  });

  testWidgets('no audio yet: the row says how to add some', (tester) async {
    await pumpApp(tester, seed: _seed());
    await _openMeditation(tester);
    expect(find.text('Add audio in Sessions first'), findsOneWidget);
  });
}
