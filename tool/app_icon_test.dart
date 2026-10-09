// Renders the iPhone app icon from the sprout's own path (DESIGN_SYSTEM §1):
//   flutter test tool/app_icon_test.dart
// Android draws the same paths as a vector (res/drawable/ic_launcher_foreground.xml).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';

const _size = 1024.0;

/// The sprout spans 18 grid units with its stroke; 60 % of the tile.
const double _scale = _size * 0.6 / 18;

void main() {
  testWidgets('writes the iPhone app icon', (tester) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xFFE2ECE5), ui.BlendMode.src)
      // Centre the sprout (12.5, 13 on the grid) in the tile.
      ..translate(_size / 2 - 12.5 * _scale, _size / 2 - 13 * _scale)
      ..scale(_scale)
      ..drawPath(
        NavmaasIcon.sprout.path,
        ui.Paint()
          ..color = const ui.Color(0xFF2C4638)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round,
      );
    await tester.runAsync(() async {
      final image = await recorder.endRecording().toImage(1024, 1024);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      // ponytail: PNG keeps an (opaque) alpha channel; strip it before any
      // App Store upload, which rejects alpha. Device installs don't care.
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
