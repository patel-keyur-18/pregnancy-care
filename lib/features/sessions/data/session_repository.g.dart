// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRepository,
          SessionRepository,
          SessionRepository
        >
    with $Provider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRepository create(Ref ref) {
    return sessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRepository>(value),
    );
  }
}

String _$sessionRepositoryHash() => r'7e1f5ca74f59c7af241add8efab8d7a79c3d6f41';

/// The active pregnancy's sessions started in [from, to) (local times).

@ProviderFor(sessionsBetween)
final sessionsBetweenProvider = SessionsBetweenFamily._();

/// The active pregnancy's sessions started in [from, to) (local times).

final class SessionsBetweenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          Stream<List<Session>>
        >
    with $FutureModifier<List<Session>>, $StreamProvider<List<Session>> {
  /// The active pregnancy's sessions started in [from, to) (local times).
  SessionsBetweenProvider._({
    required SessionsBetweenFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'sessionsBetweenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionsBetweenHash();

  @override
  String toString() {
    return r'sessionsBetweenProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Session>> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return sessionsBetween(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionsBetweenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionsBetweenHash() => r'cbe56bac84deed67d6c134c928ba674fd3eb0ec0';

/// The active pregnancy's sessions started in [from, to) (local times).

final class SessionsBetweenFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<Session>>, (DateTime, DateTime)> {
  SessionsBetweenFamily._()
    : super(
        retry: null,
        name: r'sessionsBetweenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The active pregnancy's sessions started in [from, to) (local times).

  SessionsBetweenProvider call(DateTime from, DateTime to) =>
      SessionsBetweenProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'sessionsBetweenProvider';
}

/// The walk she started and hasn't finished, if any.

@ProviderFor(walkDraft)
final walkDraftProvider = WalkDraftProvider._();

/// The walk she started and hasn't finished, if any.

final class WalkDraftProvider
    extends
        $FunctionalProvider<
          AsyncValue<WalkDraft?>,
          WalkDraft?,
          Stream<WalkDraft?>
        >
    with $FutureModifier<WalkDraft?>, $StreamProvider<WalkDraft?> {
  /// The walk she started and hasn't finished, if any.
  WalkDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkDraftHash();

  @$internal
  @override
  $StreamProviderElement<WalkDraft?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<WalkDraft?> create(Ref ref) {
    return walkDraft(ref);
  }
}

String _$walkDraftHash() => r'740501d697f5d5513e894ec5cd4d1d068612b9a7';
