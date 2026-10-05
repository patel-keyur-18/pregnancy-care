import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/features/care/domain/supplement_reminders.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care tab (prototype "Care"). M3a: supplements today. Tests, visits and
/// vitals join in M3b; kick counter and contraction timer in M5.
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
