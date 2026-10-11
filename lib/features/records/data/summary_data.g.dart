// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The PDF's fonts; widget tests read the files directly.

@ProviderFor(pdfFonts)
final pdfFontsProvider = PdfFontsProvider._();

/// The PDF's fonts; widget tests read the files directly.

final class PdfFontsProvider
    extends
        $FunctionalProvider<AsyncValue<PdfFonts>, PdfFonts, FutureOr<PdfFonts>>
    with $FutureModifier<PdfFonts>, $FutureProvider<PdfFonts> {
  /// The PDF's fonts; widget tests read the files directly.
  PdfFontsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfFontsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfFontsHash();

  @$internal
  @override
  $FutureProviderElement<PdfFonts> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PdfFonts> create(Ref ref) {
    return pdfFonts(ref);
  }
}

String _$pdfFontsHash() => r'19655db57a9209e616099f5bf71824a00ada335b';

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
