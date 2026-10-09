import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/motion.dart';
import 'package:navmaas/core/widgets/notice_box.dart';
import 'package:navmaas/features/today/mood_scene_card.dart';
import 'package:navmaas/features/today/next_visit_card.dart';
import 'package:navmaas/features/today/screen_rest_card.dart';
import 'package:navmaas/features/today/today_plan_card.dart';
import 'package:navmaas/features/today/wellbeing_card.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Today: header, the iPhone build-expiry banner when it's close, the week
/// hero card, today's plan, the next visit and Screen Rest.
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
          const _BuildExpiryBanner(),
          if (snapshot.needsReview)
            const _CheckDatesCard()
          else
            _HeroCard(
              snapshot,
              size: ref.watch(contentPackProvider).value?[snapshot.weeks]?.size,
            ),
          const SizedBox(height: 16),
          // Today's mood scene, once she has picked a mood (E4).
          const MoodSceneCard(),
          const TodayPlanCard(),
          const WellbeingCard(),
          const NextVisitCard(),
          const ScreenRestCard(),
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
    final hour = ref.watch(nowProvider).hour;
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
        PressScale(
          child: IconButton(
            tooltip: isDark ? l10n.switchToLight : l10n.switchToDark,
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            onPressed: () =>
                setThemeMode(ref, isDark ? ThemeMode.light : ThemeMode.dark),
            // Moon and sun cross-fade with a 30° turn (DESIGN_SYSTEM §5).
            icon: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: RotationTransition(
                  turns: Tween<double>(
                    begin: -1 / 12,
                    end: 0,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: NmIcon(
                isDark ? NavmaasIcon.sun : NavmaasIcon.moon,
                key: ValueKey(isDark),
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Week ring, month, trimester, due date and days to go (prototype "Today").
class _HeroCard extends StatelessWidget {
  const new(this.s, {required this.size});

  final PregnancySnapshot s;

  /// This week's size comparison, or null outside weeks 4–42.
  final String? size;

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
              // The ring's number is read out as "24 weeks 5 days".
              Semantics(
                label: l10n.weeksDays(s.weeks, s.days),
                child: ExcludeSemantics(
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
                      size == null
                          ? l10n.weeksDays(s.weeks, s.days)
                          : l10n.heroSize(size!),
                      style: text.titleMedium!.copyWith(color: on),
                    ),
                    Text(
                      s.daysPastDue > 0
                          ? l10n.pastDue(s.daysPastDue)
                          : l10n.daysToGo(
                              formatShortDate(s.dueDate),
                              s.daysToGo,
                            ),
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

/// A quiet banner when this iPhone build stops opening within a day
/// (ARCHITECTURE §12).
class _BuildExpiryBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiry = ref.watch(buildExpiryProvider).value;
    if (expiry == null) return const SizedBox.shrink();
    final days = daysBetween(
      ref.watch(todayProvider),
      dateOnly(expiry.toLocal()),
    );
    if (days > 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NoticeBox(
        icon: NavmaasIcon.clock,
        text: l10n.buildBanner(l10n.inDays(days < 0 ? 0 : days)),
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
              onPressed: () => context.go('/me/edit'),
              child: Text(l10n.checkDates),
            ),
          ],
        ),
      ),
    );
  }
}
