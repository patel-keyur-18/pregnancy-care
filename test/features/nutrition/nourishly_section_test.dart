import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/features/nutrition/presentation/nourishly_section.dart';

import '../../helpers.dart';

Future<void> _seed(AppDatabase db) =>
    PregnancyRepository(db)
        .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15));

Future<void> _care(WidgetTester tester, FakeNourishly nourishly) async {
  await pumpApp(tester, seed: _seed, nourishly: nourishly);
  await tester.tap(
    find.descendant(
      of: find.byType(NavmaasTabBar),
      matching: find.text('Care'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Nutrition'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text('Nutrition'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, FakeNourishly nourishly) async {
  await _care(tester, nourishly);
  await tester.tap(find.text('Nutrition'));
  await tester.pumpAndSettle();
}

Future<void> _resume(WidgetTester tester) async {
  [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ].forEach(tester.binding.handleAppLifecycleStateChanged);
  await tester.pumpAndSettle();
}

Future<void> _day(WidgetTester tester, String date) async {
  await tester.tap(find.byKey(ValueKey('nourishly-day-$date')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('not shared', (tester) async {
    await _open(tester, FakeNourishly());
    expect(find.text('From Nourishly'), findsOneWidget);
    expect(
      find.text('Turn on Share with Navmaas in Nourishly'),
      findsOneWidget,
    );
    expect(find.text('Foods I avoid'), findsOneWidget);
  });

  testWidgets("today's meals, totals as plain values, when it was updated", (
    tester,
  ) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Poha'), findsOneWidget);
    expect(find.text('1 katori · 150 g'), findsOneWidget);
    expect(find.text('245 kcal'), findsOneWidget);
    expect(find.text('4.6 g'), findsOneWidget);
    // No folate that day: left out, never "0".
    expect(find.text('Folate'), findsNothing);
    expect(find.text('Updated 8:40 am'), findsOneWidget);
  });

  testWidgets('another day, with a partial total; a day with nothing', (
    tester,
  ) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    await _day(tester, '2026-10-04');
    expect(find.text('Dal tadka'), findsOneWidget);
    expect(find.text('2 × 1 piece · 60 g'), findsOneWidget);
    expect(find.text('1,120 kcal'), findsOneWidget);
    expect(find.text('310 mg'), findsOneWidget);
    expect(find.text('Folate: some foods had no data'), findsOneWidget);
    await _day(tester, '2026-10-03');
    expect(find.text('No meals from Nourishly for this day'), findsOneWidget);
  });

  testWidgets('earlier weeks; never past today', (tester) async {
    await _open(tester, FakeNourishly(nourishlyJson()));
    final later = find.ancestor(
      of: find.byTooltip('Later days'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(later).onPressed, isNull);
    await tester.tap(find.byTooltip('Earlier days'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('nourishly-day-2026-09-22')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('nourishly-day-2026-10-05')),
      findsNothing,
    );
    expect(find.text('No meals from Nourishly for this day'), findsOneWidget);
    await tester.tap(later);
    await tester.pumpAndSettle();
    expect(find.text('Poha'), findsOneWidget);
  });

  testWidgets('an older file shows its date', (tester) async {
    await _open(
      tester,
      FakeNourishly(
        nourishlyJson().replaceFirst('2026-10-05T08:40', '2026-10-03T21:05'),
      ),
    );
    expect(find.text('Updated Sat, 3 Oct, 9:05 pm'), findsOneWidget);
  });

  for (final (name, fake) in [
    ('a newer version', () => FakeNourishly(nourishlyJson(version: 2))),
    (
      'a platform error',
      () => FakeNourishly()..error = PlatformException(code: 'io'),
    ),
  ]) {
    testWidgets('unreadable ($name): amber, never red', (tester) async {
      await _open(tester, fake());
      const words =
          "Couldn't read Nourishly's data. "
          'Open Nourishly once, then come back.';
      expect(find.text(words), findsOneWidget);
      final context = tester.element(find.text(words));
      final scheme = Theme.of(context).colorScheme;
      final amber = Theme.of(context).extension<NavmaasColors>()!;
      expect(
        tester.widget<Text>(find.text(words)).style!.color,
        amber.onAmberSoft,
      );
      expect(amber.onAmberSoft, isNot(scheme.error));
    });
  }

  testWidgets('reads again on resume and when Nutrition opens', (tester) async {
    final fake = FakeNourishly();
    await _open(tester, fake);
    expect(
      find.text('Turn on Share with Navmaas in Nourishly'),
      findsOneWidget,
    );
    fake.text = nourishlyJson();
    await _resume(tester);
    expect(find.text('Poha'), findsOneWidget);
    final reads = fake.reads;
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();
    expect(fake.reads, greaterThan(reads));
  });

  testWidgets("Care's tile: today's meals from Nourishly", (tester) async {
    await _care(tester, FakeNourishly(nourishlyJson()));
    expect(find.text('Today: 1 meal from Nourishly'), findsOneWidget);
  });

  testWidgets("Care's tile: foods she avoids when nothing is shared today", (
    tester,
  ) async {
    await _care(tester, FakeNourishly());
    expect(find.text('Foods you avoid'), findsOneWidget);
  });

  testWidgets('day chips: a tap action for screen readers, 48 dp on a '
      '360 dp phone', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      seed: _seed,
      nourishly: FakeNourishly(nourishlyJson()),
      size: const Size(360, 740),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Care'),
      ),
    );
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(NavmaasTabBar)))
        .go('/care/nutrition');
    await tester.pumpAndSettle();
    final chip = find.byKey(const ValueKey('nourishly-day-2026-10-04'));
    expect(
      tester.getSemantics(chip),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(tester.getSize(chip).width, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  test('back on the current week, the strip follows today again', () {
    final today = DateTime.utc(2026, 10, 5);
    final earlier = stepWeek(null, -7, today);
    expect(earlier, DateTime.utc(2026, 9, 28));
    expect(stepWeek(earlier, -7, today), DateTime.utc(2026, 9, 21));
    // Null means "today", so after midnight the strip moves with the date.
    expect(stepWeek(earlier, 7, today), isNull);
    expect(stepWeek(DateTime.utc(2026, 10, 2), 7, today), isNull);
  });
}
