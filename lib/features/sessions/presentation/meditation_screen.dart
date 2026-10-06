import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/listening_log.dart';
import 'package:navmaas/features/sessions/presentation/screen_off.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Meditation (prototype "Meditation", Plan decision 42): 5, 10, 15 or 20
/// minutes between two soft bells, played as one background-audio track so
/// it keeps time and rings with the phone locked; or her own audio. Logged
/// by the listening log as a meditation session, from one minute.
class MeditationScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen> {
  static const _lengths = [5, 10, 15, 20];
  static const _timerPrefix = '${meditationPrefix}timer-';

  var _minutes = 10;
  var _asleep = false;

  Future<AudioPlayback> get _audio => ref.read(audioPlaybackProvider.future);

  Future<void> _start(String title) async {
    final audio = await _audio;
    await ref.read(listeningLogProvider.future);
    await audio.openMeditation(minutes: _minutes, title: title);
    if (audio.current.position > Duration.zero) {
      await audio.seek(Duration.zero);
    }
    await audio.play();
  }

  Future<void> _finish() async {
    final audio = await _audio;
    await audio.pause();
    await audio.seek(Duration.zero);
    if (mounted) setState(() => _asleep = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = ref.watch(playbackProvider).value ?? idlePlayback;
    final id = p.itemId;
    // A timer track that has started and not finished (also after she
    // left this screen and came back).
    final running =
        id != null &&
        id.startsWith(_timerPrefix) &&
        !p.completed &&
        (p.playing || p.position > Duration.zero);
    final minutes = running
        ? int.parse(id.substring(_timerPrefix.length))
        : _minutes;
    final left = running
        ? Duration(minutes: minutes) - p.position
        : Duration(minutes: minutes);
    final seconds = left.isNegative ? 0 : left.inSeconds;
    final minutesLeft = (seconds / 60).ceil();
    final fg = scheme.onTertiaryContainer;

    if (_asleep && running) {
      return Scaffold(
        body: SafeArea(
          child: ScreenOff(
            icon: NavmaasIcon.bowl,
            title: l10n.meditationAsleep(minutesLeft),
            line: l10n.meditationBellAtEnd,
            onWake: () => setState(() => _asleep = false),
          ),
        ),
      );
    }

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
                        l10n.meditationTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 17,
                          height: 24 / 17,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Center(
                    child: Container(
                      width: 248,
                      height: 248,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.tertiaryContainer,
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Semantics(
                        liveRegion: running,
                        label: l10n.meditationLeft(minutesLeft),
                        excludeSemantics: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              NmIcon(
                                NavmaasIcon.bowl,
                                size: 36,
                                strokeWidth: 1.6,
                                color: scheme.tertiary,
                              ),
                              Text(
                                clockText(seconds),
                                style: theme.textTheme.displaySmall!.copyWith(
                                  fontSize: 52,
                                  height: 58 / 52,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                !running
                                    ? l10n.meditationMinutes(minutes)
                                    : p.playing
                                    ? l10n.meditationBreathe
                                    : l10n.meditationPaused,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (running)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final audio = await _audio;
                            await (p.playing ? audio.pause() : audio.play());
                          },
                          child: Text(
                            p.playing ? l10n.pauseButton : l10n.resumeButton,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _finish,
                          child: Text(l10n.finishButton),
                        ),
                      ],
                    )
                  else ...[
                    Semantics(
                      label: l10n.meditationLength,
                      container: true,
                      child: PillSegmented<int>(
                        segments: [
                          for (final m in _lengths)
                            (
                              value: m,
                              label: l10n.minutesShort(m),
                              caption: null,
                            ),
                        ],
                        selected: _minutes,
                        onChanged: (m) => setState(() => _minutes = m),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.meditationBell,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.outline,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _OwnAudioRow(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: running
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 60),
                        backgroundColor: scheme.tertiaryContainer,
                        foregroundColor: fg,
                      ),
                      onPressed: () => setState(() => _asleep = true),
                      icon: NmIcon(NavmaasIcon.eyeOff, size: 22, color: fg),
                      label: Text(
                        l10n.meditationScreenOff,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : FilledButton(
                      onPressed: () => unawaited(
                        _start(
                          '${l10n.meditationTitle} · '
                          '${l10n.minutesShort(_minutes)}',
                        ),
                      ),
                      child: Text(l10n.startButton),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Or use your own audio": her audio, the one played last first.
class _OwnAudioRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final audio = <LibraryItem>[
      for (final i
          in ref.watch(libraryItemsProvider).value ?? const <LibraryItem>[])
        if (i.kind == LibraryKind.audio) i,
    ]..sort(_lastOpenedFirst);
    final first = audio.firstOrNull;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: true,
        enabled: first != null,
        child: InkWell(
          onTap: first == null ? null : () => _choose(context, audio),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                IconTile(
                  background: scheme.tertiaryContainer,
                  child: NmIcon(
                    NavmaasIcon.music,
                    size: 20,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.meditationOwnAudio,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        first == null ? l10n.meditationOwnNone : _label(first),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (first != null)
                  NmIcon(
                    NavmaasIcon.chevronRight,
                    size: 20,
                    strokeWidth: 2,
                    color: scheme.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _lastOpenedFirst(LibraryItem a, LibraryItem b) =>
      (b.lastOpenedAt ?? b.createdAt).compareTo(a.lastOpenedAt ?? a.createdAt);

  static String _label(LibraryItem i) => i.durationSec == null
      ? i.title
      : '${i.title} · ${clockText(i.durationSec!)}';

  Future<void> _choose(BuildContext context, List<LibraryItem> audio) async {
    final picked = audio.length == 1
        ? audio.single
        : await showModalBottomSheet<LibraryItem>(
            context: context,
            showDragHandle: true,
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.meditationYourAudio,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    for (final i in audio)
                      ListTile(
                        minTileHeight: 56,
                        title: Text(_label(i)),
                        onTap: () => Navigator.pop(context, i),
                      ),
                  ],
                ),
              );
            },
          );
    if (picked == null || !context.mounted) return;
    unawaited(context.push('/listen?as=meditation', extra: picked.id));
  }
}
