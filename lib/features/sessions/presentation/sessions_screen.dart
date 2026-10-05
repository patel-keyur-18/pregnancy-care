import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/health.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/sessions/data/letter_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/presentation/breathing_screen.dart';
import 'package:navmaas/features/sessions/presentation/library_actions.dart';
import 'package:navmaas/features/sessions/presentation/walk_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// A reading session's gentle goal (prototype "15 min").
const readGoalMinutes = 15;

/// Sessions tab (prototype "Sessions"): the Garbhasanskar path, the
/// library, and Move & breathe.
class SessionsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
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
          Text(
            l10n.sessionsOverline,
            style: text.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.outline,
            ),
          ),
          Semantics(
            header: true,
            child: Text(l10n.tabSessions, style: text.headlineSmall),
          ),
          const SizedBox(height: 18),
          const _PathCard(),
          const SizedBox(height: 18),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.yourLibrary, style: text.titleMedium),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: scheme.surface,
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outlineVariant),
                  textStyle: text.labelLarge,
                ),
                onPressed: () => showAddToLibrary(context, ref),
                icon: const NmIcon(
                  NavmaasIcon.plus,
                  size: 16,
                  strokeWidth: 2.4,
                ),
                label: Text(l10n.addButton),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _LibraryCard(),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(l10n.moveAndBreathe, style: text.titleMedium),
          ),
          const SizedBox(height: 10),
          const _MoveAndBreathe(),
        ],
      ),
    );
  }
}

