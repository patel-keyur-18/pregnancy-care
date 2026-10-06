import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/core/widgets/step_button.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Adds or takes away one glass today for the active pregnancy.
void addGlass(WidgetRef ref, int delta) {
  final id = ref.read(activePregnancyProvider).value?.id;
  if (id == null) return;
  unawaited(
    ref
        .read(wellbeingRepositoryProvider)
        .addWater(pregnancyId: id, day: ref.read(todayProvider), delta: delta),
  );
}

/// Water (prototype "Water"): a glass at a time toward the goal she sets,
/// and optional reminders, which are nudges and off by default (Plan
/// decision 41).
class WaterScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = ref.watch(wellbeingWeekProvider).first.glasses;
    final goal = ref.watch(waterGoalProvider).value ?? defaultWaterGoal;
    final rules =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    final settings = ref.read(settingsRepositoryProvider);
    final fg = scheme.onPrimaryContainer;

    void setGoal(int g) => unawaited(settings.put(SettingKeys.waterGoal, '$g'));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(title: l10n.waterTitle, subtitle: l10n.waterSubtitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        spacing: 14,
                        children: [
                          Semantics(
                            label: l10n.waterOfGoal(count, goal),
                            excludeSemantics: true,
                            child: Column(
                              children: [
                                Text(
                                  l10n.waterCount(count, goal),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.displaySmall!.copyWith(
                                    fontSize: 52,
                                    height: 58 / 52,
                                    fontWeight: FontWeight.w800,
                                    color: fg,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  l10n.waterGlassesToday,
                                  style: theme.textTheme.bodyLarge!.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: fg,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (var i = 0; i < goal || i < count; i++)
                                      NmIcon(
                                        NavmaasIcon.drop,
                                        size: 26,
                                        color: scheme.primary,
                                        fillColor: i < count
                                            ? scheme.primary
                                            : null,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            spacing: 10,
                            children: [
                              StepButton(
                                symbol: '−',
                                tooltip: l10n.waterRemove,
                                onPressed: count == 0
                                    ? null
                                    : () => addGlass(ref, -1),
                              ),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => addGlass(ref, 1),
                                  icon: const NmIcon(
                                    NavmaasIcon.plus,
                                    size: 18,
                                    strokeWidth: 2.4,
                                  ),
                                  label: Text(l10n.waterAdd),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: StepperRow(
                      title: l10n.waterGoalTitle,
                      hint: l10n.waterGoalHint,
                      value: l10n.waterGoalValue(goal),
                      lessTooltip: l10n.goalLower,
                      moreTooltip: l10n.goalRaise,
                      onLess: goal <= minWaterGoal
                          ? null
                          : () => setGoal(goal - 1),
                      onMore: goal >= maxWaterGoal
                          ? null
                          : () => setGoal(goal + 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: [
                          Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionTitle(
                                      l10n.waterReminders,
                                      small: true,
                                    ),
                                    Text(
                                      rules.waterOn
                                          ? l10n.waterRemindersSub(
                                              rules.waterEvery,
                                              formatMinuteOfDay(
                                                rules.waterFrom,
                                              ),
                                              formatMinuteOfDay(
                                                rules.waterUntil,
                                              ),
                                            )
                                          : l10n.quietOff,
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: scheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Semantics(
                                label: l10n.waterReminders,
                                child: Switch(
                                  value: rules.waterOn,
                                  onChanged: (on) => unawaited(
                                    settings.put(
                                      SettingKeys.waterRemind,
                                      '$on',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (rules.waterOn)
                            PillSegmented<int>(
                              segments: [
                                for (final h in const [2, 3])
                                  (
                                    value: h,
                                    label: l10n.waterEvery(h),
                                    caption: null,
                                  ),
                              ],
                              selected: rules.waterEvery,
                              onChanged: (h) => unawaited(
                                settings.put(SettingKeys.waterEvery, '$h'),
                              ),
                            ),
                          Text(
                            l10n.waterRemindersNote,
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
