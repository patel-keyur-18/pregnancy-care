import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/features/birth_prep/domain/bag_reminder.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final now = DateTime(2026, 10, 5, 9);

  test('one reminder at the time she chose', () {
    final c = bagCandidates(
      now: now,
      at: DateTime(2026, 10, 8, 10),
      l10n: l10n,
    );
    expect(c.single.at, DateTime(2026, 10, 8, 10));
    expect(c.single.kind, ReminderKind.careItem);
    expect(c.single.title, 'Pack the hospital bag');
  });

  test('none when unset or already past', () {
    expect(bagCandidates(now: now, at: null, l10n: l10n), isEmpty);
    expect(
      bagCandidates(now: now, at: DateTime(2026, 10, 4, 10), l10n: l10n),
      isEmpty,
    );
  });

  test('read from settings; quiet hours hold it to the morning', () {
    final settings = ReminderSettings.fromSettings(const {
      SettingKeys.remindersOn: 'true',
      SettingKeys.bagRemindAt: '2026-10-06T23:00:00.000',
    });
    expect(settings.bagAt, DateTime(2026, 10, 6, 23));
    expect(
      settings,
      isNot(
        ReminderSettings.fromSettings(const {SettingKeys.remindersOn: 'true'}),
      ),
      reason: 'changing the bag reminder re-plans',
    );
    final planned = planReminders(
      now: now,
      settings: settings,
      candidates: bagCandidates(now: now, at: settings.bagAt, l10n: l10n),
    );
    expect(planned.single.at, DateTime(2026, 10, 7, 7));
  });
}
