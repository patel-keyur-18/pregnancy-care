import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';

import 'helpers.dart';

/// Small phone, so 2.0× text has the least room.
const _small = Size(360, 640);

Future<void> _seed(AppDatabase db) async {
  await SettingsRepository(db).put(SettingKeys.firstName, 'Meera');
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Each screen M1 builds, reached the way a user would.
final _screens = <String, (bool, Future<void> Function(WidgetTester))>{
  'onboarding 1': (false, (_) async {}),
  'onboarding 2': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
    },
  ),
  'onboarding 3': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
    },
  ),
  'today': (true, (_) async {}),
  'journey': (true, (t) => _tab(t, 'Journey')),
  'sessions': (true, (t) => _tab(t, 'Sessions')),
  'care': (true, (t) => _tab(t, 'Care')),
  'me': (true, (t) => _tab(t, 'Me')),
  'edit dates': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
    },
  ),
};

void main() {
  for (final MapEntry(key: name, value: (seeded, open)) in _screens.entries) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('$name at ${scale}x: no overflow, 48 dp labelled targets', (
        tester,
      ) async {
        await pumpApp(
          tester,
          seed: seeded ? _seed : null,
          textScale: scale,
          size: _small,
        );
        await open(tester);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    }
    for (final brightness in Brightness.values) {
      testWidgets('$name text contrast (${brightness.name})', (tester) async {
        await pumpApp(
          tester,
          seed: seeded ? _seed : null,
          platformBrightness: brightness,
        );
        await open(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }
  }

  testWidgets('reduce motion: onboarding steps change without animating', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await pumpApp(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Welcome to Navmaas'), findsNothing);
    expect(find.text('When did this journey begin?'), findsOneWidget);
  });
}
