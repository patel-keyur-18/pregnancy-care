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

/// Playback ids that start with this are meditation (M7b): the timer's track
/// (`meditation:timer-10`) or her own audio (`meditation:<library item id>`).
const meditationPrefix = 'meditation:';

String meditationTimerId(int minutes) => '${meditationPrefix}timer-$minutes';

String meditationAudioId(String libraryItemId) =>
    '$meditationPrefix$libraryItemId';

/// The library item a meditation id plays, or null for the timer's track.
String? meditationLibraryItem(String playbackId) {
  final rest = playbackId.substring(meditationPrefix.length);
  return rest.startsWith('timer-') ? null : rest;
}

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

  /// Loads the meditation timer as one track (Plan decision 42): the bell,
  /// quiet until [minutes] have passed, then the bell again. Position and
  /// length are of the whole track, so it keeps time with the phone locked.
  Future<Duration?> openMeditation({
    required int minutes,
    required String title,
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
  String? _path;
  Playback _current = idlePlayback;

  /// For the meditation track: where each piece starts, and its length.
  List<Duration>? _offsets;
  Duration? _total;

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
      position:
          (_offsets?[_player.currentIndex ?? 0] ?? Duration.zero) +
          _player.position,
      duration: _total ?? _player.duration,
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
        updatePosition: _current.position,
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
    // The same item with a new path is a replaced file: load it again.
    if (_itemId == itemId && _path == path) return _player.duration;
    _itemId = itemId;
    _path = path;
    _offsets = _total = null;
    final duration = await _player.setFilePath(path);
    mediaItem.add(MediaItem(id: itemId, title: title, duration: duration));
    _emit();
    return duration;
  }

  @override
  Future<Duration?> openMeditation({
    required int minutes,
    required String title,
  }) async {
    final id = meditationTimerId(minutes);
    if (_itemId == id) return _total;
    _itemId = id;
    _path = null;
    const bell = Duration(seconds: 4);
    const quiet = Duration(seconds: 30);
    final length = Duration(minutes: minutes);
    // The quiet clip fills the time after the first bell, the last piece
    // clipped, so the second bell starts exactly at [length].
    final pieces = <(AudioSource, Duration)>[
      (AudioSource.asset('assets/audio/bell.wav'), bell),
    ];
    for (var at = bell; at < length; at += quiet) {
      final left = length - at;
      pieces.add(
        left >= quiet
            ? (AudioSource.asset('assets/audio/quiet.wav'), quiet)
            : (
                ClippingAudioSource(
                  child: AudioSource.asset('assets/audio/quiet.wav'),
                  end: left,
                ),
                left,
              ),
      );
    }
    pieces.add((AudioSource.asset('assets/audio/bell.wav'), bell));
    final offsets = <Duration>[];
    var at = Duration.zero;
    for (final (_, d) in pieces) {
      offsets.add(at);
      at += d;
    }
    _offsets = offsets;
    _total = at;
    await _player.setAudioSources([for (final (s, _) in pieces) s]);
    mediaItem.add(MediaItem(id: id, title: title, duration: _total));
    _emit();
    return _total;
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

/// The current playback, then every change.
@riverpod
Stream<Playback> playback(Ref ref) async* {
  final audio = await ref.watch(audioPlaybackProvider.future);
  yield audio.current;
  yield* audio.changes;
}

/// Pauses playback after 10, 20 or 30 minutes (Listen's sleep timer). Kept
/// alive so it still runs after she leaves the Listen screen.
@Riverpod(keepAlive: true)
class SleepTimer extends _$SleepTimer {
  Timer? _timer;

  @override
  int? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Off → 10 → 20 → 30 min → off.
  void cycle() {
    final next = switch (state) {
      null => 10,
      10 => 20,
      20 => 30,
      _ => null,
    };
    _timer?.cancel();
    if (next != null) {
      _timer = Timer(Duration(minutes: next), () async {
        state = null;
        await (await ref.read(audioPlaybackProvider.future)).pause();
      });
    }
    state = next;
  }
}
