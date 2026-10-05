// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stepSource)
final stepSourceProvider = StepSourceProvider._();

final class StepSourceProvider
    extends $FunctionalProvider<StepSource, StepSource, StepSource>
    with $Provider<StepSource> {
  StepSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stepSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stepSourceHash();

  @$internal
  @override
  $ProviderElement<StepSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StepSource create(Ref ref) {
    return stepSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StepSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StepSource>(value),
    );
  }
}

String _$stepSourceHash() => r'656843632182e18a52a7b6b5275c0bd89e48dad5';
