import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "8:05 pm".
String formatTime(DateTime t) => formatMinuteOfDay(t.hour * 60 + t.minute);

/// "Today", "Yesterday" or "Fri" for [t], seen from [now].
String dayLabel(DateTime t, DateTime now, AppLocalizations l10n) =>
    switch (daysBetween(localDay(t), localDay(now))) {
      0 => l10n.dayToday,
      1 => l10n.dayYesterday,
      _ => DateFormat('EEE').format(t),
    };

/// Back button and a left-aligned title (prototype Kick counter and
/// Contraction timer headers).
class ToolHeader extends StatelessWidget {
  const new({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        spacing: 4,
        children: [
          IconButton(
            tooltip: l10n.backTooltip,
            onPressed: () => context.pop(),
            icon: const NmIcon(
              NavmaasIcon.chevronLeft,
              size: 22,
              strokeWidth: 2,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontSize: 20,
                      height: 26 / 20,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a log card: a label on the left, a value on the right.
class LogRow extends StatelessWidget {
  const new({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
