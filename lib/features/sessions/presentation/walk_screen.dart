import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/health.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// A walk's gentle goal (prototype "Goal 20 min · easy pace").
const walkGoalMinutes = 20;

/// "4,820" (Indian grouping, as in the prototype).
String formatSteps(int steps) =>
    NumberFormat.decimalPattern('en_IN').format(steps);

/// Walk (prototype "Walk session"): a timer that keeps counting with the
/// screen off, and steps from Apple Health / Health Connect. Always open
/// (Plan decision 27). Leaving logs the walk from one minute.
class WalkScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> with SessionClock {
  late final SessionRepository _sessions;
  late final StepSource _steps;
  late final String? _pregnancyId;
  final _startedAt = DateTime.now();
  Timer? _poll;
  bool? _access;
  int? _walkSteps;
  int? _todaySteps;

  @override
  bool get countWhileHidden => true;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(sessionRepositoryProvider);
    _steps = ref.read(stepSourceProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    startClock();
    unawaited(_askAndRead());
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _readSteps());
  }

  Future<void> _askAndRead() async {
    final access = await _steps.requestAccess();
    if (!mounted) return;
    setState(() => _access = access);
    await _readSteps();
  }

  Future<void> _readSteps() async {
    if (_access != true) return;
    final now = DateTime.now();
    final walk = await _steps.steps(_startedAt, now);
    final today = await _steps.steps(
      DateTime(now.year, now.month, now.day),
      now,
    );
    if (mounted) {
      setState(() {
        _walkSteps = walk;
        _todaySteps = today;
      });
      ref.invalidate(todayStepsProvider); // the Sessions tile
    }
  }

  @override
  void dispose() {
    stopClock();
    _poll?.cancel();
    if (seconds >= 60 && _pregnancyId != null) {
      unawaited(
        _sessions.log(
          pregnancyId: _pregnancyId,
          type: SessionType.walk,
          startedAt: _startedAt,
          durationSec: seconds,
          steps: _walkSteps,
        ),
      );
    }
    super.dispose();
  }

  Future<void> _changeGoal(int goal) async {
    final l10n = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => TextEntryDialog(
        title: l10n.stepsPerDay,
        initial: '$goal',
        singleLine: true,
        keyboardType: TextInputType.number,
      ),
    );
    final value = int.tryParse(text?.replaceAll(RegExp('[^0-9]'), '') ?? '');
    if (value != null && value > 0) {
      await ref
          .read(settingsRepositoryProvider)
          .put(SettingKeys.stepGoal, '$value');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = ref.watch(stepGoalProvider).value ?? defaultStepGoal;
    final caption = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.outline,
    );

    Widget stat(String label, int? value, String unit, {VoidCallback? onTap}) =>
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: caption),
                  Text(
                    value == null ? '—' : formatSteps(value),
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontSize: 26,
                      height: 34 / 26,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    child: Text(
                      l10n.walkTitle,
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
                        vertical: 28,
                      ),
                      child: Column(
                        spacing: 4,
                        children: [
                          Text(
                            paused ? l10n.pausedStatus : l10n.walkingStatus,
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              clockText(seconds),
                              style: theme.textTheme.displayMedium!.copyWith(
                                fontSize: 64,
                                height: 72 / 64,
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimaryContainer,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            l10n.walkGoal(walkGoalMinutes),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
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
                      spacing: 10,
                      children: [
                        Expanded(
                          child: stat(
                            l10n.thisWalk,
                            _walkSteps,
                            l10n.stepsLabel,
                          ),
                        ),
                        Expanded(
                          child: Semantics(
                            hint: l10n.changeStepGoal,
                            child: stat(
                              l10n.todayLabel,
                              _todaySteps,
                              l10n.ofSteps(formatSteps(goal)),
                              onTap: () => _changeGoal(goal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: l10n.dailyStepGoal,
                    value: l10n.walkTileSteps(
                      formatSteps(_todaySteps ?? 0),
                      formatSteps(goal),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ((_todaySteps ?? 0) / goal).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: context.navmaas.track,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_access == false)
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.stepsUnavailable, style: caption),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: _askAndRead,
                          child: Text(l10n.allowSteps),
                        ),
                      ],
                    )
                  else
                    Text(l10n.stepsSource, style: caption),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
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
                              NavmaasIcon.breath,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${l10n.talkTest} ${l10n.gentleNote}',
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      onPressed: () => context.pop(),
                      child: Text(l10n.finishWalk, textAlign: TextAlign.center),
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
