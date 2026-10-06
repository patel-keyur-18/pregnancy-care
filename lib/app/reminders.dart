import 'dart:async';
import 'dart:ui' show DartPluginRegistrant, Locale;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/reminders/data_reminders.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/care/data/care_repository.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/domain/care_reminders.dart';
import 'package:navmaas/features/care/domain/supplement_reminders.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminders.g.dart';

AppLocalizations get _l10n => lookupAppLocalizations(const Locale('en'));

/// "Taken" logs every dose in the reminder; "Snooze" shows it again in
/// 30 minutes. Used by the app and by the background isolate.
Future<void> applyReminderAction(
  NotificationResponse response, {
  required SupplementRepository supplements,
  required ReminderScheduler scheduler,
}) async {
  final raw = response.payload;
  if (raw == null) return;
  final payload = ReminderPayload.fromJson(raw);
  switch (response.actionId) {
    case ReminderAction.taken:
      for (final key in payload.keys) {
        final dose = parseDoseKey(key);
        if (dose == null) continue;
        await supplements.setTaken(dose.scheduleId, dose.dueAt, taken: true);
      }
    case ReminderAction.snooze:
      await scheduler.snooze(payload, _l10n);
  }
}

/// Runs in a separate isolate when an action is chosen while the app is
/// closed or in the background: opens the encrypted DB, applies, closes.
@pragma('vm:entry-point')
Future<void> reminderActionInBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final db = AppDatabase.open();
  final scheduler = LocalNotificationsScheduler();
  try {
    await scheduler.init();
    await applyReminderAction(
      response,
      supplements: SupplementRepository(db),
      scheduler: scheduler,
    );
  } finally {
    await db.close();
  }
}

/// Sets up notifications for the app. Failures never block start-up.
Future<void> initReminders(ProviderContainer container) async {
  try {
    final scheduler = container.read(reminderSchedulerProvider);
    await scheduler.init(
      onAction: (r) => applyReminderAction(
        r,
        supplements: container.read(supplementRepositoryProvider),
        scheduler: scheduler,
      ),
      onBackgroundAction: reminderActionInBackground,
    );
  } on Object catch (e) {
    debugPrint('Navmaas: reminders not initialised ($e)');
  }
}

/// Keeps the OS schedule in step with supplements, taken doses and the
/// calm-notification settings. Re-plans on any change and on resume.
@Riverpod(keepAlive: true)
class ReminderSync extends _$ReminderSync {
  var _queued = false;

  @override
  void build() {
    ref
      ..listen(reminderSettingsProvider, (_, _) => refresh())
      ..listen(supplementPlansProvider, (_, _) => refresh())
      ..listen(_upcomingTakenProvider, (_, _) => refresh())
      ..listen(appointmentsProvider, (_, _) => refresh())
      ..listen(careItemsProvider, (_, _) => refresh())
      ..listen(visitQuestionsProvider, (_, _) => refresh())
      ..listen(buildExpiryProvider, (_, _) => refresh());
    refresh();
  }

  /// Coalesces bursts of changes into one re-plan.
  void refresh() {
    if (_queued) return;
    _queued = true;
    unawaited(Future.microtask(_run));
  }

  Future<void> _run() async {
    _queued = false;
    final settings = ref.read(reminderSettingsProvider).value;
    final plans = ref.read(supplementPlansProvider).value;
    final taken = ref.read(_upcomingTakenProvider).value;
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (settings == null || plans == null || taken == null) return;
    ref.invalidate(nowProvider);
    final now = ref.read(nowProvider);
    final questions = ref.read(visitQuestionsProvider).value ?? const [];
    final planned = planReminders(
      now: now,
      settings: settings,
      candidates: [
        ...supplementCandidates(
          now: now,
          plans: plans,
          takenKeys: taken,
          l10n: _l10n,
        ),
        ...visitCandidates(
          now: now,
          appointments: ref.read(appointmentsProvider).value ?? const [],
          questionsWaiting: questions
              .where((q) => q.appointmentId == null && q.askedAt == null)
              .length,
          l10n: _l10n,
        ),
        if (pregnancy != null)
          ...careCandidates(
            now: now,
            items: ref.read(careItemsProvider).value ?? const [],
            pregnancyStart: pregnancy.startDate,
            l10n: _l10n,
          ),
        ...buildExpiryCandidates(
          expiry: ref.read(buildExpiryProvider).value,
          l10n: _l10n,
        ),
      ],
    );
    try {
      await ref.read(reminderSchedulerProvider).sync(planned, _l10n);
    } on Object catch (e) {
      debugPrint('Navmaas: reminders not scheduled ($e)');
    }
  }
}

/// Doses taken from today for the next 8 days (the planning window).
@Riverpod(keepAlive: true)
Stream<Set<String>> _upcomingTaken(Ref ref) {
  final t = ref.watch(todayProvider);
  final from = DateTime(t.year, t.month, t.day);
  return ref
      .watch(supplementRepositoryProvider)
      .watchTaken(from, DateTime(t.year, t.month, t.day + 8));
}
