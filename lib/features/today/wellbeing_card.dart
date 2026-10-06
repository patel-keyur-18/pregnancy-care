import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/widgets/step_button.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/presentation/water_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Today's "How are you today?" card (prototype Today): the five mood words
/// and water taps. Shown while today has no mood or water is under the goal;
/// hidden for the rest of the day when she closes it (Plan decision 44).
class WellbeingCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final day = ref.watch(wellbeingWeekProvider).first;
    final goal = ref.watch(waterGoalProvider).value ?? defaultWaterGoal;
    final settings = ref.watch(settingsRepositoryProvider);
    final hidden = ref.watch(wellbeingCardHiddenProvider).value;
    final todayKey = today.toIso8601String().substring(0, 10);
    if (hidden == todayKey || (day.mood != null && day.glasses >= goal)) {
      return const SizedBox.shrink();
    }

    void setMood(MoodWord m) {
      final id = ref.read(activePregnancyProvider).value?.id;
      if (id == null) return;
      unawaited(
        ref
            .read(wellbeingRepositoryProvider)
            .setMood(
              pregnancyId: id,
              day: today,
              mood: m,
              note: day.mood?.note,
            ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SectionTitle(l10n.moodQuestion)),
                  IconButton(
                    tooltip: l10n.hideForToday,
                    onPressed: () => unawaited(
                      settings.put(SettingKeys.wellbeingCardHidden, todayKey),
                    ),
                    icon: NmIcon(
                      NavmaasIcon.close,
                      size: 18,
                      strokeWidth: 2,
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Semantics(
                  label: l10n.moodChoice,
                  container: true,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in MoodWord.values)
                        WordChip(
                          label: l10n.mood(m),
                          selected: day.mood?.mood == m,
                          onTap: () => setMood(m),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Divider(height: 1, color: scheme.outlineVariant),
              ),
              const SizedBox(height: 12),
              Row(
                spacing: 12,
                children: [
                  IconSquare(
                    NavmaasIcon.drop,
                    background: scheme.primaryContainer,
                    foreground: scheme.onPrimaryContainer,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.waterTitle,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.waterOfGoal(day.glasses, goal),
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StepButton(
                    symbol: '−',
                    tooltip: l10n.waterRemove,
                    onPressed: day.glasses == 0
                        ? null
                        : () => addGlass(ref, -1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton.filled(
                      tooltip: l10n.waterAdd,
                      onPressed: () => addGlass(ref, 1),
                      icon: const NmIcon(
                        NavmaasIcon.plus,
                        size: 18,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
