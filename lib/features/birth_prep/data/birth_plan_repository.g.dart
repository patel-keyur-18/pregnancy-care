// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'birth_plan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(birthPlanRepository)
final birthPlanRepositoryProvider = BirthPlanRepositoryProvider._();

final class BirthPlanRepositoryProvider
    extends
        $FunctionalProvider<
          BirthPlanRepository,
          BirthPlanRepository,
          BirthPlanRepository
        >
    with $Provider<BirthPlanRepository> {
  BirthPlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'birthPlanRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$birthPlanRepositoryHash();

  @$internal
  @override
  $ProviderElement<BirthPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BirthPlanRepository create(Ref ref) {
    return birthPlanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BirthPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BirthPlanRepository>(value),
    );
  }
}

String _$birthPlanRepositoryHash() =>
    r'b8cca8c8854d0008c110f3b57ce7490a21ea7a10';

@ProviderFor(birthPlanAnswers)
final birthPlanAnswersProvider = BirthPlanAnswersProvider._();

final class BirthPlanAnswersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          Stream<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $StreamProvider<Map<String, String>> {
  BirthPlanAnswersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'birthPlanAnswersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$birthPlanAnswersHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, String>> create(Ref ref) {
    return birthPlanAnswers(ref);
  }
}

String _$birthPlanAnswersHash() => r'24e5ed1de1f26cbed95057a63ccc8ea38fb36986';
