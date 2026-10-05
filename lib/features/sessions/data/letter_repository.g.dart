// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letter_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(letterRepository)
final letterRepositoryProvider = LetterRepositoryProvider._();

final class LetterRepositoryProvider
    extends
        $FunctionalProvider<
          LetterRepository,
          LetterRepository,
          LetterRepository
        >
    with $Provider<LetterRepository> {
  LetterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'letterRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$letterRepositoryHash();

  @$internal
  @override
  $ProviderElement<LetterRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LetterRepository create(Ref ref) {
    return letterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LetterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LetterRepository>(value),
    );
  }
}

String _$letterRepositoryHash() => r'20c9f0bd0d5f3f3d6ad6c6a94d302e829ed488de';

@ProviderFor(letters)
final lettersProvider = LettersProvider._();

final class LettersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Letter>>,
          List<Letter>,
          Stream<List<Letter>>
        >
    with $FutureModifier<List<Letter>>, $StreamProvider<List<Letter>> {
  LettersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lettersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lettersHash();

  @$internal
  @override
  $StreamProviderElement<List<Letter>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Letter>> create(Ref ref) {
    return letters(ref);
  }
}

String _$lettersHash() => r'26d6a23a2e936ea8880e0155e9458cfa9851c94d';
