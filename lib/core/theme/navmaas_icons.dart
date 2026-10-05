// SVG path data is copied verbatim from the prototype and stays on one line.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

/// The prototype's own line icons, as exact SVG path data on a 24 × 24 grid
/// (DESIGN_SYSTEM §4). Circles and rects are written as equivalent paths.
enum NavmaasIcon {
  home([
    'M3.5 10.5 12 3.5l8.5 7V20a1 1 0 0 1-1 1H15v-6H9v6H4.5a1 1 0 0 1-1-1z',
  ]),
  sprout([
    'M12 21v-8.5',
    'M12 12.5c0-4.2 3-7.5 8-7.5 0 4.2-3 7.5-8 7.5z',
    'M12 14.5c0-3.3-2.6-6-7-6 0 3.3 2.6 6 7 6z',
  ]),
  lotus([
    'M12 19c-4 0-8-2-9-6 3 0 5.5.8 7 2.3',
    'M12 19c4 0 8-2 9-6-3 0-5.5.8-7 2.3',
    'M12 19c-2.2-2-3.2-4.5-3.2-7.2S10 6.5 12 4.5c2 2 3.2 4.6 3.2 7.3S14.2 17 12 19z',
  ]),
  heart([
    'M12 20s-7.5-4.5-9-9.5A4.6 4.6 0 0 1 12 7.2a4.6 4.6 0 0 1 9 3.3C19.5 15.5 12 20 12 20z',
  ]),
  person([
    'M16 8a4 4 0 1 1-8 0 4 4 0 1 1 8 0z',
    'M4.5 20.5a7.5 7.5 0 0 1 15 0',
  ]),
  calendar([
    'M6 5h12a2.5 2.5 0 0 1 2.5 2.5V18a2.5 2.5 0 0 1-2.5 2.5H6A2.5 2.5 0 0 1 3.5 18V7.5A2.5 2.5 0 0 1 6 5z',
    'M3.5 10h17M8 3v4M16 3v4',
  ]),
  lock([
    'M7 10.5h10a2.5 2.5 0 0 1 2.5 2.5v5.5a2.5 2.5 0 0 1-2.5 2.5H7a2.5 2.5 0 0 1-2.5-2.5V13A2.5 2.5 0 0 1 7 10.5z',
    'M8 10.5V7.5a4 4 0 0 1 8 0v3',
  ]),
  moon(['M20 14.2A8 8 0 1 1 9.8 4a6.4 6.4 0 0 0 10.2 10.2z']),
  sun([
    'M16 12a4 4 0 1 1-8 0 4 4 0 1 1 8 0z',
    'M12 2.5v2M12 19.5v2M4.6 4.6 6 6M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4 6 18M18 6l1.4-1.4',
  ]),
  check(['M5 12.5 9.5 17 19 7.5']),
  pill(['M10.5 20.5a5 5 0 0 1-7-7l7-7a5 5 0 0 1 7 7z', 'M7 10l7 7']),
  plus(['M12 5v14M5 12h14']),
  chevronLeft(['M15 6l-6 6 6 6']),
  chevronRight(['M9 6l6 6-6 6']),
  bell(['M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z', 'M10 21h4']),
  flask([
    'M9 3h6M10 3v6l-5 9a2 2 0 0 0 1.8 3h10.4a2 2 0 0 0 1.8-3l-5-9V3',
    'M7.5 15h9',
  ]),
  shield([
    'M12 3l7 3v5.5c0 4.3-3 7.8-7 9.5-4-1.7-7-5.2-7-9.5V6z',
    'M9 12l2 2 4-4',
  ]),
  phone([
    'M5 3.5h3.5l2 5-2.5 1.5a11 11 0 0 0 6 6l1.5-2.5 5 2V19a2 2 0 0 1-2 2A16.5 16.5 0 0 1 3 5.5a2 2 0 0 1 2-2z',
  ]),
  pin([
    'M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z',
    'M14.5 9.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 1 1 5 0z',
  ]),
  pencil(['M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z', 'M13.5 6.5l4 4']),
  camera([
    'M4 8h3l1.8-2.5h6.4L17 8h3v11.5H4z',
    'M15.5 13.5a3.5 3.5 0 1 1-7 0 3.5 3.5 0 1 1 7 0z',
  ]),
  book([
    'M3 5.5h5.5A3.5 3.5 0 0 1 12 9v11.5a2.5 2.5 0 0 0-2.5-2.5H3z',
    'M21 5.5h-5.5A3.5 3.5 0 0 0 12 9v11.5a2.5 2.5 0 0 1 2.5-2.5H21z',
  ]),
  headphones([
    'M4 15v-3a8 8 0 0 1 16 0v3',
    'M4.5 14H6a1.5 1.5 0 0 1 1.5 1.5v4A1.5 1.5 0 0 1 6 21H4.5A1.5 1.5 0 0 1 3 19.5v-4A1.5 1.5 0 0 1 4.5 14z',
    'M18 14h1.5a1.5 1.5 0 0 1 1.5 1.5v4a1.5 1.5 0 0 1-1.5 1.5H18a1.5 1.5 0 0 1-1.5-1.5v-4A1.5 1.5 0 0 1 18 14z',
  ]),
  palette([
    'M12 3a9 9 0 0 0 0 18c1.2 0 1.8-.9 1.8-1.8 0-1.2-.9-1.5-.9-2.6 0-1 .8-1.6 1.8-1.6H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z',
    'M8.5 11a1 1 0 1 1-2 0 1 1 0 1 1 2 0z',
    'M11.5 7a1 1 0 1 1-2 0 1 1 0 1 1 2 0z',
    'M16 7.5a1 1 0 1 1-2 0 1 1 0 1 1 2 0z',
  ]),
  music([
    'M9 18V5.5l11-2V16',
    'M9 18a2.5 2.5 0 1 1-5 0 2.5 2.5 0 1 1 5 0z',
    'M20 16a2.5 2.5 0 1 1-5 0 2.5 2.5 0 1 1 5 0z',
  ]),
  eyeOff([
    'M3 3l18 18',
    'M10.6 5.1A9.6 9.6 0 0 1 12 5c6 0 9.5 7 9.5 7a16 16 0 0 1-2.9 3.7M6.3 6.9C3.9 8.6 2.5 12 2.5 12s3.5 7 9.5 7c1.6 0 3-.4 4.3-1',
    'M9.9 9.9a3 3 0 0 0 4.2 4.2',
  ]),
  play(['M8 5.5v13l11-6.5z'], fill: true),
  pause(['M8.5 5v14M15.5 5v14']),
  rewind(['M4 12a8 8 0 1 0 2.4-5.7', 'M4 4v4h4']),
  forward(['M20 12a8 8 0 1 1-2.4-5.7', 'M20 4v4h-4']),
  walk([
    'M8.5 3.5c1.7 0 2.7 2 2.7 4.5S10 12 8.5 12 5.8 10.5 5.8 8s1-4.5 2.7-4.5z',
    'M6.2 15h4.6',
    'M15.5 8.5c1.7 0 2.7 2 2.7 4.5s-1.2 4-2.7 4-2.7-1.5-2.7-4 1-4.5 2.7-4.5z',
    'M13.2 20h4.6',
  ]),
  pelvic([
    'M14.5 12a2.5 2.5 0 1 1-5 0 2.5 2.5 0 1 1 5 0z',
    'M7 7a7 7 0 0 0 0 10M17 7a7 7 0 0 1 0 10',
  ]),
  breath([
    'M3 8.5h10.5a2.5 2.5 0 1 0-2.5-2.5',
    'M3 12.5h15a3 3 0 1 1-3 3',
    'M3 16.5h6',
  ]),
  notice(['M12 3.5 2.5 20h19z', 'M12 10v4.5M12 17.5v.01']),
  // Same line style as the prototype's icons (not drawn there).
  close(['M6 6l12 12M18 6 6 18']),
  scan(['M4 5h16v12H4z', 'M12 17v3M8 20h8', 'M7 12c1.5-3 3.5-3 5 0s3.5 3 5 0']);

