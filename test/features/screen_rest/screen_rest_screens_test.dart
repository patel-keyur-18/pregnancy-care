import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';

import '../../helpers.dart';

/// A pregnancy plus [files] (name → text) already in the library.
Future<void> Function(AppDatabase) _seed(
  Directory library, [
  Map<String, String> files = const {},
]) => (db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final repo = LibraryRepository(db, directory: () async => library);
  for (final MapEntry(key: name, value: text) in files.entries) {
    await repo.import(name, Stream.value(utf8.encode(text)));
  }
};

Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _openScreenRest(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Screen-free from 9:30 pm'), 200);
  await tester.tap(find.text('Screen-free from 9:30 pm'));
  await tester.pumpAndSettle();
}

Future<void> _switch(WidgetTester tester, int index) async {
  await tester.ensureVisible(find.byType(Switch).at(index));
  await tester.tap(find.byType(Switch).at(index));
  await tester.pumpAndSettle();
}

Future<String?> _setting(WidgetTester tester, AppDatabase db, String key) =>
    tester
        .runAsync(() => SettingsRepository(db).watch(key).first)
        .then((v) => v);

/// Taps a reminder that opens [open].
Future<void> _tapReminder(WidgetTester tester, String open) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(NavmaasApp)),
  );
  await tester.runAsync(
    () => openReminder(
      container,
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: ReminderPayload(
          keys: const ['k'],
          title: 't',
          body: 'b',
          open: open,
        ).toJson(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Directory library;
  setUp(() => library = Directory.systemTemp.createTempSync('navmaas_rest'));
  tearDown(() => library.deleteSync(recursive: true));

  testWidgets('Today opens Screen Rest; rules change what rests next', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(
      tester,
      scheduler: scheduler,
      library: library,
      seed: (db) async {
        await _seed(library)(db);
        await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
      },
    );
    expect(find.text('Phone down, baby time.'), findsOneWidget);
    await _openScreenRest(tester);
    expect(find.text('Screen Rest'), findsOneWidget);
    expect(
      find.text(
        'Next screen-free window starts at 1:00 pm. Navmaas will stay quiet '
        'until 1:45 pm.',
      ),
      findsOneWidget,
    );
    expect(find.text('9:30 pm – 7:00 am · no reminders'), findsOneWidget);
    expect(
      find.text('1:00 pm – 1:45 pm and 8:00 pm – 8:45 pm'),
      findsOneWidget,
    );
    expect(find.text('9:00 pm · screen dims, audio only'), findsOneWidget);
    // Meal notices are planned; no wind-down while it's off.
    List<String> nudges() => [
      for (final p in scheduler.scheduled)
        for (final i in p.items)
          if (i.kind == ReminderKind.nudge) i.title,
    ];
    expect(nudges(), contains('Meal time'));
    expect(nudges(), isNot(contains('Time to wind down')));

    // Meal times off: bedtime is next.
    await _switch(tester, 1);
    expect(await _setting(tester, db, SettingKeys.mealRest), 'false');
    expect(
      find.text(
        'Next screen-free window starts at 9:30 pm. Navmaas will stay quiet '
        'until 7:00 am.',
      ),
      findsOneWidget,
    );
    expect(nudges(), isNot(contains('Meal time')));

    // Wind-down on: planned, and on Today.
    await _switch(tester, 3);
    expect(nudges(), contains('Time to wind down'));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.text('Wind-down audio at 9:00 pm — phone down, baby time.'),
      findsOneWidget,
    );

    // Bedtime rest off: no quiet hours, nothing rests.
    await _openScreenRest(tester);
    await _switch(tester, 0);
    expect(
      find.text('Switch on a rest rule below for calm, screen-free times.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Screen Rest'), findsOneWidget);
  });

  testWidgets('a rule row changes its times', (tester) async {
    await pumpApp(tester, library: library, seed: _seed(library));
    await _openScreenRest(tester);
    await tester.tap(find.text('Wind-down audio'));
    await tester.pumpAndSettle();
    expect(find.text('Wind-down at'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meal times'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch starts'), findsOneWidget);
  });

  testWidgets('time in Navmaas counts while on screen and is saved', (
    tester,
  ) async {
    final db = await pumpApp(tester, library: library, seed: _seed(library));
    await tester.pump(const Duration(minutes: 14));
    await _openScreenRest(tester);
    expect(find.text('In Navmaas today · 14 min'), findsOneWidget);

    [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await _settleIo(tester);
    expect(await _setting(tester, db, SettingKeys.useDay), '2026-10-05');
    final seconds = int.parse(
      (await _setting(tester, db, SettingKeys.useSeconds))!,
    );
    expect(seconds ~/ 60, 14);
    // Time away doesn't count.
    await tester.pump(const Duration(minutes: 30));
    [
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await _openScreenRest(tester);
    expect(find.text('In Navmaas today · 14 min'), findsOneWidget);
  });

  testWidgets('wind-down opens her last audio with the screen off', (
    tester,
  ) async {
    final audio = FakeAudio();
    await pumpApp(
      tester,
      audio: audio,
      library: library,
      seed: _seed(library, {'om_chanting.mp3': 'not really audio'}),
    );
    await _tapReminder(tester, ReminderOpen.windDown);
    await _settleIo(tester);
    expect(audio.opened, hasLength(1));
    expect(find.text('om chanting is playing'), findsOneWidget);
  });

  testWidgets('wind-down without audio opens Sessions; the digest, Today', (
    tester,
  ) async {
    await pumpApp(tester, library: library, seed: _seed(library));
    await _tapReminder(tester, ReminderOpen.windDown);
    final tabs = tester.widget<NavmaasTabBar>(find.byType(NavmaasTabBar));
    expect(tabs.currentIndex, 2);
    await _tapReminder(tester, ReminderOpen.today);
    expect(
      tester.widget<NavmaasTabBar>(find.byType(NavmaasTabBar)).currentIndex,
      0,
    );
  });

  testWidgets('reading: a 20-second eye rest every 20 minutes', (tester) async {
    final db = await pumpApp(
      tester,
      library: library,
      seed: _seed(library, {'evening_stories.md': '# Lamp\n\nOnce.'}),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Sessions'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('evening stories'));
    await tester.pumpAndSettle();
    await _settleIo(tester);
    const banner = 'Rest your eyes: look far away for 20 seconds.';
    await tester.pump(const Duration(minutes: 19, seconds: 59));
    expect(find.text(banner), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(banner), findsOneWidget);
    expect(find.text('20 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('15 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
    expect(find.text(banner), findsNothing);

    // Closed early, and switched off.
    await tester.pump(const Duration(minutes: 19, seconds: 40));
    expect(find.text(banner), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    expect(find.text(banner), findsNothing);
    await tester.runAsync(
      () => SettingsRepository(db).put(SettingKeys.eyeRest, 'false'),
    );
    await tester.pump(const Duration(minutes: 20));
    expect(find.text(banner), findsNothing);
  });
}
