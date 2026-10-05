import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';

void main() {
  // Token → Flutter role, per DESIGN_SYSTEM §2 and §7.
  final cases = {
    'Dawn': (
      AppTheme.light,
      {
        'bg': (0xFFFAF6F0, (ThemeData t) => t.scaffoldBackgroundColor),
        'surface': (0xFFFFFDF9, (ThemeData t) => t.colorScheme.surface),
        'surface-2': (
          0xFFF3EDE4,
          (ThemeData t) => t.colorScheme.surfaceContainerHighest,
        ),
        'border': (0xFFE6DDD1, (ThemeData t) => t.colorScheme.outlineVariant),
        'text': (0xFF2F2A28, (ThemeData t) => t.colorScheme.onSurface),
        'text-2': (0xFF5E5650, (ThemeData t) => t.colorScheme.onSurfaceVariant),
        'text-3': (0xFF6E655E, (ThemeData t) => t.colorScheme.outline),
        'primary': (0xFF4A6F5D, (ThemeData t) => t.colorScheme.primary),
        'rose': (0xFFA85A61, (ThemeData t) => t.colorScheme.secondary),
        'lavender': (0xFF6E63A0, (ThemeData t) => t.colorScheme.tertiary),
        'danger': (0xFFB3261E, (ThemeData t) => t.colorScheme.error),
        'amber': (
          0xFF9A6416,
          (ThemeData t) => t.extension<NavmaasColors>()!.amber,
        ),
        'track': (
          0xFFE9E1D6,
          (ThemeData t) => t.extension<NavmaasColors>()!.track,
        ),
      },
    ),
    'Moonlit': (
      AppTheme.dark,
      {
        'bg': (0xFF1B1820, (ThemeData t) => t.scaffoldBackgroundColor),
        'surface': (0xFF24202A, (ThemeData t) => t.colorScheme.surface),
        'surface-2': (
          0xFF2D2833,
          (ThemeData t) => t.colorScheme.surfaceContainerHighest,
        ),
        'border': (0xFF3B3542, (ThemeData t) => t.colorScheme.outlineVariant),
        'text': (0xFFE8E0D8, (ThemeData t) => t.colorScheme.onSurface),
        'text-2': (0xFFC2B8B0, (ThemeData t) => t.colorScheme.onSurfaceVariant),
        'text-3': (0xFFA99F98, (ThemeData t) => t.colorScheme.outline),
        'primary': (0xFF9CC2AE, (ThemeData t) => t.colorScheme.primary),
        'rose': (0xFFE2A6A6, (ThemeData t) => t.colorScheme.secondary),
        'lavender': (0xFFB9AFE3, (ThemeData t) => t.colorScheme.tertiary),
        'danger': (0xFFF2B8B5, (ThemeData t) => t.colorScheme.error),
        'amber': (
          0xFFE2B464,
          (ThemeData t) => t.extension<NavmaasColors>()!.amber,
        ),
        'track': (
          0xFF39323F,
          (ThemeData t) => t.extension<NavmaasColors>()!.track,
        ),
      },
    ),
  };

  for (final MapEntry(key: name, value: (theme, tokens)) in cases.entries) {
    group(name, () {
      for (final MapEntry(key: token, value: (hex, read)) in tokens.entries) {
        test(token, () => expect(read(theme), Color(hex)));
      }
      test('uses bundled Nunito', () {
        expect(theme.textTheme.bodyMedium!.fontFamily, 'Nunito');
        expect(theme.textTheme.bodyMedium!.fontSize, 16);
      });
    });
  }
}
