import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "Next doctor visit" (prototype Today); hidden when none is planned.
class NextVisitCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.navmaas;
    final now = DateTime.now();
    final visit = (ref.watch(appointmentsProvider).value ?? const [])
        .where((a) => a.at.isAfter(now))
        .firstOrNull;
    if (visit == null) return const SizedBox.shrink();
    final waiting = (ref.watch(visitQuestionsProvider).value ?? const [])
        .where((q) => q.appointmentId == null && q.askedAt == null)
        .length;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/care/visit', extra: visit.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 14,
              children: [
                IconTile(
                  size: 44,
                  background: brand.amberSoft,
                  child: NmIcon(
                    NavmaasIcon.calendar,
                    size: 22,
                    color: brand.onAmberSoft,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nextDoctorVisit,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                      Text(
                        formatDateTime(visit.at),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          ?visit.doctor,
                          l10n.questionsReady(waiting),
                        ].join(' · '),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
