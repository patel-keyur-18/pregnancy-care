import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/reminders/data_reminders.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/features/third_trimester/domain/patterns.dart';
import 'package:navmaas/features/third_trimester/presentation/kick_counter_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

final _at = DateTime(2026, 10, 5);

KickSession _kicks(int hour, int minutes, int count) => KickSession(
  id: '$hour-$minutes-$count',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  startedAt: _at.add(Duration(hours: hour)),
  endedAt: _at.add(Duration(hours: hour, minutes: minutes)),
  count: count,
);

Contraction _contraction(DateTime start, int seconds) => Contraction(
  id: '$start',
  createdAt: _at,
  updatedAt: _at,
  pregnancyId: 'p',
  startedAt: start,
  endedAt: start.add(Duration(seconds: seconds)),
);

void main() {
  group('kick pattern', () {
    test('needs three sessions', () {
      expect(mostActiveWindow([_kicks(20, 20, 10), _kicks(9, 30, 10)]), null);
    });

    test('the two-hour window with the most movements per minute', () {
      expect(
        mostActiveWindow([
          _kicks(9, 30, 10), // 0.33 a minute
          _kicks(20, 15, 10), // 8–10 pm: 0.67
          _kicks(21, 25, 10), // 8–10 pm: 0.4; together 0.5
          _kicks(14, 40, 10), // 0.25
        ]),
        20,
      );
    });

    test('windows read like the prototype', () {
      expect(formatWindow(20), '8–10 pm');
      expect(formatWindow(10), '10 am–12 pm');
      expect(formatWindow(22), '10 pm–12 am');
      expect(formatWindow(0), '12–2 am');
    });
  });

  group('contraction summary', () {
    final now = DateTime(2026, 10, 5, 23);
    test('the last hour: count, average length, average gap', () {
      final log = [
        _contraction(now.subtract(const Duration(minutes: 5)), 60),
        _contraction(now.subtract(const Duration(minutes: 13)), 50),
        _contraction(now.subtract(const Duration(minutes: 21)), 40),
        // Over an hour ago: not counted.
        _contraction(now.subtract(const Duration(minutes: 70)), 30),
      ];
      final s = summariseContractions(log, now);
      expect(s.count, 3);
      expect(s.averageLength, const Duration(seconds: 50));
      expect(s.averageGap, const Duration(minutes: 8));
    });

    test('one contraction has no gap; none has nothing', () {
      final one = summariseContractions([
        _contraction(now.subtract(const Duration(minutes: 5)), 45),
      ], now);
      expect((one.count, one.averageGap), (1, null));
      final none = summariseContractions(const [], now);
      expect((none.count, none.averageLength), (0, null));
    });
  });

  group('iPhone build expiry', () {
    test('reads ExpirationDate from a provisioning profile', () {
      // A profile is a signed envelope (binary) around an XML plist.
      final profile = [
        0x30, 0x82, 0xff, 0x00, // envelope bytes
        ...utf8.encode('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
  <key>CreationDate</key>
  <date>2026-10-03T09:12:00Z</date>
  <key>ExpirationDate</key>
  <date>2026-10-10T09:12:00Z</date>
</dict></plist>'''),
        0x00, 0xa0, 0x82,
      ];
      expect(parseProvisionExpiry(profile), DateTime.utc(2026, 10, 10, 9, 12));
    });

    test('null without the key', () {
      expect(parseProvisionExpiry(utf8.encode('<plist></plist>')), null);
    });

    test('a reminder the day before at 10:00', () {
      final expiry = DateTime(2026, 10, 10, 9, 12);
      final c = buildExpiryCandidates(
        expiry: expiry,
        l10n: AppLocalizationsEn(),
      ).single;
      expect(c.at, DateTime(2026, 10, 9, 10));
      expect(c.kind, ReminderKind.buildExpiry);
      expect(c.title, 'Navmaas expires tomorrow');
      expect(
        buildExpiryCandidates(expiry: null, l10n: AppLocalizationsEn()),
        isEmpty,
      );
    });
  });
}
