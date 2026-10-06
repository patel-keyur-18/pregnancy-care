/// Reminder planner (ARCHITECTURE §7). Pure Dart: turns everything that
/// could remind her into at most a few calm notifications a day.
library;

import 'dart:convert';

import 'package:navmaas/core/reminders/reminder_settings.dart';

/// Priority order when a day is over its limit (first wins).
enum ReminderKind {
  appointment,
  buildExpiry,
  backup,
  supplement,
  careItem,
  nudge,
}

/// Something that may become a notification.
class ReminderCandidate {
  const new({
    required this.key,
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
  });

  /// Stable id of the source, e.g. a dose slot key.
  final String key;

  /// Local time.
  final DateTime at;
  final ReminderKind kind;
  final String title;
  final String body;
}

/// A notification to schedule. [keys] are the candidates it covers.
class PlannedReminder {
  const new({
    required this.id,
    required this.at,
    required this.kind,
    required this.items,
    this.isDigest = false,
  });

  final int id;
  final DateTime at;
  final ReminderKind kind;
  final List<ReminderCandidate> items;
  final bool isDigest;

  List<String> get keys => [for (final i in items) i.key];
}

/// Key prefix of a meal window's own notice, which its window doesn't hold.
const mealKeyPrefix = 'meal@';

/// Key prefix of the wind-down nudge; tapping it opens her audio.
const windDownKeyPrefix = 'wind-down@';

/// Plans the next [days] days from [now]:
/// 1. reminders inside a meal window or quiet hours move to their end;
///    nudges there are dropped;
/// 2. reminders within 30 minutes are bundled at the first time;
/// 3. each day keeps at most `dailyLimit` by priority; the rest fold into
///    one digest at the end of quiet hours (skipped if that has passed).
///    Nudges never wait for the digest: over the limit they are dropped;
/// 4. at most [maxPending] are kept (iOS allows 64 pending).
List<PlannedReminder> planReminders({
  required DateTime now,
  required List<ReminderCandidate> candidates,
  required ReminderSettings settings,
  int days = 7,
  int maxPending = 60,
}) {
  if (!settings.on) return const [];
  final end = DateTime(
    now.year,
    now.month,
    now.day + days,
    now.hour,
    now.minute,
  );

  // 1. Meal windows and quiet hours, then the window.
  final moved = <ReminderCandidate>[];
  for (final c in candidates) {
    final nudge = c.kind == ReminderKind.nudge;
    var at = c.at;
    final mealEnd = settings.mealEnd(at.hour * 60 + at.minute);
    if (mealEnd != null && !c.key.startsWith(mealKeyPrefix)) {
      if (nudge) continue;
      at = DateTime(at.year, at.month, at.day, 0, mealEnd);
    }
    final minute = at.hour * 60 + at.minute;
    if (settings.isQuiet(minute)) {
      if (nudge) continue;
      final nextDay = minute >= settings.quietEnd ? 1 : 0;
      at = DateTime(
        at.year,
        at.month,
        at.day + nextDay,
        settings.quietEnd ~/ 60,
        settings.quietEnd % 60,
      );
    }
    if (at.isBefore(now) || !at.isBefore(end)) continue;
    moved.add(_at(c, at));
  }
  moved.sort((a, b) => a.at.compareTo(b.at));

  // 2. Bundle.
  final groups = <List<ReminderCandidate>>[];
  for (final c in moved) {
    if (groups.isNotEmpty &&
        c.at.difference(groups.last.first.at) <= const Duration(minutes: 30)) {
      groups.last.add(c);
    } else {
      groups.add([c]);
    }
  }

  // 3. Daily limit with a morning digest.
  final byDay = <DateTime, List<List<ReminderCandidate>>>{};
  for (final g in groups) {
    final first = g.first.at;
    byDay
        .putIfAbsent(DateTime(first.year, first.month, first.day), () => [])
        .add(g);
  }
  final out = <PlannedReminder>[];
  for (final MapEntry(key: day, value: dayGroups) in byDay.entries) {
    final limit = settings.dailyLimit;
    final ranked = [...dayGroups]
      ..sort((a, b) {
        final p = _kind(a).index.compareTo(_kind(b).index);
        return p != 0 ? p : a.first.at.compareTo(b.first.at);
      });
    // Nudges rank last; if only nudges are over the limit, no digest.
    final needed = ranked.where((g) => _kind(g) != ReminderKind.nudge).length;
    final digest = needed > limit;
    for (final g in ranked.take(digest ? limit - 1 : limit)) {
      out.add(_planned(g, g.first.at, digest: false));
    }
    if (digest) {
      final digestAt = DateTime(
        day.year,
        day.month,
        day.day,
        settings.quietEnd ~/ 60,
        settings.quietEnd % 60,
      );
      if (!digestAt.isBefore(now)) {
        final waiting = [
          for (final g in ranked.skip(limit - 1))
            for (final c in g)
              if (c.kind != ReminderKind.nudge) c,
        ];
        out.add(_planned(waiting, digestAt, digest: true));
      }
    }
  }

  // 4. Cap.
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(maxPending).toList();
}

ReminderKind _kind(List<ReminderCandidate> g) =>
    g.map((c) => c.kind).reduce((a, b) => a.index <= b.index ? a : b);

ReminderCandidate _at(ReminderCandidate c, DateTime at) => ReminderCandidate(
  key: c.key,
  at: at,
  kind: c.kind,
  title: c.title,
  body: c.body,
);

PlannedReminder _planned(
  List<ReminderCandidate> items,
  DateTime at, {
  required bool digest,
}) {
  final sorted = [...items]..sort((a, b) => a.key.compareTo(b.key));
  final keys = sorted.map((c) => c.key).join('|');
  return PlannedReminder(
    id: stableId('${digest ? 'digest' : 'at'}@${at.toIso8601String()}#$keys'),
    at: at,
    kind: _kind(sorted),
    items: sorted,
    isDigest: digest,
  );
}

/// FNV-1a 32-bit, positive and non-zero: the same input always gives the
/// same notification id, so re-planning replaces exactly what changed.
int stableId(String s) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(s)) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  final id = h & 0x7fffffff;
  return id == 0 ? 1 : id;
}
