import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/care_repository.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/domain/supplement_reminders.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/care/presentation/tests_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care tab (prototype "Care"): supplements today, coming up (visits,
/// tests, scans, vaccines) and vitals. Kick counter and contraction timer
/// tiles join in M5.
class CareScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          24,
          AppTheme.gutter,
          24,
        ),
        children: [
          Text(
            l10n.careOverline,
            style: text.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.outline,
            ),
          ),
          Semantics(
            header: true,
            child: Text(l10n.tabCare, style: text.headlineSmall),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.supplementsToday, style: text.titleMedium),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/care/supplements'),
                child: Text(l10n.seeAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const TodaySupplementsCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.comingUp, style: text.titleMedium),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/care/tests'),
                child: Text(l10n.seeAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _ComingUpCard(),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(l10n.vitalsLogged, style: text.titleMedium),
          ),
          const SizedBox(height: 10),
          const _VitalsRow(),
        ],
      ),
    );
  }
}

/// Today's doses with Take / Taken, or a gentle prompt to add supplements.
class TodaySupplementsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = localDay(ref.watch(todayProvider));
    final plans = ref.watch(supplementPlansProvider).value ?? const [];
    final taken =
        ref
            .watch(takenDosesProvider(day, day.add(const Duration(days: 1))))
            .value ??
        const {};
    final slots = slotsOn(day, plans);
    if (slots.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                l10n.noSupplements,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              FilledButton.tonal(
                onPressed: () => context.go('/care/supplements/edit'),
                child: Text(l10n.addButton),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, slot) in slots.indexed) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.supplement.name,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: taken.contains(slot.key)
                                ? scheme.outline
                                : scheme.onSurface,
                          ),
                        ),
                        Text(
                          doseSubtitle(slot),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TakeButton(
                    name: slot.supplement.name,
                    taken: taken.contains(slot.key),
                    onPressed: () => ref
                        .read(supplementRepositoryProvider)
                        .setTaken(
                          slot.schedule.id,
                          slot.dueAt,
                          taken: !taken.contains(slot.key),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "1 tablet · after breakfast", or the time when neither is set.
String doseSubtitle(DoseSlot slot) {
  final line = doseLine(slot);
  return line.isEmpty ? formatMinuteOfDay(slot.schedule.minuteOfDay) : line;
}

/// The prototype's rose pill tile.
Widget pillTile(ColorScheme scheme) => IconTile(
  background: scheme.secondaryContainer,
  child: NmIcon(NavmaasIcon.pill, size: 20, color: scheme.onSecondaryContainer),
);

/// The next visit and the tests / vaccines due around now (prototype Care).
class _ComingUpCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final week = currentWeek(ref);
    final notes = careNotes(ref);
    final visit = (ref.watch(appointmentsProvider).value ?? const [])
        .where((a) => a.at.isAfter(now))
        .firstOrNull;
    final waiting = (ref.watch(visitQuestionsProvider).value ?? const [])
        .where((q) => q.appointmentId == null && q.askedAt == null)
        .length;
    final items = [
      for (final i in ref.watch(careItemsProvider).value ?? const <CareItem>[])
        if (i.doneAt == null &&
            ((i.scheduledAt?.isAfter(now) ?? false) ||
                (week >= i.fromWeek - 2 && week <= i.toWeek)))
          i,
    ].take(3).toList();

    final rows = <Widget>[
      if (visit != null)
        () {
          final (icon, bg, fg) = careStyle(context, null);
          return CareRow(
            icon: icon,
            background: bg,
            foreground: fg,
            title: [l10n.visitTitle, ?visit.doctor].join(' · '),
            subtitle:
                '${formatDateTime(visit.at)} · ${l10n.questionsReady(waiting)}',
            trailing: NmIcon(
              NavmaasIcon.chevronRight,
              size: 20,
              strokeWidth: 2,
              color: scheme.outline,
            ),
            onTap: () => context.go('/care/visit', extra: visit.id),
          );
        }(),
      for (final item in items)
        () {
          final (icon, bg, fg) = careStyle(context, item.kind);
          return CareRow(
            icon: icon,
            background: bg,
            foreground: fg,
            title: item.title,
            subtitle: careSubtitle(l10n, item, week),
            trailing: item.scheduledAt == null
                ? ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: context.navmaas.amberSoft,
                        shape: const StadiumBorder(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.bookChip,
                          style: theme.textTheme.labelSmall!.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.navmaas.onAmberSoft,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            onTap: () => showCareItemSheet(
              context,
              ref,
              item,
              note: notes[item.templateKey],
            ),
          );
        }(),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.nothingComingUp,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            row,
          ],
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton.icon(
                onPressed: () => context.go('/care/visit-edit'),
                icon: NmIcon(
                  NavmaasIcon.plus,
                  size: 18,
                  strokeWidth: 2.2,
                  color: scheme.primary,
                ),
                label: Text(l10n.addVisit),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Latest weight and blood pressure with "Log" buttons (prototype Care).
class _VitalsRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weights =
        ref.watch(vitalsProvider(VitalKind.weight)).value ?? const [];
    final bp =
        ref.watch(vitalsProvider(VitalKind.bloodPressure)).value ?? const [];
    String kg(double v) => v.toStringAsFixed(1);
    final change = weights.length < 2
        ? null
        : weights.last.value1 - weights.first.value1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Expanded(
            child: _VitalTile(
              label: l10n.weight,
              value: weights.isEmpty
                  ? null
                  : l10n.weightKg(kg(weights.last.value1)),
              detail: change == null
                  ? (weights.isEmpty
                        ? l10n.notLoggedYet
                        : l10n.loggedOn(formatShortDate(weights.last.at)))
                  : l10n.weightChange(
                      '${change >= 0 ? '+' : '−'}${kg(change.abs())}',
                    ),
              action: l10n.logWeight,
              onLog: () => logVital(context, ref, VitalKind.weight),
            ),
          ),
          Expanded(
            child: _VitalTile(
              label: l10n.bloodPressure,
              value: bp.isEmpty
                  ? null
                  : '${bp.last.value1.round()}/${bp.last.value2?.round()}',
              detail: bp.isEmpty
                  ? l10n.notLoggedYet
                  : l10n.loggedOn(formatShortDate(bp.last.at)),
              action: l10n.logBp,
              onLog: () => logVital(context, ref, VitalKind.bloodPressure),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.detail,
    required this.action,
    required this.onLog,
  });

  final String label;
  final String? value;
  final String detail;
  final String action;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.outline,
              ),
            ),
            Text(
              value ?? '—',
              style: theme.textTheme.headlineSmall!.copyWith(
                fontSize: 24,
                height: 30 / 24,
              ),
            ),
            Text(
              detail,
              style: theme.textTheme.bodySmall!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
                side: BorderSide(color: scheme.outlineVariant),
                minimumSize: const Size(48, 48),
                textStyle: theme.textTheme.labelLarge,
              ),
              onPressed: onLog,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
