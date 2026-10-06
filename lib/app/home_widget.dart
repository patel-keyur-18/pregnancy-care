import 'dart:async';
import 'dart:ui' show Locale;

import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/home_widget.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/home_widget/domain/widget_snapshot.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget.g.dart';

/// Keeps the home-screen widget's snapshot in step with the pregnancy, the
/// planned reminders and "Hide details" (Plan decisions 47 and 49).
/// Publishes only when the snapshot changes.
@Riverpod(keepAlive: true)
class WidgetSync extends _$WidgetSync {
  String? _last;
  var _queued = false;

  @override
  void build() {
    ref
      ..listen(reminderSyncProvider, (_, _) => _refresh())
      ..listen(activePregnancyProvider, (_, _) => _refresh())
      ..listen(contentPackProvider, (_, _) => _refresh())
      ..listen(widgetHideDetailsProvider, (_, _) => _refresh());
    _refresh();
  }

  void _refresh() {
    if (_queued) return;
    _queued = true;
    unawaited(Future.microtask(_run));
  }

  Future<void> _run() async {
    _queued = false;
    final pregnancy = ref.read(activePregnancyProvider);
    final hidden = ref.read(widgetHideDetailsProvider).value;
    if (!pregnancy.hasValue || hidden == null) return;
    final l10n = lookupAppLocalizations(const Locale('en'));
    final planned = ref.read(reminderSyncProvider);
    final now = clockNow();
    final snapshot = widgetSnapshot(
      today: ref.read(todayProvider),
      now: now,
      start: pregnancy.value?.startDate,
      pack: ref.read(contentPackProvider).value,
      planned: planned,
      titles: [for (final p in planned) reminderPayloadFor(p, l10n).title],
      hidden: hidden,
      l10n: l10n,
    );
    if (snapshot == _last) return;
    _last = snapshot;
    await ref
        .read(widgetPublisherProvider)
        .publish(snapshot, widgetUpdateTimes(now: now, planned: planned));
  }
}
