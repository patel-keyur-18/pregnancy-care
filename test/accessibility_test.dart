import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';

import 'helpers.dart';

/// Small phone, so 2.0× text has the least room.
const _small = Size(360, 640);

/// Library files for the seeded screens (a book and an audio file).
final Directory _library = Directory.systemTemp.createTempSync('navmaas_a11y');

Future<void> _seed(AppDatabase db) async {
  await SettingsRepository(db).put(SettingKeys.firstName, 'Meera');
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));
  final library = LibraryRepository(db, directory: () async => _library);
  await library.import(
    'evening_stories.txt',
    Stream.value(utf8.encode('# The little lamp\n\nIn a quiet village.')),
  );
  await library.import('om_chanting.mp3', Stream.value([0]));
}

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

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavmaasTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [text] into view (screens are long at 2.0×), then taps it.
/// [last]: the text appears more than once; take the last.
Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final finder = last ? find.text(text).last : find.text(text);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Each screen the app has, reached the way a user would.
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
  'onboarding 4': (
    false,
    (t) async {
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await pickDate(t, '04/15/2026');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
    },
  ),
  'today': (true, (_) async {}),
  'journey': (true, (t) => _tab(t, 'Journey')),
  'sessions': (true, (t) => _tab(t, 'Sessions')),
  'care': (true, (t) => _tab(t, 'Care')),
  'me': (true, (t) => _tab(t, 'Me')),
  'supplements': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await t.tap(find.text('See all').first); // Supplements today
      await t.pumpAndSettle();
    },
  ),
  'add supplement': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add');
    },
  ),
  'tests and vaccines': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await t.scrollUntilVisible(
        find.text('Coming up'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('See all').last);
      await t.pumpAndSettle();
    },
  ),
  'add visit': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add a visit');
    },
  ),
  'visit': (
    true,
    (t) async {
      await _tab(t, 'Care');
      await _tapText(t, 'Add a visit');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
    },
  ),
  'reader': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'evening stories');
      await _settleIo(t);
    },
  ),
  'listen': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'om chanting', last: true); // library row
      await _settleIo(t);
    },
  ),
  'listen, screen off': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'om chanting', last: true); // library row
      await _settleIo(t);
      await _tapText(t, 'Screen off — keep listening');
    },
  ),
  'letters': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
    },
  ),
  'write a letter': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Talk to baby');
      await t.tap(find.text('Write a letter'));
      await t.pumpAndSettle();
    },
  ),
  'add to library': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Add');
    },
  ),
  'activity': (
    true,
    (t) async {
      await _tab(t, 'Sessions');
      await _tapText(t, 'Activity');
    },
  ),
  'doctor': (
    true,
    (t) async {
      await _tab(t, 'Me');
      await _tapText(t, "Add your doctor's details");
    },
  ),
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
          library: _library,
          textScale: scale,
          size: _small,
        );
        await open(tester);
        // Lists build lazily: scroll to the end so every section is laid out.
        final lists = find.byType(ListView);
        if (lists.evaluate().isNotEmpty) {
          await tester.drag(lists.first, const Offset(0, -20000));
          await tester.pumpAndSettle();
        }
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
          library: _library,
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
