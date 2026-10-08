import 'dart:convert';

/// A walk she started and hasn't finished: the stretches she walked, the
/// last one still going while she walks. Kept in `settings` (`walk_draft`),
/// so she can pause, leave and carry on later, even after the app closed.
class WalkDraft {
  const new(this.stretches);

  /// Starts a walk at [now].
  factory start(DateTime now) => WalkDraft([(now, null)]);

  /// Start and end of each stretch; the end is null while she walks.
  final List<(DateTime, DateTime?)> stretches;

  DateTime get startedAt => stretches.first.$1;

  bool get running => stretches.last.$2 == null;

  /// Seconds walked by [now].
  int seconds(DateTime now) => stretches.fold(
    0,
    (sum, s) => sum + (s.$2 ?? now).difference(s.$1).inSeconds,
  );

  WalkDraft pause(DateTime now) => running
      ? WalkDraft([
          ...stretches.take(stretches.length - 1),
          (stretches.last.$1, now),
        ])
      : this;

  WalkDraft resume(DateTime now) =>
      running ? this : WalkDraft([...stretches, (now, null)]);

  /// True when the walk began before [today] (a local midnight).
  bool startedBefore(DateTime today) => startedAt.isBefore(today);

  /// A walk left from an earlier day ends, at the latest, at the midnight
  /// after it began; it is logged to that day.
  WalkDraft endOfItsDay() {
    final s = startedAt;
    return pause(DateTime(s.year, s.month, s.day + 1));
  }

  String encode() => jsonEncode([
    for (final (from, to) in stretches)
      [from.toIso8601String(), to?.toIso8601String()],
  ]);

  /// The saved draft, or null when there is none (or it can't be read).
  static WalkDraft? decode(String? json) {
    if (json == null) return null;
    try {
      final list = [
        for (final s in jsonDecode(json) as List)
          (
            DateTime.parse((s as List)[0] as String),
            s[1] == null ? null : DateTime.parse(s[1] as String),
          ),
      ];
      return list.isEmpty ? null : WalkDraft(list);
    } on Object {
      return null;
    }
  }
}
