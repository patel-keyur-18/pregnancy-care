import 'package:navmaas/core/utils/date_only.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock.g.dart';

/// "Today" as a calendar date. Override in tests for a fixed day; the app
/// refreshes it when it comes back to the foreground.
@riverpod
DateTime today(Ref ref) => dateOnly(DateTime.now());
