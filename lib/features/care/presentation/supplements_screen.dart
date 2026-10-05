import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// All supplements (prototype "Supplements"): this week's doses, then each
/// time of day with Take / Taken, notes and low stock.
class SupplementsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final today = localDay(ref.watch(todayProvider));
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final plans = ref.watch(supplementPlansProvider).value ?? const [];
    final taken =
        ref
            .watch(
              takenDosesProvider(monday, monday.add(const Duration(days: 7))),
            )
            .value ??
        const {};
    final days = adherence(week, plans, taken);
    final soFar = days.where((d) => !d.day.isAfter(today));

    // Rows: each supplement at each of its times, grouped by time of day.
    final groups = <String, List<(SupplementPlan, SupplementSchedule)>>{};
    for (final p in plans) {
      for (final s in p.schedules) {
        final group = s.minuteOfDay < 12 * 60
            ? l10n.timeMorning
            : s.minuteOfDay < 17 * 60
            ? l10n.timeAfternoon
            : l10n.timeNight;
        groups.putIfAbsent(group, () => []).add((p, s));
      }
    }
    final ordered = [
      for (final g in [l10n.timeMorning, l10n.timeAfternoon, l10n.timeNight])
        if (groups[g] case final rows?) (g, rows),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supplementsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => context.go('/care/supplements/edit'),
              icon: NmIcon(
                NavmaasIcon.plus,
                size: 16,
                strokeWidth: 2.4,
                color: scheme.onPrimary,
              ),
              label: Text(l10n.addButton),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          28,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      Text(
                        l10n.thisWeek,
                        style: text.titleMedium!.copyWith(fontSize: 16),
                      ),
                      Text(
                        l10n.weekDoses(
                          soFar.fold(0, (n, d) => n + d.taken),
                          soFar.fold(0, (n, d) => n + d.due),
                        ),
                        style: text.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (final d in days)
                        Expanded(
                          child: _DayDot(
                            day: d.day,
                            due: d.due,
                            taken: d.taken,
                            isToday: d.day == today,
                            future: d.day.isAfter(today),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final (title, rows) in ordered) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                title,
                style: text.labelLarge!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final (plan, schedule) in rows) ...[
              _SupplementCard(plan: plan, schedule: schedule, today: today),
              const SizedBox(height: 10),
            ],
          ],
          if (plans.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.noSupplements,
              style: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.supplementsFooter,
            style: text.bodySmall!.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const new({
    required this.day,
    required this.due,
    required this.taken,
    required this.isToday,
    required this.future,
  });

  final DateTime day;
  final int due;
  final int taken;
  final bool isToday;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final full = due > 0 && taken == due && !future;
    final part = taken > 0 && taken < due;
    final label = due == 0 || (future && !isToday) ? '' : '$taken/$due';
    return Semantics(
      // Its own node: Cards merge their children otherwise.
      container: true,
      label: '${DateFormat('EEEE').format(day)} $label',
      excludeSemantics: true,
      child: Column(
        spacing: 6,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: full
                  ? scheme.primary
                  : part
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
                  label,
                  style: theme.textTheme.labelSmall!.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: full ? scheme.onPrimary : scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          Text(
            DateFormat('EEEEE').format(day),
            style: theme.textTheme.labelSmall!.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplementCard extends ConsumerWidget {
  const new({required this.plan, required this.schedule, required this.today});

  final SupplementPlan plan;
  final SupplementSchedule schedule;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.navmaas;
    final s = plan.supplement;
    final slot = slotsOn(today, [
      (supplement: s, schedules: [schedule]),
    ]).firstOrNull;
    final taken =
        ref
            .watch(
              takenDosesProvider(today, today.add(const Duration(days: 1))),
            )
            .value ??
        const {};
    final isTaken = slot != null && taken.contains(slot.key);
    final (stock, refillAt) = (s.stock, s.refillAt);
    final low = stock != null && refillAt != null && stock <= refillAt;
    final line = [
      formatMinuteOfDay(schedule.minuteOfDay),
      s.doseText,
      schedule.label ?? '',
    ].where((x) => x.isNotEmpty).join(' · ');

    Widget box(Color bg, Color fg, String message, {Widget? leading}) =>
        DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                ?leading,
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/care/supplements/edit', extra: s.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Row(
                spacing: 12,
                children: [
                  pillTile(scheme),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isTaken ? scheme.outline : scheme.onSurface,
                          ),
                        ),
                        Text(
                          line,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (slot != null)
                    TakeButton(
                      name: s.name,
                      taken: isTaken,
                      onPressed: () => ref
                          .read(supplementRepositoryProvider)
                          .setTaken(schedule.id, slot.dueAt, taken: !isTaken),
                    ),
                ],
              ),
              if (s.notes case final note?)
                box(
                  scheme.surfaceContainerHighest,
                  scheme.onSurfaceVariant,
                  l10n.yourNote(note),
                ),
              if (low)
                box(
                  brand.amberSoft,
                  brand.onAmberSoft,
                  l10n.refillLow(stock),
                  leading: NmIcon(
                    NavmaasIcon.bell,
                    size: 16,
                    strokeWidth: 2,
                    color: brand.onAmberSoft,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
