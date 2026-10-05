import 'package:flutter/material.dart';

/// The Navmaas mark: a sage crescent moon cradling a rose seed.
class BrandMark extends StatelessWidget {
  const new({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MoonPainter(scheme.primary, scheme.secondary),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const new(this.moon, this.seed);

  final Color moon;
  final Color seed;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on the prototype's 40 × 40 grid.
    canvas.scale(size.width / 40);
    final crescent = Path()
      ..moveTo(27, 6.5)
      ..arcToPoint(
        const Offset(33.5, 27),
        radius: const Radius.circular(15),
        largeArc: true,
        clockwise: false,
      )
      ..arcToPoint(const Offset(27, 6.5), radius: const Radius.circular(11.5))
      ..close();
    canvas
      ..drawPath(crescent, Paint()..color = moon)
      ..drawCircle(const Offset(28.6, 16.6), 3, Paint()..color = seed);
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.moon != moon || old.seed != seed;
}
