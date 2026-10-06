import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/app_usage.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';
import 'package:navmaas/features/screen_rest/data/screen_use.dart';
import 'package:navmaas/features/screen_rest/domain/rest_windows.dart';
import 'package:navmaas/features/screen_rest/presentation/app_limits_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Screen Rest (prototype "Screen Rest"): the next screen-free window, time
/// in Navmaas today and her rest rules. In-app only (ARCHITECTURE §10);
/// limits on other apps are Phase 2.
class ScreenRestScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    final settings = ref.read(settingsRepositoryProvider);
    final eyes = ref.watch(eyeRestProvider).value ?? true;

    String range(int start, int end) =>
        l10n.quietRange(formatMinuteOfDay(start), formatMinuteOfDay(end));
    Future<void> put(String key, Object value) => settings.put(key, '$value');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.backTooltip,
                    // A limit notice opens Screen Rest on its own.
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/today'),
                    icon: const NmIcon(
                      NavmaasIcon.chevronLeft,
                      size: 22,
                      strokeWidth: 2,
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.screenRestTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 17,
                          height: 24 / 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _RestHero(s),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.restRulesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _RuleRow(
                          title: l10n.restBedtime,
                          sub: l10n.restBedtimeSub(
                            range(s.quietStart, s.quietEnd),
                          ),
                          value: s.quietOn,
                          onChanged: (v) => put(SettingKeys.quietOn, v),
                          onEdit: () => pickQuietHours(context, settings, s),
                        ),
                        _RuleRow(
                          title: l10n.restMeals,
                          sub: l10n.restMealsSub(
                            range(
                              s.mealLunch,
                              s.mealLunch + ReminderSettings.mealMinutes,
                            ),
                            range(
                              s.mealDinner,
                              s.mealDinner + ReminderSettings.mealMinutes,
                            ),
                          ),
                          value: s.mealOn,
                          onChanged: (v) => put(SettingKeys.mealRest, v),
                          onEdit: () async {
                            final lunch = await pickMinute(
                              context,
                              l10n.restLunchStarts,
                              s.mealLunch,
                            );
                            if (lunch == null || !context.mounted) return;
                            final dinner = await pickMinute(
                              context,
                              l10n.restDinnerStarts,
                              s.mealDinner,
                            );
                            if (dinner == null) return;
                            await put(SettingKeys.mealLunch, lunch);
                            await put(SettingKeys.mealDinner, dinner);
                          },
                        ),
                        _RuleRow(
                          title: l10n.eyeRestTitle,
                          sub: l10n.eyeRestSub,
                          value: eyes,
                          onChanged: (v) => put(SettingKeys.eyeRest, v),
                        ),
                        _RuleRow(
                          title: l10n.windDownTitle,
                          sub: l10n.windDownSub(
                            formatMinuteOfDay(s.windDownAt),
                          ),
                          value: s.windDownOn,
                          onChanged: (v) => put(SettingKeys.windDown, v),
                          onEdit: () async {
                            final at = await pickMinute(
                              context,
                              l10n.windDownAt,
                              s.windDownAt,
                            );
                            if (at != null) {
                              await put(SettingKeys.windDownAt, at);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (ref.watch(appUsageProvider).supported) ...[
                    const SizedBox(height: 16),
                    const _AppLimitsCard(),
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

/// Limits for other apps (M11, Android only; prototype "Screen Rest · app
/// limits card"): today's minutes for each app, or how to start.
class _AppLimitsCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final limits = ref.watch(appLimitsProvider).value;
    if (limits == null) return const SizedBox.shrink();
    void open() => unawaited(context.push('/app-limits'));
    final heading = Semantics(
      header: true,
      child: Text(l10n.appLimitsTitle, style: theme.textTheme.titleMedium),
    );
    if (limits.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              heading,
              Text(
                l10n.appLimitsCardIntro,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              OutlinedButton(onPressed: open, child: Text(l10n.appLimitsSetUp)),
            ],
          ),
        ),
      );
    }
    final access = ref.watch(usageAccessProvider).value ?? false;
    final minutes = ref.watch(limitMinutesTodayProvider).value ?? const {};
    final icons = ref.watch(installedAppsProvider).value ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        heading,
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!access)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text(
                    l10n.appLimitsCardPaused,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.extension<NavmaasColors>()!.onAmberSoft,
                    ),
                  ),
                )
              else
                for (final limit in limits)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        spacing: 12,
                        children: [
                          AppIcon(
                            label: limit.label,
                            icon: icons[limit.package]?.icon,
                          ),
                          Expanded(
                            child: LimitProgress(
                              limit: limit,
                              used: minutes[limit.package] ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: open,
                child: Text(l10n.appLimitsManage),
              ),
            ],
          ),
        ),
        Text(
          l10n.appLimitsFootnote,
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }
}

/// The lavender card: what rests next, and time in Navmaas today.
class _RestHero extends ConsumerWidget {
  const new(this.s);

  final ReminderSettings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onTertiaryContainer;
    final now = clockNow();
    final window = nextRestWindow(s, now);
    String time(DateTime t) => formatMinuteOfDay(t.hour * 60 + t.minute);
    final line = window == null
        ? l10n.restNoWindow
        : window.start.isAfter(now)
        ? l10n.restNextWindow(time(window.start), time(window.end))
        : l10n.restInWindow(time(window.end));
    final used = ref.watch(usedTodayTotalProvider).value ?? Duration.zero;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            IconTile(
              size: 48,
              background: scheme.surface,
              child: NmIcon(NavmaasIcon.moon, color: scheme.tertiary),
            ),
            Text(
              l10n.restHeroTitle,
              style: theme.textTheme.titleLarge!.copyWith(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w800,
                color: on,
              ),
            ),
            Text(
              line,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 15,
                height: 22 / 15,
                fontWeight: FontWeight.w600,
                color: on,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    l10n.restUsedToday(used.inMinutes),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rule with its switch; tapping the text changes its times when it has
/// any ([onEdit]).
class _RuleRow extends StatelessWidget {
  const new({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.onEdit,
  });

  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          sub,
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.outline,
          ),
        ),
      ],
    );
    final edit = onEdit;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      position: DecorationPosition.foreground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: edit == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: text,
                    )
                  : Semantics(
                      onTapHint: l10n.restChangeTimes,
                      child: InkWell(
                        onTap: edit,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: text,
                        ),
                      ),
                    ),
            ),
            // The switch reads out the rule it turns on or off.
            Semantics(
              label: title,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

/// A time picker for [initial] minutes after midnight; null if cancelled.
Future<int?> pickMinute(BuildContext context, String help, int initial) async {
  final t = await showTimePicker(
    context: context,
    helpText: help,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Bedtime rest's times, which are the quiet hours (also set from Me).
Future<void> pickQuietHours(
  BuildContext context,
  SettingsRepository settings,
  ReminderSettings s,
) async {
  final l10n = AppLocalizations.of(context);
  final start = await pickMinute(context, l10n.quietFrom, s.quietStart);
  if (start == null || !context.mounted) return;
  final end = await pickMinute(context, l10n.quietUntil, s.quietEnd);
  if (end == null) return;
  await settings.put(SettingKeys.quietStart, '$start');
  await settings.put(SettingKeys.quietEnd, '$end');
}
