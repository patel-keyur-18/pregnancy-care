import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/nutrition/data/nourishly_meals.dart';
import 'package:navmaas/features/nutrition/domain/nourishly_share.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The strip's last day after moving [days] from [end] (null: [today]).
/// Reaching today gives null again, so the strip follows the date past
/// midnight while Nutrition stays open.
DateTime? stepWeek(DateTime? end, int days, DateTime today) {
  final next = addDays(end ?? today, days);
  return next.isBefore(today) ? next : null;
}

/// The day shown after tapping [day]: null for [today], so the selection
/// follows the date past midnight like the strip.
DateTime? pickDay(DateTime day, DateTime today) => day == today ? null : day;

/// Care → Nutrition → From Nourishly (M8b): the meals and day totals she
/// logged in Nourishly, a week at a time. Values only; nothing is stored.
class NourishlySection extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NourishlySection> createState() => _NourishlySectionState();
}

class _NourishlySectionState extends ConsumerState<NourishlySection> {
  /// The strip's last day and the day shown; null means today.
  DateTime? _end;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    // Read again on open: Nourishly may still have been writing when
    // Navmaas came back to the front.
    unawaited(Future.microtask(() => ref.invalidate(nourishlyShareProvider)));
  }

  void _week(int days, DateTime today) {
    final end = stepWeek(_end, days, today);
    setState(() => _end = _selected = end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = theme.extension<NavmaasColors>()!;
    final today = ref.watch(todayProvider);
    final read = ref.watch(nourishlyShareProvider);
    final calm = theme.textTheme.bodyMedium!.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.nourishlyTitle, style: theme.textTheme.titleMedium),
        ),
        switch (read) {
          AsyncData(value: null) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.nourishlyNotShared, style: calm),
            ),
          ),
          AsyncError() => DecoratedBox(
            decoration: BoxDecoration(
              color: brand.amberSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.nourishlyUnreadable,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: brand.onAmberSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AsyncData(value: final share?) => _Shared(
            share: share,
            today: today,
            end: _end ?? today,
            selected: _selected ?? today,
            onPick: (day) => setState(() => _selected = pickDay(day, today)),
            onWeek: (days) => _week(days, today),
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _Shared extends StatelessWidget {
  const new({
    required this.share,
    required this.today,
    required this.end,
    required this.selected,
    required this.onPick,
    required this.onWeek,
  });

  final NourishlyShare share;
  final DateTime today;
  final DateTime end;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  final ValueChanged<int> onWeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = addDays(end, -6);
    final day = share.day(selected);
    final at = share.generatedAt;
    final time = DateFormat('h:mm a').format(at).toLowerCase();
    final atDay = DateTime.utc(at.year, at.month, at.day);
    final short = DateFormat('EEE d MMM');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.nourishlyEarlier,
              onPressed: () => onWeek(-7),
              icon: const NmIcon(NavmaasIcon.chevronLeft, size: 20),
            ),
            Expanded(
              child: Text(
                l10n.nourishlyRange(short.format(start), short.format(end)),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.nourishlyLater,
              onPressed: end == today ? null : () => onWeek(7),
              icon: const NmIcon(NavmaasIcon.chevronRight, size: 20),
            ),
          ],
        ),
        // Seven chips of at least 48 dp need 336 dp: on a 360 dp phone the
        // strip reaches 12 dp into each gutter.
        LayoutBuilder(
          builder: (context, constraints) => OverflowBox(
            fit: OverflowBoxFit.deferToChild,
            minWidth: constraints.maxWidth + 24,
            maxWidth: constraints.maxWidth + 24,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayChip(
                      day: addDays(start, i),
                      selected: addDays(start, i) == selected,
                      isToday: addDays(start, i) == today,
                      hasMeals:
                          share.day(addDays(start, i))?.meals.isNotEmpty ??
                          false,
                      onTap: () => onPick(addDays(start, i)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: day == null || day.meals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.nourishlyNoMeals,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _Day(day: day),
        ),
        Text(
          l10n.nourishlyUpdated(
            atDay == today ? time : '${formatShortDate(atDay)}, $time',
          ),
          style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const new({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasMeals,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasMeals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: formatDate(day),
      // The InkWell's tap is excluded with its semantics: give it back.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('nourishly-day-${DateFormat('yyyy-MM-dd').format(day)}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              FittedBox(
                child: Text(
                  DateFormat('EEEEE').format(day),
                  style: theme.textTheme.labelSmall!.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.outline,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? scheme.primaryContainer
                      : Colors.transparent,
                  border: Border.all(
                    color: isToday ? scheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '${day.day}',
                      style: theme.textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasMeals ? scheme.primary : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One day: its meals, then the day totals Nourishly had data for.
class _Day extends StatelessWidget {
  const new({required this.day});

  final NourishlyDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String label(String id) => switch (id) {
      'energy' => l10n.nourishlyEnergy,
      'protein' => l10n.nourishlyProtein,
      'iron' => l10n.nourishlyIron,
      'calcium' => l10n.nourishlyCalcium,
      'folate' => l10n.nourishlyFolate,
      _ => l10n.nourishlyFibre,
    };
    String unit(String id) => switch (id) {
      'energy' => l10n.nourishlyUnitKcal,
      'iron' || 'calcium' => l10n.nourishlyUnitMg,
      'folate' => l10n.nourishlyUnitUg,
      _ => l10n.nourishlyUnitG,
    };
    final ids = [
      for (final id in nourishlyNutrients)
        if (day.totals.containsKey(id)) id,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, meal) in day.meals.indexed) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  meal.slot,
                  style: theme.textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                for (final item in meal.items)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.amount,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
        if (ids.isNotEmpty)
          ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    l10n.nourishlyTotals,
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.outline,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in ids)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Wrap(
                              spacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  label(id),
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: scheme.outline,
                                  ),
                                ),
                                Text(
                                  '${formatNutrient(day.totals[id]!)} '
                                  '${unit(id)}',
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (day.partial.isNotEmpty)
                    Text(
                      l10n.nourishlyPartial(
                        [
                          for (final id in ids)
                            if (day.partial.contains(id)) label(id),
                        ].join(', '),
                      ),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
