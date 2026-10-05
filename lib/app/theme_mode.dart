import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode.g.dart';

/// Light / Dark / System, persisted in settings. Defaults to System.
@Riverpod(keepAlive: true)
Stream<ThemeMode> themeMode(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.themeMode)
    .map((v) => ThemeMode.values.asNameMap()[v] ?? ThemeMode.system);

Future<void> setThemeMode(WidgetRef ref, ThemeMode mode) =>
    ref.read(settingsRepositoryProvider).put(SettingKeys.themeMode, mode.name);
