import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/platform/voice.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/sessions/data/letter_repository.dart';
import 'package:navmaas/features/sessions/presentation/session_clock.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:path/path.dart' as p;

/// The longest voice note (E3, Plan decision 62).
const int voiceMaxSeconds = 10 * 60;

/// Letters to baby ("Talk to baby"), newest first: words, a voice note, or
/// both (prototype "Letters to baby", E3).
class LettersScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final letters = ref.watch(lettersProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lettersTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          24,
        ),
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: () => context.go('/sessions/letters/edit'),
                  icon: NmIcon(
                    NavmaasIcon.pencil,
                    size: 18,
                    strokeWidth: 2.2,
                    color: scheme.onPrimary,
                  ),
                  label: Text(l10n.writeLetter),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 52),
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(width: 1.5, color: scheme.outlineVariant),
                  ),
                  onPressed: () => context.go('/sessions/letters/edit?speak=1'),
                  icon: const NmIcon(
                    NavmaasIcon.mic,
                    size: 18,
                    strokeWidth: 2.2,
                  ),
                  label: Text(l10n.speakLetter),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (letters.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.lettersEmpty,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          for (final letter in letters) _LetterCard(letter),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const new(this.letter);

  final Letter letter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final seconds = letter.voiceSec;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/sessions/letters/edit', extra: letter.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                formatDate(letter.createdAt.toLocal()),
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.outline,
                ),
              ),
              if (letter.voiceFile != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: NmIcon(
                            NavmaasIcon.play,
                            size: 14,
                            color: scheme.tertiary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.voiceNoteChip(clockText(seconds ?? 0)),
                            style: theme.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (letter.body.isNotEmpty)
                Text(
                  letter.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.reading.copyWith(
                    fontSize: 16,
                    height: 24 / 16,
                    color: scheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Write or record a new letter, or reread and edit one. Her voice note is
/// recorded into the private temporary folder and sealed with the
/// attachment key the moment she stops; to play it, a plain copy goes back
/// there until the screen closes (E3, ADR 055).
class EditLetterScreen extends ConsumerStatefulWidget {
  const new({this.letterId, this.speak = false, super.key});

  final String? letterId;

  /// Opened from "Speak": the voice note first, no keyboard.
  final bool speak;

  @override
  ConsumerState<EditLetterScreen> createState() => _EditLetterScreenState();
}

enum _Voice { none, recording, recorded }

class _EditLetterScreenState extends ConsumerState<EditLetterScreen> {
  final _body = TextEditingController();
  late final Future<AttachmentStore> _store;
  late final Future<Directory> _temp;
  late final KeepScreenOn _keepScreenOn;
  late final VoiceRecorder _recorder;
  late final VoicePlayer _player;
  StreamSubscription<VoicePlayback>? _playback;
  AppLifecycleListener? _lifecycle;
  Timer? _tick;
  bool _loaded = false;
  bool _saved = false;

  /// The voice note the letter had when opened.
  String? _savedVoice;

  /// The voice note shown now (sealed file name), and its length.
  String? _voice;
  int? _voiceSec;

  /// Notes recorded on this screen, deleted unless she saves one of them.
  final _recordedHere = <String>[];

  _Voice _state = _Voice.none;
  int _recordSeconds = 0;
  bool _micOff = false;
  bool _missing = false;

  /// The plain copy loaded in the player, if any.
  String? _loadedVoice;
  VoicePlayback? _now;

  @override
  void initState() {
    super.initState();
    _store = ref.read(voiceStoreProvider.future);
    _temp = ref.read(voiceTempDirProvider.future);
    _keepScreenOn = ref.read(keepScreenOnProvider);
    _recorder = ref.read(newVoiceRecorderProvider)();
    _player = ref.read(newVoicePlayerProvider)();
    _playback = _player.changes.listen((now) {
      if (mounted) setState(() => _now = now);
    });
    // Leaving Navmaas (or locking the phone) stops a recording; what she
    // said is kept.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (_state == _Voice.recording) unawaited(_stop());
        if (_now?.playing ?? false) unawaited(_player.pause());
      },
    );
    // Seed from the saved letter once, as soon as letters have loaded.
    if (widget.letterId != null) {
      ref.listenManual(lettersProvider, (_, next) {
        if (_loaded || !next.hasValue) return;
        _loaded = true;
        final letter = next.value!
            .where((l) => l.id == widget.letterId)
            .firstOrNull;
        if (letter == null) return;
        _body.text = letter.body;
        _savedVoice = _voice = letter.voiceFile;
        _voiceSec = letter.voiceSec;
        _state = _voice == null ? _Voice.none : _Voice.recorded;
        if (mounted) setState(() {});
      }, fireImmediately: true);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle?.dispose();
    unawaited(_playback?.cancel());
    final wasRecording = _state == _Voice.recording;
    final unsaved = _saved ? const <String>[] : [..._recordedHere];
    unawaited(() async {
      if (wasRecording) {
        await _recorder.stop();
        await _keepScreenOn(on: false);
      }
      await _recorder.dispose();
      await _player.dispose();
      final store = await _store;
      for (final name in unsaved) {
        await store.delete(name);
      }
      // No plain copy outlives the screen.
      await clearVoiceTemp(await _temp);
    }());
    _body.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    if (_now?.playing ?? false) await _player.pause();
    if (!await _recorder.requestPermission()) {
      if (mounted) setState(() => _micOff = true);
      return;
    }
    final temp = await _temp;
    await temp.create(recursive: true);
    await _keepScreenOn(on: true);
    await _recorder.start(
      p.join(temp.path, 'rec-${clockNow().millisecondsSinceEpoch}.m4a'),
    );
    if (!mounted) return;
    setState(() {
      _micOff = false;
      _state = _Voice.recording;
      _recordSeconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
      if (_recordSeconds >= voiceMaxSeconds) unawaited(_stop());
    });
  }

  /// Stops recording and seals what she said; the plain file goes at once.
  Future<void> _stop() async {
    if (_state != _Voice.recording) return;
    _tick?.cancel();
    final seconds = _recordSeconds;
    setState(() => _state = _voice == null ? _Voice.none : _Voice.recorded);
    final path = await _recorder.stop();
    await _keepScreenOn(on: false);
    if (path == null || seconds < 1) return;
    final plain = File(path);
    final name = await (await _store).save(await plain.readAsBytes());
    if (plain.existsSync()) await plain.delete();
    // A note recorded here and now replaced is never needed again.
    final replaced = _voice;
    if (replaced != null && _recordedHere.remove(replaced)) {
      await (await _store).delete(replaced);
    }
    _recordedHere.add(name);
    if (!mounted) return;
    setState(() {
      _voice = name;
      _voiceSec = seconds;
      _missing = false;
      _state = _Voice.recorded;
    });
  }

  Future<void> _togglePlay() async {
    final voice = _voice;
    if (voice == null) return;
    if (_now?.playing ?? false) {
      await _player.pause();
      return;
    }
    if (_loadedVoice != voice) {
      final Uint8List bytes;
      try {
        bytes = await (await _store).read(voice);
      } on Object {
        // Restored from a backup made without voice letters.
        if (mounted) setState(() => _missing = true);
        return;
      }
      final temp = await _temp;
      await temp.create(recursive: true);
      final plain = File(p.join(temp.path, 'play-$voice.m4a'));
      await plain.writeAsBytes(bytes, flush: true);
      await _player.open(plain.path);
      _loadedVoice = voice;
    } else if (_now?.completed ?? false) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  Future<void> _removeVoice() async {
    if (_now?.playing ?? false) await _player.pause();
    final voice = _voice;
    if (voice != null && _recordedHere.remove(voice)) {
      await (await _store).delete(voice);
    }
    setState(() {
      _voice = null;
      _voiceSec = null;
      _missing = false;
      _state = _Voice.none;
    });
  }

  Future<void> _save() async {
    if (_state == _Voice.recording) await _stop();
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (pregnancy == null || (_body.text.trim().isEmpty && _voice == null)) {
      return;
    }
    await ref
        .read(letterRepositoryProvider)
        .save(
          pregnancy.id,
          _body.text,
          id: widget.letterId,
          voiceFile: _voice,
          voiceSec: _voiceSec,
        );
    _saved = true;
    final old = _savedVoice;
    if (old != null && old != _voice) await (await _store).delete(old);
    for (final name in _recordedHere.where((n) => n != _voice)) {
      await (await _store).delete(name);
    }
    if (mounted) context.pop();
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.removeLetter),
        content: Text(l10n.removeLetterNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.removeLetter),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(letterRepositoryProvider).remove(widget.letterId!);
    final old = _savedVoice;
    if (old != null) await (await _store).delete(old);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editLetter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          24,
        ),
        children: [
          TextField(
            controller: _body,
            autofocus: widget.letterId == null && !widget.speak,
            minLines: widget.speak ? 4 : 10,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(20000)],
            style: AppTheme.reading.copyWith(color: scheme.onSurface),
            decoration: InputDecoration(hintText: l10n.letterHint),
          ),
          const SizedBox(height: 14),
          _voiceCard(context),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
            onPressed: _save,
            child: Text(l10n.saveButton),
          ),
          if (widget.letterId != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 52),
                foregroundColor: scheme.error,
                side: BorderSide(width: 1.5, color: scheme.error),
              ),
              onPressed: _remove,
              icon: NmIcon(
                NavmaasIcon.close,
                size: 18,
                strokeWidth: 2,
                color: scheme.error,
              ),
              label: Text(l10n.removeLetter),
            ),
          ],
        ],
      ),
    );
  }

  /// The voice note card: Record, recording, or her note to play.
  Widget _voiceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final heading = Semantics(
      header: true,
      child: Text(
        l10n.voiceNote,
        style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
      ),
    );
    final caption = text.bodySmall!.copyWith(color: scheme.outline);
    final outlined = OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      side: BorderSide(width: 1.5, color: scheme.outlineVariant),
    );

    if (_state == _Voice.recording) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.secondary, // rose
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    l10n.recordingStatus,
                    style: text.bodySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  clockText(_recordSeconds),
                  style: text.displaySmall!.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                l10n.recordingOf(clockText(voiceMaxSeconds)),
                style: text.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: _stop,
                  icon: NmIcon(
                    NavmaasIcon.stop,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                  label: Text(l10n.stopButton),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final voice = _voice;
    return Card(
      margin: EdgeInsets.zero,
      // Its buttons stay separate for screen readers (a Card merges them).
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (voice == null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  Text(l10n.voiceNoteHint, style: caption),
                ],
              ),
              if (_micOff) Text(l10n.micOff, style: caption),
              OutlinedButton.icon(
                style: outlined,
                onPressed: _record,
                icon: NmIcon(
                  NavmaasIcon.mic,
                  size: 20,
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
                label: Text(l10n.recordButton),
              ),
            ] else ...[
              heading,
              if (_missing)
                Text(l10n.voiceMissing, style: caption)
              else
                _playerRow(context, voice),
              if (_micOff) Text(l10n.micOff, style: caption),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: outlined,
                      onPressed: _record,
                      icon: NmIcon(
                        NavmaasIcon.mic,
                        size: 18,
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                      label: Text(
                        l10n.recordAgain,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: l10n.removeVoiceNote,
                      excludeSemantics: true,
                      button: true,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: scheme.errorContainer,
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        onPressed: _removeVoice,
                        icon: NmIcon(
                          NavmaasIcon.close,
                          size: 18,
                          strokeWidth: 2,
                          color: scheme.onErrorContainer,
                        ),
                        label: Text(l10n.removeVoice),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Play / pause, how far it has played, and its length.
  Widget _playerRow(BuildContext context, String voice) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = _loadedVoice == voice ? _now : null;
    final playing = now?.playing ?? false;
    final total = now?.duration ?? Duration(seconds: _voiceSec ?? 0);
    final at = now?.completed ?? false ? total : now?.position ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return Row(
      spacing: 12,
      children: [
        IconButton.filled(
          tooltip: playing ? l10n.pauseVoice : l10n.playVoice,
          style: IconButton.styleFrom(fixedSize: const Size.square(52)),
          onPressed: _togglePlay,
          icon: NmIcon(
            playing ? NavmaasIcon.pause : NavmaasIcon.play,
            size: 22,
            strokeWidth: 2.4,
            color: scheme.onPrimary,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Semantics(
                label: l10n.voicePlayed,
                value: '${(progress * 100).round()}%',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: context.navmaas.track,
                  ),
                ),
              ),
              Text(
                '${clockText(at.inSeconds)} / ${clockText(total.inSeconds)}',
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
