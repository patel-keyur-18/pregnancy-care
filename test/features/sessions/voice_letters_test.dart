import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

/// Lets real file reads and writes (outside fake time) finish.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<void> _openLetters(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavmaasTabBar),
      matching: find.text('Sessions'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Talk to baby'));
  await tester.pumpAndSettle();
}

void main() {
  late Directory voiceDir;
  late Directory voiceTemp;
  setUp(() {
    voiceDir = Directory.systemTemp.createTempSync('navmaas_voice');
    voiceTemp = Directory.systemTemp.createTempSync('navmaas_vtemp');
  });
  tearDown(() {
    for (final d in [voiceDir, voiceTemp]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  List<File> files(Directory d) => d.existsSync()
      ? d.listSync(recursive: true).whereType<File>().toList()
      : const [];

  testWidgets('Speak: record, stop, play and save an encrypted voice note', (
    tester,
  ) async {
    final recorder = FakeRecorder();
    final player = FakeVoicePlayer();
    final screenOn = <bool>[];
    final db = await pumpApp(
      tester,
      seed: _seed,
      recorder: recorder,
      voicePlayer: player,
      screenOn: screenOn,
      voiceDir: voiceDir,
      voiceTemp: voiceTemp,
    );
    await _openLetters(tester);
    await tester.tap(find.text('Speak'));
    await tester.pumpAndSettle();
    expect(find.text('Voice note'), findsOneWidget);

    await tester.tap(find.text('Record'));
    await _settleIo(tester);
    expect(find.text('RECORDING'), findsOneWidget);
    expect(screenOn, [true], reason: 'the screen stays on');
    expect(recorder.started.single, startsWith(voiceTemp.path));
    await tester.pump(const Duration(seconds: 42));
    expect(find.text('0:42'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await _settleIo(tester);
    expect(screenOn, [true, false]);
    expect(find.text('0:00 / 0:42'), findsOneWidget);
    // Sealed: no plain copy anywhere, and the file isn't the plain bytes.
    expect(files(voiceTemp), isEmpty);
    final sealed = files(voiceDir).single;
    expect(
      utf8.decode(sealed.readAsBytesSync(), allowMalformed: true),
      isNot(contains('plain voice bytes')),
    );

    // Play: a plain copy for the player only, while the screen is open.
    await tester.tap(find.byTooltip('Play voice note'));
    await _settleIo(tester);
    expect(utf8.decode(player.openedBytes.single), 'plain voice bytes');
    expect(player.opened.single, startsWith(voiceTemp.path));
    expect(find.byTooltip('Pause voice note'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(find.text('Voice note · 0:42'), findsOneWidget);
    final letter = (await tester.runAsync(
      () => db.select(db.letters).getSingle(),
    ))!;
    expect((letter.body, letter.voiceSec), ('', 42));
    expect(letter.voiceFile, sealed.uri.pathSegments.last);
    expect(files(voiceTemp), isEmpty, reason: 'cleared when the screen closed');
  });

  testWidgets('mic off: a calm line, nothing recorded', (tester) async {
    await pumpApp(
      tester,
      seed: _seed,
      recorder: FakeRecorder()..permission = false,
      voiceDir: voiceDir,
      voiceTemp: voiceTemp,
    );
    await _openLetters(tester);
    await tester.tap(find.text('Speak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record'));
    await _settleIo(tester);
    expect(
      find.text(
        "Turn on the microphone for Navmaas in your phone's Settings to "
        'record.',
      ),
      findsOneWidget,
    );
    expect(find.text('RECORDING'), findsNothing);
  });

  testWidgets('stops by itself at 10:00, and when Navmaas leaves the screen', (
    tester,
  ) async {
    final screenOn = <bool>[];
    await pumpApp(
      tester,
      seed: _seed,
      screenOn: screenOn,
      voiceDir: voiceDir,
      voiceTemp: voiceTemp,
    );
    await _openLetters(tester);
    await tester.tap(find.text('Speak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record'));
    await _settleIo(tester);
    await tester.pump(const Duration(minutes: 10));
    await _settleIo(tester);
    expect(find.text('RECORDING'), findsNothing);
    expect(find.text('0:00 / 10:00'), findsOneWidget);

    // Record again, then leave Navmaas: stopped and kept, the new note
    // replacing the first.
    await tester.tap(find.text('Record again'));
    await _settleIo(tester);
    await tester.pump(const Duration(seconds: 5));
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await _settleIo(tester);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    expect(find.text('0:00 / 0:05'), findsOneWidget);
    expect(files(voiceDir), hasLength(1), reason: 'the first note is gone');
    expect(screenOn, [true, false, true, false]);
  });

  testWidgets('remove the voice note, then the letter: files go too', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: _seed,
      voiceDir: voiceDir,
      voiceTemp: voiceTemp,
    );
    await _openLetters(tester);
    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hello, little one.');
    await tester.ensureVisible(find.text('Record'));
    await tester.tap(find.text('Record'));
    await _settleIo(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Stop'));
    await _settleIo(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.pumpAndSettle();
    expect(files(voiceDir), hasLength(1));

    // Remove the voice note: the words stay, the file goes on Save.
    await tester.tap(find.text('Hello, little one.'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.ensureVisible(find.bySemanticsLabel('Remove voice note'));
    await tester.tap(find.bySemanticsLabel('Remove voice note'));
    await tester.pumpAndSettle();
    expect(find.text('Record'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(files(voiceDir), isEmpty);
    var letter = (await tester.runAsync(
      () => db.select(db.letters).getSingle(),
    ))!;
    expect((letter.body, letter.voiceFile), ('Hello, little one.', null));

    // Record once more, save, then remove the whole letter.
    await tester.tap(find.text('Hello, little one.'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.ensureVisible(find.text('Record'));
    await tester.tap(find.text('Record'));
    await _settleIo(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await _settleIo(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hello, little one.'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    await tester.ensureVisible(find.text('Remove letter'));
    await tester.tap(find.text('Remove letter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove letter').last);
    await tester.pumpAndSettle();
    await _settleIo(tester);
    expect(files(voiceDir), isEmpty);
    letter = (await tester.runAsync(() => db.select(db.letters).getSingle()))!;
    expect(letter.deletedAt, isNotNull);
  });

  testWidgets('a voice note not on this phone says so', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await _seed(db);
        final id = (await db.select(db.pregnancies).getSingle()).id;
        await db
            .into(db.letters)
            .insert(
              LettersCompanion.insert(
                pregnancyId: id,
                body: 'From the old phone.',
                voiceFile: const Value('gone.bin'),
                voiceSec: const Value(30),
              ),
            );
      },
      voiceDir: voiceDir,
      voiceTemp: voiceTemp,
    );
    await _openLetters(tester);
    expect(find.text('Voice note · 0:30'), findsOneWidget);
    await tester.tap(find.text('From the old phone.'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play voice note'));
    await _settleIo(tester);
    expect(find.text("This voice note isn't on this phone."), findsOneWidget);
  });
}
