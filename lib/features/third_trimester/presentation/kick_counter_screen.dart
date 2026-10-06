import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/widgets/notice_box.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/features/third_trimester/data/third_trimester_repository.dart';
import 'package:navmaas/features/third_trimester/domain/patterns.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "8–10 pm", or "10 am–12 pm" across noon, for a window starting at [hour].
String formatWindow(int hour) {
  String h(int x) => '${x % 12 == 0 ? 12 : x % 12}';
  String half(int x) => x % 24 < 12 ? 'am' : 'pm';
  final end = hour + 2;
  return half(hour) == half(end)
      ? '${h(hour)}–${h(end)} ${half(end)}'
      : '${h(hour)} ${half(hour)}–${h(end)} ${half(end)}';
}

/// Kick counter (prototype "Kick counter", Plan §5.3): a log of her baby's
/// movements to show the doctor. The session starts at the first tap; Save
/// (or leaving with a count) logs it. Shows her own pattern, never a verdict.
class KickCounterScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends ConsumerState<KickCounterScreen>
    with SessionClock {
  late final ThirdTrimesterRepository _repo;
  late final String? _pregnancyId;
  DateTime? _startedAt;

  /// The clock second of each movement.
  final _kicks = <int>[];
  var _saved = false;

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

  void _tap() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (_startedAt == null) {
        _startedAt = clockNow();
        paused = false;
      }
      _kicks.add(seconds);
    });
  }

  void _undo() => setState(() {
    _kicks.removeLast();
    if (_kicks.isEmpty) {
      _startedAt = null;
      paused = true;
      seconds = 0;
    }
  });

  void _save() {
    final start = _startedAt;
    if (_saved || start == null || _kicks.isEmpty || _pregnancyId == null) {
      return;
    }
    _saved = true;
    unawaited(
      _repo.saveKicks(
        pregnancyId: _pregnancyId,
        startedAt: start,
        endedAt: start.add(Duration(seconds: _kicks.last)),
        count: _kicks.length,
      ),
    );
  }

  @override
  void dispose() {
    stopClock();
    _save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final sessions = ref.watch(kickSessionsProvider).value ?? const [];
    final window = mostActiveWindow(sessions);
    final now = clockNow();
    final count = _kicks.length;
    final caption = text.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.outline,
    );

    Widget stat(String label, String value) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: caption),
            Text(
              value,
              style: text.titleMedium!.copyWith(
                fontSize: 20,
                height: 28 / 20,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(title: l10n.kickTitle, subtitle: l10n.kickSubtitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: Semantics(
                      button: true,
                      label: l10n.kickTapLabel(count),
                      excludeSemantics: true,
                      onTap: _tap,
                      child: Material(
                        shape: CircleBorder(
                          side: BorderSide(
                            width: 10,
                            color: scheme.secondaryContainer,
                          ),
                        ),
                        color: scheme.surface,
                        elevation: 2,
                        shadowColor: const Color(0x293C281E),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _tap,
                          child: SizedBox.square(
                            dimension: 220,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$count',
                                      style: text.displayMedium!.copyWith(
                                        fontSize: 64,
                                        height: 68 / 64,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      l10n.kickTapHint,
                                      style: text.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        Expanded(
                          child: stat(
                            l10n.kickStarted,
                            _startedAt == null ? '—' : formatTime(_startedAt!),
                          ),
                        ),
                        Expanded(
                          child: stat(
                            l10n.kickTimeSoFar,
                            l10n.minutesShort(seconds ~/ 60),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.recentSessions,
                      style: text.titleMedium!.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (sessions.isEmpty)
                    Text(l10n.kickNoSessions, style: caption)
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, s) in sessions.take(5).indexed) ...[
                            if (i > 0) const Divider(),
                            LogRow(
                              label:
                                  '${dayLabel(s.startedAt, now, l10n)} · '
                                  '${formatTime(s.startedAt)}',
                              value: l10n.kickResult(s.count, _minutes(s)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (window != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.kickMostActive(formatWindow(window)),
                      style: caption,
                    ),
                  ],
                  const SizedBox(height: 16),
                  NoticeBox(text: l10n.kickNote),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                        textStyle: text.labelLarge!.copyWith(fontSize: 16),
                      ),
                      onPressed: count == 0 ? null : _undo,
                      child: Text(l10n.undoLast, textAlign: TextAlign.center),
                    ),
                  ),
                  Expanded(
                    flex: 13,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 56),
                        textStyle: text.labelLarge!.copyWith(fontSize: 16),
                      ),
                      onPressed: () {
                        _save();
                        context.pop();
                      },
                      child: Text(
                        l10n.saveSession,
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

  /// Whole minutes from the first to the last movement, at least one.
  static int _minutes(KickSession s) {
    final m = (s.endedAt.difference(s.startedAt).inSeconds / 60).round();
    return m < 1 ? 1 : m;
  }
}
