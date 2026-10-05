// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(visitRepository)
final visitRepositoryProvider = VisitRepositoryProvider._();

final class VisitRepositoryProvider
    extends
        $FunctionalProvider<VisitRepository, VisitRepository, VisitRepository>
    with $Provider<VisitRepository> {
  VisitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitRepositoryHash();

  @$internal
  @override
  $ProviderElement<VisitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisitRepository create(Ref ref) {
    return visitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisitRepository>(value),
    );
  }
}

String _$visitRepositoryHash() => r'612940191cc6bfdc430322b4673e1106c59e4546';

@ProviderFor(appointments)
final appointmentsProvider = AppointmentsProvider._();

final class AppointmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Appointment>>,
          List<Appointment>,
          Stream<List<Appointment>>
        >
    with
        $FutureModifier<List<Appointment>>,
        $StreamProvider<List<Appointment>> {
  AppointmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appointmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appointmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<Appointment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Appointment>> create(Ref ref) {
    return appointments(ref);
  }
}

String _$appointmentsHash() => r'4eac00879be0cecc348f3dd0c0e95dc47c9b4a45';

@ProviderFor(visitQuestions)
final visitQuestionsProvider = VisitQuestionsProvider._();

final class VisitQuestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VisitQuestion>>,
          List<VisitQuestion>,
          Stream<List<VisitQuestion>>
        >
    with
        $FutureModifier<List<VisitQuestion>>,
        $StreamProvider<List<VisitQuestion>> {
  VisitQuestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitQuestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitQuestionsHash();

  @$internal
  @override
  $StreamProviderElement<List<VisitQuestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<VisitQuestion>> create(Ref ref) {
    return visitQuestions(ref);
  }
}

String _$visitQuestionsHash() => r'0fdd5af0c51ea349ed9095bd84ac47b69f14dc29';

@ProviderFor(visitAttachments)
final visitAttachmentsProvider = VisitAttachmentsFamily._();

final class VisitAttachmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Attachment>>,
          List<Attachment>,
          Stream<List<Attachment>>
        >
    with $FutureModifier<List<Attachment>>, $StreamProvider<List<Attachment>> {
  VisitAttachmentsProvider._({
    required VisitAttachmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'visitAttachmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visitAttachmentsHash();

  @override
  String toString() {
    return r'visitAttachmentsProvider'
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
    return visitAttachments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VisitAttachmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visitAttachmentsHash() => r'cd12d5574b78a3597b48cad4debc8e21662942d8';

final class VisitAttachmentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Attachment>>, String> {
  VisitAttachmentsFamily._()
    : super(
        retry: null,
        name: r'visitAttachmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VisitAttachmentsProvider call(String appointmentId) =>
      VisitAttachmentsProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'visitAttachmentsProvider';
}
