import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Screen Rest status on Today (prototype Today): bedtime and wind-down at
/// a glance; opens Screen Rest.
class ScreenRestCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onTertiaryContainer;
    final s =
        ref.watch(reminderSettingsProvider).value ?? const ReminderSettings();
    final title = s.quietOn
        ? l10n.todayRestTitle(formatMinuteOfDay(s.quietStart))
        : l10n.screenRestTitle;
    final sub = s.windDownOn
        ? l10n.todayRestWindDown(formatMinuteOfDay(s.windDownAt))
        : s.quietOn
        ? l10n.restHeroTitle
        : l10n.todayRestOff;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/screen-rest'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 14,
              children: [
                IconTile(
                  size: 44,
                  background: scheme.surface,
                  child: NmIcon(
                    NavmaasIcon.moon,
                    size: 22,
                    color: scheme.tertiary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: on,
                        ),
                      ),
                      Text(
                        sub,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: on,
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
    );
  }
}
