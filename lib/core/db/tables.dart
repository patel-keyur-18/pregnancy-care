import 'package:drift/drift.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:uuid/uuid.dart';

/// Time-ordered UUID v7, used as every row's id.
String newId() => const Uuid().v7();

/// Columns every table has (ARCHITECTURE §8): UUID v7 id, timestamps and a
/// soft-delete marker.
mixin BaseColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
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
