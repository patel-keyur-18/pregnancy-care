import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// How long a scene moves before it rests (DESIGN_SYSTEM §5).
const moodSceneDuration = Duration(seconds: 12);

/// Today's mood scene (prototype "Mood scenes", E4, Plan decision 63): an
/// original drawing and one line for the mood she picked today, until
/// midnight. It moves gently for 12 seconds each time the app opens to
/// Today, and again when tapped; with reduce motion it stays still. Each
/// mood is equal: every one has its own scene. The lines live in
/// `app_en.arb` (`moodSceneLine*`), so they can be reworded there alone.
class MoodSceneCard extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MoodSceneCard> createState() => _MoodSceneCardState();
}

class _MoodSceneCardState extends ConsumerState<MoodSceneCard>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: moodSceneDuration,
  );
  late final AppLifecycleListener _lifecycle;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    // Opening the app again (back from the background) plays it again.
    _lifecycle = AppLifecycleListener(onShow: _play);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _motion.dispose();
    super.dispose();
  }

  void _play() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _motion.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(wellbeingWeekProvider).first.mood?.mood;
    if (mood == null) return const SizedBox.shrink();
    if (!_played) {
      // The first time it shows in this run of the app.
      _played = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (mood) {
      MoodWord.calm => (scheme.primaryContainer, scheme.onPrimaryContainer),
      MoodWord.happy ||
      MoodWord.low => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      MoodWord.okay => (scheme.surfaceContainerHighest, scheme.onSurface),
      MoodWord.tired => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    final (line, art) = switch (mood) {
      MoodWord.calm => (l10n.moodSceneLineCalm, l10n.moodSceneArtCalm),
      MoodWord.happy => (l10n.moodSceneLineHappy, l10n.moodSceneArtHappy),
      MoodWord.okay => (l10n.moodSceneLineOkay, l10n.moodSceneArtOkay),
      MoodWord.tired => (l10n.moodSceneLineTired, l10n.moodSceneArtTired),
      MoodWord.low => (l10n.moodSceneLineLow, l10n.moodSceneArtLow),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        button: true,
        label: '$art. $line',
        hint: l10n.moodSceneReplay,
        excludeSemantics: true,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _play,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
              child: Row(
                spacing: 14,
                children: [
                  AnimatedBuilder(
                    animation: _motion,
                    builder: (context, _) => CustomPaint(
                      size: const Size(120, 100),
                      painter: MoodScenePainter(
                        mood,
                        t: _motion.value,
                        scheme: scheme,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          l10n.moodSceneOverline(l10n.mood(mood)).toUpperCase(),
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: foreground,
                          ),
                        ),
                        Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 18,
                            height: 26 / 18,
                            fontWeight: FontWeight.w500,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a mood's scene on a 120 × 100 grid, as in the prototype. [t] runs
/// 0 → 1 over the 12 seconds of motion; 0 and 1 are the same resting frame.
class MoodScenePainter extends CustomPainter {
  const new(this.mood, {required this.t, required this.scheme});

  final MoodWord mood;
  final double t;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 100);
    switch (mood) {
      case MoodWord.calm:
        _calm(canvas);
      case MoodWord.happy:
        _happy(canvas);
      case MoodWord.okay:
        _okay(canvas);
      case MoodWord.tired:
        _tired(canvas);
      case MoodWord.low:
        _low(canvas);
    }
  }

  /// A wave that starts and ends at 0, [cycles] times over the motion.
  double _wave(int cycles) => math.sin(2 * math.pi * cycles * t);

  Paint _fill(Color c, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * opacity)
    ..style = PaintingStyle.fill;

  Paint _stroke(Color c, double width, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _calm(Canvas canvas) {
    final rose = scheme.secondary;
    canvas.drawCircle(const Offset(98, 20), 8, _fill(scheme.surface));
    // A ripple widening and fading, three times.
    final p = (t * 3) % 1;
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(60, 80),
          width: (14 + 34 * p) * 2,
          height: 6,
        ),
        _stroke(scheme.primary, 1.5, 0.6 * (1 - p)),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(60, 80), width: 44, height: 8),
        _stroke(scheme.primary, 1.5, 0.35),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 76)
          ..cubicTo(50, 72, 44, 64, 44, 57)
          ..cubicTo(52, 59, 58, 66, 60, 76)
          ..close(),
        _fill(rose, 0.55),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 76)
          ..cubicTo(70, 72, 76, 64, 76, 57)
          ..cubicTo(68, 59, 62, 66, 60, 76)
          ..close(),
        _fill(rose, 0.55),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 48)
          ..cubicTo(53, 58, 53, 69, 60, 76)
          ..cubicTo(67, 69, 67, 58, 60, 48)
          ..close(),
        _fill(rose, 0.85),
      );
  }

  void _happy(Canvas canvas) {
    final rose = scheme.secondary;
    // The sun's rays turn 45° twice (eight rays, so each turn looks whole).
    canvas
      ..save()
      ..translate(36, 34)
      ..save()
      ..rotate(math.pi / 4 * ((t * 2) % 1));
    final rays = _stroke(rose, 2.4);
    for (var i = 0; i < 8; i++) {
      canvas
        ..drawLine(const Offset(0, -24), const Offset(0, -18), rays)
        ..rotate(math.pi / 4);
    }
    canvas
      ..restore()
      ..drawCircle(Offset.zero, 12, _fill(rose, 0.85))
      ..restore();
    // Three small flowers sway.
    for (final (x, y, stem, r, dir) in [
      (70.0, 84.0, 20.0, 5.0, 1),
      (88.0, 86.0, 14.0, 4.0, -1),
      (104.0, 84.0, 22.0, 5.0, 1),
    ]) {
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(dir * 6 * math.pi / 180 * _wave(3))
        ..drawLine(Offset.zero, Offset(0, -stem), _stroke(scheme.primary, 2))
        ..drawCircle(Offset(0, -stem - 4), r, _fill(scheme.surface))
        ..drawCircle(Offset(0, -stem - 4), r, _stroke(rose, 2))
        ..restore();
    }
  }

  void _cloud(
    Canvas canvas,
    double dx,
    List<(double, double, double)> puffs,
    Rect base,
    double opacity,
  ) {
    final paint = _fill(scheme.surface, opacity);
    canvas
      ..save()
      ..translate(dx, 0);
    for (final (x, y, r) in puffs) {
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(base, Radius.circular(base.height / 2)),
        paint,
      )
      ..restore();
  }

  void _okay(Canvas canvas) {
    // Two clouds drift a little and come back, twice.
    final drift = (1 - math.cos(2 * math.pi * 2 * t)) / 2;
    _cloud(
      canvas,
      10 * drift,
      const [(30, 30, 10), (42, 26, 13), (54, 31, 9)],
      const Rect.fromLTWH(22, 31, 38, 9),
      1,
    );
    _cloud(
      canvas,
      -8 * drift,
      const [(86, 20, 7), (95, 17, 9), (104, 21, 6)],
      const Rect.fromLTWH(80, 21, 28, 6),
      0.8,
    );
    final green = scheme.primary;
    canvas
      ..drawLine(
        const Offset(60, 88),
        const Offset(60, 68),
        _stroke(green, 2.2),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 72)
          ..cubicTo(52, 72, 48, 66, 48, 60)
          ..cubicTo(56, 60, 60, 65, 60, 72)
          ..close(),
        _fill(green, 0.8),
      )
      ..drawPath(
        Path()
          ..moveTo(60, 68)
          ..cubicTo(68, 68, 72, 62, 72, 56)
          ..cubicTo(64, 56, 60, 61, 60, 68)
          ..close(),
        _fill(green),
      )
      ..drawLine(
        const Offset(44, 88),
        const Offset(76, 88),
        _stroke(scheme.outline, 1.6),
      );
  }

  /// A curled, sleeping baby: round body, head, closed eye, tucked arm and
  /// leg.
  void _baby(Canvas canvas, Offset at, double scale) {
    final skin = _fill(scheme.secondaryContainer);
    final line = _stroke(scheme.onSurfaceVariant, 1.6 / scale);
    final body = Path()
      ..moveTo(-2, -2)
      ..cubicTo(10, -6, 20, 2, 18, 12)
      ..cubicTo(16, 22, 2, 24, -6, 18)
      ..cubicTo(-12, 13, -10, 4, -2, -2)
      ..close();
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..scale(scale)
      ..drawPath(body, skin)
      ..drawPath(body, line)
      ..drawCircle(const Offset(-8, -8), 9, skin)
      ..drawCircle(const Offset(-8, -8), 9, line)
      ..drawPath(
        Path()
          ..moveTo(-11, -8)
          ..quadraticBezierTo(-8.5, -6, -6, -8),
        line,
      )
      ..drawPath(
        Path()
          ..moveTo(2, 6)
          ..quadraticBezierTo(7, 10, 12, 8),
        line,
      )
      ..drawPath(
        Path()
          ..moveTo(-2, 14)
          ..quadraticBezierTo(4, 18, 10, 14),
        line,
      )
      ..restore();
  }

  void _tired(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(78, 14)
        ..arcToPoint(
          const Offset(104, 74),
          radius: const Radius.circular(36),
          largeArc: true,
          clockwise: false,
        )
        ..arcToPoint(
          const Offset(78, 14),
          radius: const Radius.circular(30),
          largeArc: true,
        )
        ..close(),
      _fill(scheme.surface),
    );
    _baby(canvas, const Offset(58, 62), 0.95);
    // Stars twinkle softly.
    final star = scheme.tertiary;
    for (final (x, y, r, cycles, base) in [
      (18.0, 20.0, 2.0, 4, true),
      (34.0, 10.0, 1.5, 4, false),
      (104.0, 12.0, 2.0, 3, true),
      (14.0, 50.0, 1.5, 3, false),
    ]) {
      final c = math.cos(2 * math.pi * cycles * t);
      final opacity = base ? 0.6 + 0.4 * c : 0.65 - 0.35 * c;
      canvas.drawCircle(Offset(x, y), r, _fill(star, opacity));
    }
  }

  void _low(Canvas canvas) {
    final rose = scheme.secondary;
    canvas
      ..drawCircle(const Offset(60, 60), 32, _fill(scheme.surface, 0.85))
      ..drawCircle(const Offset(60, 60), 32, _stroke(rose, 1.5, 0.6));
    _baby(canvas, const Offset(62, 60), 0.9);
    // A small heart beats gently, seven times.
    final beat = 1 + 0.075 * (1 - math.cos(2 * math.pi * 7 * t));
    canvas
      ..save()
      ..translate(60, 14)
      ..scale(beat)
      ..drawPath(
        Path()
          ..moveTo(0, 8)
          ..cubicTo(-8, 2, -10, -6, -4, -8)
          ..cubicTo(-2, -9, 0, -7, 0, -5)
          ..cubicTo(0, -7, 2, -9, 4, -8)
          ..cubicTo(10, -6, 8, 2, 0, 8)
          ..close(),
        _fill(rose),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(MoodScenePainter old) =>
      old.t != t || old.mood != mood || old.scheme != scheme;
}
