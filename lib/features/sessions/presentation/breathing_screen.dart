import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Slow breathing's length (prototype "5 min").
const breathingMinutes = 5;

/// In for 4 s, out for 6 s.
const _inSec = 4;
const _cycleSec = 10;

/// Slow breathing (Plan decision 28): a quiet paced timer, no audio. A
/// circle grows as she breathes in and shrinks as she breathes out; with
/// reduce motion, only the words change. Starts when she taps Start, and
/// logs from one minute.
class BreathingScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SessionClock {
  late final SessionRepository _sessions;
  late final String? _pregnancyId;
  DateTime? _startedAt;

  static const int _total = breathingMinutes * 60;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(sessionRepositoryProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    paused = true;
    startClock();
  }

  @override
  void onSecond() {
    if (seconds >= _total) paused = true;
  }

  @override
  void dispose() {
    stopClock();
    if (seconds >= 60 && _pregnancyId != null && _startedAt != null) {
      unawaited(
        _sessions.log(
          pregnancyId: _pregnancyId,
          type: SessionType.breathing,
          startedAt: _startedAt!,
          durationSec: seconds,
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final done = seconds >= _total;
    final started = _startedAt != null;
    final inPhase = seconds % _cycleSec < _inSec;
    // Where the circle should be one second from now (it eases there).
    final next = (seconds + 1) % _cycleSec;
    final scale = next == 0
        ? 0.6
        : next <= _inSec
        ? 0.6 + 0.4 * next / _inSec
        : 1.0 - 0.4 * (next - _inSec) / (_cycleSec - _inSec);
    final running = started && !paused;

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
                    child: Text(
                      l10n.breathingTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                children: [
                  ExcludeSemantics(
                    child: Center(
                      child: Container(
                        width: 248,
                        height: 248,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.tertiaryContainer,
                        ),
                        child: AnimatedScale(
                          scale: running && !reduceMotion ? scale : 0.8,
                          duration: running && !reduceMotion
                              ? const Duration(seconds: 1)
                              : Duration.zero,
                          child: Container(
                            width: 200,
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.surface,
                              border: Border.all(
                                width: 1.5,
                                color: scheme.tertiary,
                              ),
                            ),
                            child: NmIcon(
                              NavmaasIcon.breath,
                              size: 40,
                              strokeWidth: 1.6,
                              color: scheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      done
                          ? l10n.routineDone
                          : running
                          ? (inPhase ? l10n.breatheIn : l10n.breatheOut)
                          : l10n.breathingTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 24,
                        height: 30 / 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    started
                        ? l10n.timeLeft(clockText(_total - seconds))
                        : l10n.breathingIntro,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                spacing: 10,
                children: [
                  if (started && !done)
                    Expanded(
                      flex: 10,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 56),
                          backgroundColor: scheme.surface,
                          side: BorderSide(
                            width: 1.5,
                            color: scheme.outlineVariant,
                          ),
                          textStyle: theme.textTheme.labelLarge!.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => setState(() => paused = !paused),
                        child: Text(
                          paused ? l10n.resumeButton : l10n.pauseButton,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 13,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        textStyle: theme.textTheme.labelLarge!.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      onPressed: started
                          ? () => context.pop()
                          : () => setState(() {
                              _startedAt = DateTime.now();
                              paused = false;
                            }),
                      child: Text(
                        started ? l10n.finishButton : l10n.startButton,
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
