import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/widgets/motion.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/journey/data/checklist_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Journey (prototype "Journey"): trimester tabs, week picker, the week's
/// notes and checklist, and how this trimester is going.
class JourneyScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  /// The week being viewed; null follows the current week.
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final pack = ref.watch(contentPackProvider).value;
    if (pregnancy == null || pack == null) return const SizedBox.shrink();

    final snapshot = PregnancySnapshot.of(
      start: pregnancy.startDate,
      today: ref.watch(todayProvider),
    );
    final current = snapshot.weeks.clamp(
      ContentPack.firstWeek,
      ContentPack.lastWeek,
    );
    final week = _picked ?? current;
    final tri = trimesterOfWeek(week);
    final content = pack[week]!;
    final ticked = ref.watch(tickedItemsProvider).value ?? const {};

    return SafeArea(
      bottom: false,
      // No side padding here: the week chips run edge to edge, everything
      // else gets the gutter through [_gutter].
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: _gutter(except: _WeekChips, [
          Text(
            l10n.journeyOverline,
            style: text.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.outline,
            ),
          ),
          Semantics(
            header: true,
            child: Text(l10n.tabJourney, style: text.headlineSmall),
          ),
          const SizedBox(height: 16),
          PillSegmented<int>(
            segments: [
              for (final t in [1, 2, 3])
                (
                  value: t,
                  label: l10n.trimesterShort(t),
                  caption: l10n.trimesterRange(
                    trimesterWeeks[t]!.$1,
                    trimesterWeeks[t]!.$2,
                  ),
                ),
            ],
            selected: tri,
            onChanged: (t) => setState(
              () => _picked = trimesterOfWeek(current) == t
                  ? current
                  : _firstWeek(t),
            ),
          ),
          const SizedBox(height: 16),
          _WeekChips(
            weeks: [for (var w = _firstWeek(tri); w <= _lastWeek(tri); w++) w],
            selected: week,
            onPick: (w) => setState(() => _picked = w),
          ),
          const SizedBox(height: 16),
          _WeekCard(content: content, isCurrent: week == snapshot.weeks),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              week == snapshot.weeks
                  ? l10n.checklistThisWeek
                  : l10n.checklistWeek(week),
              style: text.titleMedium,
            ),
          ),
          const SizedBox(height: 10),
          _Checklist(
            items: content.checklist,
            ticked: ticked,
            onToggle: (key, {required ticked}) => ref
                .read(checklistRepositoryProvider)
                .setTicked(pregnancy.id, key, ticked: ticked),
          ),
          const SizedBox(height: 16),
          _TrimesterProgress(
            trimester: snapshot.trimester,
            week: snapshot.weeks,
            done: ticked.where((key) {
              final w = int.tryParse(key.substring(1, 3));
              return w != null && trimesterOfWeek(w) == snapshot.trimester;
            }).length,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.journeyDisclaimer,
            style: text.bodySmall!.copyWith(color: scheme.outline),
          ),
        ]),
      ),
    );
  }
}

/// Adds the screen gutter to every child except the edge-to-edge [except].
List<Widget> _gutter(List<Widget> children, {required Type except}) => [
  for (final c in children)
    if (c.runtimeType == except)
      c
    else
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        child: c,
      ),
];

/// Weeks with notes in trimester [t]: 4–13, 14–27, 28–42.
int _firstWeek(int t) => math.max(trimesterWeeks[t]!.$1, ContentPack.firstWeek);
int _lastWeek(int t) => t == 3 ? ContentPack.lastWeek : trimesterWeeks[t]!.$2;

/// Horizontal week chips, edge to edge; the selected week is centred.
class _WeekChips extends StatefulWidget {
  const new({
    required this.weeks,
    required this.selected,
    required this.onPick,
  });

  final List<int> weeks;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  State<_WeekChips> createState() => _WeekChipsState();
}

class _WeekChipsState extends State<_WeekChips> {
  static const _gap = 8.0;
  final _controller = ScrollController();

