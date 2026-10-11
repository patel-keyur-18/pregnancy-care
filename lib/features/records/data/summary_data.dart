import 'package:drift/drift.dart';
import 'package:navmaas/core/content/content_pack.dart' show BirthPlanPrompt;
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'summary_data.g.dart';

/// The sections she last chose for the visit summary.
@riverpod
Stream<Set<SummarySection>> summarySections(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.summarySections)
    .map(parseSummarySections);

/// Reads what the visit summary may show for one pregnancy and [range]
/// (both days included). Plain reads, outside any transaction.
Future<SummaryData> loadSummaryData(
  AppDatabase db, {
  required String pregnancyId,
  required SummaryRange range,
  required List<BirthPlanPrompt> prompts,
  String? visitId,
}) async {
  // Local-time bounds for timestamps; date strings for date-only columns.
  final from = DateTime(range.from.year, range.from.month, range.from.day);
  final end = DateTime(range.to.year, range.to.month, range.to.day + 1);
  const dates = DateOnlyConverter();
  final fromDay = dates.toSql(range.from);
  final toDay = dates.toSql(range.to);

  final pregnancy = await (db.select(
    db.pregnancies,
  )..where((t) => t.id.equals(pregnancyId))).getSingle();
  final profile = await (db.select(
    db.profiles,
  )..where((t) => t.deletedAt.isNull())).getSingleOrNull();
  final name = (await SettingsRepository(db).getAll())[SettingKeys.firstName];

  // Supplements with their times, and the days a dose was marked taken.
  final supplements =
      await (db.select(db.supplements)
            ..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();
  final schedules = await (db.select(
    db.supplementSchedules,
  )..where((t) => t.deletedAt.isNull())).get();
  final taken =
      await (db.select(db.doseLogs)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.status.equalsValue(DoseStatus.taken) &
                t.dueAt.isBiggerOrEqualValue(from) &
                t.dueAt.isSmallerThanValue(end),
          ))
          .get();
  final scheduleOf = {for (final s in schedules) s.id: s.supplementId};
  final daysTaken = <String, Set<DateTime>>{};
  for (final d in taken) {
    final supplement = scheduleOf[d.scheduleId];
    if (supplement == null) continue;
    daysTaken.putIfAbsent(supplement, () => {}).add(localDay(d.dueAt));
  }

  final vitals =
      await (db.select(db.vitalReadings)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.at.isBiggerOrEqualValue(from) &
                t.at.isSmallerThanValue(end),
          ))
          .get();
  final questions =
      await (db.select(db.visitQuestions)
            ..where(
              (t) =>
                  t.pregnancyId.equals(pregnancyId) &
                  t.deletedAt.isNull() &
                  (t.askedAt.isNull() |
                      (visitId == null
                          ? const Constant(false)
                          : t.appointmentId.equals(visitId))),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
  final kicks =
      await (db.select(db.kickSessions)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.startedAt.isBiggerOrEqualValue(from) &
                t.startedAt.isSmallerThanValue(end),
          ))
          .get();
  final contractions =
      await (db.select(db.contractions)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.startedAt.isBiggerOrEqualValue(from) &
                t.startedAt.isSmallerThanValue(end),
          ))
          .get();
  final records =
      await (db.select(db.attachments)
            ..where(
              (t) =>
                  t.pregnancyId.equals(pregnancyId) &
                  t.deletedAt.isNull() &
                  t.takenOn.isBetweenValues(fromDay, toDay),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.takenOn)]))
          .get();
  final moods =
      await (db.select(db.moodEntries)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBetweenValues(fromDay, toDay),
          ))
          .get();
  final symptoms =
      await (db.select(db.symptomEntries)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.loggedAt.isBiggerOrEqualValue(from) &
                t.loggedAt.isSmallerThanValue(end),
          ))
          .get();
  final sleep =
      await (db.select(db.sleepLogs)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBetweenValues(fromDay, toDay),
          ))
          .get();
  final water =
      await (db.select(db.waterLogs)..where(
            (t) =>
                t.pregnancyId.equals(pregnancyId) &
                t.deletedAt.isNull() &
                t.day.isBetweenValues(fromDay, toDay),
          ))
          .get();
  final answers = {
    for (final a
        in await (db.select(db.birthPlanAnswers)..where(
              (t) => t.pregnancyId.equals(pregnancyId) & t.deletedAt.isNull(),
            ))
            .get())
      a.promptKey: a.answer.trim(),
  };

  return (
    name: name,
    pregnancy: pregnancy,
    profile: profile,
    supplements: [
      for (final s in supplements)
        (
          name: s.name,
          asPrescribed: [
            if (s.doseText.trim().isNotEmpty) s.doseText.trim(),
            [
              for (final t in schedules.where((t) => t.supplementId == s.id))
                t.label ?? formatMinuteOfDay(t.minuteOfDay),
            ].join(', '),
          ].where((x) => x.isNotEmpty).join(' · '),
          daysTaken: daysTaken[s.id]?.length ?? 0,
        ),
    ],
    vitals: vitals,
    questions: [for (final q in questions) q.body],
    kicks: kicks,
    contractions: contractions,
    records: records,
    moods: moods,
    symptoms: symptoms,
    sleep: sleep,
    water: water,
    birthPlan: [
      for (final p in prompts)
        if (answers[p.key] case final a? when a.isNotEmpty)
          (prompt: p.title, answer: a),
    ],
  );
}
