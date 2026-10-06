import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Exercise session (prototype "Exercise session"): one move at a time with
/// a ring timer, up next, previous / next. Reached only when "doctor cleared
/// me" is on. Leaving logs the routine from one minute.
class ExerciseScreen extends ConsumerStatefulWidget {
  const new({required this.routineKey, super.key});

  final String routineKey;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen>
    with SessionClock {
  late final SessionRepository _sessions;
  late final String? _pregnancyId;
  final DateTime _startedAt = clockNow();
  int _step = 0;
  int? _left;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(sessionRepositoryProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    startClock();
  }

  Routine? get _routine => (ref.read(routinesProvider).value ?? const [])
      .where((r) => r.key == widget.routineKey)
      .firstOrNull;

  @override
  void onSecond() {
    final routine = _routine;
    if (routine == null) return;
    final left = (_left ?? routine.moves[_step].sec) - 1;
    if (left > 0) {
      _left = left;
    } else if (_step < routine.moves.length - 1) {
      _step++;
      _left = routine.moves[_step].sec;
    } else {
      _left = 0;
      _done = true;
      paused = true;
    }
  }

  void _go(int step) => setState(() {
    _step = step;
    _left = _routine!.moves[step].sec;
    _done = false;
  });

  @override
  void dispose() {
    stopClock();
    if (seconds >= 60 && _pregnancyId != null) {
      unawaited(
        _sessions.log(
          pregnancyId: _pregnancyId,
          type: SessionType.exercise,
          startedAt: _startedAt,
          durationSec: seconds,
          routineKey: widget.routineKey,
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.navmaas;
    final routine = ref
        .watch(routinesProvider)
        .value
        ?.where((r) => r.key == widget.routineKey)
        .firstOrNull;
    if (routine == null) return const Scaffold();
    final move = routine.moves[_step];
    final left = _left ?? move.sec;
    final upNext = routine.moves.skip(_step + 1).toList();

    Widget round(NavmaasIcon icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(56),
            backgroundColor: scheme.surface,
            side: BorderSide(width: 1.5, color: scheme.outlineVariant),
          ),
          icon: NmIcon(icon, size: 22, strokeWidth: 2),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
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
                      children: [
                        Text(
                          routine.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.routineStep(_step + 1, routine.moves.length),
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
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
                            label: l10n.moveSecondsLeft(left),
                            child: SizedBox.square(
                              dimension: 140,
                              child: CustomPaint(
                                painter: _Ring(
                                  progress: 1 - left / move.sec,
                                  track: scheme.surface,
                                  color: scheme.primary,
                                ),
                                child: _RingTime(
                                  time: clockText(left),
                                  label: l10n.leftLabel,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _done ? l10n.routineDone : move.name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge!.copyWith(
                              fontSize: 22,
                              height: 28 / 22,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          if (!_done)
                            Text(
                              move.how,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (upNext.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.upNext,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, m) in upNext.indexed) ...[
                            if (i > 0) const Divider(height: 1),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 52),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  spacing: 12,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.name,
                                        style: theme.textTheme.bodyLarge!
                                            .copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      l10n.minutesShort(
                                        math.max(1, (m.sec / 60).round()),
                                      ),
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.outline,
                                          ),
                                    ),
                                  ],
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
                      color: brand.amberSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: NmIcon(
                              NavmaasIcon.notice,
                              size: 20,
                              color: brand.onAmberSoft,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.gentleNote,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: brand.onAmberSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.clearedNote,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  round(
                    NavmaasIcon.chevronLeft,
                    l10n.previousMove,
                    _step > 0 ? () => _go(_step - 1) : null,
                  ),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 150),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 60),
                          textStyle: theme.textTheme.labelLarge!.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _done
                            ? () => context.pop()
                            : () => setState(() => paused = !paused),
                        child: Text(
                          _done
                              ? l10n.finishButton
                              : paused
                              ? l10n.resumeButton
                              : l10n.pauseButton,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  round(
                    NavmaasIcon.chevronRight,
                    l10n.nextMove,
                    _step < routine.moves.length - 1
                        ? () => _go(_step + 1)
                        : null,
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

/// "0:38 / left" inside the ring; shrinks to fit at large text sizes.
class _RingTime extends StatelessWidget {
  const new({required this.time, required this.label});

  final String time;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                time,
                style: theme.textTheme.headlineMedium!.copyWith(
                  fontSize: 34,
                  height: 40 / 34,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prototype's 140 px progress ring (10 px, round cap, from the top).
class _Ring extends CustomPainter {
  const new({required this.progress, required this.track, required this.color});

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final circle = rect.deflate(10);
    // Shows time remaining, like the prototype: full at the start.
    canvas
      ..drawArc(circle, 0, math.pi * 2, false, paint..color = track)
      ..drawArc(
        circle,
        -math.pi / 2,
        math.pi * 2 * (1 - progress.clamp(0, 1)),
        false,
        paint..color = color,
      );
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.progress != progress || old.track != track || old.color != color;
}
