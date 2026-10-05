// Runs on a real phone: the OS really schedules, lists and cancels the
// reminders. iOS only keeps scheduled notifications once they're allowed,
// so first open Navmaas on the phone and turn on Me → Reminders, then:
//   flutter test integration_test -d <device>
import 'dart:ui' show Locale;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('OS schedule follows the plan; snooze adds one', (tester) async {
    final scheduler = LocalNotificationsScheduler();
    await scheduler.init();
    expect(
      await scheduler.hasPermission(),
      isTrue,
      reason: 'Allow Navmaas notifications first (Me → Reminders), then rerun',
    );
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();

    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day + 1, 12);
    List<PlannedReminder> plan(List<String> names) => planReminders(
      now: now,
      settings: const ReminderSettings(on: true, dailyLimit: 8),
      candidates: [
        for (final (i, n) in names.indexed)
          ReminderCandidate(
            key: 'dose:$n@${at.toIso8601String()}',
            at: at.add(Duration(hours: i)),
            kind: ReminderKind.supplement,
            title: n,
            body: '1 tablet',
          ),
      ],
    );

    final first = plan(['Iron', 'Calcium']);
    await scheduler.sync(first, l10n);
    var pending = await plugin.pendingNotificationRequests();
    expect({for (final p in pending) p.id}, {for (final p in first) p.id});
    expect(pending.map((p) => p.title).toSet(), {'Iron', 'Calcium'});
    final payload = ReminderPayload.fromJson(pending.first.payload!);
    expect(payload.actions, isTrue, reason: 'Taken / Snooze on doses');

    final second = plan(['Iron']);
    await scheduler.sync(second, l10n);
    pending = await plugin.pendingNotificationRequests();
    expect(pending.map((p) => p.id), [second.single.id]);

    await scheduler.snooze(payload, l10n);
    pending = await plugin.pendingNotificationRequests();
    expect(pending, hasLength(2));
    await scheduler.sync(second, l10n);
    expect(
      await plugin.pendingNotificationRequests(),
      hasLength(2),
      reason: 'a re-plan leaves snoozed reminders alone',
    );

    await plugin.cancelAll();
  });
}
