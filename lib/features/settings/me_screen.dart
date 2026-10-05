import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/profile_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/core/widgets/step_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Me, M1 subset: profile + pregnancy dates, appearance, disclaimer.
class MeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final name = ref.watch(firstNameProvider).value;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final on = scheme.onPrimaryContainer;

    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.labelLarge!.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );

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
          Semantics(
            header: true,
            child: Text(l10n.meTitle, style: text.headlineSmall),
          ),
          const SizedBox(height: 18),
          if (pregnancy != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  spacing: 14,
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.primary,
                        child: Text(
                          (name ?? l10n.meNoName).characters.first
                              .toUpperCase(),
                          style: text.titleMedium!.copyWith(
                            fontSize: 20,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? l10n.meNoName,
                            style: text.titleMedium!.copyWith(
                              fontSize: 17,
                              color: on,
                            ),
                          ),
                          Text(
                            l10n.dueOn(formatDate(pregnancy.dueDate)),
                            style: text.bodyMedium!.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: on,
                            ),
                          ),
                          Text(
                            l10n.datedBy(pregnancy.datingMethod.name),
                            style: text.bodyMedium!.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: on,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurface,
                        minimumSize: const Size(64, 48),
                        textStyle: text.labelLarge,
                      ),
                      onPressed: () => context.go('/me/edit'),
                      child: Text(
                        l10n.editButton,
                        semanticsLabel: l10n.editDetailsLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          section(l10n.yourDoctor, const _DoctorRow()),
          const SizedBox(height: 18),
          section(
            l10n.appearance,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                PillSegmented<ThemeMode>(
                  segments: [
                    (
                      value: ThemeMode.light,
                      label: l10n.themeLight,
                      caption: null,
                    ),
                    (
                      value: ThemeMode.dark,
                      label: l10n.themeDark,
                      caption: null,
                    ),
                    (
                      value: ThemeMode.system,
                      label: l10n.themeSystem,
                      caption: null,
                    ),
                  ],
                  selected: mode,
                  onChanged: (m) => setThemeMode(ref, m),
                ),
                MergeSemantics(
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.nightReading,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.nightReadingSub,
                              style: text.bodySmall!.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: ref.watch(nightReadingProvider).value ?? true,
                        onChanged: (v) => ref
                            .read(settingsRepositoryProvider)
                            .put(SettingKeys.nightReading, '$v'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          section(l10n.calmNotifications, const _CalmNotifications()),
          const SizedBox(height: 18),
          section(l10n.exerciseSection, const _ExerciseSwitches()),
          const SizedBox(height: 18),
          Text(
            l10n.disclaimer,
            style: text.bodySmall!.copyWith(
              fontSize: 12,
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = ref.watch(profileProvider).value;
    final title = p?.doctorName ?? p?.clinicName;
    final sub = [
      if (p?.doctorName != null) ?p?.clinicName,
      p?.clinicPhone,
    ].nonNulls.join(' · ');
    return InkWell(
      onTap: () => context.go('/me/doctor'),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? l10n.addDoctor,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            NmIcon(
              NavmaasIcon.chevronRight,
              size: 20,
              strokeWidth: 2,
              color: scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reminders on/off, daily limit and quiet hours (prototype Me).
class _CalmNotifications extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    final settings = ref.read(settingsRepositoryProvider);

    Widget titled(String title, String sub) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          sub,
          style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
        ),
      ],
    );

    Future<void> setOn({required bool on}) async {
      if (!on) {
        await settings.put(SettingKeys.remindersOn, 'false');
        return;
      }
      final scheduler = ref.read(reminderSchedulerProvider);
      final granted =
          await scheduler.hasPermission() ||
          await scheduler.requestPermission();
      if (granted) {
        await settings.put(SettingKeys.remindersOn, 'true');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.remindersDenied)));
      }
    }

    Future<void> pickQuiet() async {
      TimeOfDay time(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
      final start = await showTimePicker(
        context: context,
        helpText: l10n.quietFrom,
        initialTime: time(s.quietStart),
      );
      if (start == null || !context.mounted) return;
      final end = await showTimePicker(
        context: context,
        helpText: l10n.quietUntil,
        initialTime: time(s.quietEnd),
      );
      if (end == null) return;
      await settings.put(
        SettingKeys.quietStart,
        '${start.hour * 60 + start.minute}',
      );
      await settings.put(SettingKeys.quietEnd, '${end.hour * 60 + end.minute}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        MergeSemantics(
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: titled(l10n.remindersSwitch, l10n.remindersSwitchSub),
              ),
              Switch(
                value: s.on,
                onChanged: (v) => setOn(on: v),
              ),
            ],
          ),
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(child: titled(l10n.dailyLimit, l10n.dailyLimitSub)),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                StepButton(
                  symbol: '−',
                  tooltip: l10n.fewerNotifications,
                  onPressed: s.dailyLimit > ReminderSettings.minLimit
                      ? () => settings.put(
                          SettingKeys.dailyLimit,
                          '${s.dailyLimit - 1}',
                        )
                      : null,
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${s.dailyLimit}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                StepButton(
                  symbol: '+',
                  tooltip: l10n.moreNotifications,
                  onPressed: s.dailyLimit < ReminderSettings.maxLimit
                      ? () => settings.put(
                          SettingKeys.dailyLimit,
                          '${s.dailyLimit + 1}',
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
        InkWell(
          onTap: pickQuiet,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: titled(l10n.quietHours, l10n.quietHoursSub)),
                Flexible(
                  child: Text(
                    l10n.quietRange(
                      formatMinuteOfDay(s.quietStart),
                      formatMinuteOfDay(s.quietEnd),
                    ),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

/// "Doctor cleared me for exercise" and "High-risk pregnancy" (prototype Me
/// → Exercise). Walking is always open (Plan decision 27).
class _ExerciseSwitches extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pregnancy = ref.watch(activePregnancyProvider).value;
    if (pregnancy == null) return const SizedBox.shrink();
    final repo = ref.read(pregnancyRepositoryProvider);

    Widget row(
      String title,
      String sub, {
      required bool value,
      required ValueChanged<bool> set,
    }) => MergeSemantics(
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  sub,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: set),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        row(
          l10n.clearedSwitch,
          l10n.clearedSub,
          value: pregnancy.exerciseCleared,
          set: (v) => repo.setFlags(pregnancy.id, exerciseCleared: v),
        ),
        row(
          l10n.highRiskSwitch,
          l10n.highRiskSub,
          value: pregnancy.highRisk,
          set: (v) => repo.setFlags(pregnancy.id, highRisk: v),
        ),
      ],
    );
  }
}
