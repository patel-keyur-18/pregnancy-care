import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:navmaas/features/records/data/summary_data.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:navmaas/l10n/gen/app_localizations_en.dart';

// The same words the arb hard-line test bans (content_pack_test.dart).
final _forbidden = RegExp(
  r'\b(warn\w*|serious|severe|urgent\w*|abnormal|normal|risk\w*|'
  'unsafe|safe|should|must|consult|contact|hospital|sign of|'
  r'symptom of|good|bad|poor|better|worse|score\w*|healthy|unhealthy|'
  r'enough|too (much|little|few|many)|emergency|danger\w*|sos|dose|'
  r'doses|dosage|mg|ml|boy|girl|gender|sex|guarantee\w*)\b',
  caseSensitive: false,
);

final _l10n = AppLocalizationsEn();
final _today = DateTime.utc(2026, 10, 5);
final _start = DateTime.utc(2026, 4, 4);
final SummaryRange _range = (from: DateTime.utc(2026, 9, 17), to: _today);
final _at = DateTime(2026, 9, 20);

final _pregnancy = Pregnancy(
  id: 'p1',
  createdAt: _at,
  updatedAt: _at,
  status: PregnancyStatus.active,
  datingMethod: DatingMethod.lmp,
  startDate: _start,
  dueDate: DateTime.utc(2027, 1, 9),
  twins: false,
  highRisk: false,
  exerciseCleared: false,
);

VitalReading _vital(
  String id,
  VitalKind kind,
  double v1, {
  required DateTime at,
  double? v2,
  BloodSugarContext? context,
}) => VitalReading(
  id: id,
  createdAt: at,
  updatedAt: at,
  pregnancyId: 'p1',
  kind: kind,
  value1: v1,
  value2: v2,
  at: at,
  context: context,
);

SummaryData _data({List<VitalReading>? vitals}) => (
  name: 'Meera',
  pregnancy: _pregnancy,
  profile: Profile(
    id: 'd1',
    createdAt: _at,
    updatedAt: _at,
    doctorName: 'Dr. Mehta',
    clinicName: "City Women's Clinic",
  ),
  supplements: [(name: 'Folic acid', asPrescribed: '1 tablet', daysTaken: 18)],
  vitals:
      vitals ??
      [
        _vital(
          'v1',
          VitalKind.bloodSugar,
          96,
          context: BloodSugarContext.fasting,
          at: DateTime(2026, 10, 5, 7, 40),
        ),
        _vital('v2', VitalKind.weight, 61.2, at: DateTime(2026, 10, 2, 9)),
        _vital(
          'v3',
          VitalKind.bloodPressure,
          112,
          v2: 72,
          at: DateTime(2026, 10, 2, 9, 5),
        ),
      ],
  questions: ['When is the next scan?'],
  kicks: [
    KickSession(
      id: 'k1',
      createdAt: _at,
      updatedAt: _at,
      pregnancyId: 'p1',
      startedAt: DateTime(2026, 10, 1, 19),
      endedAt: DateTime(2026, 10, 1, 19, 24),
      count: 10,
    ),
  ],
  contractions: const [],
  records: [
    Attachment(
      id: 'r1',
      createdAt: _at,
      updatedAt: _at,
      fileName: 'x.bin',
      mimeType: 'application/pdf',
      pregnancyId: 'p1',
      category: RecordCategory.report,
      title: 'Blood report',
      takenOn: DateTime.utc(2026, 10, 2),
    ),
  ],
  moods: [
    MoodEntry(
      id: 'm1',
      createdAt: _at,
      updatedAt: _at,
      pregnancyId: 'p1',
      day: DateTime.utc(2026, 10, 4),
      mood: MoodWord.calm,
    ),
  ],
  symptoms: [
    SymptomEntry(
      id: 's1',
      createdAt: _at,
      updatedAt: _at,
      pregnancyId: 'p1',
      loggedAt: DateTime(2026, 10, 4, 18),
      symptomKey: SymptomKind.backache,
      severity: Severity.mild,
    ),
  ],
  sleep: [
    SleepLog(
      id: 'z1',
      createdAt: _at,
      updatedAt: _at,
      pregnancyId: 'p1',
      day: DateTime.utc(2026, 10, 4),
      bedAt: DateTime(2026, 10, 3, 22, 30),
      wokeAt: DateTime(2026, 10, 4, 6, 15),
      napMinutes: 0,
    ),
  ],
  water: [
    WaterLog(
      id: 'w1',
      createdAt: _at,
      updatedAt: _at,
      pregnancyId: 'p1',
      day: DateTime.utc(2026, 10, 4),
      glasses: 7,
    ),
  ],
  birthPlan: [(prompt: 'Who will be with you', answer: 'My mother')],
);

