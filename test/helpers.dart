import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/platform/health.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Records what the app asks the OS to schedule (no platform plugin).
class FakeScheduler implements ReminderScheduler {
  bool permission = false;
  bool granted = true;
  List<PlannedReminder> scheduled = const [];
  final snoozed = <ReminderPayload>[];

  @override
  Future<void> init({
    void Function(NotificationResponse)? onAction,
    void Function(NotificationResponse)? onBackgroundAction,
  }) async {}

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async => permission = granted;

  @override
  Future<void> sync(
    List<PlannedReminder> planned,
    AppLocalizations l10n,
  ) async => scheduled = planned;

  @override
  Future<void> snooze(ReminderPayload payload, AppLocalizations l10n) async =>
      snoozed.add(payload);

  @override
  Future<void> refreshTimeZone() async {}
}

/// Plays nothing; records what the app asks for.
class FakeAudio implements AudioPlayback {
  final _changes = StreamController<Playback>.broadcast();
  Playback _current = idlePlayback;
  final opened = <String>[];

  @override
  Playback get current => _current;

  @override
  Stream<Playback> get changes => _changes.stream;

  void _set(Playback p) => _changes.add(_current = p);

  @override
  Future<Duration?> open({
    required String itemId,
    required String title,
    required String path,
  }) async {
    opened.add(itemId);
    _set((
      itemId: itemId,
      playing: false,
      completed: false,
      position: Duration.zero,
      duration: const Duration(minutes: 10),
    ));
    return const Duration(minutes: 10);
  }

  @override
  Future<void> play() async => _set((
    itemId: _current.itemId,
    playing: true,
    completed: false,
    position: _current.position,
    duration: _current.duration,
  ));

  @override
  Future<void> pause() async => _set((
    itemId: _current.itemId,
    playing: false,
    completed: false,
    position: _current.position,
    duration: _current.duration,
  ));

  @override
  Future<void> seek(Duration position) async => _set((
    itemId: _current.itemId,
    playing: _current.playing,
    completed: false,
    position: position,
    duration: _current.duration,
  ));
}

/// Steps without Apple Health / Health Connect: [walk] for any interval
/// that starts today after midnight, [today] for the whole day.
class FakeSteps implements StepSource {
  bool access = true;
  int walk = 1420;
  int today = 4820;
  int asked = 0;

  @override
  Future<bool> requestAccess() async {
    asked++;
    return access;
  }

  @override
  Future<int?> steps(DateTime from, DateTime to) async {
    if (!access) return null;
    final midnight = from.hour == 0 && from.minute == 0 && from.second == 0;
    return midnight ? today : walk;
  }
}

/// Fixed "today" for widget tests: Monday, 5 October 2026.
final testToday = DateTime.utc(2026, 10, 5);

/// Pumps the whole app on a fresh in-memory database, like a first install.
/// [seed] runs against the database before the first frame.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  FakeScheduler? scheduler,
  FakeAudio? audio,
  FakeSteps? steps,
  Directory? library,
  PickFile? pickFile,
  DateTime? buildExpiry,
  Future<void> Function(AppDatabase db)? seed,
  Brightness platformBrightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // The app's wall clock starts at 9:00 on the test's day and moves with
  // real and fake time, so rows it stamps fall on the day the screens show
  // and still come in order.
  final fakeStart = tester.binding.clock.now();
  final real = Stopwatch()..start();
  final pinned = DateTime(testToday.year, testToday.month, testToday.day, 9);
  clockNow = () => pinned.add(
    real.elapsed + tester.binding.clock.now().difference(fakeStart),
  );
  addTearDown(() => clockNow = DateTime.now);
  // Synchronous stream closing: no drift timer outlives the widget tree.
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (seed != null) await tester.runAsync(() => seed(db));
  tester.platformDispatcher
    ..platformBrightnessTestValue = platformBrightness
    ..textScaleFactorTestValue = textScale;
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.platformDispatcher.clearAllTestValues();
    tester.view.reset();
    // The in-memory database is not closed: after a failed test a query from
    // the abandoned fake-async zone can hold drift's lock, and close() would
    // wait forever. It is garbage-collected with the test.
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        todayProvider.overrideWithValue(testToday),
        // 9:00 am, so the greeting is always "Good morning".
        nowProvider.overrideWithValue(DateTime(2026, 10, 5, 9)),
        reminderSchedulerProvider.overrideWithValue(
          scheduler ?? FakeScheduler(),
        ),
        audioPlaybackProvider.overrideWith((_) async => audio ?? FakeAudio()),
        stepSourceProvider.overrideWithValue(steps ?? FakeSteps()),
        libraryRepositoryProvider.overrideWith(
          (ref) => LibraryRepository(
            ref.watch(appDatabaseProvider),
            directory: () async =>
                library ?? Directory.systemTemp.createTempSync('navmaas_lib'),
          ),
        ),
        pickFileProvider.overrideWithValue(pickFile ?? (_) async => null),
        buildExpiryProvider.overrideWith((_) async => buildExpiry),
      ],
      child: const NavmaasApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Opens the date field and types [mmddyyyy] in the picker's input mode.
Future<void> pickDate(WidgetTester tester, String mmddyyyy) async {
  final field = find.byKey(const ValueKey('date-field'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    ),
    mmddyyyy,
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
