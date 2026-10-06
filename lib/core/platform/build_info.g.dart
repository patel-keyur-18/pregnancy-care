// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_info.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When this iPhone build stops opening (ARCHITECTURE §12): a free Apple ID
/// signs for 7 days. The profile sits next to the app's executable. Null on
/// Android, the simulator and App Store builds, which have no such limit.

@ProviderFor(buildExpiry)
final buildExpiryProvider = BuildExpiryProvider._();

/// When this iPhone build stops opening (ARCHITECTURE §12): a free Apple ID
/// signs for 7 days. The profile sits next to the app's executable. Null on
/// Android, the simulator and App Store builds, which have no such limit.

final class BuildExpiryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateTime?>,
          DateTime?,
          FutureOr<DateTime?>
        >
    with $FutureModifier<DateTime?>, $FutureProvider<DateTime?> {
  /// When this iPhone build stops opening (ARCHITECTURE §12): a free Apple ID
  /// signs for 7 days. The profile sits next to the app's executable. Null on
  /// Android, the simulator and App Store builds, which have no such limit.
  BuildExpiryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildExpiryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildExpiryHash();

  @$internal
  @override
  $FutureProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime?> create(Ref ref) {
    return buildExpiry(ref);
  }
}

String _$buildExpiryHash() => r'498541e6becdb0ea305e7b374e928e4fb34695c8';