String _allText(SummaryDoc doc) => [
  doc.title,
  doc.subtitle,
  doc.forLine ?? '',
  doc.footer,
  for (final b in doc.blocks) ...[
    b.heading,
    ...b.lines,
    ...?b.table?.header,
    ...?b.table?.rows.expand((r) => r),
  ],
].join('\n');

void main() {
  group('range', () {
    test('since last visit: the latest past visit to today', () {
      final r = summaryRange(
        .sinceLastVisit,
        today: _today,
        pregnancyStart: _start,
        visitDays: [
          DateTime.utc(2026, 10, 8),
          DateTime.utc(2026, 8, 20),
          DateTime.utc(2026, 9, 17),
        ],
      );
      expect(r, (from: DateTime.utc(2026, 9, 17), to: _today));
    });

    test(
      'since last visit with only today or later visits: whole pregnancy',
      () {
        final r = summaryRange(
          .sinceLastVisit,
          today: _today,
          pregnancyStart: _start,
          visitDays: [_today, DateTime.utc(2026, 10, 8)],
        );
        expect(r, (from: _start, to: _today));
      },
    );

    test('from a visit: the visit before it, else the pregnancy start', () {
      final days = [DateTime.utc(2026, 9, 17), DateTime.utc(2026, 10, 8)];
      expect(
        summaryRange(
          .sinceLastVisit,
          today: _today,
          pregnancyStart: _start,
          visitDays: days,
          fromVisitDay: DateTime.utc(2026, 10, 8),
        ).from,
        DateTime.utc(2026, 9, 17),
      );
      expect(
        summaryRange(
          .sinceLastVisit,
          today: _today,
          pregnancyStart: _start,
          visitDays: days,
          fromVisitDay: DateTime.utc(2026, 9, 17),
        ).from,
        _start,
      );
    });

    test('last four weeks (never before the start) and whole pregnancy', () {
      expect(
        summaryRange(
          .lastFourWeeks,
          today: _today,
          pregnancyStart: _start,
          visitDays: const [],
        ),
        (from: DateTime.utc(2026, 9, 7), to: _today),
      );
      expect(
        summaryRange(
          .lastFourWeeks,
          today: DateTime.utc(2026, 4, 10),
          pregnancyStart: _start,
          visitDays: const [],
        ).from,
        _start,
      );
      expect(
        summaryRange(
          .wholePregnancy,
          today: _today,
          pregnancyStart: _start,
          visitDays: const [],
        ).from,
        _start,
      );
    });

    test('from an upcoming visit, later visits never start the range', () {
      final r = summaryRange(
        .sinceLastVisit,
        today: _today,
        pregnancyStart: _start,
        visitDays: [
          DateTime.utc(2026, 9, 17),
          DateTime.utc(2026, 10, 12),
          DateTime.utc(2026, 10, 20),
        ],
        fromVisitDay: DateTime.utc(2026, 10, 20),
      );
      expect(r, (from: DateTime.utc(2026, 9, 17), to: _today));
    });

    test('custom keeps her dates', () {
      final mine = (
        from: DateTime.utc(2026, 9, 2),
        to: DateTime.utc(2026, 9, 30),
      );
      expect(
        summaryRange(
          .custom,
          today: _today,
          pregnancyStart: _start,
          visitDays: const [],
          custom: mine,
        ),
        mine,
      );
    });
  });

  group('content', () {
    test('only the chosen sections, in order', () {
      final doc = visitSummaryContent(
        _data(),
        _range,
        {SummarySection.vitals, SummarySection.pregnancy},
        l10n: _l10n,
        today: _today,
      );
      expect(doc.blocks.map((b) => b.heading), ['Pregnancy summary', 'Vitals']);
      expect(doc.forLine, 'For Dr. Mehta');
      expect(doc.subtitle, 'Meera · Thu, 17 Sep – Mon, 5 Oct 2026');
    });

    test('the pregnancy summary has the week today and the due date', () {
      final doc = visitSummaryContent(
        _data(),
        _range,
        {SummarySection.pregnancy},
        l10n: _l10n,
        today: _today,
      );
      final cells = doc.blocks.single.table!.rows.expand((r) => r).toList();
      expect(cells, contains('Week 26, day 2'));
      expect(cells, contains('Sat, 9 Jan 2027 · Dated by last period'));
      expect(cells, contains("Dr. Mehta · City Women's Clinic"));
    });

    test('an empty section says so instead of disappearing', () {
      final doc = visitSummaryContent(
        _data(vitals: const []),
        _range,
        {SummarySection.vitals},
        l10n: _l10n,
        today: _today,
      );
      expect(doc.blocks.single.lines, ['Nothing logged in this range']);
      expect(doc.blocks.single.table, isNull);
    });

    test('vitals are values with units and context, by day', () {
      final doc = visitSummaryContent(
        _data(),
        _range,
        {SummarySection.vitals},
        l10n: _l10n,
        today: _today,
      );
      final t = doc.blocks.single.table!;
      expect(t.header, ['Date', 'Weight', 'Blood pressure', 'Blood sugar']);
      expect(t.rows, [
        ['Mon, 5 Oct', '—', '—', '96 mg/dL · Fasting, 7:40 am'],
        ['Fri, 2 Oct', '61.2 kg', '112/72 mmHg', '—'],
      ]);
    });

    test('supplements, kicks, records and wellbeing as values', () {
      final doc = visitSummaryContent(
        _data(),
        _range,
        {
          SummarySection.supplements,
          SummarySection.kicks,
          SummarySection.records,
          SummarySection.wellbeing,
          SummarySection.birthPlan,
        },
        l10n: _l10n,
        today: _today,
      );
      final [supps, kicks, records, wellbeing, plan] = doc.blocks;
      expect(supps.table!.rows.single, [
        'Folic acid',
        '1 tablet',
        '18 of 19 days',
      ]);
      expect(kicks.lines, ['Kick sessions: 1', 'Contractions timed: 0']);
      expect(records.table!.rows.single, [
        'Fri, 2 Oct',
        'Report',
        'Blood report',
      ]);
      expect(wellbeing.lines.single, contains('Sun, 4 Oct'));
      expect(wellbeing.lines.single, contains('Calm'));
      expect(wellbeing.lines.single, contains('Backache (Mild)'));
      expect(wellbeing.lines.single, contains('sleep 7 h 45 min'));
      expect(wellbeing.lines.single, contains('water 7 glasses'));
      expect(plan.lines, ['## Who will be with you', 'My mother']);
    });

    test('the words the summary adds pass the hard-line check', () {
      final doc = visitSummaryContent(
        _data(),
        _range,
        SummarySection.values.toSet(),
        l10n: _l10n,
        today: _today,
      );
      final text = _allText(doc).replaceAll('mg/dL', '');
      expect(_forbidden.allMatches(text).map((m) => m[0]), isEmpty);
    });
  });

  group('sections setting', () {
    test('null is the default; stored names round-trip', () {
      expect(parseSummarySections(null), defaultSummarySections);
      expect(parseSummarySections(''), isEmpty);
      final s = {SummarySection.vitals, SummarySection.wellbeing};
      expect(parseSummarySections(storeSummarySections(s)), s);
      expect(parseSummarySections('vitals,gone'), {SummarySection.vitals});
    });
  });

  group('loader', () {
    late AppDatabase db;
    late String pid;
    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      await PregnancyRepository(db).saveDating(method: .lmp, date: _start);
      pid = (await db.select(db.pregnancies).getSingle()).id;
    });
    tearDown(() => db.close());

    test(
      'counts days taken, keeps the range, and picks the questions',
      () async {
        final supplements = SupplementRepository(db);
        final sid = await supplements.save(
          pregnancyId: pid,
          name: 'Folic acid',
          doseText: '1 tablet',
          times: [
            (id: null, minuteOfDay: 9 * 60, weekdayMask: 127, label: null),
          ],
        );
        final schedule = await (db.select(
          db.supplementSchedules,
        )..where((t) => t.supplementId.equals(sid))).getSingle();
        for (final day in [20, 21, 10]) {
          await supplements.setTaken(
            schedule.id,
            DateTime(2026, 9, day, 9),
            taken: true,
          );
        }
        final vitals = VitalsRepository(db);
        await vitals.add(
          pregnancyId: pid,
          kind: VitalKind.weight,
          value1: 60,
          at: DateTime(2026, 9, 20, 9),
        );
        await vitals.add(
          pregnancyId: pid,
          kind: VitalKind.weight,
          value1: 58,
          at: DateTime(2026, 9, 1, 9),
        );
        final visits = VisitRepository(db);
        final visit = await visits.saveAppointment(
          pregnancyId: pid,
          at: DateTime(2026, 10, 8, 11),
        );
        final other = await visits.saveAppointment(
          pregnancyId: pid,
          at: DateTime(2026, 9, 17, 11),
        );
        await visits.addQuestion(pid, 'Waiting question');
        await visits.addQuestion(pid, 'Asked last time');
        await visits.addQuestion(pid, 'Asked at this visit');
        final qs = await db.select(db.visitQuestions).get();
        await visits.setAsked(
          qs.firstWhere((q) => q.body == 'Asked last time').id,
          asked: true,
          appointmentId: other,
        );
        await visits.setAsked(
          qs.firstWhere((q) => q.body == 'Asked at this visit').id,
          asked: true,
          appointmentId: visit,
        );

        final data = await loadSummaryData(
          db,
          pregnancyId: pid,
          range: _range,
          visitId: visit,
          prompts: const [],
        );
        expect(data.supplements.single.daysTaken, 2);
        expect(data.supplements.single.asPrescribed, startsWith('1 tablet'));
        expect(data.vitals.map((v) => v.value1), [60]);
        expect(data.questions, ['Waiting question', 'Asked at this visit']);
      },
    );
  });
}
