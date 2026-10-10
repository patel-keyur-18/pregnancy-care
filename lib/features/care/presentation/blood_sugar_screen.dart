import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Every blood-sugar reading, newest day first (Care → Blood sugar). Values
/// as logged: no ranges, colours or labels.
class BloodSugarScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readings =
        ref.watch(vitalsProvider(VitalKind.bloodSugar)).value ?? const [];
    final today = ref.watch(todayProvider);
    final days = <DateTime, List<VitalReading>>{};
    for (final r in readings.reversed) {
      (days[localDay(r.at)] ??= []).add(r);
    }
    String time(DateTime at) => formatMinuteOfDay(at.hour * 60 + at.minute);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bloodSugar)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          28,
        ),
        children: [
          Text(
            l10n.bloodSugarSubtitle,
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
          ),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(l10n.bloodSugarEmpty),
            ),
          for (final MapEntry(key: day, value: rows) in days.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  localDay(today) == day
                      ? l10n.bloodSugarDayToday(formatShortDate(day))
                      : formatShortDate(day),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final (i, r) in rows.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 2,
                        children: [
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Text(
                                time(r.at),
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: scheme.outline,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${r.value1.round()}',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                l10n.bloodSugarUnit,
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: scheme.outline,
                                ),
                              ),
                              if (r.context case final c?)
                                Text(
                                  bloodSugarContextWord(l10n, c),
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (r.note case final note?)
                            Text(
                              note,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          12,
          AppTheme.gutter,
          16,
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => logBloodSugar(context, ref),
          child: Text(l10n.logBloodSugar),
        ),
      ),
    );
  }
}
