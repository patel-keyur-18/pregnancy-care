import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';

/// "Moonlit Sage" (DESIGN_SYSTEM §2–§7). Exact hex values; do not tweak here
/// without updating the design system doc.
abstract final class AppTheme {
  /// Screen gutter (DESIGN_SYSTEM §4).
  static const gutter = 20.0;

  static final ThemeData light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF4A6F5D),
      onPrimary: Color(0xFFFFFDF9),
      primaryContainer: Color(0xFFE2ECE5),
      onPrimaryContainer: Color(0xFF2C4638),
      secondary: Color(0xFFA85A61),
      onSecondary: Color(0xFFFFFDF9),
      secondaryContainer: Color(0xFFF6E5E2),
      onSecondaryContainer: Color(0xFF743840),
      tertiary: Color(0xFF6E63A0),
      onTertiary: Color(0xFFFFFDF9),
      tertiaryContainer: Color(0xFFECE8F6),
      onTertiaryContainer: Color(0xFF433B6B),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFBE4E1),
      onErrorContainer: Color(0xFF7F1D17),
      surface: Color(0xFFFFFDF9),
      onSurface: Color(0xFF2F2A28),
      surfaceContainerHighest: Color(0xFFF3EDE4),
      onSurfaceVariant: Color(0xFF5E5650),
      outline: Color(0xFF6E655E),
      outlineVariant: Color(0xFFE6DDD1),
      surfaceTint: Colors.transparent,
    ),
    background: const Color(0xFFFAF6F0),
    brand: NavmaasColors.light,
  );

  static final ThemeData dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9CC2AE),
      onPrimary: Color(0xFF15201A),
      primaryContainer: Color(0xFF2B3A33),
      onPrimaryContainer: Color(0xFFCFE4D7),
      secondary: Color(0xFFE2A6A6),
      onSecondary: Color(0xFF1B1820),
      secondaryContainer: Color(0xFF3E2A2E),
      onSecondaryContainer: Color(0xFFF4D4D2),
      tertiary: Color(0xFFB9AFE3),
      onTertiary: Color(0xFF1B1820),
      tertiaryContainer: Color(0xFF302A42),
      onTertiaryContainer: Color(0xFFDDD6F5),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF3B0B08),
      errorContainer: Color(0xFF4E201D),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF24202A),
      onSurface: Color(0xFFE8E0D8),
      surfaceContainerHighest: Color(0xFF2D2833),
      onSurfaceVariant: Color(0xFFC2B8B0),
      outline: Color(0xFFA99F98),
      outlineVariant: Color(0xFF3B3542),
      surfaceTint: Colors.transparent,
    ),
    background: const Color(0xFF1B1820),
    brand: NavmaasColors.dark,
  );

  /// Reading style for the M4 reader (DESIGN_SYSTEM §3).
  static const reading = TextStyle(
    fontFamily: 'Literata',
    fontSize: 19,
    height: 32 / 19,
    fontWeight: FontWeight.w400,
  );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color background,
    required NavmaasColors brand,
  }) {
    final isLight = scheme.brightness == Brightness.light;
    final text = _textTheme(scheme.onSurface);
    const pill = WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder());
    final buttonLabel = WidgetStatePropertyAll(_nunito(16, 24, 800));
    const buttonSize = WidgetStatePropertyAll(Size(64, 56));

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Nunito',
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _ReduceMotion(
            FadeForwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: _ReduceMotion(CupertinoPageTransitionsBuilder()),
        },
      ),
      extensions: [brand],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: EdgeInsets.zero,
        elevation: isLight ? 2 : 0,
        shadowColor: const Color(0x293C281E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          minimumSize: buttonSize,
          textStyle: buttonLabel,
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant, width: 1.5),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(textStyle: WidgetStatePropertyAll(text.labelLarge)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.surface
                : scheme.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 84,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => _nunito(13, 18, s.contains(WidgetState.selected) ? 800 : 600)
              .copyWith(
                color: s.contains(WidgetState.selected)
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
              ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: brand.track,
        circularTrackColor: brand.track,
      ),
    );
  }

  /// Type scale (DESIGN_SYSTEM §3). Nunito is a variable font; Flutter maps
  /// `fontWeight` onto its `wght` axis.
  static TextTheme _textTheme(Color color) {
    final display = _nunito(32, 40, 800);
    final title = _nunito(26, 32, 800);
    final heading = _nunito(18, 24, 800);
    final body = _nunito(16, 24, 500);
    final label = _nunito(14, 20, 800);
    final caption = _nunito(13, 18, 600);
    return TextTheme(
      displaySmall: display,
      headlineMedium: title,
      headlineSmall: title,
      titleLarge: heading,
      titleMedium: heading,
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: caption,
      labelSmall: caption,
    ).apply(bodyColor: color, displayColor: color);
  }

  static TextStyle _nunito(double size, double line, int weight) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    height: line / size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
  );
}

/// Platform page transitions, or none when the OS asks to reduce motion.
class _ReduceMotion extends PageTransitionsBuilder {
  const new(this._inner);

  final PageTransitionsBuilder _inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : _inner.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
