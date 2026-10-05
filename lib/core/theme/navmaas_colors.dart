import 'package:flutter/material.dart';

/// Brand colours that have no Material 3 `ColorScheme` slot
/// (DESIGN_SYSTEM §7).
@immutable
class NavmaasColors extends ThemeExtension<NavmaasColors> {
  const new({
    required this.amber,
    required this.amberSoft,
    required this.onAmberSoft,
    required this.track,
    required this.readPaperBg,
    required this.readPaperText,
    required this.readNightBg,
    required this.readNightText,
    required this.sleep,
    required this.sleepText,
  });

  final Color amber;
  final Color amberSoft;
  final Color onAmberSoft;
  final Color track;
  final Color readPaperBg;
  final Color readPaperText;
  final Color readNightBg;
  final Color readNightText;
  final Color sleep;
  final Color sleepText;

  static const light = NavmaasColors(
    amber: Color(0xFF9A6416),
    amberSoft: Color(0xFFFAEEDB),
    onAmberSoft: Color(0xFF65420E),
    track: Color(0xFFE9E1D6),
    readPaperBg: Color(0xFFF6EEDF),
    readPaperText: Color(0xFF3B2F25),
    readNightBg: Color(0xFF1E1913),
    readNightText: Color(0xFFE3CDA8),
    sleep: Color(0xFF0E0C10),
    sleepText: Color(0xFFA99F98),
  );

  static const dark = NavmaasColors(
    amber: Color(0xFFE2B464),
    amberSoft: Color(0xFF3A2F1F),
    onAmberSoft: Color(0xFFF2DAAA),
    track: Color(0xFF39323F),
    readPaperBg: Color(0xFFF6EEDF),
    readPaperText: Color(0xFF3B2F25),
    readNightBg: Color(0xFF1E1913),
    readNightText: Color(0xFFE3CDA8),
    sleep: Color(0xFF0E0C10),
    sleepText: Color(0xFFA99F98),
  );

  @override
  NavmaasColors copyWith({
    Color? amber,
    Color? amberSoft,
    Color? onAmberSoft,
    Color? track,
    Color? readPaperBg,
    Color? readPaperText,
    Color? readNightBg,
    Color? readNightText,
    Color? sleep,
    Color? sleepText,
  }) => NavmaasColors(
    amber: amber ?? this.amber,
    amberSoft: amberSoft ?? this.amberSoft,
    onAmberSoft: onAmberSoft ?? this.onAmberSoft,
    track: track ?? this.track,
    readPaperBg: readPaperBg ?? this.readPaperBg,
    readPaperText: readPaperText ?? this.readPaperText,
    readNightBg: readNightBg ?? this.readNightBg,
    readNightText: readNightText ?? this.readNightText,
    sleep: sleep ?? this.sleep,
    sleepText: sleepText ?? this.sleepText,
  );

  @override
  NavmaasColors lerp(NavmaasColors? other, double t) {
    if (other == null) return this;
    return NavmaasColors(
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      onAmberSoft: Color.lerp(onAmberSoft, other.onAmberSoft, t)!,
      track: Color.lerp(track, other.track, t)!,
      readPaperBg: Color.lerp(readPaperBg, other.readPaperBg, t)!,
      readPaperText: Color.lerp(readPaperText, other.readPaperText, t)!,
      readNightBg: Color.lerp(readNightBg, other.readNightBg, t)!,
      readNightText: Color.lerp(readNightText, other.readNightText, t)!,
      sleep: Color.lerp(sleep, other.sleep, t)!,
      sleepText: Color.lerp(sleepText, other.sleepText, t)!,
    );
  }
}

extension NavmaasColorsX on BuildContext {
  NavmaasColors get navmaas => Theme.of(this).extension<NavmaasColors>()!;
}
