import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';

import '../../helpers.dart';

const _youtube = 'com.google.android.youtube';

/// Week 24, reminders on; [limit] sets YouTube to 30 minutes.
Future<void> Function(AppDatabase) _seed({bool limit = false}) => (db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
  if (limit) {
    await AppLimitsRepository(db)
        .save(package: _youtube, label: 'YouTube', minutes: 30);
  }
};

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _openScreenRest(WidgetTester tester) =>
    _tap(tester, find.text('Screen-free from 9:30 pm'));

/// She comes back to Navmaas (from Settings).
Future<void> _resume(WidgetTester tester) async {
  [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('iPhone: Screen Rest has no app limits', (tester) async {
    await pumpApp(tester, seed: _seed());
    await _openScreenRest(tester);
    expect(find.text('Wind-down audio'), findsOneWidget);
    expect(find.text('Limits for other apps'), findsNothing);
  });

  testWidgets('set up: Usage access, choose an app, its minutes; remove', (
    tester,
  ) async {
    final usage = FakeAppUsage();
    await pumpApp(tester, appUsage: usage, seed: _seed());
    await _openScreenRest(tester);
    await _tap(tester, find.text('Set up limits'));
    expect(find.text('See your time in other apps'), findsOneWidget);
    await tester.tap(find.text('Open Usage access settings'));
    await tester.pumpAndSettle();
    expect(usage.settingsOpened, 1);

    usage.access = true;
    await _resume(tester);
    expect(find.text('Add an app'), findsOneWidget);
    await tester.tap(find.text('Add an app'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an app'), findsOneWidget);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('Daily limit for YouTube'), findsOneWidget);
    expect(find.text('Remove this limit'), findsNothing, reason: 'new');
    await tester.tap(find.text('45 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('0 of 45 min today'), findsOneWidget);
    expect(
      find.text('45 min on YouTube today. Phone down, baby time.'),
      findsOneWidget,
      reason: 'the notice preview',
    );
    expect(usage.limits, 1, reason: 'the check runs while a limit is set');
    final rules = jsonDecode(usage.rules!) as Map<String, dynamic>;
    expect((rules['limits'] as List).single, containsPair('minutes', 45));
    expect(rules['days'], hasLength(7));

    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove this limit'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 45 min today'), findsNothing);
    expect(usage.limits, 0, reason: 'no limits, no check');
  });

  testWidgets("today's minutes on Screen Rest; past the limit, said calmly", (
    tester,
  ) async {
    final usage = FakeAppUsage(access: true)..minutes[_youtube] = 32;
    await pumpApp(tester, appUsage: usage, seed: _seed(limit: true));
    await _openScreenRest(tester);
    await tester.scrollUntilVisible(
      find.text('Manage limits'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('32 min today · past your 30 min'), findsOneWidget);
  });

  testWidgets('Usage access turned off: limits are paused, not lost', (
    tester,
  ) async {
    final usage = FakeAppUsage();
    await pumpApp(tester, appUsage: usage, seed: _seed(limit: true));
    await _openScreenRest(tester);
    await tester.scrollUntilVisible(
      find.text('Manage limits'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Paused: Usage access is off'), findsOneWidget);
    await _tap(tester, find.text('Manage limits'));
    expect(find.text('Your limits are paused'), findsOneWidget);
    expect(find.text('Turn on Usage access'), findsOneWidget);
    expect(usage.limits, 1, reason: 'the check still has the limit');
  });
}
