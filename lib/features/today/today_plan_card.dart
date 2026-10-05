import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/motion.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/presentation/library_actions.dart';
import 'package:navmaas/features/sessions/presentation/sessions_screen.dart';
import 'package:navmaas/features/sessions/presentation/walk_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "Today's gentle plan" (prototype Today): today's supplement doses, a
/// reading session once there's a book, and a gentle walk.
class TodayPlanCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final day = localDay(ref.watch(todayProvider));
    final tomorrow = day.add(const Duration(days: 1));
    final slots = slotsOn(
      day,
      ref.watch(supplementPlansProvider).value ?? const [],
    );
    final taken =
        ref.watch(takenDosesProvider(day, tomorrow)).value ?? const {};
    final book = (ref.watch(libraryItemsProvider).value ?? const [])
        .where((i) => i.kind != LibraryKind.audio)
        .firstOrNull;
    final todaySessions =
        ref.watch(sessionsBetweenProvider(day, tomorrow)).value ?? const [];
    final readToday = todaySessions.any((s) => s.type == SessionType.reading);
    final walkedToday = todaySessions.any((s) => s.type == SessionType.walk);

    final rows = <Widget>[
      for (final slot in slots)
        _PlanRow(
          tile: pillTile(scheme),
          title: slot.supplement.name,
          subtitle: doseSubtitle(slot),
          done: taken.contains(slot.key),
          onOpen: () => context.go('/care/supplements'),
          onToggle: () => ref
              .read(supplementRepositoryProvider)
              .setTaken(
                slot.schedule.id,
                slot.dueAt,
                taken: !taken.contains(slot.key),
              ),
        ),
      if (book != null)
        _PlanRow(
          tile: IconTile(
            background: scheme.tertiaryContainer,
            child: NmIcon(
              NavmaasIcon.book,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
          ),
          title: l10n.planReading,
          subtitle: l10n.minutesTitle(readGoalMinutes, book.title),
          done: readToday,
          onOpen: () => openLibraryItem(context, book),
        ),
      // Walking is always open (Plan decision 27).
      _PlanRow(
        tile: IconTile(
          background: scheme.primaryContainer,
          child: NmIcon(
            NavmaasIcon.walk,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: l10n.walkTitle,
        subtitle: l10n.walkEasy(walkGoalMinutes),
        done: walkedToday,
        onOpen: () => context.push('/walk'),
      ),
    ];
    final done = [
      for (final s in slots) taken.contains(s.key),
      if (book != null) readToday,
      walkedToday,
    ].where((d) => d).length;

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
              child: Text(l10n.planTitle, style: text.titleMedium),
            ),
            Text(
              l10n.planDone(done, rows.length),
              style: text.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.outline,
              ),
            ),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) const Divider(height: 1),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One plan item. [onToggle] ticks it by hand (supplements); without it
/// the circle only shows whether it's done (reading is ticked by a session).
class _PlanRow extends StatelessWidget {
  const new({
    required this.tile,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onOpen,
    this.onToggle,
  });

  final Widget tile;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onOpen;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  spacing: 12,
                  children: [
                    tile,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: done ? scheme.outline : scheme.onSurface,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: scheme.outline,
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
          Semantics(
            // Its own node: Cards merge their children otherwise.
            container: true,
            button: onToggle != null,
            toggled: onToggle == null ? null : done,
            label: done
                ? l10n.doneName(name)
                : onToggle == null
                ? ''
                : l10n.markDone(name),
            excludeSemantics: true,
            child: PressScale(
              child: InkResponse(
                onTap: onToggle,
                radius: 24,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0),
                        border: Border.all(
                          color: done ? scheme.primary : scheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? DrawOnIcon(
                              NavmaasIcon.check,
                              active: done,
                              size: 16,
                              strokeWidth: 3,
                              color: scheme.onPrimary,
                              duration: const Duration(milliseconds: 250),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
