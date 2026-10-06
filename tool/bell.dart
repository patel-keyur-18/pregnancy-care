// Generates Meditation's original sounds (Plan decision 42):
//   dart run tool/bell.dart
// assets/audio/bell.wav: a soft struck-bowl bell, 4 s, 22.05 kHz, 16-bit mono.
// assets/audio/quiet.wav: 30 s of silence, 8 kHz, 8-bit mono, looped between
// the bells so the timer plays as one background-audio track.
// Deterministic: a test checks the committed files match this script.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const bellWavPath = 'assets/audio/bell.wav';
const quietWavPath = 'assets/audio/quiet.wav';

/// Length of each sound, which the timer's track is built from.
const bellLength = Duration(seconds: 4);
const quietLength = Duration(seconds: 30);

void main() {
  File(bellWavPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bellWav());
  File(quietWavPath).writeAsBytesSync(quietWav());
}

/// A bowl struck softly: a low fundamental with a slow shimmer and a few
/// inharmonic partials that fade faster than it does.
Uint8List bellWav() {
  const rate = 22050;
  final n = rate * bellLength.inSeconds;
  // (frequency ratio, amplitude, decay time in seconds)
  const partials = [
    (1.0, 1.0, 1.6),
    (1.003, 0.3, 1.6),
    (2.71, 0.45, 0.9),
    (5.15, 0.2, 0.5),
    (8.43, 0.08, 0.3),
  ];
  const f0 = 392.0;
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (final (ratio, amp, decay) in partials) {
      v += amp * exp(-t / decay) * sin(2 * pi * f0 * ratio * t);
    }
    // 8 ms soft attack, 300 ms fade to silence at the end.
    final attack = t < 0.008 ? 0.5 - 0.5 * cos(pi * t / 0.008) : 1.0;
    final left = bellLength.inMilliseconds / 1000 - t;
    final release = left < 0.3 ? left / 0.3 : 1.0;
    samples[i] = v * attack * release;
  }
  final peak = samples.map((s) => s.abs()).reduce(max);
  final pcm = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    // Peak at −6 dBFS.
    pcm.setInt16(i * 2, (samples[i] / peak * 0.5 * 32767).round(), .little);
  }
  return _wav(pcm.buffer.asUint8List(), rate: rate, bits: 16);
}

/// Silence; 8-bit PCM is unsigned, so silence is 128.
Uint8List quietWav() {
  const rate = 8000;
  return _wav(
    Uint8List(rate * quietLength.inSeconds)
      ..fillRange(0, rate * quietLength.inSeconds, 128),
    rate: rate,
    bits: 8,
  );
}

/// A mono PCM WAV file around [pcm].
Uint8List _wav(Uint8List pcm, {required int rate, required int bits}) {
  final bytesPerSample = bits ~/ 8;
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // "RIFF"
    ..setUint32(4, 36 + pcm.length, .little)
    ..setUint32(8, 0x57415645) // "WAVE"
    ..setUint32(12, 0x666d7420) // "fmt "
    ..setUint32(16, 16, .little)
    ..setUint16(20, 1, .little) // PCM
    ..setUint16(22, 1, .little) // mono
    ..setUint32(24, rate, .little)
    ..setUint32(28, rate * bytesPerSample, .little)
    ..setUint16(32, bytesPerSample, .little)
    ..setUint16(34, bits, .little)
    ..setUint32(36, 0x64617461) // "data"
    ..setUint32(40, pcm.length, .little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
}
