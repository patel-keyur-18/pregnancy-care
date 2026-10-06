import 'package:drift/drift.dart';
import 'package:navmaas/core/content/content_pack.dart' show CareKind;
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:uuid/uuid.dart';

/// Time-ordered UUID v7, used as every row's id.
String newId() => const Uuid().v7();

/// Columns every table has (ARCHITECTURE §8): UUID v7 id, timestamps and a
/// soft-delete marker.
mixin BaseColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get createdAt => dateTime().clientDefault(clockNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(clockNow)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

enum PregnancyStatus { active, paused, ended, delivered }

@DataClassName('Pregnancy')
class Pregnancies extends Table with BaseColumns {
  @override
  String get tableName => 'pregnancy';

  TextColumn get status => textEnum<PregnancyStatus>()();
  TextColumn get datingMethod => textEnum<DatingMethod>()();
  TextColumn get lmp => text().map(const DateOnlyConverter()).nullable()();
  IntColumn get cycleLength => integer().nullable()();

  /// Conception date, IVF transfer date or scan due date.
  TextColumn get anchorDate =>
      text().map(const DateOnlyConverter()).nullable()();
  IntColumn get embryoDay => integer().nullable()();
  TextColumn get startDate => text().map(const DateOnlyConverter())();
  TextColumn get dueDate => text().map(const DateOnlyConverter())();
  BoolColumn get twins => boolean().withDefault(const Constant(false))();
  BoolColumn get highRisk => boolean().withDefault(const Constant(false))();
  BoolColumn get exerciseCleared =>
      boolean().withDefault(const Constant(false))();
}

/// A ticked item from a week's checklist (Journey). Unticking soft-deletes.
@DataClassName('ChecklistTick')
class ChecklistTicks extends Table with BaseColumns {
  @override
  String get tableName => 'checklist_tick';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();

  /// `ChecklistItem.key` from the content pack, e.g. `w24-gtt`.
  TextColumn get itemKey => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {pregnancyId, itemKey},
  ];
}

/// The owner's doctor and clinic (one row). Everything is optional.
@DataClassName('Profile')
class Profiles extends Table with BaseColumns {
  @override
  String get tableName => 'profile';

  TextColumn get doctorName => text().nullable()();
  TextColumn get clinicName => text().nullable()();
  TextColumn get clinicPhone => text().nullable()();
  TextColumn get clinicAddress => text().nullable()();
}

/// A supplement as prescribed. [doseText] is copied from the prescription;
/// the app never suggests doses.
@DataClassName('Supplement')
class Supplements extends Table with BaseColumns {
  @override
  String get tableName => 'supplement';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get name => text()();
  TextColumn get doseText => text().withDefault(const Constant(''))();
  TextColumn get notes => text().nullable()();

  /// Doses left; each "Taken" uses one. Null when not tracked.
  IntColumn get stock => integer().nullable()();

  /// Remind to refill at or below this many doses.
  IntColumn get refillAt => integer().nullable()();
}

/// When a supplement is taken: a time of day on some weekdays.
@DataClassName('SupplementSchedule')
class SupplementSchedules extends Table with BaseColumns {
  @override
  String get tableName => 'supplement_schedule';

  TextColumn get supplementId => text().references(Supplements, #id)();

  /// Minutes after midnight, local time.
  IntColumn get minuteOfDay => integer()();

  /// Bit 0 = Monday … bit 6 = Sunday; 127 = every day.
  IntColumn get weekdayMask => integer().withDefault(const Constant(127))();

  /// "after breakfast".
  TextColumn get label => text().nullable()();
}

enum DoseStatus { taken, skipped, missed }

/// A dose marked for one scheduled slot. Unmarking soft-deletes it.
@DataClassName('DoseLog')
class DoseLogs extends Table with BaseColumns {
  @override
  String get tableName => 'dose_log';

  TextColumn get scheduleId => text().references(SupplementSchedules, #id)();

  /// The slot's local date and time.
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  TextColumn get status => textEnum<DoseStatus>()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {scheduleId, dueAt},
  ];
}

/// A test, scan or vaccine for this pregnancy, created from the India care
/// template. Booked = [scheduledAt] set; done = [doneAt] set.
@DataClassName('CareItem')
class CareItems extends Table with BaseColumns {
  @override
  String get tableName => 'care_item';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get templateKey => text().nullable()();
  TextColumn get kind => textEnum<CareKind>()();
  TextColumn get title => text()();
  IntColumn get fromWeek => integer()();
  IntColumn get toWeek => integer()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get doneAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {pregnancyId, templateKey},
  ];
}

