import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/features/onboarding/onboarding_screen.dart';
import 'package:navmaas/features/today/today_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('no pregnancy: onboarding, without the tab bar', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('active pregnancy: Today, and all five tabs open', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) =>
          PregnancyRepository(db)
              .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 15)),
    );
    expect(find.byType(TodayScreen), findsOneWidget);
    for (final tab in ['Journey', 'Sessions', 'Care', 'Me', 'Today']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        ['Today', 'Journey', 'Sessions', 'Care', 'Me'].indexOf(tab),
      );
    }
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
