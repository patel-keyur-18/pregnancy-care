// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'records_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pickImage)
final pickImageProvider = PickImageProvider._();

final class PickImageProvider
    extends $FunctionalProvider<PickImage, PickImage, PickImage>
    with $Provider<PickImage> {
  PickImageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pickImageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pickImageHash();

  @$internal
  @override
  $ProviderElement<PickImage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PickImage create(Ref ref) {
    return pickImage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickImage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickImage>(value),
    );
  }
}

String _$pickImageHash() => r'309d76777bc33b2ba33003642e832a90557f6c40';

/// Where a record or the visit summary waits, plain, for the share sheet.

@ProviderFor(recordsTempDir)
final recordsTempDirProvider = RecordsTempDirProvider._();

/// Where a record or the visit summary waits, plain, for the share sheet.

final class RecordsTempDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// Where a record or the visit summary waits, plain, for the share sheet.
  RecordsTempDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordsTempDirProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordsTempDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return recordsTempDir(ref);
  }
}

String _$recordsTempDirHash() => r'74218a04965de56b6b2282b6f101d08511dae12d';

@ProviderFor(recordsRepository)
final recordsRepositoryProvider = RecordsRepositoryProvider._();

final class RecordsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordsRepository>,
          RecordsRepository,
          FutureOr<RecordsRepository>
        >
    with
        $FutureModifier<RecordsRepository>,
        $FutureProvider<RecordsRepository> {
  RecordsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<RecordsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecordsRepository> create(Ref ref) {
    return recordsRepository(ref);
  }
}

String _$recordsRepositoryHash() => r'daf448d20e9642965e9d209cf9223d24de939d73';

/// Records of the active pregnancy, newest first.

@ProviderFor(records)
final recordsProvider = RecordsProvider._();

/// Records of the active pregnancy, newest first.

final class RecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Attachment>>,
          List<Attachment>,
          Stream<List<Attachment>>
        >
    with $FutureModifier<List<Attachment>>, $StreamProvider<List<Attachment>> {
  /// Records of the active pregnancy, newest first.
  RecordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordsHash();

  @$internal
  @override
  $StreamProviderElement<List<Attachment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Attachment>> create(Ref ref) {
    return records(ref);
  }
}

String _$recordsHash() => r'dea116bb8f5d7fba26a5e33d0f6fc51ecaf0da91';

@ProviderFor(visitRecords)
final visitRecordsProvider = VisitRecordsFamily._();

final class VisitRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Attachment>>,
          List<Attachment>,
          Stream<List<Attachment>>
        >
    with $FutureModifier<List<Attachment>>, $StreamProvider<List<Attachment>> {
  VisitRecordsProvider._({
    required VisitRecordsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'visitRecordsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visitRecordsHash();

  @override
  String toString() {
    return r'visitRecordsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Attachment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Attachment>> create(Ref ref) {
    final argument = this.argument as String;
    return visitRecords(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VisitRecordsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visitRecordsHash() => r'1c7b3ea05bc9925589f939aad889711031a49d12';

final class VisitRecordsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Attachment>>, String> {
  VisitRecordsFamily._()
    : super(
        retry: null,
        name: r'visitRecordsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VisitRecordsProvider call(String appointmentId) =>
      VisitRecordsProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'visitRecordsProvider';
}
