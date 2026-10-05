import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Today, M1 subset: header and the week hero card. The plan, visit and
/// Screen Rest cards arrive in M2/M3.
class TodayScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(activePregnancyProvider).value;
    if (pregnancy == null) return const SizedBox.shrink();
    final today = ref.watch(todayProvider);
    final snapshot = PregnancySnapshot.of(
      start: pregnancy.startDate,
      today: today,
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
          _Header(today: today, name: ref.watch(firstNameProvider).value),
          const SizedBox(height: 16),
          if (snapshot.needsReview)
            const _CheckDatesCard()
          else
            _HeroCard(snapshot),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const new({required this.today, required this.name});

  final DateTime today;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'morning'
        : hour < 17
        ? 'afternoon'
        : 'evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(today),
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.outline,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  name == null
                      ? l10n.greeting(period)
                      : l10n.greetingName(period, name!),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isDark ? l10n.switchToLight : l10n.switchToDark,
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurfaceVariant,
          ),
          onPressed: () =>
              setThemeMode(ref, isDark ? ThemeMode.light : ThemeMode.dark),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );
  }
}

/// Week ring, month, trimester, due date and days to go (prototype "Today").
class _HeroCard extends StatelessWidget {
  const new(this.s);

  final PregnancySnapshot s;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onPrimaryContainer;
    final text = theme.textTheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            spacing: 18,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (s.gaDays / pregnancyLengthDays).clamp(0, 1),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: scheme.primary,
                        backgroundColor: scheme.surface,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${s.weeks}',
                                style: text.headlineSmall!.copyWith(
                                  height: 28 / 26,
                                  color: on,
                                ),
                              ),
                              Text(
                                l10n.ringDays(s.days),
                                style: text.bodySmall!.copyWith(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w700,
                                  color: on,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      l10n.heroOverline(s.month, s.trimester),
                      style: text.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.26,
                        color: on,
                      ),
                    ),
                    Text(
                      l10n.weeksDays(s.weeks, s.days),
                      style: text.titleMedium!.copyWith(color: on),
                    ),
                    Text(
                      s.daysPastDue > 0
                          ? l10n.pastDue(s.daysPastDue)
                          : l10n.daysToGo(formatDate(s.dueDate), s.daysToGo),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the hero when the dates put her below 0 or above 44
/// weeks (ARCHITECTURE §6).
class _CheckDatesCard extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.navmaas;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.amberSoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              l10n.datesNeedReview,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: brand.onAmberSoft,
              ),
            ),
            OutlinedButton(
              onPressed: () => context.go('/me/dates'),
              child: Text(l10n.checkDates),
            ),
          ],
        ),
      ),
    );
  }
}
