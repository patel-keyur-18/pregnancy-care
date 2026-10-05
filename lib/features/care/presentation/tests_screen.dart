import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/care/data/care_repository.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The current completed week, or 0 without a pregnancy.
int currentWeek(WidgetRef ref) {
  final p = ref.watch(activePregnancyProvider).value;
  if (p == null) return 0;
  return PregnancySnapshot.of(
    start: p.startDate,
    today: ref.watch(todayProvider),
  ).weeks;
}

/// The template's note for each item key.
Map<String, String> careNotes(WidgetRef ref) => {
  for (final t
      in ref.watch(careTemplateProvider).value ?? const <CareTemplateItem>[])
    t.key: t.note,
};

/// Every test, scan and vaccine, by trimester (Care → Coming up → See all).
class TestsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = ref.watch(careItemsProvider).value ?? const [];
    final week = currentWeek(ref);
    final notes = careNotes(ref);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.testsAndVaccines)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          28,
        ),
        children: [
          for (final t in [1, 2, 3])
            if (items.where((i) => trimesterOfWeek(i.fromWeek) == t).toList()
                case final group when group.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.trimesterName(t),
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, item) in group.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      () {
                        final (icon, bg, fg) = careStyle(context, item.kind);
                        return CareRow(
                          icon: icon,
                          background: bg,
                          foreground: fg,
                          title: item.title,
                          subtitle: careSubtitle(l10n, item, week),
                          onTap: () => showCareItemSheet(
                            context,
                            ref,
                            item,
                            note: notes[item.templateKey],
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),
            ],
          const SizedBox(height: 16),
          Text(
            l10n.careFooter,
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
