import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/screen_rest/presentation/screen_rest_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Walk → Move breaks (E6, Plan decision 82): a nudge every hour or two in
/// her hours, on the days she picks, to stand up and walk for 5 minutes.
/// Off by default; the reminders come from `ReminderSync`.
class MoveBreaksCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsRepositoryProvider);
    final rules =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    void put(String key, Object value) =>
        unawaited(settings.put(key, '$value'));
    // Monday 5 Jan 2026 + d: the day names in her locale.
    final days = [for (var d = 1; d <= 7; d++) DateTime(2026, 1, 4 + d)];
    final picked = [
      for (final d in days)
        if (rules.moveDays.contains('${d.weekday}')) DateFormat.E().format(d),
    ];
    final dayText = switch (rules.moveDays) {
      '1234567' => l10n.moveDaysEveryDay,
      '12345' => l10n.moveDaysWeekdays,
      '' => l10n.moveDaysNone,
      _ => picked.join(', '),
    };

    // From must stay before Until: the other end moves an hour away.
    Future<void> pickFrom() async {
      final m = await pickMinute(context, l10n.moveFrom, rules.moveFrom);
      if (m == null) return;
      put(SettingKeys.moveFrom, m);
      if (m >= rules.moveUntil) {
        put(SettingKeys.moveUntil, (m + 60).clamp(0, 24 * 60 - 1));
      }
    }

    Future<void> pickUntil() async {
      final m = await pickMinute(context, l10n.moveUntil, rules.moveUntil);
      if (m == null) return;
      put(SettingKeys.moveUntil, m);
      if (m <= rules.moveFrom) {
        put(SettingKeys.moveFrom, (m - 60).clamp(0, 24 * 60 - 1));
      }
    }

    Widget time(String label, int minute, VoidCallback onTap) {
      final shown = formatMinuteOfDay(minute);
      return Semantics(
        button: true,
        label: l10n.moveTimeChange(label, shown),
        excludeSemantics: true,
        child: Material(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                    Text(
                      shown,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                IconTile(
                  background: scheme.primaryContainer,
                  child: NmIcon(
                    NavmaasIcon.clock,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(l10n.moveBreaks, small: true),
                      Text(
                        rules.moveOn
                            ? l10n.moveBreaksSub(
                                l10n.moveEvery(rules.moveEvery),
                                formatMinuteOfDay(rules.moveFrom),
                                formatMinuteOfDay(rules.moveUntil),
                                dayText,
                              )
                            : l10n.quietOff,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: l10n.moveBreaks,
                  child: Switch(
                    value: rules.moveOn,
                    onChanged: (on) => put(SettingKeys.moveRemind, on),
                  ),
                ),
              ],
            ),
            if (rules.moveOn) ...[
              PillSegmented<int>(
                segments: [
                  for (final h in const [1, 2])
                    (value: h, label: l10n.moveEvery(h), caption: null),
                ],
                selected: rules.moveEvery,
                onChanged: (h) => put(SettingKeys.moveEvery, h),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: time(l10n.moveFrom, rules.moveFrom, pickFrom),
                    ),
                    Expanded(
                      child: time(l10n.moveUntil, rules.moveUntil, pickUntil),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.moveDaysTitle,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.outline,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in days)
                    Semantics(
                      label: DateFormat.EEEE().format(d),
                      excludeSemantics: true,
                      button: true,
                      checked: rules.moveDays.contains('${d.weekday}'),
                      child: WordChip(
                        label: DateFormat.E().format(d),
                        selected: rules.moveDays.contains('${d.weekday}'),
                        exclusive: false,
                        onTap: () {
                          final w = '${d.weekday}';
                          put(
                            SettingKeys.moveDays,
                            moveDaysOf(
                              rules.moveDays.contains(w)
                                  ? rules.moveDays.replaceAll(w, '')
                                  : rules.moveDays + w,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
            Text(
              l10n.moveBreaksNote,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
