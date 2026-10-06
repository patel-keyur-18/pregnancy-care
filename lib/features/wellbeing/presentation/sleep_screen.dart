import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/screen_rest/presentation/screen_rest_screen.dart'
    show pickMinute;
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/domain/week.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Sleep entry (prototype "Sleep"): last night's bedtime and wake time, naps
/// and how rested she feels, in words. One entry per night, dated by the day
/// she woke up (Plan decision 44).
class SleepScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  static const _napStep = 15;
  static const _maxNap = 240;

  int _bed = 22 * 60 + 30;
  int _woke = 6 * 60 + 30;
  var _nap = 0;
  Rested? _rested;
  var _touched = false;

  @override
  void initState() {
    super.initState();
    // Today's night if saved, else her last night's times.
    var ready = false;
    ref.listenManual(wellbeingWeekProvider, (_, week) {
      final nights = [for (final d in week) ?d.sleep];
      if (_touched || nights.isEmpty) return;
      final today = week.first.sleep;
      final from = today ?? nights.first;
      void seed() {
        _bed = from.bedAt.toLocal().hour * 60 + from.bedAt.toLocal().minute;
        _woke = from.wokeAt.toLocal().hour * 60 + from.wokeAt.toLocal().minute;
        if (today != null) {
          _nap = today.napMinutes;
          _rested = today.rested;
        }
      }

      ready ? setState(seed) : seed();
    }, fireImmediately: true);
    ready = true;
  }

  void _change(VoidCallback f) => setState(() {
    f();
    _touched = true;
  });

  /// Bedtime on the evening before (or the same morning, after midnight).
  ({DateTime bedAt, DateTime wokeAt}) _times(DateTime day) {
    final morning = localDay(day);
    final wokeAt = morning.add(Duration(minutes: _woke));
    final bedDay = _bed > _woke
        ? morning.subtract(const Duration(days: 1))
        : morning;
    return (
      bedAt: DateTime(bedDay.year, bedDay.month, bedDay.day, 0, _bed),
      wokeAt: wokeAt,
    );
  }

  void _save() {
    final id = ref.read(activePregnancyProvider).value?.id;
    if (id == null) return;
    final day = ref.read(todayProvider);
    final t = _times(day);
    unawaited(
      ref
          .read(wellbeingRepositoryProvider)
          .saveSleep(
            pregnancyId: id,
            day: day,
            bedAt: t.bedAt,
            wokeAt: t.wokeAt,
            napMinutes: _nap,
            rested: _rested,
          ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<NavmaasColors>()!;
    final day = ref.watch(todayProvider);
    final week = ref.watch(wellbeingWeekProvider);
    final t = _times(day);
    final night = t.wokeAt.difference(t.bedAt).inMinutes;
    final average = averageSleepMinutes([for (final d in week) ?d.sleep]);
    final fg = scheme.onTertiaryContainer;

    Widget timeRow(
      NavmaasIcon icon,
      Color bg,
      Color iconFg,
      String label,
      int minute,
      ValueChanged<int> onPicked,
    ) => Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: () async {
          final m = await pickMinute(context, label, minute);
          if (m != null) _change(() => onPicked(m));
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                IconSquare(
                  icon,
                  background: bg,
                  foreground: iconFg,
                  radius: 12,
                ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        formatMinuteOfDay(minute),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(
              title: l10n.sleepTitle,
              subtitle: l10n.sleepLastNight(
                DateFormat('EEE d').format(addDays(day, -1)),
                DateFormat('EEE d MMM').format(day),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        spacing: 2,
                        children: [
                          Text(
                            l10n.sleepAsleep,
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: fg,
                            ),
                          ),
                          Text(
                            l10n.duration(night),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall!.copyWith(
                              fontSize: 44,
                              height: 52 / 44,
                              fontWeight: FontWeight.w800,
                              color: fg,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            _nap == 0
                                ? l10n.sleepNoNaps
                                : l10n.sleepWithNaps(
                                    l10n.duration(night + _nap),
                                  ),
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        timeRow(
                          NavmaasIcon.moon,
                          scheme.tertiaryContainer,
                          scheme.onTertiaryContainer,
                          l10n.sleepWentToBed,
                          _bed,
                          (m) => _bed = m,
                        ),
                        const Divider(height: 1),
                        timeRow(
                          NavmaasIcon.sun,
                          colors.amberSoft,
                          colors.onAmberSoft,
                          l10n.sleepWokeUp,
                          _woke,
                          (m) => _woke = m,
                        ),
                        const Divider(height: 1),
                        StepperRow(
                          title: l10n.sleepNaps,
                          hint: l10n.sleepNapsHint,
                          value: _nap == 0
                              ? l10n.napNone
                              : l10n.minutesShort(_nap),
                          lessTooltip: l10n.napLess,
                          moreTooltip: l10n.napMore,
                          onLess: _nap == 0
                              ? null
                              : () => _change(() => _nap -= _napStep),
                          onMore: _nap >= _maxNap
                              ? null
                              : () => _change(() => _nap += _napStep),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionTitle(l10n.sleepHowRested),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in Rested.values)
                        WordChip(
                          label: l10n.rested(r),
                          selected: _rested == r,
                          large: true,
                          onTap: () =>
                              _change(() => _rested = _rested == r ? null : r),
                        ),
                    ],
                  ),
                  if (average != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.sleepWeekLine(l10n.duration(average)),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
