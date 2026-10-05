// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Light / Dark / System, persisted in settings. Defaults to System.

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

/// Light / Dark / System, persisted in settings. Defaults to System.

final class ThemeModeProvider
    extends
        $FunctionalProvider<AsyncValue<ThemeMode>, ThemeMode, Stream<ThemeMode>>
    with $FutureModifier<ThemeMode>, $StreamProvider<ThemeMode> {
  /// Light / Dark / System, persisted in settings. Defaults to System.
  ThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $StreamProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ThemeMode> create(Ref ref) {
    return themeMode(ref);
  }
}

String _$themeModeHash() => r'7d742678b2e343cc59a0cf9835d6026e3bf29385';
