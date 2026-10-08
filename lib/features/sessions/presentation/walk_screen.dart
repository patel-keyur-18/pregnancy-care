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
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:navmaas/features/sessions/domain/walk_draft.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// A walk's gentle goal (prototype "Goal 20 min · easy pace").
const walkGoalMinutes = 20;

/// "4,820" (Indian grouping, as in the prototype).
String formatSteps(int steps) =>
    NumberFormat.decimalPattern('en_IN').format(steps);

/// Walk (prototype "Walk session"): Start, then Pause / Resume and Finish
/// walk. The walk is kept in `settings` until Finish, so leaving (which
/// pauses it) and coming back carries on where she was; with the screen off
/// it keeps counting. Steps come from Apple Health / Health Connect, counted
/// only while she walks. Always open (Plan decision 27). Finish logs the
/// walk from one minute.
class WalkScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  late final SessionRepository _sessions;
  late final SettingsRepository _settings;
  late final StepSource _steps;
  late final String? _pregnancyId;
  Timer? _tick;
  Timer? _poll;
  WalkDraft? _draft;
  bool _loaded = false;
  bool? _access;
  int? _walkSteps;
  int? _todaySteps;

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(sessionRepositoryProvider);
    _settings = ref.read(settingsRepositoryProvider);
    _steps = ref.read(stepSourceProvider);
    _pregnancyId = ref.read(activePregnancyProvider).value?.id;
    // Carry on with a walk she left; once, from the saved draft.
    ref.listenManual(walkDraftProvider, (_, next) {
      if (_loaded || next is! AsyncData<WalkDraft?>) return;
      _loaded = true;
      unawaited(_load(next.value));
    }, fireImmediately: true);
    unawaited(_askAndRead());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_draft?.running ?? false) setState(() {});
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_draft?.running ?? false) unawaited(_readSteps());
    });
  }

  Future<void> _load(WalkDraft? saved) async {
    var draft = saved;
    final now = clockNow();
    // A walk left from an earlier day goes to that day; today starts fresh.
    if (draft != null &&
        draft.startedBefore(DateTime(now.year, now.month, now.day))) {
      await _log(draft.endOfItsDay());
      await _settings.remove(SettingKeys.walkDraft);
      draft = null;
    }
    if (!mounted) return;
    setState(() => _draft = draft);
    await _readSteps();
  }

  Future<void> _askAndRead() async {
    final access = await _steps.requestAccess();
    if (!mounted) return;
    setState(() => _access = access);
    await _readSteps();
  }

  /// Steps over the stretches she walked; null without Health access.
  Future<int?> _stepsOf(WalkDraft draft, DateTime now) async {
    var total = 0;
    for (final (from, to) in draft.stretches) {
      final n = await _steps.steps(from, to ?? now);
      if (n == null) return null;
      total += n;
    }
    return total;
  }

  Future<void> _readSteps() async {
    if (_access != true) return;
    final now = clockNow();
    final draft = _draft;
    final walk = draft == null ? 0 : await _stepsOf(draft, now);
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

  void _save(WalkDraft draft) {
    setState(() => _draft = draft);
    unawaited(_settings.put(SettingKeys.walkDraft, draft.encode()));
    unawaited(_readSteps());
  }

  /// Logs [draft] (a paused walk) from one minute.
  Future<void> _log(WalkDraft draft) async {
    final seconds = draft.seconds(clockNow());
    if (seconds < 60 || _pregnancyId == null) return;
    final steps = _access == false ? null : await _stepsOf(draft, clockNow());
    await _sessions.log(
      pregnancyId: _pregnancyId,
      type: SessionType.walk,
      startedAt: draft.startedAt,
      durationSec: seconds,
      steps: steps,
    );
  }

  Future<void> _finish() async {
    final draft = _draft?.pause(clockNow());
    _draft = null;
    if (draft != null) {
      await _log(draft);
      await _settings.remove(SettingKeys.walkDraft);
    }
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    // Leaving pauses the walk; it waits for her in settings.
    final draft = _draft;
    if (draft != null && draft.running) {
      unawaited(
        _settings.put(SettingKeys.walkDraft, draft.pause(clockNow()).encode()),
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
    final draft = _draft;
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
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.walkTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
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
                            switch (draft) {
                              null => l10n.readyStatus,
                              WalkDraft(running: true) => l10n.walkingStatus,
                              _ => l10n.pausedStatus,
                            },
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              clockText(draft?.seconds(clockNow()) ?? 0),
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
                  if (draft != null)
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
                        onPressed: () => _save(
                          draft.running
                              ? draft.pause(clockNow())
                              : draft.resume(clockNow()),
                        ),
                        child: Text(
                          draft.running ? l10n.pauseButton : l10n.resumeButton,
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
                      onPressed: draft == null
                          ? () => _save(WalkDraft.start(clockNow()))
                          : _finish,
                      child: Text(
                        draft == null ? l10n.startButton : l10n.finishWalk,
                        textAlign: TextAlign.center,
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
