import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/motion.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "Today's gentle plan" (prototype Today). M3: today's supplement doses;
/// reading and walk items join in M4.
class TodayPlanCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final day = localDay(ref.watch(todayProvider));
    final slots = slotsOn(
      day,
      ref.watch(supplementPlansProvider).value ?? const [],
    );
    final taken =
        ref
            .watch(takenDosesProvider(day, day.add(const Duration(days: 1))))
            .value ??
        const {};
    final done = slots.where((s) => taken.contains(s.key)).length;

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
            if (slots.isNotEmpty)
              Text(
                l10n.planDone(done, slots.length),
                style: text.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.outline,
                ),
              ),
          ],
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: slots.isEmpty
              ? InkWell(
                  onTap: () => context.go('/care/supplements/edit'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      spacing: 12,
                      children: [
                        pillTile(scheme),
                        Expanded(
                          child: Text(
                            l10n.planEmpty,
                            style: text.bodyMedium!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, slot) in slots.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _PlanRow(
                        slot: slot,
                        done: taken.contains(slot.key),
                        onToggle: () => ref
                            .read(supplementRepositoryProvider)
                            .setTaken(
                              slot.schedule.id,
                              slot.dueAt,
                              taken: !taken.contains(slot.key),
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

class _PlanRow extends StatelessWidget {
  const new({required this.slot, required this.done, required this.onToggle});

  final DoseSlot slot;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = slot.supplement.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go('/care/supplements'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  spacing: 12,
                  children: [
                    pillTile(scheme),
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
                            doseSubtitle(slot),
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
            button: true,
            toggled: done,
            label: done ? l10n.doneName(name) : l10n.markDone(name),
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