  new(this.svg, {this.fill = false});

  final List<String> svg;

  /// Filled shape instead of a line (the prototype's play triangle).
  final bool fill;

  static final _cache = <NavmaasIcon, ui.Path>{};

  /// The icon's outline on the 24 × 24 grid, parsed once.
  ui.Path get path => _cache.putIfAbsent(this, () {
    final proxy = _FlutterPath();
    for (final d in svg) {
      writeSvgPathDataToPath(d, proxy);
    }
    return proxy.path;
  });
}

class _FlutterPath implements PathProxy {
  final path = ui.Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// Paints a [NavmaasIcon] as a rounded line. [progress] (0–1) traces the
/// stroke for the draw-on animation. Decorative: the parent carries the label.
class NmIcon extends StatelessWidget {
  const new(
    this.icon, {
    this.size = 24,
    this.color,
    this.strokeWidth = 1.8,
    this.progress = 1,
    super.key,
  });

  final NavmaasIcon icon;
  final double size;
  final Color? color;

  /// In 24-grid units, like the prototype's SVG `stroke-width`.
  final double strokeWidth;
  final double progress;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(
        icon,
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000),
        strokeWidth,
        progress,
      ),
    ),
  );
}

class _IconPainter extends CustomPainter {
  const new(this.icon, this.color, this.strokeWidth, this.progress);

  final NavmaasIcon icon;
  final Color color;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = icon.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress >= 1) {
      canvas.drawPath(icon.path, paint);
      return;
    }
    // Every stroke of the icon is traced at the same pace.
    for (final metric in icon.path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
}
