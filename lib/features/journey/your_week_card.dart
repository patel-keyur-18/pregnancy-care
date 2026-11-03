import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/journey/data/week_report_data.dart';
import 'package:navmaas/features/sessions/presentation/walk_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Journey's "Your week" (E7, Plan decision 83): what she logged in [week],
/// values only. Supplements, walks and exercise first; Show more opens the
/// rest (owner, 2026-11-03). Nothing for a week still to come.
class YourWeekCard extends ConsumerStatefulWidget {
  const new({
    required this.week,
    required this.isCurrent,
    required this.firstDay,
    super.key,
  });

  final int week;
  final bool isCurrent;

  /// The week's first date (UTC midnight), for its date range.
  final DateTime firstDay;

  @override
  ConsumerState<YourWeekCard> createState() => _YourWeekCardState();
}

typedef _Row = ({NavmaasIcon icon, String title, String value, int tone});

class _YourWeekCardState extends ConsumerState<YourWeekCard> {
  var _more = false;

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(weekReportOfProvider(widget.week));
    if (r == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String time(int m) =>
        m < 60 ? l10n.minutesShort(m) : l10n.hoursMinutes(m ~/ 60, m % 60);
    final dates = DateFormat('d MMM');
    final last = widget.firstDay.add(const Duration(days: 6));

    // Tones: 0 rose, 1 sage, 2 lavender (as on the board).
    final first = <_Row>[
      if (r.dosesDue > 0)
        (
          icon: NavmaasIcon.pill,
          title: l10n.yourWeekSupplements,
          value: l10n.yourWeekDosesTaken(r.dosesTaken, r.dosesDue),
          tone: 0,
        ),
      if (r.walkDays > 0 || r.walkMinutes > 0)
        (
          icon: NavmaasIcon.walk,
          title: l10n.yourWeekWalks,
          value: [
            l10n.yourWeekDays(r.walkDays),
            if (r.walkMinutes > 0) time(r.walkMinutes),
            if (r.steps case final s? when s > 0)
              l10n.yourWeekSteps(formatSteps(s)),
          ].join(' · '),
          tone: 1,
        ),
      if (r.exerciseSessions > 0)
        (
          icon: NavmaasIcon.pelvic,
          title: l10n.yourWeekExercise,
          value:
              '${l10n.yourWeekSessions(r.exerciseSessions)} · '
              '${time(r.exerciseMinutes)}',
          tone: 1,
        ),
    ];
    final rest = <_Row>[
      for (final (icon, title, minutes, tone) in [
        (NavmaasIcon.book, l10n.yourWeekReading, r.readingMinutes, 2),
        (NavmaasIcon.headphones, l10n.yourWeekListening, r.listeningMinutes, 2),
        (NavmaasIcon.lotus, l10n.yourWeekMeditation, r.meditationMinutes, 2),
        (NavmaasIcon.breath, l10n.yourWeekBreathing, r.breathingMinutes, 1),
      ])
        if (minutes > 0)
          (icon: icon, title: title, value: time(minutes), tone: tone),
      if (r.waterAverage case final w?)
        (
          icon: NavmaasIcon.drop,
          title: l10n.yourWeekWater,
          value: l10n.yourWeekWaterAverage(w),
          tone: 1,
        ),
      if (r.sleepAverage case final s?)
        (
          icon: NavmaasIcon.bed,
          title: l10n.yourWeekSleep,
          value: l10n.yourWeekSleepAverage(time(s)),
          tone: 2,
        ),
      if (r.moods.isNotEmpty)
        (
          icon: NavmaasIcon.heart,
          title: l10n.yourWeekMood,
          value: [
            for (final (m, n) in r.moods)
              l10n.yourWeekMoodCount(l10n.mood(m), n),
          ].join(' · '),
          tone: 0,
        ),
    ];
    // With none of the first three, the rest show straight away.
    final open = _more || first.isEmpty;
    final shown = [...first, if (open) ...rest];

    Widget row(_Row row) {
      final (bg, fg) = switch (row.tone) {
        0 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
        1 => (scheme.primaryContainer, scheme.onPrimaryContainer),
        _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      };
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            spacing: 12,
            children: [
              IconTile(
                background: bg,
                child: NmIcon(row.icon, size: 20, color: fg),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      row.value,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.isCurrent
                    ? l10n.yourWeekSoFar
                    : l10n.yourWeekTitle(widget.week),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              widget.isCurrent
                  ? l10n.yourWeekDatesToday(dates.format(widget.firstDay))
                  : l10n.yourWeekDates(
                      dates.format(widget.firstDay),
                      dates.format(last),
                    ),
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.outline,
              ),
            ),
          ],
        ),
        if (r.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.yourWeekNothing,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            semanticContainer: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, r) in shown.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Semantics(container: true, child: row(r)),
                ],
                if (first.isNotEmpty && rest.isNotEmpty) ...[
                  const Divider(height: 1),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () => setState(() => _more = !_more),
                    iconAlignment: IconAlignment.end,
                    icon: RotatedBox(
                      quarterTurns: _more ? 3 : 1,
                      child: NmIcon(
                        NavmaasIcon.chevronRight,
                        size: 18,
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                    label: Text(
                      _more
                          ? l10n.yourWeekShowLess
                          : l10n.yourWeekShowMore(rest.length),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
