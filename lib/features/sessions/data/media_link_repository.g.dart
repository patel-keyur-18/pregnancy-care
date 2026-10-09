// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_link_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaLinkRepository)
final mediaLinkRepositoryProvider = MediaLinkRepositoryProvider._();

final class MediaLinkRepositoryProvider
    extends
        $FunctionalProvider<
          MediaLinkRepository,
          MediaLinkRepository,
          MediaLinkRepository
        >
    with $Provider<MediaLinkRepository> {
  MediaLinkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLinkRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLinkRepositoryHash();

  @$internal
  @override
  $ProviderElement<MediaLinkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaLinkRepository create(Ref ref) {
    return mediaLinkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaLinkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaLinkRepository>(value),
    );
  }
}

String _$mediaLinkRepositoryHash() =>
    r'62693d93463a5bd14a9fd9f2563c81162ec560fe';

@ProviderFor(mediaLinks)
final mediaLinksProvider = MediaLinksProvider._();

final class MediaLinksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MediaLink>>,
          List<MediaLink>,
          Stream<List<MediaLink>>
        >
    with $FutureModifier<List<MediaLink>>, $StreamProvider<List<MediaLink>> {
  MediaLinksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLinksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLinksHash();

  @$internal
  @override
  $StreamProviderElement<List<MediaLink>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MediaLink>> create(Ref ref) {
    return mediaLinks(ref);
  }
}

String _$mediaLinksHash() => r'1d64c0a95004603b8db79e7743bbfd32db2e67f3';

@ProviderFor(openLink)
final openLinkProvider = OpenLinkProvider._();

final class OpenLinkProvider
    extends $FunctionalProvider<OpenLink, OpenLink, OpenLink>
    with $Provider<OpenLink> {
  OpenLinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openLinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openLinkHash();

  @$internal
  @override
  $ProviderElement<OpenLink> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OpenLink create(Ref ref) {
    return openLink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenLink value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenLink>(value),
    );
  }
}

String _$openLinkHash() => r'4737fce6fab862fd9474664ea8268bb4d8cef88a';
