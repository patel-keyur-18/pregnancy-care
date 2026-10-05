import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/app.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';

void main() {
  // Regression: reading (not listening to) a stream provider left drift's
  // stream paused, so main() waited forever on a real device.
  test('loadFirstValues completes and keeps values loaded', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await loadFirstValues(container).timeout(const Duration(seconds: 5));
    expect(container.read(activePregnancyProvider).hasValue, isTrue);
    expect(container.read(activePregnancyProvider).value, isNull);
    expect(container.read(themeModeProvider).value, ThemeMode.system);
  });
}
