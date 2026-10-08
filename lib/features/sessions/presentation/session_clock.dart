import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:navmaas/core/utils/clock.dart';

/// A once-a-second clock for a timed session screen: [seconds] counts while
/// not [paused]. In the background it stops, except with
/// [countWhileHidden], whose time away is added back on return.
mixin SessionClock<T extends StatefulWidget> on State<T> {
  int seconds = 0;
  bool paused = false;

  /// True for the kick counter and contraction timer, which time on with
  /// the screen off. (The walk keeps its own time in `WalkDraft`.)
  bool get countWhileHidden => false;

  /// Called on every counted second (inside setState).
  void onSecond() {}

  Timer? _tick;
  AppLifecycleListener? _lifecycle;
  DateTime? _hiddenAt;

  void startClock() {
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = clockNow(),
      onShow: () {
        final hiddenAt = _hiddenAt;
        _hiddenAt = null;
        if (countWhileHidden && hiddenAt != null && !paused && mounted) {
          setState(() => seconds += clockNow().difference(hiddenAt).inSeconds);
        }
      },
    );
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused || _hiddenAt != null) return;
      setState(() {
        seconds++;
        onSecond();
      });
    });
  }

  void stopClock() {
    _tick?.cancel();
    _lifecycle?.dispose();
  }
}

/// "6:10" for [seconds].
String clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