/// Read · listen · activity · talk to baby, for today (prototype path card).
class _PathCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final today = ref.watch(todayProvider);
    final snapshot = pregnancy == null
        ? null
        : PregnancySnapshot.of(start: pregnancy.startDate, today: today);
    final items = ref.watch(libraryItemsProvider).value ?? const [];
    final book = items.where((i) => i.kind != LibraryKind.audio).firstOrNull;
    final audio = items.where((i) => i.kind == LibraryKind.audio).firstOrNull;
    final activity = activityOfTheDay(
      ref.watch(activitiesProvider).value ?? const [],
      snapshot?.gaDays ?? 0,
    );
    final lastLetter = ref.watch(lettersProvider).value?.firstOrNull;
    final now = ref.watch(nowProvider);
    final wroteToday =
        lastLetter != null &&
        DateUtils.isSameDay(lastLetter.createdAt.toLocal(), now);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.pathTitle,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
                if (snapshot != null)
                  Text(
                    l10n.pathDay(snapshot.weeks, snapshot.days),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
            _TilePair(
              _PathTile(
                icon: NavmaasIcon.book,
                title: l10n.pathRead,
                subtitle: book == null
                    ? l10n.addBook
                    : l10n.minutesTitle(readGoalMinutes, book.title),
                onTap: () => book == null
                    ? addToLibrary(context, ref, audio: false)
                    : openLibraryItem(context, book),
              ),
              _PathTile(
                icon: NavmaasIcon.headphones,
                title: l10n.pathListen,
                subtitle: audio == null
                    ? l10n.addAudio
                    : switch (audio.durationSec) {
                        final s? => l10n.minutesTitle(
                          (s / 60).ceil(),
                          audio.title,
                        ),
                        null => audio.title,
                      },
                onTap: () => audio == null
                    ? addToLibrary(context, ref, audio: true)
                    : openLibraryItem(context, audio),
              ),
            ),
            _TilePair(
              _PathTile(
                icon: NavmaasIcon.palette,
                title: l10n.pathActivity,
                subtitle: activity?.title ?? '',
                onTap: activity == null
                    ? null
                    : () => showActivitySheet(context, activity),
              ),
              _PathTile(
                icon: NavmaasIcon.pencil,
                title: l10n.pathTalk,
                subtitle: wroteToday ? l10n.pathTalkDone : l10n.pathTalkSub,
                onTap: () => context.go('/sessions/letters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The activity for day [gaDays] of the pregnancy, cycling through the list.
Activity? activityOfTheDay(List<Activity> activities, int gaDays) =>
    activities.isEmpty ? null : activities[gaDays.abs() % activities.length];

/// Two tiles side by side, equally tall.
class _TilePair extends StatelessWidget {
  const new(this.left, this.right);

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    ),
  );
}

class _PathTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final NavmaasIcon icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                NmIcon(icon, color: scheme.tertiary),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
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

/// The owner's books and audio (prototype "Your library").
class _LibraryCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(libraryItemsProvider).value ?? const [];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.libraryEmpty,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _LibraryRow(item),
                ],
              ],
            ),
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const new(this.item);

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = item.total;
    final progress = total == null || total == 0
        ? null
        : ((item.position + 1) / total).clamp(0.0, 1.0);
    final detail = switch (item.kind) {
      LibraryKind.pdf when total != null => [
        l10n.libraryPdf,
        l10n.libraryPage(item.position + 1, total),
      ],
      LibraryKind.pdf => [l10n.libraryPdf],
      LibraryKind.text when total != null => [
        l10n.libraryText,
        l10n.libraryPercent(item.position * 100 ~/ total),
      ],
      LibraryKind.text => [l10n.libraryText],
      LibraryKind.audio => [
        l10n.libraryAudio,
        if (item.durationSec case final s?) l10n.minutesShort((s / 60).ceil()),
        l10n.offline,
      ],
    }.join(' · ');

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.libraryItemActions): () =>
            showLibraryItemActions(context, ref, item),
      },
      child: InkWell(
        onTap: () => openLibraryItem(context, item),
        onLongPress: () => showLibraryItemActions(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              if (item.kind == LibraryKind.audio)
                IconTile(
                  size: 44,
                  background: scheme.tertiaryContainer,
                  child: NmIcon(
                    NavmaasIcon.music,
                    size: 20,
                    color: scheme.onTertiaryContainer,
                  ),
                )
              else
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.title.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
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
                      item.title,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                    if (progress != null)
                      Semantics(
                        label: l10n.bookProgress,
                        value: '${(progress * 100).round()}%',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: scheme.secondary,
                            backgroundColor: context.navmaas.track,
                          ),
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

/// Walk (always open), the routines for this trimester (locked until
/// "doctor cleared me"), and slow breathing (prototype "Move & breathe").
class _MoveAndBreathe extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final trimester = pregnancy == null
        ? 1
        : PregnancySnapshot.of(
            start: pregnancy.startDate,
            today: ref.watch(todayProvider),
          ).trimester;
    final cleared = pregnancy?.exerciseCleared ?? false;
    final routines = routinesFor(
      ref.watch(routinesProvider).value ?? const [],
      trimester: trimester,
      highRisk: pregnancy?.highRisk ?? false,
    );
    final steps = ref.watch(todayStepsProvider).value;
    final goal = ref.watch(stepGoalProvider).value ?? defaultStepGoal;

    final tiles = [
      _MoveTile(
        icon: NavmaasIcon.walk,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        title: l10n.walkTile,
        subtitle: steps != null && steps > 0
            ? l10n.walkTileSteps(formatSteps(steps), formatSteps(goal))
            : l10n.walkEasy(walkGoalMinutes),
        onTap: () => context.push('/walk'),
      ),
      for (final r in routines)
        _MoveTile(
          icon: r.key == 'pelvic-floor'
              ? NavmaasIcon.pelvic
              : cleared
              ? NavmaasIcon.lotus
              : NavmaasIcon.lock,
          background: r.key == 'pelvic-floor'
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          foreground: r.key == 'pelvic-floor'
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
          title: r.title,
          subtitle: !cleared
              ? l10n.routineLocked
              : r.trimesters.length == 1
              ? l10n.routineOneTrimester(trimester, (r.seconds / 60).ceil())
              : l10n.minutesShort((r.seconds / 60).ceil()),
          onTap: cleared
              ? () => context.push('/exercise', extra: r.key)
              : () => context.go('/me'),
        ),
      _MoveTile(
        icon: NavmaasIcon.breath,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        title: l10n.breathingTitle,
        subtitle: l10n.breathingSub(breathingMinutes),
        onTap: () => context.push('/breathe'),
      ),
    ];
    return Column(
      spacing: 10,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          _TilePair(
            tiles[i],
            i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _MoveTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final NavmaasIcon icon;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              IconTile(
                background: background,
                child: NmIcon(icon, size: 20, color: foreground),
              ),
              Text(
                title,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's calm idea, in a sheet.
Future<void> showActivitySheet(BuildContext context, Activity activity) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    IconTile(
                      background: scheme.tertiaryContainer,
                      child: NmIcon(
                        NavmaasIcon.palette,
                        size: 20,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.activityToday,
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.outline,
                            ),
                          ),
                          Text(
                            activity.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(activity.text, style: theme.textTheme.bodyLarge),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.doneButton),
                ),
              ],
            ),
          ),
        );
      },
    );
