import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio.g.dart';

/// What's loaded and how far it has played.
typedef Playback = ({
  String? itemId,
  bool playing,
  bool completed,
  Duration position,
  Duration? duration,
});

const Playback idlePlayback = (
  itemId: null,
  playing: false,
  completed: false,
  position: Duration.zero,
  duration: null,
);

/// Audio that keeps playing with the screen off, with lock-screen controls
/// (ARCHITECTURE §10). Faked in widget tests.
abstract interface class AudioPlayback {
  Playback get current;
  Stream<Playback> get changes;

  /// Loads a library file (if it isn't loaded already) and returns its
  /// length, when known.
  Future<Duration?> open({
    required String itemId,
    required String title,
    required String path,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
}

/// just_audio behind an audio_service handler: a media foreground service
/// on Android, the audio background mode and Now Playing on iOS.
class DeviceAudioPlayback extends BaseAudioHandler
    with SeekHandler
    implements AudioPlayback {
  new _() {
    _player.playbackEventStream.listen((_) => _emit());
    _player.playerStateStream.listen((_) => _emit());
    _player.positionStream.listen((_) => _emit());
  }

  static Future<DeviceAudioPlayback>? _instance;

  /// Starts the audio service once, on first use (not at app start).
  static Future<DeviceAudioPlayback> get instance =>
      _instance ??= AudioService.init(
        builder: DeviceAudioPlayback._,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.patelkeyur.navmaas.listening',
          androidNotificationChannelName: 'Listening',
          androidNotificationOngoing: true,
          fastForwardInterval: Duration(seconds: 15),
          rewindInterval: Duration(seconds: 15),
        ),
      );

  final _player = AudioPlayer();
  final _changes = StreamController<Playback>.broadcast();
  String? _itemId;
  Playback _current = idlePlayback;

  @override
  Playback get current => _current;

  @override
  Stream<Playback> get changes => _changes.stream;

  void _emit() {
    final completed = _player.processingState == ProcessingState.completed;
    _current = (
      itemId: _itemId,
      playing: _player.playing && !completed,
      completed: completed,
      position: _player.position,
      duration: _player.duration,
    );
    _changes.add(_current);
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          if (_current.playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  @override
  Future<Duration?> open({
    required String itemId,
    required String title,
    required String path,
  }) async {
    if (_itemId == itemId) return _player.duration;
    _itemId = itemId;
    final duration = await _player.setFilePath(path);
    mediaItem.add(MediaItem(id: itemId, title: title, duration: duration));
    _emit();
    return duration;
  }

  @override
  Future<void> play() async {
    if (_current.completed) await _player.seek(Duration.zero);
    // just_audio's play() completes only when playback stops.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}

@Riverpod(keepAlive: true)
Future<AudioPlayback> audioPlayback(Ref ref) => DeviceAudioPlayback.instance;
