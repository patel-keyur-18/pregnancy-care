import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';

import '../../helpers.dart';

/// Week 24 day 3, reminders on, Iron at 9:00 pm.
Future<void> _seed(AppDatabase db) async {
  await PregnancyRepository(db)
      .saveDating(method: .lmp, date: DateTime.utc(2026, 4, 17));
  await SettingsRepository(db).put(SettingKeys.remindersOn, 'true');
  final id = (await db.select(db.pregnancies).getSingle()).id;
  await SupplementRepository(db).save(
    pregnancyId: id,
    name: 'Iron',
    doseText: '1 tablet',
    times: [(id: null, minuteOfDay: 21 * 60, weekdayMask: 127, label: null)],
  );
  await db
      .update(db.supplements)
      .write(SupplementsCompanion(createdAt: Value(DateTime(2026))));
}

void main() {
  testWidgets('the widget shows the week and next reminder; Me hides them', (
    tester,
  ) async {
    final widget = FakeWidgetPublisher();
    await pumpApp(tester, widget: widget, seed: _seed);
    var s = jsonDecode(widget.snapshots.last) as Map<String, dynamic>;
    expect(
      (s['days'] as List).first,
      containsPair('weekDay', 'Week 24 · day 3'),
    );
    // Every notification counts, the meal-time notice too (Plan 49).
    expect(
      [
        for (final n in (s['next'] as List).cast<Map<String, dynamic>>())
          if (n['date'] == '2026-10-05') '${n['time']} ${n['title']}',
      ],
      ['1:00 pm Meal time', '8:00 pm Meal time', '9:00 pm Iron'],
    );
    expect(
      widget.updateTimes,
      contains(DateTime(2026, 10, 5, 21, 0, 1)),
      reason: 'Android redraws once Iron has fired',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavmaasTabBar),
        matching: find.text('Me'),
      ),
    );
    await tester.pumpAndSettle();
    final hide = find.text('Hide details on widget');
    await tester.scrollUntilVisible(
      hide,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(hide);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: hide, matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    s = jsonDecode(widget.snapshots.last) as Map<String, dynamic>;
    expect(s['hidden'], isTrue);
    expect(s['days'], isEmpty);
    expect((s['next'] as List)[2], {
      'at': DateTime(2026, 10, 5, 21).millisecondsSinceEpoch,
      'date': '2026-10-05',
      'weekday': 'Mon',
      'time': '9:00 pm',
    });
  });
}
