// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_pack.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contentPack)
final contentPackProvider = ContentPackProvider._();

final class ContentPackProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentPack>,
          ContentPack,
          FutureOr<ContentPack>
        >
    with $FutureModifier<ContentPack>, $FutureProvider<ContentPack> {
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

String _$contentPackHash() => r'ed5327d66b41d27d30f3530fcbe0a6ef8b487c07';
