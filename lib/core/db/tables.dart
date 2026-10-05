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
