// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supplementRepository)
final supplementRepositoryProvider = SupplementRepositoryProvider._();

final class SupplementRepositoryProvider
    extends
        $FunctionalProvider<
          SupplementRepository,
          SupplementRepository,
          SupplementRepository
        >
    with $Provider<SupplementRepository> {
  SupplementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplementRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplementRepositoryHash();

  @$internal
  @override
  $ProviderElement<SupplementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupplementRepository create(Ref ref) {
    return supplementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupplementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupplementRepository>(value),
    );
  }
}

String _$supplementRepositoryHash() =>
    r'f20bb1ab189e21e7c9601d612b7b224d30424547';

/// Supplements of the active pregnancy.

@ProviderFor(supplementPlans)
final supplementPlansProvider = SupplementPlansProvider._();

/// Supplements of the active pregnancy.

final class SupplementPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SupplementPlan>>,
          List<SupplementPlan>,
          Stream<List<SupplementPlan>>
        >
    with
        $FutureModifier<List<SupplementPlan>>,
        $StreamProvider<List<SupplementPlan>> {
  /// Supplements of the active pregnancy.
  SupplementPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supplementPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supplementPlansHash();

  @$internal
  @override
  $StreamProviderElement<List<SupplementPlan>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SupplementPlan>> create(Ref ref) {
    return supplementPlans(ref);
  }
}

String _$supplementPlansHash() => r'7c7b5ecf90b0959582241911caedd2b5a16f42b2';

/// Keys of doses taken with due times in [from, to) (local dates).

@ProviderFor(takenDoses)
final takenDosesProvider = TakenDosesFamily._();

/// Keys of doses taken with due times in [from, to) (local dates).

final class TakenDosesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Keys of doses taken with due times in [from, to) (local dates).
  TakenDosesProvider._({
    required TakenDosesFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'takenDosesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$takenDosesHash();

  @override
  String toString() {
    return r'takenDosesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return takenDoses(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TakenDosesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$takenDosesHash() => r'82c55b9992b9ecb0a6d4fb8ca6d3cca989c9eb41';

/// Keys of doses taken with due times in [from, to) (local dates).

final class TakenDosesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<String>>, (DateTime, DateTime)> {
  TakenDosesFamily._()
    : super(
        retry: null,
        name: r'takenDosesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keys of doses taken with due times in [from, to) (local dates).

  TakenDosesProvider call(DateTime from, DateTime to) =>
      TakenDosesProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'takenDosesProvider';
}
