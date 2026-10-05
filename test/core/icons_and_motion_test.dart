import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/widgets/motion.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _progress(WidgetTester tester) =>
    tester.widget<NmIcon>(find.byType(NmIcon)).progress;

void main() {
  test('every icon parses to a non-empty path inside the 24 grid', () {
    for (final icon in NavmaasIcon.values) {
      final b = icon.path.getBounds();
      expect(b.isEmpty, isFalse, reason: icon.name);
      expect(
        const Rect.fromLTRB(0, 0, 24, 24).inflate(0.01).contains(b.topLeft) &&
            const Rect.fromLTRB(
              0,
              0,
              24,
              24,
            ).inflate(0.01).contains(b.bottomRight),
        isTrue,
        reason: '${icon.name} $b',
      );
    }
  });

  group('DrawOnIcon', () {
    Future<void> activate(WidgetTester tester, {required bool reduce}) async {
      await tester.pumpWidget(
        _wrap(
          const DrawOnIcon(NavmaasIcon.home, active: false),
          reduceMotion: reduce,
        ),
      );
      expect(_progress(tester), 1);
      await tester.pumpWidget(
        _wrap(
          const DrawOnIcon(NavmaasIcon.home, active: true),
          reduceMotion: reduce,
        ),
      );
    }

    testWidgets('traces the stroke over 350 ms when it becomes active', (
      tester,
    ) async {
      await activate(tester, reduce: false);
      expect(_progress(tester), 0);
      await tester.pump(const Duration(milliseconds: 175));
      expect(_progress(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_progress(tester), 1);
    });

    testWidgets('reduce motion: fully drawn at once', (tester) async {
      await activate(tester, reduce: true);
      expect(_progress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('PressScale', () {
    testWidgets('shrinks to 92% while pressed, then returns', (tester) async {
      await tester.pumpWidget(
        _wrap(const PressScale(child: SizedBox.square(dimension: 48))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.92,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('reduce motion: never scales', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PressScale(child: SizedBox.square(dimension: 48)),
          reduceMotion: true,
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });
}
