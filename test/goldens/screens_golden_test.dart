// Golden screenshots of the main screens (ARCHITECTURE §16), light and dark
// at 1.0× and 2.0× text. They use Flutter's built-in test font, so they
// render the same on macOS and on CI's Linux: they check layout, colour and
// icons, not letter shapes. Update with:
//   flutter test test/goldens --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';

import '../helpers.dart';

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

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      final name = '${brightness.name}_${scale}x';

      testWidgets('onboarding $name', (tester) async {
        await pumpApp(tester, platformBrightness: brightness, textScale: scale);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await pickDate(tester, '04/15/2026');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('onboarding_$name.png'),
        );
      });

      testWidgets('tabs $name', (tester) async {
        await pumpApp(
          tester,
          seed: _seed,
          platformBrightness: brightness,
          textScale: scale,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('today_$name.png'),
        );
        for (final tab in ['Journey', 'Me']) {
          await _tab(tester, tab);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('${tab.toLowerCase()}_$name.png'),
          );
        }
      });
    }
  }
}
