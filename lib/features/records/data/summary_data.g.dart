// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sections she last chose for the visit summary.

@ProviderFor(summarySections)
final summarySectionsProvider = SummarySectionsProvider._();

/// The sections she last chose for the visit summary.

final class SummarySectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<SummarySection>>,
          Set<SummarySection>,
          Stream<Set<SummarySection>>
        >
    with
        $FutureModifier<Set<SummarySection>>,
        $StreamProvider<Set<SummarySection>> {
  /// The sections she last chose for the visit summary.
  SummarySectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summarySectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summarySectionsHash();

  @$internal
  @override
  $StreamProviderElement<Set<SummarySection>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<SummarySection>> create(Ref ref) {
    return summarySections(ref);
  }
}

String _$summarySectionsHash() => r'2aa61fd178c2de92764cf3e83665ca219c16df95';
