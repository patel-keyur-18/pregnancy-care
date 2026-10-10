// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nourishly_meals.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What Nourishly shares (M8b). Null: not shared; an error: there is a file
/// Navmaas can't read. Never stored. Re-read on resume (`app.dart`) and when
/// Nutrition opens; no automatic retry (a broken file stays broken).

@ProviderFor(nourishlyShare)
final nourishlyShareProvider = NourishlyShareProvider._();

/// What Nourishly shares (M8b). Null: not shared; an error: there is a file
/// Navmaas can't read. Never stored. Re-read on resume (`app.dart`) and when
/// Nutrition opens; no automatic retry (a broken file stays broken).

final class NourishlyShareProvider
    extends
        $FunctionalProvider<
          AsyncValue<NourishlyShare?>,
          NourishlyShare?,
          FutureOr<NourishlyShare?>
        >
    with $FutureModifier<NourishlyShare?>, $FutureProvider<NourishlyShare?> {
  /// What Nourishly shares (M8b). Null: not shared; an error: there is a file
  /// Navmaas can't read. Never stored. Re-read on resume (`app.dart`) and when
  /// Nutrition opens; no automatic retry (a broken file stays broken).
  NourishlyShareProvider._()
    : super(
        from: null,
        argument: null,
        retry: _never,
        name: r'nourishlyShareProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nourishlyShareHash();

  @$internal
  @override
  $FutureProviderElement<NourishlyShare?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NourishlyShare?> create(Ref ref) {
    return nourishlyShare(ref);
  }
}

String _$nourishlyShareHash() => r'c23485771cc41781681d5d84c2b79c5bed386f68';
