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
