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
  // Same line style as the prototype's icons (not drawn there).
  close(['M6 6l12 12M18 6 6 18']);

  new(this.svg);

  final List<String> svg;

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
      ..style = PaintingStyle.stroke
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
