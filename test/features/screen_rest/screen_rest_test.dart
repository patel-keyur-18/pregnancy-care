import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/features/screen_rest/data/screen_use.dart';
import 'package:navmaas/features/screen_rest/domain/rest_reminders.dart';
import 'package:navmaas/features/screen_rest/domain/rest_windows.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  // Monday 5 October 2026, 9:00.
  final now = DateTime(2026, 10, 5, 9);
  DateTime t(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 10, day, hour, minute);

  group('rest reminders', () {
    test('a notice as each meal window starts; wind-down when on', () {
      final c = restCandidates(
        now: now,
        settings: const ReminderSettings(windDownOn: true),
        l10n: l10n,
        days: 1,
      );
      expect(c.map((c) => (c.at, c.title, c.kind)), [
        (t(5, 13), 'Meal time', ReminderKind.nudge),
        (t(5, 20), 'Meal time', ReminderKind.nudge),
        (t(5, 21), 'Time to wind down', ReminderKind.nudge),
      ]);
      expect(c.last.key, startsWith(windDownKeyPrefix));
    });
    test('both off: none', () {
      expect(
        restCandidates(
          now: now,
          settings: const ReminderSettings(mealOn: false),
          l10n: l10n,
        ),
        isEmpty,
      );
    });
  });

  group('the next rest window', () {
    const s = ReminderSettings();
    test('the next to start, or the one she is in', () {
      expect(nextRestWindow(s, now), (start: t(5, 13), end: t(5, 13, 45)));
      expect(nextRestWindow(s, t(5, 13, 10)), (
        start: t(5, 13),
        end: t(5, 13, 45),
      ));
      expect(nextRestWindow(s, t(5, 20, 50)), (
        start: t(5, 21, 30),
        end: t(6, 7),
      ));
    });
    test('bedtime from the night before, and every rule off', () {
      expect(nextRestWindow(s, t(5, 6)), (start: t(4, 21, 30), end: t(5, 7)));
      expect(
        nextRestWindow(
          const ReminderSettings(quietOn: false, mealOn: false),
          now,
        ),
        isNull,
      );
    });
  });

  group('time in Navmaas today', () {
    test('what was saved today plus the time on screen now', () {
      final saved = {
        SettingKeys.useDay: '2026-10-05',
        SettingKeys.useSeconds: '600',
      };
      expect(
        usedToday(saved, since: t(5, 8, 55), now: now),
        const Duration(minutes: 15),
      );
      expect(
        usedToday(saved, since: null, now: now),
        const Duration(minutes: 10),
      );
    });
    test('a new day starts from nothing, counted from midnight', () {
      final saved = {
        SettingKeys.useDay: '2026-10-04',
        SettingKeys.useSeconds: '600',
      };
      expect(
        usedToday(saved, since: t(4, 23, 50), now: t(5, 0, 5)),
        const Duration(minutes: 5),
      );
    });
  });

  group('notification text and taps', () {
    ReminderCandidate c(String key, String title) => ReminderCandidate(
      key: key,
      at: now,
      kind: ReminderKind.supplement,
      title: title,
      body: '',
    );
    test('the digest names three, then "and N more", and opens Today', () {
      final p = reminderPayloadFor(
        PlannedReminder(
          id: 1,
          at: now,
          kind: ReminderKind.supplement,
          isDigest: true,
          items: [
            for (final n in ['A', 'B', 'C', 'D', 'E']) c(n, n),
          ],
        ),
        l10n,
      );
      expect(p.title, "Today's reminders");
      expect(p.body, 'A · B · C and 2 more');
      expect(p.open, ReminderOpen.today);
    });
    test('wind-down opens her audio; others open nothing special', () {
      ReminderPayload single(String key) => reminderPayloadFor(
        PlannedReminder(
          id: 1,
          at: now,
          kind: ReminderKind.nudge,
          items: [c(key, 'x')],
        ),
        l10n,
      );
      expect(single('${windDownKeyPrefix}x').open, ReminderOpen.windDown);
      expect(single('${mealKeyPrefix}x').open, isNull);
      // The tap target survives a snooze's round trip.
      final json = single('${windDownKeyPrefix}x').toJson();
      expect(ReminderPayload.fromJson(json).open, ReminderOpen.windDown);
    });
  });
}
