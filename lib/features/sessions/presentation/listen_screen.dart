import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/features/sessions/data/listening_log.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Listening (prototype "Listen"): plays an imported audio file that keeps
/// going with the screen off, with a sleep timer and a near-black "screen
/// off" mode. No wakelock: the phone locks as usual.
class ListenScreen extends ConsumerStatefulWidget {
  const new({required this.itemId, this.screenOff = false, super.key});

  final String itemId;

  /// Opens already in screen-off mode.
  final bool screenOff;

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  LibraryItem? _item;
  bool _failed = false;
  late bool _asleep = widget.screenOff;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final library = ref.read(libraryRepositoryProvider);
      final audio = await ref.read(audioPlaybackProvider.future);
      await ref.read(listeningLogProvider.future);
      final item = await library.get(widget.itemId);
      if (item == null) throw StateError('missing');
      final duration = await audio.open(
        itemId: item.id,
        title: item.title,
        path: (await library.file(item)).path,
      );
      await library.markOpened(item.id);
      if (item.durationSec == null && duration != null) {
        await library.setDuration(item.id, duration.inSeconds);
      }
      if (!mounted) return;
      setState(() => _item = item);
      if (!audio.current.playing) await audio.play();
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<AudioPlayback> get _audio => ref.read(audioPlaybackProvider.future);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.navmaas;
    final item = _item;
    final p = ref.watch(playbackProvider).value ?? idlePlayback;
    final mine = item != null && p.itemId == item.id;
    final playing = mine && p.playing;
    final position = mine ? p.position : Duration.zero;
    final duration = mine ? p.duration : null;
    final sleep = ref.watch(sleepTimerProvider);
    final caption = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.outline,
    );

    Widget round({
      required double size,
      required Color bg,
      required Widget icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: bg,
        fixedSize: Size.square(size),
      ),
      icon: icon,
    );

    final player = Column(
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
                    l10n.listening,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
            child: Column(
              spacing: 28,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 248,
                    height: 248,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.tertiaryContainer,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final (inset, alpha) in [
                          (28.0, 0.35),
                          (58.0, 0.55),
                        ])
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(inset),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 1.5,
                                    color: scheme.tertiary.withValues(
                                      alpha: alpha,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Container(
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface,
                          ),
                          child: NmIcon(
                            NavmaasIcon.moon,
                            size: 40,
                            strokeWidth: 1.6,
                            color: scheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  spacing: 2,
                  children: [
                    Text(
                      item?.title ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 24,
                        height: 30 / 24,
                      ),
                    ),
                    Text(
                      _failed ? l10n.fileUnreadable : l10n.listenSub,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 6,
                  children: [
                    Semantics(
                      label: l10n.playbackPosition,
                      value: clockText(position.inSeconds),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: duration == null || duration == Duration.zero
                              ? 0
                              : (position.inMilliseconds /
                                        duration.inMilliseconds)
                                    .clamp(0, 1),
                          minHeight: 6,
                          color: scheme.tertiary,
                          backgroundColor: brand.track,
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(clockText(position.inSeconds), style: caption),
                          Text(
                            duration == null
                                ? ''
                                : clockText(duration.inSeconds),
                            style: caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 28,
                  children: [
                    round(
                      size: 52,
                      bg: scheme.surfaceContainerHighest,
                      tooltip: l10n.back15,
                      onPressed: mine
                          ? () async {
                              final back =
                                  position - const Duration(seconds: 15);
                              await (await _audio).seek(
                                back < Duration.zero ? Duration.zero : back,
                              );
                            }
                          : null,
                      icon: NmIcon(
                        NavmaasIcon.rewind,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    round(
                      size: 76,
                      bg: scheme.primary,
                      tooltip: playing ? l10n.pauseButton : l10n.playButton,
                      onPressed: mine
                          ? () async {
                              final audio = await _audio;
                              await (playing ? audio.pause() : audio.play());
                            }
                          : null,
                      icon: NmIcon(
                        playing ? NavmaasIcon.pause : NavmaasIcon.play,
                        size: 30,
                        strokeWidth: 2.6,
                        color: scheme.onPrimary,
                      ),
                    ),
                    round(
                      size: 52,
                      bg: scheme.surfaceContainerHighest,
                      tooltip: l10n.forward15,
                      onPressed: mine
                          ? () async {
                              final next =
                                  position + const Duration(seconds: 15);
                              await (await _audio).seek(
                                duration != null && next > duration
                                    ? duration
                                    : next,
                              );
                            }
                          : null,
                      icon: NmIcon(
                        NavmaasIcon.forward,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurfaceVariant,
                    textStyle: theme.textTheme.labelLarge!.copyWith(
                      fontSize: 13,
                    ),
                  ),
                  onPressed: ref.read(sleepTimerProvider.notifier).cycle,
                  child: Text(
                    sleep == null ? l10n.sleepTimerOff : l10n.sleepTimer(sleep),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 60),
              backgroundColor: scheme.tertiaryContainer,
              foregroundColor: scheme.onTertiaryContainer,
              textStyle: theme.textTheme.labelLarge!.copyWith(fontSize: 16),
            ),
            onPressed: () => setState(() => _asleep = true),
            icon: NmIcon(
              NavmaasIcon.eyeOff,
              size: 22,
              color: scheme.onTertiaryContainer,
            ),
            label: Text(l10n.screenOff, textAlign: TextAlign.center),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(child: _asleep ? _sleepOverlay(l10n, brand) : player),
    );
  }

  /// Near-black, so the screen rests; a tap brings the player back.
  Widget _sleepOverlay(AppLocalizations l10n, NavmaasColors brand) {
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w600, color: brand.sleepText);
    return Semantics(
      button: true,
      label: l10n.wakeScreen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _asleep = false),
        child: ColoredBox(
          color: brand.sleep,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  NmIcon(
                    NavmaasIcon.moon,
                    size: 28,
                    strokeWidth: 1.6,
                    color: brand.sleepText,
                  ),
                  Text(
                    l10n.isPlaying(_item?.title ?? ''),
                    textAlign: TextAlign.center,
                    style: style.copyWith(fontSize: 15),
                  ),
                  Text(
                    l10n.restEyes,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
