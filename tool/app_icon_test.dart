// Makes every app icon and logo image from the owner's logo art in
// design/logo/ (Plan decision 78, ADR 063):
//   flutter test tool/app_icon_test.dart
// main.png (sage background), dark.png (dark background) and monochrome.png
// (white on transparent) are the same drawing in the same place; the logo
// itself is cut from main.png and dark.png by removing their background.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// The art's backgrounds (`primary-soft` and dark `bg`).
const _sage = (0xE2, 0xEC, 0xE5);
const _dark = (0x1B, 0x18, 0x20);

const _ios = 'ios/Runner/Assets.xcassets';
const _android = 'android/app/src/main/res';

/// The art's size in Android's 108 dp adaptive tile: the largest that keeps
/// the (tall) logo inside the 66 dp circle every launcher mask keeps.
const _adaptiveScale = 0.76;

void main() {
  testWidgets('writes the app icons and logo images', (tester) async {
    await tester.runAsync(() async {
      final main = await _read('design/logo/main.png');
      final dark = await _read('design/logo/dark.png');
      final mono = await _read('design/logo/monochrome.png');
      final light = _cut(main, _sage);
      final night = _cut(dark, _dark);

      // iPhone: one 1024 px icon with dark and tinted (iOS 18) looks.
      // ponytail: PNGs keep an (opaque) alpha channel; strip it before any
      // App Store upload, which rejects alpha. Device installs don't care.
      await _write(
        '$_ios/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
        main,
        1024,
      );
      await _write(
        '$_ios/AppIcon.appiconset/Icon-App-Dark-1024x1024@1x.png',
        dark,
        1024,
      );
      await _write(
        '$_ios/AppIcon.appiconset/Icon-App-Tinted-1024x1024@1x.png',
        mono,
        1024,
      );

      // Android adaptive icon: the logo (and its white shape for themed
      // icons) on the 108 dp tile, background colour in values/.
      final foreground = await _write(
        '$_android/drawable-nodpi/ic_launcher_foreground.png',
        light,
        432,
        scale: _adaptiveScale,
      );
      await _write(
        '$_android/drawable-nodpi/ic_launcher_monochrome.png',
        mono,
        432,
        scale: _adaptiveScale,
      );
      _expectInsideSafeZone(foreground);

      // Status-bar icon: white on transparent, 24 dp at every density.
      final white = _white(mono);
      for (final (density, px) in [
        ('mdpi', 24),
        ('hdpi', 36),
        ('xhdpi', 48),
        ('xxhdpi', 72),
        ('xxxhdpi', 96),
      ]) {
        final icon = await _write(
          '$_android/drawable-$density/ic_notification.png',
          _square(white, pad: 0.08),
          px,
        );
        _expectWhite(icon);
      }

      // The logo alone, light and dark: widget, app-switcher cover, launch.
      final logo = _square(light, pad: 0.04);
      final logoDark = _square(night, pad: 0.04);
      await _write('assets/brand/logo.png', logo, 512);
      await _write('assets/brand/logo_dark.png', logoDark, 512);
      await _write('$_android/drawable-nodpi/logo.png', logo, 384);
      await _write('$_android/drawable-night-nodpi/logo.png', logoDark, 384);
      for (final (suffix, px) in [('', 128), ('@2x', 256), ('@3x', 384)]) {
        await _write(
          '$_ios/LaunchImage.imageset/LaunchImage$suffix.png',
          logo,
          px,
        );
        await _write(
          '$_ios/LaunchImage.imageset/LaunchImageDark$suffix.png',
          logoDark,
          px,
        );
        await _write(
          'ios/NavmaasWidget/Assets.xcassets/Logo.imageset/Logo$suffix.png',
          logo,
          px ~/ 2,
        );
        await _write(
          'ios/NavmaasWidget/Assets.xcassets/Logo.imageset/LogoDark$suffix.png',
          logoDark,
          px ~/ 2,
        );
      }
    });
  });
}

/// RGBA pixels, straight (not premultiplied) alpha.
typedef _Pixels = ({int width, int height, Uint8List rgba});

Future<_Pixels> _read(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return (
    width: image.width,
    height: image.height,
    rgba: data!.buffer.asUint8List(),
  );
}

