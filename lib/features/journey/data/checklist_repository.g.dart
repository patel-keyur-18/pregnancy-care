// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checklistRepository)
final checklistRepositoryProvider = ChecklistRepositoryProvider._();

final class ChecklistRepositoryProvider
    extends
        $FunctionalProvider<
          ChecklistRepository,
          ChecklistRepository,
          ChecklistRepository
        >
    with $Provider<ChecklistRepository> {
  ChecklistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChecklistRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistRepository create(Ref ref) {
    return checklistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistRepository>(value),
    );
  }
}

String _$checklistRepositoryHash() =>
    r'da45270ad38eb1e85c8fab56052e6ff17756f445';

/// Ticked item keys for the active pregnancy (empty when there is none).

@ProviderFor(tickedItems)
final tickedItemsProvider = TickedItemsProvider._();

/// Ticked item keys for the active pregnancy (empty when there is none).

final class TickedItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Ticked item keys for the active pregnancy (empty when there is none).
  TickedItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tickedItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tickedItemsHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return tickedItems(ref);
  }
}

String _$tickedItemsHash() => r'23ebf22e14ed1ac4b40d4b182a707a66564ab6e6';
