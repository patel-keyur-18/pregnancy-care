import 'package:navmaas/core/utils/date_only.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// The wall clock. Everything that stamps or compares times calls this
/// instead of `DateTime.now`, so widget tests can pin it to their fixed day
/// (`pumpApp`); fake time then moves it forward.
DateTime Function() clockNow = DateTime.now;

/// "Today" as a calendar date. Override in tests for a fixed day; the app
/// refreshes it when it comes back to the foreground.
@riverpod
DateTime today(Ref ref) => dateOnly(clockNow());

/// The current time, for time-of-day wording such as the greeting. Fixed in
/// tests; refreshed with [todayProvider] when the app resumes.
@riverpod
DateTime now(Ref ref) => clockNow();
