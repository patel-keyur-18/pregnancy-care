import 'dart:async';
import 'dart:ui' show Locale;

import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/platform/app_usage.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';
import 'package:navmaas/features/screen_rest/domain/limit_rules.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_limit_sync.g.dart';

/// Keeps the Android app-limit check's rules in step with the reminder
/// plan, the calm-notification settings, her limits and tracking (Plan
/// decision 53). Sends them only when they change; Android only.
@Riverpod(keepAlive: true)
class AppLimitSync extends _$AppLimitSync {
  String? _last;
  var _queued = false;

  @override
  void build() {
    if (!ref.read(appUsageProvider).supported) return;
    ref
      ..listen(reminderSyncProvider, (_, _) => _refresh())
      ..listen(reminderSettingsProvider, (_, _) => _refresh())
      ..listen(appLimitsProvider, (_, _) => _refresh())
      ..listen(activePregnancyProvider, (_, _) => _refresh());
    _refresh();
  }

  void _refresh() {
    if (_queued) return;
    _queued = true;
    unawaited(Future.microtask(_run));
  }

  Future<void> _run() async {
    _queued = false;
    final settings = ref.read(reminderSettingsProvider).value;
    final limits = ref.read(appLimitsProvider).value;
    final pregnancy = ref.read(activePregnancyProvider);
    if (settings == null || limits == null || !pregnancy.hasValue) return;
    final rules = limitRules(
      now: clockNow(),
      settings: settings,
      active: pregnancy.value != null,
      planned: ref.read(reminderSyncProvider),
      limits: [
        for (final l in limits)
          (package: l.package, label: l.label, minutes: l.minutes),
      ],
      l10n: lookupAppLocalizations(const Locale('en')),
    );
    if (rules == _last) return;
    _last = rules;
    await ref.read(appUsageProvider).setRules(rules, limits: limits.length);
  }
}
