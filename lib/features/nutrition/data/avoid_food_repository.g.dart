// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avoid_food_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(avoidFoodRepository)
final avoidFoodRepositoryProvider = AvoidFoodRepositoryProvider._();

final class AvoidFoodRepositoryProvider
    extends
        $FunctionalProvider<
          AvoidFoodRepository,
          AvoidFoodRepository,
          AvoidFoodRepository
        >
    with $Provider<AvoidFoodRepository> {
  AvoidFoodRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avoidFoodRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avoidFoodRepositoryHash();

  @$internal
  @override
  $ProviderElement<AvoidFoodRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AvoidFoodRepository create(Ref ref) {
    return avoidFoodRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvoidFoodRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvoidFoodRepository>(value),
    );
  }
}

String _$avoidFoodRepositoryHash() =>
    r'05cf2156ddd5d0f2117b958abac05b0b51d66c91';

@ProviderFor(avoidFoods)
final avoidFoodsProvider = AvoidFoodsProvider._();

final class AvoidFoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AvoidFood>>,
          List<AvoidFood>,
          Stream<List<AvoidFood>>
        >
    with $FutureModifier<List<AvoidFood>>, $StreamProvider<List<AvoidFood>> {
  AvoidFoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avoidFoodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avoidFoodsHash();

  @$internal
  @override
  $StreamProviderElement<List<AvoidFood>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AvoidFood>> create(Ref ref) {
    return avoidFoods(ref);
  }
}

String _$avoidFoodsHash() => r'e4f7a1eb0f8ec2f726c664b7ecb5521e09686e58';
