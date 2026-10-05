// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitals_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vitalsRepository)
final vitalsRepositoryProvider = VitalsRepositoryProvider._();

final class VitalsRepositoryProvider
    extends
        $FunctionalProvider<
          VitalsRepository,
          VitalsRepository,
          VitalsRepository
        >
    with $Provider<VitalsRepository> {
  VitalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vitalsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vitalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<VitalsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VitalsRepository create(Ref ref) {
    return vitalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VitalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VitalsRepository>(value),
    );
  }
}

String _$vitalsRepositoryHash() => r'b3f3f56049ae1d9605b1389fc2aea379818c4906';

@ProviderFor(vitals)
final vitalsProvider = VitalsFamily._();

final class VitalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VitalReading>>,
          List<VitalReading>,
          Stream<List<VitalReading>>
        >
    with
        $FutureModifier<List<VitalReading>>,
        $StreamProvider<List<VitalReading>> {
  VitalsProvider._({
    required VitalsFamily super.from,
    required VitalKind super.argument,
  }) : super(
         retry: null,
         name: r'vitalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vitalsHash();

  @override
  String toString() {
    return r'vitalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<VitalReading>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<VitalReading>> create(Ref ref) {
    final argument = this.argument as VitalKind;
    return vitals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VitalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vitalsHash() => r'88e088ddfceab2229fe0519ec07149eef46b9819';

final class VitalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<VitalReading>>, VitalKind> {
  VitalsFamily._()
    : super(
        retry: null,
        name: r'vitalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VitalsProvider call(VitalKind kind) =>
      VitalsProvider._(argument: kind, from: this);

  @override
  String toString() => r'vitalsProvider';
}
