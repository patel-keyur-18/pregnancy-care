/// The home-screen widget's snapshot (ARCHITECTURE §10, Plan decisions
/// 47 and 49). The widget never opens the database: it shows only this
/// JSON, written by the app. Every word in it comes from `app_en.arb`, so
/// the native widgets only pick the entry for the current day and the next
/// reminder still ahead. Pure Dart.
library;

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Days of week text the snapshot carries, so the widget stays right when
/// she doesn't open the app for a while.
const widgetDays = 28;

/// Reminders the snapshot carries.
const widgetReminders = 20;

/// The snapshot as JSON.
///
/// [start] is the active pregnancy's start, or null while tracking is
/// stopped (the widget then shows only the brand mark). With [hidden], it
/// holds no week, size or reminder titles: only the reminders' times.
/// [titles] are the notification titles of [planned], in order.
String widgetSnapshot({
  required DateTime today,
  required DateTime now,
  required DateTime? start,
  required ContentPack? pack,
  required List<PlannedReminder> planned,
  required List<String> titles,
  required bool hidden,
  required AppLocalizations l10n,
}) {
  final stopped = start == null;
  String day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  return jsonEncode({
    'v': 1,
    'stopped': stopped,
    'hidden': hidden,
    'labels': {
      'name': l10n.appTitle,
      'next': l10n.widgetNext,
      'nextReminder': l10n.widgetNextReminder,
      'none': l10n.widgetNoReminders,
      'tomorrow': l10n.widgetTomorrow,
    },
    'days': [
      if (!stopped && !hidden)
        for (var i = 0; i < widgetDays; i++)
          if (PregnancySnapshot.of(start: start, today: addDays(today, i))
              case final s when !s.needsReview)
            {
              'date': day(addDays(today, i)),
              'week': l10n.weekNumber(s.weeks),
              'weekDay': l10n.pathDay(s.weeks, s.days),
              ...switch (pack?[s.weeks]?.size) {
                final size? => {
                  'daySize': l10n.widgetDaySize(s.days, size),
                  'size': l10n.heroSize(size),
                },
                null => {'daySize': l10n.embryoDay(s.days), 'size': ''},
              },
            },
    ],
    'next': [
      if (!stopped)
        for (final (i, p)
            in planned.indexed
                .where((e) => e.$2.at.isAfter(now))
                .take(widgetReminders))
          {
            'at': p.at.millisecondsSinceEpoch,
            'date': day(p.at),
            'weekday': DateFormat('EEE').format(p.at),
            'time': formatMinuteOfDay(p.at.hour * 60 + p.at.minute),
            if (!hidden) 'title': titles[i],
          },
    ],
  });
}

/// When the Android widget should redraw: each reminder in [planned] (its
/// "next" moves on) and the next [widgetDays] midnights (a new day).
List<DateTime> widgetUpdateTimes({
  required DateTime now,
  required List<PlannedReminder> planned,
}) => [
  for (final p in planned)
    if (p.at.isAfter(now)) p.at.add(const Duration(seconds: 1)),
  for (var i = 1; i <= widgetDays; i++)
    DateTime(now.year, now.month, now.day + i, 0, 0, 1),
];
