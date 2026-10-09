import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice.g.dart';

/// Records a voice letter (E3) into a file in [voiceTempDir], which is
/// encrypted and deleted as soon as she stops. Faked in widget tests.
abstract interface class VoiceRecorder {
  /// Asks for the microphone the first time; false when it's off.
  Future<bool> requestPermission();
  Future<void> start(String path);

  /// Stops; the recorded file's path, or null if nothing was recorded.
  Future<String?> stop();
  Future<void> dispose();
}

class DeviceVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  /// AAC in an M4A file, mono: about half a megabyte a minute.
  @override
  Future<void> start(String path) => _recorder.start(
    const RecordConfig(numChannels: 1, bitRate: 64000),
    path: path,
  );

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}

/// What the voice note player is doing.
typedef VoicePlayback = ({
  bool playing,
  bool completed,
  Duration position,
  Duration? duration,
});

/// Plays a decrypted voice note on the letter screen only: not the
/// background player, no lock-screen controls, not logged as listening.
abstract interface class VoicePlayer {
  Stream<VoicePlayback> get changes;
  Future<Duration?> open(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

class DeviceVoicePlayer implements VoicePlayer {
  // Like the background player: playback events only come on load, play,
  // pause and the end, so the position stream (a tick about every 200 ms
  // while playing) moves the time and the bar.
  new() {
    _player.playbackEventStream.listen((_) => _emit());
    _player.playerStateStream.listen((_) => _emit());
    _player.positionStream.listen((_) => _emit());
  }

  final _player = AudioPlayer();
  final _changes = StreamController<VoicePlayback>.broadcast();

  void _emit() {
    if (_changes.isClosed) return;
    _changes.add((
      playing: _player.playing,
      completed: _player.processingState == ProcessingState.completed,
      position: _player.position,
      duration: _player.duration,
    ));
  }

  @override
  Stream<VoicePlayback> get changes => _changes.stream;

  @override
  Future<Duration?> open(String path) => _player.setFilePath(path);

  // just_audio's play() completes only when playback stops.
  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _changes.close();
  }
}

/// A new recorder for each letter screen.
@riverpod
VoiceRecorder Function() newVoiceRecorder(Ref ref) => DeviceVoiceRecorder.new;

/// A new player for each letter screen.
@riverpod
VoicePlayer Function() newVoicePlayer(Ref ref) => DeviceVoicePlayer.new;

/// Keeps the screen from dimming and locking while she records
/// (`navmaas/screen`). Faked in widget tests.
typedef KeepScreenOn = Future<void> Function({required bool on});

@riverpod
KeepScreenOn keepScreenOn(Ref ref) => ({required on}) async {
  try {
    await const MethodChannel('navmaas/screen')
        .invokeMethod<void>('keepOn', on);
  } on MissingPluginException {
    // Not on a phone.
  }
};

/// The private temporary folder for a recording or a voice note being
/// played (OS backups skip it). Emptied when the letter screen closes and
/// when the app starts, so no plain copy outlives its use.
@Riverpod(keepAlive: true)
Future<Directory> voiceTempDir(Ref ref) async =>
    Directory(p.join((await getTemporaryDirectory()).path, 'voice'));

/// Deletes every plain recording or played copy in [dir].
Future<void> clearVoiceTemp(Directory dir) async {
  if (dir.existsSync()) await dir.delete(recursive: true);
}