  /// Chips grow with text size, up to 1.6×, so the number never clips.
  double get _grow => MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centre(animate: false),
    );
  }

  @override
  void didUpdateWidget(_WeekChips old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected ||
        old.weeks.first != widget.weeks.first) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centre(animate: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The list is built lazily, so the offset is computed, not looked up.
  void _centre({required bool animate}) {
    if (!mounted || !_controller.hasClients) return;
    final i = widget.weeks.indexOf(widget.selected);
    if (i < 0) return;
    final width = 52 * _grow;
    final position = _controller.position;
    final target =
        (AppTheme.gutter +
                i * (width + _gap) +
                width / 2 -
                position.viewportDimension / 2)
            .clamp(0.0, position.maxScrollExtent);
    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final grow = _grow;
    return SizedBox(
      height: 64 * grow,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        itemCount: widget.weeks.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final w = widget.weeks[i];
          final on = w == widget.selected;
          final fg = on ? scheme.onPrimary : scheme.onSurface;
          return Semantics(
            button: true,
            selected: on,
            label: l10n.weekNumber(w),
            excludeSemantics: true,
            child: Material(
              color: on ? scheme.primary : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: on ? scheme.primary : scheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onPick(w),
                child: SizedBox(
                  width: 52 * grow,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.weekChip,
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontSize: 12,
                          height: 14 / 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      Text(
                        '$w',
                        style: theme.textTheme.titleMedium!.copyWith(
                          height: 22 / 18,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const new({required this.content, required this.isCurrent});

  final WeekContent content;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final note = text.bodyLarge!.copyWith(
      fontSize: 15,
      height: 22 / 15,
      color: scheme.onSurfaceVariant,
    );

    Widget row(String tag, Color bg, Color fg, String body) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              tag,
              style: text.bodySmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ),
        Expanded(child: Text(body, style: note)),
      ],
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 14,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: NmIcon(
                    NavmaasIcon.sprout,
                    size: 28,
                    strokeWidth: 1.6,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrent
                            ? l10n.weekThis(content.week)
                            : l10n.weekNumber(content.week),
                        style: text.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                      Text(
                        l10n.aboutSize(content.size),
                        style: text.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            row(
              l10n.babyTag,
              scheme.primaryContainer,
              scheme.onPrimaryContainer,
              content.baby,
            ),
            row(
              l10n.youTag,
              scheme.secondaryContainer,
              scheme.onSecondaryContainer,
              content.you,
            ),
          ],
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const new({
    required this.items,
    required this.ticked,
    required this.onToggle,
  });

  final List<ChecklistItem> items;
  final Set<String> ticked;
  final void Function(String key, {required bool ticked}) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const Divider(height: 1),
            _CheckRow(
              text: item.text,
              ticked: ticked.contains(item.key),
              onTap: () =>
                  onToggle(item.key, ticked: !ticked.contains(item.key)),
              scheme: scheme,
              style: theme.textTheme.bodyLarge!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Prototype checklist row; ticking fills the box sage and draws the check
/// (DESIGN_SYSTEM §5).
class _CheckRow extends StatelessWidget {
  const new({
    required this.text,
    required this.ticked,
    required this.onTap,
    required this.scheme,
    required this.style,
  });

  final String text;
  final bool ticked;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: ticked,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ticked
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ticked ? scheme.primary : scheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: ticked
                    ? DrawOnIcon(
                        NavmaasIcon.check,
                        active: ticked,
                        size: 14,
                        strokeWidth: 3.2,
                        color: scheme.onPrimary,
                        duration: const Duration(milliseconds: 250),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  text,
                  style: style.copyWith(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w600,
                    color: ticked ? scheme.outline : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrimesterProgress extends StatelessWidget {
  const new({required this.trimester, required this.week, required this.done});

  final int trimester;
  final int week;
  final int done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final (first, last) = trimesterWeeks[trimester]!;
    final total = last - first + 1;
    final into = (week - first + 1).clamp(1, total);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.trimesterSoFar(trimester),
                    style: text.titleMedium!.copyWith(
                      fontSize: 16,
                      height: 22 / 16,
                    ),
                  ),
                ),
                Text(
                  l10n.weekOf(into, total),
                  style: text.bodySmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Semantics(
              label: l10n.trimesterSoFar(trimester),
              value: l10n.weekOf(into, total),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: into / total,
                  minHeight: 8,
                  backgroundColor: context.navmaas.track,
                ),
              ),
            ),
            // Reading, walk and supplement tiles join these in M3 / M4.
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '$done',
                    label: l10n.checklistDone(done),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const new({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontSize: 22,
                height: 28 / 22,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall!.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
