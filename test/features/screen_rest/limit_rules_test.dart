import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/features/screen_rest/domain/limit_rules.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 5, 9);
  const on = ReminderSettings(on: true);
  const youtube = (
    package: 'com.google.android.youtube',
    label: 'YouTube',
    minutes: 30,
  );

  PlannedReminder at(int id, DateTime at) => PlannedReminder(
    id: id,
    at: at,
    kind: ReminderKind.supplement,
    items: const [],
  );

  Map<String, dynamic> rules({
    ReminderSettings settings = on,
    bool active = true,
    List<PlannedReminder> planned = const [],
  }) => jsonDecode(
    limitRules(
      now: now,
      settings: settings,
      active: active,
      planned: planned,
      limits: [youtube],
      l10n: l10n,
    ),
  ) as Map<String, dynamic>;

  int ms(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 10, day, hour, minute).millisecondsSinceEpoch;

  test("the notice is ready-made, in the owner's words", () {
    expect((rules()['limits'] as List).single, {
      'package': 'com.google.android.youtube',
      'minutes': 30,
      'title': 'Time for a pause',
      'body': '30 min on YouTube today. Phone down, baby time.',
    });
  });

  test('notices may go out only outside quiet hours and meal windows', () {
    final days = (rules()['days'] as List).cast<Map<String, dynamic>>();
    expect(days, hasLength(7));
    expect(days.first['date'], '2026-10-05');
    // Quiet 9:30 pm – 7:00 am, meals 1:00–1:45 pm and 8:00–8:45 pm.
    expect(days.first['open'], [
      [ms(5, 7), ms(5, 13)],
      [ms(5, 13, 45), ms(5, 20)],
      [ms(5, 20, 45), ms(5, 21, 30)],
    ]);
  });

  test('with rest rules off, the whole day is open', () {
    final days =
        (rules(
                  settings: const ReminderSettings(
                    on: true,
                    quietOn: false,
                    mealOn: false,
                  ),
                )['days']
                as List)
            .cast<Map<String, dynamic>>();
    expect(days.first['open'], [
      [ms(5, 0), ms(6, 0)],
    ]);
  });

  test('room is what the daily limit leaves after planned reminders', () {
    final days =
        (rules(
                  planned: [
                    at(1, DateTime(2026, 10, 5, 8)),
                    at(2, DateTime(2026, 10, 5, 21)),
                    at(3, DateTime(2026, 10, 6, 8)),
                    for (var i = 0; i < 6; i++)
                      at(10 + i, DateTime(2026, 10, 7, 8 + i)),
                  ],
                )['days']
                as List)
            .cast<Map<String, dynamic>>();
    expect(days.take(4).map((d) => d['room']), [2, 3, 0, 4]);
  });

  test('reminders off or tracking stopped: no notice at all', () {
    expect(rules(settings: const ReminderSettings())['days'], isEmpty);
    expect(rules(active: false)['days'], isEmpty);
  });
}
