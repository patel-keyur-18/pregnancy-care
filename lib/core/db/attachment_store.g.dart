// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attachmentStore)
final attachmentStoreProvider = AttachmentStoreProvider._();

final class AttachmentStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttachmentStore>,
          AttachmentStore,
          FutureOr<AttachmentStore>
        >
    with $FutureModifier<AttachmentStore>, $FutureProvider<AttachmentStore> {
  AttachmentStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentStoreHash();

  @$internal
  @override
  $FutureProviderElement<AttachmentStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttachmentStore> create(Ref ref) {
    return attachmentStore(ref);
  }
}

String _$attachmentStoreHash() => r'8416f96c070b0476381b02d833f87eace6e90819';

/// Voice letters (E3), sealed like attachments with the same key, in their
/// own `db/voice/` folder (skipped by OS backups; in a `.navmaas` backup only
/// when "Include voice letters" is on).

@ProviderFor(voiceStore)
final voiceStoreProvider = VoiceStoreProvider._();

/// Voice letters (E3), sealed like attachments with the same key, in their
/// own `db/voice/` folder (skipped by OS backups; in a `.navmaas` backup only
/// when "Include voice letters" is on).

final class VoiceStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttachmentStore>,
          AttachmentStore,
          FutureOr<AttachmentStore>
        >
    with $FutureModifier<AttachmentStore>, $FutureProvider<AttachmentStore> {
  /// Voice letters (E3), sealed like attachments with the same key, in their
  /// own `db/voice/` folder (skipped by OS backups; in a `.navmaas` backup only
  /// when "Include voice letters" is on).
  VoiceStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceStoreHash();

  @$internal
  @override
  $FutureProviderElement<AttachmentStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttachmentStore> create(Ref ref) {
    return voiceStore(ref);
  }
}

String _$voiceStoreHash() => r'327c718934fbeda16ffbd7d9a66b407ca695d388';
