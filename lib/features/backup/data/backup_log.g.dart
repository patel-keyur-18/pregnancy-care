// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_log.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When she last made a backup on this phone, or null.

@ProviderFor(lastBackup)
final lastBackupProvider = LastBackupProvider._();

/// When she last made a backup on this phone, or null.

final class LastBackupProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  /// When she last made a backup on this phone, or null.
  LastBackupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastBackupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastBackupHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return lastBackup(ref);
  }
}

String _$lastBackupHash() => r'1c54613641bf674d2f3c96b7765dbfe7c4d92253';
