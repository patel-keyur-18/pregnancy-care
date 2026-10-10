/// When a blood-sugar reading was taken (M8a): a time today, never later
/// than now. Pure Dart.
library;

/// [hour]:[minute] today, or null when that time hasn't come yet.
DateTime? sugarTimeToday(DateTime now, int hour, int minute) {
  final at = DateTime(now.year, now.month, now.day, hour, minute);
  return at.isAfter(now) ? null : at;
}
