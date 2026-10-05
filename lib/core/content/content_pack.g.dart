// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_pack.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read once (the provider is kept alive), so the bundle cache isn't needed.

@ProviderFor(contentPack)
final contentPackProvider = ContentPackProvider._();

/// Read once (the provider is kept alive), so the bundle cache isn't needed.

final class ContentPackProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentPack>,
          ContentPack,
          FutureOr<ContentPack>
        >
    with $FutureModifier<ContentPack>, $FutureProvider<ContentPack> {
  /// Read once (the provider is kept alive), so the bundle cache isn't needed.
  ContentPackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentPackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentPackHash();

  @$internal
  @override
  $FutureProviderElement<ContentPack> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContentPack> create(Ref ref) {
    return contentPack(ref);
  }
}

String _$contentPackHash() => r'e92813536859a553f09f9e8ae5598eeb58b24e56';

@ProviderFor(careTemplate)
final careTemplateProvider = CareTemplateProvider._();

final class CareTemplateProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareTemplateItem>>,
          List<CareTemplateItem>,
          FutureOr<List<CareTemplateItem>>
        >
    with
        $FutureModifier<List<CareTemplateItem>>,
        $FutureProvider<List<CareTemplateItem>> {
  CareTemplateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'careTemplateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$careTemplateHash();

  @$internal
  @override
  $FutureProviderElement<List<CareTemplateItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CareTemplateItem>> create(Ref ref) {
    return careTemplate(ref);
  }
}

String _$careTemplateHash() => r'683d498e975d8a54505c17ad7ead2c83176aff55';

@ProviderFor(activities)
final activitiesProvider = ActivitiesProvider._();

final class ActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  ActivitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    return activities(ref);
  }
}

String _$activitiesHash() => r'a37f517645efff8158ae1cb492a68bff6da302e4';

@ProviderFor(routines)
final routinesProvider = RoutinesProvider._();

final class RoutinesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Routine>>,
          List<Routine>,
          FutureOr<List<Routine>>
        >
    with $FutureModifier<List<Routine>>, $FutureProvider<List<Routine>> {
  RoutinesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routinesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routinesHash();

  @$internal
  @override
  $FutureProviderElement<List<Routine>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Routine>> create(Ref ref) {
    return routines(ref);
  }
}

String _$routinesHash() => r'3a8af206f9a7eeb0f66b0c2d778b4b2e9e55a3e4';