/// A doctor visit.
@DataClassName('Appointment')
class Appointments extends Table with BaseColumns {
  @override
  String get tableName => 'appointment';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  DateTimeColumn get at => dateTime()();
  TextColumn get doctor => text().nullable()();
  TextColumn get place => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Things to bring, one per line.
  TextColumn get bringAlong => text().withDefault(const Constant(''))();
}

/// A question to ask the doctor; unlinked ones wait for the next visit.
@DataClassName('VisitQuestion')
class VisitQuestions extends Table with BaseColumns {
  @override
  String get tableName => 'visit_question';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get appointmentId =>
      text().nullable().references(Appointments, #id)();
  TextColumn get body => text()();
  DateTimeColumn get askedAt => dateTime().nullable()();
}

/// An encrypted file (e.g. a prescription photo) in the private data folder.
@DataClassName('Attachment')
class Attachments extends Table with BaseColumns {
  @override
  String get tableName => 'attachment';

  TextColumn get appointmentId =>
      text().nullable().references(Appointments, #id)();

  /// File name inside `db/attachments/`.
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
}

enum VitalKind { weight, bloodPressure }

/// A logged reading. Weight: [value1] kg. Blood pressure: [value1] systolic,
/// [value2] diastolic (mmHg). Recorded only; never interpreted.
@DataClassName('VitalReading')
class VitalReadings extends Table with BaseColumns {
  @override
  String get tableName => 'vital_reading';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get kind => textEnum<VitalKind>()();
  RealColumn get value1 => real()();
  RealColumn get value2 => real().nullable()();
  DateTimeColumn get at => dateTime()();
}

enum LibraryKind { pdf, text, audio }

/// A book or audio file the owner imported (M4a). The file is a copy inside
/// the private `db/library/` folder, which OS backups skip. Not tied to a
/// pregnancy: the library stays with the phone.
@DataClassName('LibraryItem')
class LibraryItems extends Table with BaseColumns {
  @override
  String get tableName => 'library_item';

  TextColumn get kind => textEnum<LibraryKind>()();
  TextColumn get title => text()();

  /// File name inside `db/library/`.
  TextColumn get fileName => text()();

  /// Audio length, once known.
  IntColumn get durationSec => integer().nullable()();

  /// Where she left off: PDF page (0-based), or thousandths of the way
  /// through a text.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// PDF pages, or 1000 for a text, once opened.
  IntColumn get total => integer().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
}

enum SessionType { reading, listening, walk, exercise, breathing }

/// A logged session: reading, listening, a walk, a routine or breathing.
@DataClassName('Session')
class Sessions extends Table with BaseColumns {
  @override
  String get tableName => 'session';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get type => textEnum<SessionType>()();
  TextColumn get libraryItemId =>
      text().nullable().references(LibraryItems, #id)();
  TextColumn get routineKey => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationSec => integer()();
  IntColumn get steps => integer().nullable()();
}

/// A letter to baby (Garbhasanskar "talk to baby").
@DataClassName('Letter')
class Letters extends Table with BaseColumns {
  @override
  String get tableName => 'letter';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  TextColumn get body => text()();
}

/// A kick-counter session: movements counted from the first tap to the last.
@DataClassName('KickSession')
class KickSessions extends Table with BaseColumns {
  @override
  String get tableName => 'kick_session';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get count => integer()();
}

/// One timed contraction, from start to end.
@DataClassName('Contraction')
class Contractions extends Table with BaseColumns {
  @override
  String get tableName => 'contraction';

  TextColumn get pregnancyId => text().references(Pregnancies, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
}

enum BackupKind { backup, restore }

/// When a backup was made or restored. Never holds the password.
@DataClassName('BackupLogEntry')
class BackupLog extends Table with BaseColumns {
  @override
  String get tableName => 'backup_log';

  TextColumn get kind => textEnum<BackupKind>()();
  IntColumn get sizeBytes => integer()();
  BoolColumn get includesLibrary => boolean()();
}

/// Key-value app settings (theme, first name, …).
@DataClassName('Setting')
class Settings extends Table with BaseColumns {
  @override
  String get tableName => 'settings';

  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

/// Calendar dates are stored as `yyyy-MM-dd` text, never as instants.
class DateOnlyConverter extends TypeConverter<DateTime, String> {
  const new();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse('${fromDb}T00:00:00Z');

  @override
  String toSql(DateTime value) => value.toIso8601String().substring(0, 10);
}
