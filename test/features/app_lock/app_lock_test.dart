import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/app_lock/lock_screen.dart';

import '../../helpers.dart';

/// Week 24, with app lock already on when [locked].
Future<void> Function(AppDatabase) _seed({bool locked = false}) => (db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  if (locked) await SettingsRepository(db).put(SettingKeys.appLock, 'true');
};

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Taps the switch in the row titled [title] (Me → Your data).
Future<void> _switch(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  final row = find.ancestor(of: find.text(title), matching: find.byType(Row));
  final toggle = find.descendant(of: row.first, matching: find.byType(Switch));
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

/// Navmaas goes to the background for [away], then comes back.
Future<void> _leave(WidgetTester tester, Duration away) async {
  // Step by step, as the engine reports it.
  const out = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  out.forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pump(away);
  [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pumpAndSettle();
}

final Finder _locked = find.text('Navmaas is locked');

void main() {
  testWidgets('a fresh open is locked; a failed try stays locked', (
    tester,
  ) async {
    final auth = FakeAuthenticator();
    await pumpApp(tester, authenticator: auth, seed: _seed(locked: true));
    expect(_locked, findsOneWidget);
    expect(auth.attempts, 1, reason: 'it asks as soon as it shows');
    expect(find.byType(NavmaasTabBar), findsNothing, reason: 'nothing shows');

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect((auth.attempts, _locked.evaluate().length), (2, 1));

    auth.succeed = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(_locked, findsNothing);
    expect(find.text('Good morning'), findsOneWidget, reason: 'Today');
  });

  testWidgets('turned on in Me: locks after a minute away and hides the '
      "widget's details", (tester) async {
    final auth = FakeAuthenticator();
    final widget = FakeWidgetPublisher();
    await pumpApp(tester, authenticator: auth, widget: widget, seed: _seed());
    expect(jsonDecode(widget.snapshots.last), containsPair('hidden', false));
    await _tab(tester, 'Me');
    expect(find.text('Lock after leaving Navmaas for'), findsNothing);
    await _switch(tester, 'App lock');
    expect(find.text('Lock after leaving Navmaas for'), findsOneWidget);
    expect(
      jsonDecode(widget.snapshots.last),
      containsPair('hidden', true),
      reason: 'with app lock on, details hide unless she shows them',
    );
    expect(_locked, findsNothing, reason: 'turning it on keeps her in');

    await _leave(tester, const Duration(seconds: 40));
    expect(_locked, findsNothing, reason: 'under a minute away');

    await _leave(tester, const Duration(minutes: 2));
    expect(_locked, findsOneWidget);
    auth.succeed = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Lock after leaving Navmaas for'), findsOneWidget);

    // 5 minutes: two minutes away no longer locks.
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    auth.succeed = false;
    await _leave(tester, const Duration(minutes: 2));
    expect(_locked, findsNothing);
    await _leave(tester, const Duration(minutes: 6));
    expect(_locked, findsOneWidget);
  });

  testWidgets('a notification or widget tap opens its screen behind the lock', (
    tester,
  ) async {
    final auth = FakeAuthenticator();
    await pumpApp(tester, authenticator: auth, seed: _seed(locked: true));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavmaasApp)),
    );
    // What openReminder and the widget's deep link do.
    container.read(routerProvider).go('/sessions');
    await tester.pumpAndSettle();
    expect(_locked, findsOneWidget);
    expect(find.text('Garbhasanskar path'), findsNothing);

    auth.succeed = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Garbhasanskar path'), findsOneWidget);
  });

  testWidgets('the app switcher sees a plain cover while app lock is on', (
    tester,
  ) async {
    final auth = FakeAuthenticator()..succeed = true;
    await pumpApp(tester, authenticator: auth, seed: _seed(locked: true));
    expect(find.byType(PrivacyCover), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byType(PrivacyCover), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(PrivacyCover), findsNothing);
  });

  testWidgets('without a screen lock on the phone it stays off', (
    tester,
  ) async {
    final auth = FakeAuthenticator()..screenLock = false;
    await pumpApp(tester, authenticator: auth, seed: _seed());
    await _tab(tester, 'Me');
    await _switch(tester, 'App lock');
    expect(
      find.text(
        'Set a screen lock on your phone first, then turn on app lock.',
      ),
      findsOneWidget,
    );
    expect(find.text('Lock after leaving Navmaas for'), findsNothing);
  });
}
