import 'package:drift/drift.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/attachment_store.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visit_repository.g.dart';

/// Doctor visits, questions to ask and encrypted attachments.
class VisitRepository {
  const new(this._db);

  final AppDatabase _db;

  Stream<List<Appointment>> watchAppointments(String pregnancyId) =>
      (_db.select(_db.appointments)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.at)]))
          .watch();

  Future<String> saveAppointment({
    required String pregnancyId,
    required DateTime at,
    String? id,
    String? doctor,
    String? place,
  }) async {
    Value<String?> v(String? s) =>
        Value(s == null || s.trim().isEmpty ? null : s.trim());
    final row = AppointmentsCompanion(
      pregnancyId: Value(pregnancyId),
      at: Value(at),
      doctor: v(doctor),
      place: v(place),
      updatedAt: Value(clockNow()),
    );
    if (id == null) {
      return (await _db.into(_db.appointments).insertReturning(row)).id;
    }
    await (_db.update(
      _db.appointments,
    )..where((t) => t.id.equals(id))).write(row);
    return id;
  }

  Future<void> setNotes(String id, String notes) =>
      (_db.update(_db.appointments)..where((t) => t.id.equals(id))).write(
        AppointmentsCompanion(
          notes: Value(notes.trim().isEmpty ? null : notes.trim()),
          updatedAt: Value(clockNow()),
        ),
      );

  Future<void> setBringAlong(String id, List<String> items) =>
      (_db.update(_db.appointments)..where((t) => t.id.equals(id))).write(
        AppointmentsCompanion(
          bringAlong: Value(
            items.map((s) => s.trim()).where((s) => s.isNotEmpty).join('\n'),
          ),
          updatedAt: Value(clockNow()),
        ),
      );

  Future<void> removeAppointment(String id) =>
      (_db.update(_db.appointments)..where((t) => t.id.equals(id))).write(
        AppointmentsCompanion(deletedAt: Value(clockNow())),
      );

  Stream<List<VisitQuestion>> watchQuestions(String pregnancyId) =>
      (_db.select(_db.visitQuestions)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> addQuestion(String pregnancyId, String body) => _db
      .into(_db.visitQuestions)
      .insert(
        VisitQuestionsCompanion.insert(
          pregnancyId: pregnancyId,
          body: body.trim(),
        ),
      );

  /// Ticks a question as asked at [appointmentId], or unticks it.
  Future<void> setAsked(
    String id, {
    required bool asked,
    required String appointmentId,
  }) => (_db.update(_db.visitQuestions)..where((t) => t.id.equals(id))).write(
    VisitQuestionsCompanion(
      askedAt: Value(asked ? clockNow() : null),
      appointmentId: Value(asked ? appointmentId : null),
      updatedAt: Value(clockNow()),
    ),
  );

  Future<void> removeQuestion(String id) =>
      (_db.update(_db.visitQuestions)..where((t) => t.id.equals(id))).write(
        VisitQuestionsCompanion(deletedAt: Value(clockNow())),
      );

  Stream<List<Attachment>> watchAttachments(String appointmentId) =>
      (_db.select(_db.attachments)
            ..where(
              (t) =>
                  t.appointmentId.equals(appointmentId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> addAttachment(
    AttachmentStore store,
    String appointmentId,
    Uint8List bytes,
    String mimeType,
  ) async {
    final name = await store.save(bytes);
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            appointmentId: Value(appointmentId),
            fileName: name,
            mimeType: mimeType,
          ),
        );
  }

  Future<void> removeAttachment(AttachmentStore store, Attachment a) async {
    await (_db.update(_db.attachments)..where((t) => t.id.equals(a.id))).write(
      AttachmentsCompanion(deletedAt: Value(clockNow())),
    );
    await store.delete(a.fileName);
  }
}

@riverpod
VisitRepository visitRepository(Ref ref) =>
    VisitRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<Appointment>> appointments(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(visitRepositoryProvider).watchAppointments(id);
}

@riverpod
Stream<List<VisitQuestion>> visitQuestions(Ref ref) {
  final id = ref.watch(activePregnancyProvider).value?.id;
  if (id == null) return Stream.value(const []);
  return ref.watch(visitRepositoryProvider).watchQuestions(id);
}

@riverpod
Stream<List<Attachment>> visitAttachments(Ref ref, String appointmentId) =>
    ref.watch(visitRepositoryProvider).watchAttachments(appointmentId);
