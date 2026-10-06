import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/features/third_trimester/data/third_trimester_repository.dart';
import 'package:navmaas/features/third_trimester/domain/patterns.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Contraction timer (prototype "Contraction timer", Plan §5.3): a log to
/// share with her doctor. Each contraction is saved when it ends (or when
/// she leaves mid-way). The clock keeps counting with the screen off.
class ContractionScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ContractionScreen> createState() => _ContractionScreenState();
}

class _ContractionScreenState extends ConsumerState<ContractionScreen>
    with SessionClock {
  late final ThirdTrimesterRepository _repo;
  late final String? _pregnancyId;

  /// The last day's contractions are listed.
  final DateTime _since = clockNow().subtract(const Duration(hours: 24));
  DateTime? _startedAt;

  @override
  bool get countWhileHidden => true;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(thirdTrimesterRepositoryProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    paused = true;
    startClock();
  }

  void _press() {
    final start = _startedAt;
    if (start == null) {
      setState(() {
        _startedAt = clockNow();
        seconds = 0;
        paused = false;
      });
      return;
    }
    _end(start);
    setState(() {
      _startedAt = null;
      seconds = 0;
      paused = true;
    });
  }

  void _end(DateTime start) {
    if (_pregnancyId == null) return;
    unawaited(
      _repo.saveContraction(
        pregnancyId: _pregnancyId,
        startedAt: start,
        endedAt: start.add(Duration(seconds: seconds < 1 ? 1 : seconds)),
      ),
    );
  }

  @override
  void dispose() {
    stopClock();
    if (_startedAt case final start?) _end(start);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final log = ref.watch(contractionsSinceProvider(_since)).value ?? const [];
    final summary = summariseContractions(log, clockNow());
    final running = _startedAt != null;
    final onCard = scheme.onTertiaryContainer;

    Widget stat(String value, String label) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: text.titleMedium!.copyWith(
                fontSize: 20,
                height: 26 / 20,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: text.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    String length(Duration? d) =>
        d == null ? '—' : l10n.secondsShort(d.inSeconds);
    String gap(Duration? d) =>
        d == null ? '—' : l10n.minutesShort((d.inSeconds / 60).round());

    final rows = [
      for (final (i, c) in log.take(12).indexed)
        (
          at: formatTime(c.startedAt),
          length: length(c.endedAt.difference(c.startedAt)),
          apart: i + 1 < log.length
              ? gap(c.startedAt.difference(log[i + 1].startedAt))
              : '—',
        ),
    ];

    final columns = text.bodySmall!.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.outline,
    );
    final cell = text.bodyLarge!.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget tableRow(List<String> cells, TextStyle style, {Color? last}) => Row(
      children: [
        for (final (i, c) in cells.indexed)
          Expanded(
            flex: i == 0 ? 6 : 5,
            child: Text(
              c,
              style: i == 2 && last != null
                  ? style.copyWith(color: last)
                  : style,
            ),
          ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(title: l10n.contractionTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Column(
                        spacing: 14,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              running
                                  ? l10n.contractionInProgress
                                  : l10n.contractionResting,
                              textAlign: TextAlign.center,
                              style: text.bodySmall!.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: onCard,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              clockText(seconds),
                              style: text.displayMedium!.copyWith(
                                fontSize: 56,
                                height: 64 / 56,
                                fontWeight: FontWeight.w800,
                                color: onCard,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              // A new button per state: no colour tween, so
                              // the label never fades through the fill.
                              key: ValueKey(running),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 64),
                                backgroundColor: running
                                    ? scheme.surface
                                    : scheme.primary,
                                foregroundColor: running
                                    ? scheme.onSurface
                                    : scheme.onPrimary,
                                textStyle: text.labelLarge!.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              onPressed: _press,
                              child: Text(
                                running
                                    ? l10n.contractionEnd
                                    : l10n.contractionStart,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        Expanded(
                          child: stat('${summary.count}', l10n.inLastHour),
                        ),
                        Expanded(
                          child: stat(
                            length(summary.averageLength),
                            l10n.averageLength,
                          ),
                        ),
                        Expanded(
                          child: stat(
                            gap(summary.averageGap),
                            l10n.apartOnAverage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    Text(
                      l10n.contractionsEmpty,
                      style: columns.copyWith(fontWeight: FontWeight.w700),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ExcludeSemantics(
                        child: tableRow([
                          l10n.startedColumn,
                          l10n.lengthColumn,
                          l10n.apartColumn,
                        ], columns),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, r) in rows.indexed) ...[
                            if (i > 0) const Divider(),
                            Semantics(
                              container: true,
                              label:
                                  '${l10n.startedColumn} ${r.at}, '
                                  '${l10n.lengthColumn} ${r.length}, '
                                  '${l10n.apartColumn} ${r.apart}',
                              excludeSemantics: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: tableRow(
                                  [r.at, r.length, r.apart],
                                  cell,
                                  last: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.contractionNote,
                        style: text.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
