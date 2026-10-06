import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/domain/week.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care → Wellbeing (prototype "Wellbeing"): today's four logs and the last
/// 7 days. Only what she wrote: no scores, colours or verdicts.
class WellbeingScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final week = ref.watch(wellbeingWeekProvider);
    final goal = ref.watch(waterGoalProvider).value ?? defaultWaterGoal;
    final today = week.first;
    final symptoms = today.symptoms;

    Widget tile(
      NavmaasIcon icon,
      Color bg,
      Color fg,
      String label,
      String value,
      String route,
    ) => Expanded(
      child: _Tile(
        icon: IconSquare(icon, background: bg, foreground: fg),
        label: label,
        value: value,
        onTap: () => context.push(route),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(
              title: l10n.wellbeingTitle,
              subtitle: l10n.wellbeingSubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  SectionTitle(l10n.dayToday),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        tile(
                          NavmaasIcon.heart,
                          scheme.secondaryContainer,
                          scheme.onSecondaryContainer,
                          l10n.moodTitle,
                          today.mood == null
                              ? l10n.wellbeingNotYet
                              : l10n.mood(today.mood!.mood),
                          '/wellbeing/mood',
                        ),
                        tile(
                          NavmaasIcon.notes,
                          scheme.surfaceContainerHighest,
                          scheme.onSurfaceVariant,
                          l10n.symptomsTitle,
                          switch (symptoms.length) {
                            0 => l10n.wellbeingNotYet,
                            1 => l10n.symptomWithSeverity(
                              l10n.symptomName(symptoms.single),
                              l10n
                                  .severity(symptoms.single.severity)
                                  .toLowerCase(),
                            ),
                            _ => l10n.symptomsLogged(symptoms.length),
                          },
                          '/wellbeing/symptoms',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        tile(
                          NavmaasIcon.bed,
                          scheme.tertiaryContainer,
                          scheme.onTertiaryContainer,
                          l10n.sleepTitle,
                          today.sleep == null
                              ? l10n.wellbeingNotYet
                              : l10n.duration(sleepMinutes(today.sleep!)),
                          '/wellbeing/sleep',
                        ),
                        tile(
                          NavmaasIcon.drop,
                          scheme.primaryContainer,
                          scheme.onPrimaryContainer,
                          l10n.waterTitle,
                          l10n.waterOfGoal(today.glasses, goal),
                          '/wellbeing/water',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SleepWeekCard(week),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: SectionTitle(l10n.yourWeek)),
                      Text(
                        l10n.dateRange(
                          DateFormat('d MMM').format(week.last.day),
                          DateFormat('d MMM').format(today.day),
                        ),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, d) in week.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _DayRow(day: d, isToday: i == 0, goal: goal),
                        ],
                      ],
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
}

class _Tile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                icon,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The weekly sleep average, naps included (Plan decision 44).
class _SleepWeekCard extends StatelessWidget {
  const new(this.week);

  final List<WellbeingDay> week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onTertiaryContainer;
    final nights = [for (final d in week) ?d.sleep];
    final average = averageSleepMinutes(nights);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: [
            IconSquare(
              NavmaasIcon.moon,
              background: scheme.surface,
              foreground: scheme.tertiary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sleepWeekTitle,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  if (average == null)
                    Text(
                      l10n.sleepWeekNone,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    )
                  else ...[
                    Text(
                      l10n.sleepWeekAverage(l10n.duration(average)),
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontSize: 20,
                        height: 26 / 20,
                        color: fg,
                      ),
                    ),
                    Text(
                      l10n.sleepWeekNights(nights.length),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One day of the week: the mood word, sleep and water, then symptoms.
class _DayRow extends StatelessWidget {
  const new({required this.day, required this.isToday, required this.goal});

  final WellbeingDay day;
  final bool isToday;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final line = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    final facts = [
      if (day.sleep != null)
        l10n.weekSleep(l10n.duration(sleepMinutes(day.sleep!))),
      if (day.glasses > 0) l10n.weekWater(day.glasses, goal),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? l10n.dayToday : DateFormat('EEE').format(day.day),
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  DateFormat(isToday ? 'EEE d MMM' : 'd MMM').format(day.day),
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                if (day.isEmpty)
                  Text(
                    l10n.nothingLogged,
                    style: line.copyWith(color: scheme.outline),
                  ),
                if (day.mood != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        l10n.mood(day.mood!.mood),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                if (facts.isNotEmpty) Text(facts.join(' · '), style: line),
                if (day.symptoms.isNotEmpty)
                  Text(
                    day.symptoms
                        .map(
                          (s) => l10n.symptomInWeek(
                            l10n.symptomName(s),
                            l10n.severity(s.severity).toLowerCase(),
                          ),
                        )
                        .join(' · '),
                    style: line,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
