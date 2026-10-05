import 'dart:async';

import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/platform/audio.dart';
import 'package:navmaas/features/sessions/data/session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'listening_log.g.dart';

/// Turns playback into listening sessions: one per item she plays, growing
/// while it actually plays (screen on or off). Logged from one minute.
class ListeningLogger {
  new(this._sessions, {required this.pregnancyId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SessionRepository _sessions;
  final String? Function() pregnancyId;
  final DateTime Function() _clock;

  static const minimum = Duration(minutes: 1);
  static const saveEvery = Duration(seconds: 30);

  Future<void> _queue = Future.value();
  String? _itemId;
  String? _sessionId;
  DateTime? _startedAt;
  DateTime? _since;
  DateTime? _savedAt;
  Duration _played = Duration.zero;

  /// Feeds one playback update; updates are handled in order.
  Future<void> onPlayback(Playback p) => _queue = _queue.then((_) => _on(p));

  Future<void> _on(Playback p) async {
    final now = _clock();
    if (p.itemId != _itemId) {
      _stopClock(now);
      await _save(now);
      _itemId = p.itemId;
      _sessionId = _startedAt = _since = _savedAt = null;
      _played = Duration.zero;
    }
    if (p.playing && _since == null) {
      _since = now;
      _startedAt ??= now;
    } else if (!p.playing && _since != null) {
      _stopClock(now);
      await _save(now);
    } else if (p.playing && now.difference(_savedAt ?? _since!) >= saveEvery) {
      _stopClock(now);
      _since = now;
      await _save(now);
    }
  }

  void _stopClock(DateTime now) {
    if (_since case final since?) _played += now.difference(since);
    _since = null;
  }

  Future<void> _save(DateTime now) async {
    final pregnancy = pregnancyId();
    if (_played < minimum || _itemId == null || pregnancy == null) return;
    _savedAt = now;
    if (_sessionId case final id?) {
      await _sessions.setDuration(id, _played.inSeconds);
      return;
    }
    _sessionId = await _sessions.log(
      pregnancyId: pregnancy,
      type: SessionType.listening,
      startedAt: _startedAt!,
      durationSec: _played.inSeconds,
      libraryItemId: _itemId,
    );
  }
}

/// Started by the Listen screen; kept alive so audio that goes on playing
/// after she leaves it is still counted.
@Riverpod(keepAlive: true)
Future<ListeningLogger> listeningLog(Ref ref) async {
  final audio = await ref.watch(audioPlaybackProvider.future);
  final logger = ListeningLogger(
    ref.watch(sessionRepositoryProvider),
    pregnancyId: () => ref.read(activePregnancyProvider).value?.id,
  );
  final sub = audio.changes.listen(logger.onPlayback);
  ref.onDispose(sub.cancel);
  return logger;
}
