import 'package:intl/intl.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_use.g.dart';

/// "In Navmaas today" (Screen Rest): time the app was on screen today.
/// [ScreenUse] holds when the app last came on screen; the seconds before
/// that are saved in settings when it leaves the screen, so nothing is
/// written while she uses it.
@Riverpod(keepAlive: true)
class ScreenUse extends _$ScreenUse {
  /// On screen since (the app starts on screen), or null while hidden.
  @override
  DateTime? build() => clockNow();

  void shown() => state ??= clockNow();

  /// Saves the time since the app came on screen.
  Future<void> hidden() async {
    final since = state;
    if (since == null) return;
    state = null;
    final settings = ref.read(settingsRepositoryProvider);
    final all = await settings.getAll();
    final now = clockNow();
    final seconds = usedToday(all, since: since, now: now).inSeconds;
    await settings.put(SettingKeys.useDay, _day(now));
    await settings.put(SettingKeys.useSeconds, '$seconds');
  }
}

/// Time in Navmaas today, as the Screen Rest card shows it.
@riverpod
Stream<Duration> usedTodayTotal(Ref ref) {
  final since = ref.watch(screenUseProvider);
  return ref
      .watch(settingsRepositoryProvider)
      .watchAll()
      .map((s) => usedToday(s, since: since, now: clockNow()));
}

/// Time in Navmaas on [now]'s day: what [settings] saved for that day, plus
/// the time on screen [since] (counted from midnight if it began earlier).
Duration usedToday(
  Map<String, String> settings, {
  required DateTime? since,
  required DateTime now,
}) {
  final midnight = localDay(now);
  final saved = settings[SettingKeys.useDay] == _day(now)
      ? int.tryParse(settings[SettingKeys.useSeconds] ?? '') ?? 0
      : 0;
  final from = since == null || since.isAfter(midnight) ? since : midnight;
  return Duration(seconds: saved) +
      (from == null ? Duration.zero : now.difference(from));
}

/// "Eye-rest nudge" (Screen Rest): on unless switched off.
@riverpod
Stream<bool> eyeRest(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.eyeRest)
    .map((v) => v != 'false');

String _day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