/// Removes the flat [bg]: alpha from each pixel's distance to it, colour
/// un-mixed from the anti-aliased edge so it sits cleanly on any colour.
_Pixels _cut(_Pixels p, (int, int, int) bg) {
  final out = Uint8List.fromList(p.rgba);
  final b = [bg.$1, bg.$2, bg.$3];
  for (var i = 0; i < out.length; i += 4) {
    var d = 0;
    for (var c = 0; c < 3; c++) {
      d = math.max(d, (out[i + c] - b[c]).abs());
    }
    final a = ((d - 10) / 50).clamp(0.0, 1.0);
    for (var c = 0; c < 3; c++) {
      out[i + c] = a == 0
          ? 0
          : ((out[i + c] - (1 - a) * b[c]) / a).round().clamp(0, 255);
    }
    out[i + 3] = (a * 255).round();
  }
  return (width: p.width, height: p.height, rgba: out);
}

/// The same shape in pure white.
_Pixels _white(_Pixels p) {
  final out = Uint8List.fromList(p.rgba);
  for (var i = 0; i < out.length; i += 4) {
    out
      ..[i] = 255
      ..[i + 1] = 255
      ..[i + 2] = 255;
  }
  return (width: p.width, height: p.height, rgba: out);
}

/// The smallest square around the opaque pixels, with [pad] (a fraction
/// of its side) on each edge.
_Pixels _square(_Pixels p, {required double pad}) {
  var (left, top, right, bottom) = (p.width, p.height, 0, 0);
  for (var y = 0; y < p.height; y++) {
    for (var x = 0; x < p.width; x++) {
      if (p.rgba[(y * p.width + x) * 4 + 3] > 8) {
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
  }
  final side = (math.max(right - left, bottom - top) * (1 + 2 * pad)).round();
  final x0 = (left + right) ~/ 2 - side ~/ 2;
  final y0 = (top + bottom) ~/ 2 - side ~/ 2;
  final out = Uint8List(side * side * 4);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final sx = x0 + x;
      final sy = y0 + y;
      if (sx < 0 || sy < 0 || sx >= p.width || sy >= p.height) continue;
      final s = (sy * p.width + sx) * 4;
      final d = (y * side + x) * 4;
      out.setRange(d, d + 4, p.rgba, s);
    }
  }
  return (width: side, height: side, rgba: out);
}

/// Draws [p] into a [size] px square PNG at [path], [scale] of the square
/// and centred, and returns the pixels written.
Future<_Pixels> _write(
  String path,
  _Pixels p,
  int size, {
  double scale = 1,
}) async {
  final source = await _image(p);
  final side = size * scale;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    source,
    ui.Rect.fromLTWH(0, 0, p.width.toDouble(), p.height.toDouble()),
    ui.Rect.fromCenter(
      center: ui.Offset(size / 2, size / 2),
      width: side,
      height: side,
    ),
    // Mipmapped, so large reductions (1254 → 24 px) stay smooth.
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
  final raw = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return (width: size, height: size, rgba: raw!.buffer.asUint8List());
}

Future<ui.Image> _image(_Pixels p) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(p.rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: p.width,
    height: p.height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

/// Every visible pixel of the adaptive foreground lies inside the 66 dp
/// circle of the 108 dp tile, which no launcher mask cuts.
void _expectInsideSafeZone(_Pixels p) {
  final centre = p.width / 2;
  final radius = p.width * 33 / 108;
  for (var y = 0; y < p.height; y++) {
    for (var x = 0; x < p.width; x++) {
      if (p.rgba[(y * p.width + x) * 4 + 3] < 64) continue;
      final r = math.sqrt(math.pow(x - centre, 2) + math.pow(y - centre, 2));
      expect(r, lessThanOrEqualTo(radius), reason: 'pixel $x, $y is cut off');
    }
  }
}

/// Android draws status-bar icons from their alpha: white, nothing else.
void _expectWhite(_Pixels p) {
  for (var i = 0; i < p.rgba.length; i += 4) {
    if (p.rgba[i + 3] < 128) continue;
    expect(p.rgba.sublist(i, i + 3), everyElement(greaterThan(240)));
  }
}
