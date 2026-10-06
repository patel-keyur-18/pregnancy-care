// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_use.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "In Navmaas today" (Screen Rest): time the app was on screen today.
/// [ScreenUse] holds when the app last came on screen; the seconds before
/// that are saved in settings when it leaves the screen, so nothing is
/// written while she uses it.

@ProviderFor(ScreenUse)
final screenUseProvider = ScreenUseProvider._();

/// "In Navmaas today" (Screen Rest): time the app was on screen today.
/// [ScreenUse] holds when the app last came on screen; the seconds before
/// that are saved in settings when it leaves the screen, so nothing is
/// written while she uses it.
final class ScreenUseProvider extends $NotifierProvider<ScreenUse, DateTime?> {
  /// "In Navmaas today" (Screen Rest): time the app was on screen today.
  /// [ScreenUse] holds when the app last came on screen; the seconds before
  /// that are saved in settings when it leaves the screen, so nothing is
  /// written while she uses it.
  ScreenUseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenUseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenUseHash();

  @$internal
  @override
  ScreenUse create() => ScreenUse();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$screenUseHash() => r'6dc53a82f09724f2158e068335421dc14adadd11';

/// "In Navmaas today" (Screen Rest): time the app was on screen today.
/// [ScreenUse] holds when the app last came on screen; the seconds before
/// that are saved in settings when it leaves the screen, so nothing is
/// written while she uses it.

abstract class _$ScreenUse extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Time in Navmaas today, as the Screen Rest card shows it.

@ProviderFor(usedTodayTotal)
final usedTodayTotalProvider = UsedTodayTotalProvider._();

/// Time in Navmaas today, as the Screen Rest card shows it.

final class UsedTodayTotalProvider
    extends
        $FunctionalProvider<AsyncValue<Duration>, Duration, Stream<Duration>>
    with $FutureModifier<Duration>, $StreamProvider<Duration> {
  /// Time in Navmaas today, as the Screen Rest card shows it.
  UsedTodayTotalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usedTodayTotalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usedTodayTotalHash();

  @$internal
  @override
  $StreamProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Duration> create(Ref ref) {
    return usedTodayTotal(ref);
  }
}

String _$usedTodayTotalHash() => r'd981c9cbaf126ce683c75b3af778b42f81d528eb';

/// "Eye-rest nudge" (Screen Rest): on unless switched off.

@ProviderFor(eyeRest)
final eyeRestProvider = EyeRestProvider._();

/// "Eye-rest nudge" (Screen Rest): on unless switched off.

final class EyeRestProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// "Eye-rest nudge" (Screen Rest): on unless switched off.
  EyeRestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eyeRestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eyeRestHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return eyeRest(ref);
  }
}

String _$eyeRestHash() => r'9d2031f89de62ebea72edf3c143e4a9f6c95fa81';
