import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/delete_all_data.dart';
import 'package:navmaas/core/platform/app_usage.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/platform/authenticator.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/platform/health.dart';
import 'package:navmaas/core/platform/home_widget.dart';
import 'package:navmaas/core/platform/voice.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/media_link_repository.dart';
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

  @override
  Future<NotificationResponse?> launchResponse() async => null;

  @override
  Future<void> cancelAll() async => scheduled = const [];
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
  Future<Duration?> openMeditation({
    required int minutes,
    required String title,
  }) async {
    final id = meditationTimerId(minutes);
    opened.add(id);
    final length = Duration(minutes: minutes, seconds: 4);
    _set((
      itemId: id,
      playing: false,
      completed: false,
      position: Duration.zero,
      duration: length,
    ));
    return length;
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

/// Records nothing: [stop] writes [bytes] where the recording would be.
class FakeRecorder implements VoiceRecorder {
  bool permission = true;
  List<int> bytes = utf8.encode('plain voice bytes');
  final started = <String>[];
  String? _path;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> start(String path) async {
    started.add(path);
    _path = path;
  }

  @override
  Future<String?> stop() async {
    final path = _path;
    _path = null;
    if (path != null) File(path).writeAsBytesSync(bytes);
    return path;
  }

  @override
  Future<void> dispose() async {}
}

/// Plays nothing: records what was opened and reports play / pause.
class FakeVoicePlayer implements VoicePlayer {
  final opened = <String>[];

  /// What each opened file held (it is deleted when the screen closes).
  final openedBytes = <List<int>>[];
  final _changes = StreamController<VoicePlayback>.broadcast();
  VoicePlayback _now = (
    playing: false,
    completed: false,
    position: Duration.zero,
    duration: null,
  );

  void _set(VoicePlayback now) => _changes.add(_now = now);

  @override
  Stream<VoicePlayback> get changes => _changes.stream;

  @override
  Future<Duration?> open(String path) async {
    opened.add(path);
    openedBytes.add(File(path).readAsBytesSync());
    return null;
  }

  @override
  Future<void> play() async => _set((
    playing: true,
    completed: false,
    position: _now.position,
    duration: _now.duration,
  ));

  @override
  Future<void> pause() async => _set((
    playing: false,
    completed: false,
    position: _now.position,
    duration: _now.duration,
  ));

  @override
  Future<void> seek(Duration position) async => _set((
    playing: _now.playing,
    completed: false,
    position: position,
    duration: _now.duration,
  ));

  @override
  Future<void> dispose() async {}
}

/// Backups without files or crypto: records what the screens ask for.
/// [password] opens its one backup; anything else is "wrong password".
class FakeBackupService implements BackupService {
  String password = 'correct horse';
  final created =
      <({String password, bool includeLibrary, bool includeVoice})>[];
  final shared = <File>[];
  int restores = 0;

  static final _header = BackupHeader(
    createdAt: DateTime(2026, 10, 3, 21, 12),
    appVersion: '1.0.0',
    schemaVersion: 6,
    includesLibrary: false,
  );

  @override
  Future<BackupResult> create({
    required String password,
    required bool includeLibrary,
    bool includeVoice = false,
  }) async {
    created.add((
      password: password,
      includeLibrary: includeLibrary,
      includeVoice: includeVoice,
    ));
    return (
      file: File('navmaas-backup-2026-10-05.navmaas'),
      sizeBytes: 2516582,
      entries: 1284,
      photos: 6,
    );
  }

  @override
  Future<({int base, int library, int voice})> sizes() async =>
      (base: 2516582, library: 191260672, voice: 6291456);

  @override
  Future<({File file, int size})> receive(Stream<List<int>> bytes) async {
    await bytes.drain<void>();
    return (file: File('picked.navmaas'), size: 2516582);
  }

  @override
  Future<BackupHeader> inspect(File file) async => _header;

  @override
  Future<RestoreResult> restore(File file, String password) async {
    if (password != this.password) {
      throw const BackupException(BackupError.wrongPassword);
    }
    restores++;
    return (madeAt: _header.createdAt, entries: 1284, photos: 6);
  }
}

/// Fixed "today" for widget tests: Monday, 5 October 2026.
/// Face ID / fingerprint stand-in: [screenLock] says whether the phone has
/// one; [succeed] whether she unlocks (until set, every attempt fails, as
/// if she cancelled). Counts the attempts.
class FakeAuthenticator implements Authenticator {
  bool screenLock = true;
  bool succeed = false;
  int attempts = 0;

  @override
  Future<bool> canLock() async => screenLock;

  @override
  Future<bool> unlock(String reason) async {
    attempts++;
    return succeed;
  }
}

/// Android's Usage access stand-in: [supported] is the phone being
/// Android, [access] whether she allowed it; [minutes] is today's use per
/// package; [rules] the last rules handed to the check.
class FakeAppUsage implements AppUsage {
  new({this.supported = true, this.access = false});

  @override
  final bool supported;
  bool access;
  int settingsOpened = 0;
  final minutes = <String, int>{};
  String? rules;
  int limits = 0;
  List<InstalledApp> installed = const [
    (package: 'com.google.android.youtube', label: 'YouTube', icon: null),
    (package: 'com.instagram.android', label: 'Instagram', icon: null),
    (package: 'com.netflix.mediaclient', label: 'Netflix', icon: null),
  ];

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<List<InstalledApp>> apps() async => installed;

  @override
  Future<Map<String, int>> minutesToday(List<String> packages) async => {
    for (final p in packages) p: minutes[p] ?? 0,
  };

  @override
  Future<void> setRules(String rules, {required int limits}) async {
    this.rules = rules;
    this.limits = limits;
  }
}

/// Records the home-screen widget's snapshots (no platform plugin).
class FakeWidgetPublisher implements WidgetPublisher {
  final snapshots = <String>[];
  List<DateTime> updateTimes = const [];

  @override
  Future<void> publish(String snapshot, List<DateTime> updateTimes) async {
    snapshots.add(snapshot);
    this.updateTimes = updateTimes;
  }
}

final testToday = DateTime.utc(2026, 10, 5);

/// Pumps the whole app on a fresh in-memory database, like a first install.
/// [seed] runs against the database before the first frame.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  FakeScheduler? scheduler,
  FakeAudio? audio,
  FakeSteps? steps,
  FakeWidgetPublisher? widget,
  FakeAuthenticator? authenticator,
  FakeAppUsage? appUsage,
  Directory? library,
  PickFile? pickFile,
  OpenLink? openLink,
  FakeRecorder? recorder,
  FakeVoicePlayer? voicePlayer,
  List<bool>? screenOn,
  Directory? voiceDir,
  Directory? voiceTemp,
  DateTime? buildExpiry,
  FakeBackupService? backup,
  ShareFile? share,
  DeleteAllData? deleteAll,
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
        widgetPublisherProvider.overrideWithValue(
          widget ?? FakeWidgetPublisher(),
        ),
        authenticatorProvider.overrideWithValue(
          authenticator ?? FakeAuthenticator(),
        ),
        // iPhone by default: no app limits (the card is hidden).
        appUsageProvider.overrideWithValue(
          appUsage ?? FakeAppUsage(supported: false),
        ),
        libraryRepositoryProvider.overrideWith(
          (ref) => LibraryRepository(
            ref.watch(appDatabaseProvider),
            directory: () async =>
                library ?? Directory.systemTemp.createTempSync('navmaas_lib'),
          ),
        ),
        pickFileProvider.overrideWithValue(pickFile ?? (_) async => null),
        openLinkProvider.overrideWithValue(openLink ?? (_) async => true),
        newVoiceRecorderProvider.overrideWithValue(
          () => recorder ?? FakeRecorder(),
        ),
        newVoicePlayerProvider.overrideWithValue(
          () => voicePlayer ?? FakeVoicePlayer(),
        ),
        keepScreenOnProvider.overrideWithValue(
          ({required on}) async => screenOn?.add(on),
        ),
        voiceStoreProvider.overrideWith(
          (_) async => AttachmentStore(
            directory:
                voiceDir ?? Directory.systemTemp.createTempSync('navmaas_vo'),
            key: () async => List.filled(32, 7),
          ),
        ),
        voiceTempDirProvider.overrideWith(
          (_) async =>
              voiceTemp ?? Directory.systemTemp.createTempSync('navmaas_vt'),
        ),
        buildExpiryProvider.overrideWith((_) async => buildExpiry),
        backupServiceProvider.overrideWith(
          (_) async => backup ?? FakeBackupService(),
        ),
        shareFileProvider.overrideWithValue(share ?? (_) async {}),
        // The real one deletes folders and keys; this empties the database.
        deleteAllDataProvider.overrideWith(
          (ref) =>
              deleteAll ??
              () async {
                await ref.read(reminderSchedulerProvider).cancelAll();
                await db.customStatement('PRAGMA foreign_keys = OFF');
                for (final table in db.allTables) {
                  await db.delete(table).go();
                }
                await db.customStatement('PRAGMA foreign_keys = ON');
              },
        ),
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
