/// The visit summary (M9a): which dates, which sections, and the plain
/// content that becomes the PDF. Values and her own words only; nothing here
/// rates, ranges or explains a value.
library;

import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart'
    show bloodSugarContextWord;
import 'package:navmaas/features/records/presentation/records_screen.dart'
    show recordDay, recordKindWord, recordLabel;
import 'package:navmaas/features/third_trimester/domain/patterns.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

enum SummarySection {
  pregnancy,
  supplements,
  vitals,
  questions,
  kicks,
  records,
  wellbeing,
  birthPlan,
}

/// Ticked until she changes them (Plan decision 79): the clinical ones.
const Set<SummarySection> defaultSummarySections = {
  SummarySection.pregnancy,
  SummarySection.supplements,
  SummarySection.vitals,
  SummarySection.questions,
  SummarySection.kicks,
  SummarySection.records,
};

enum SummaryRangeChoice {
  sinceLastVisit,
  lastFourWeeks,
  wholePregnancy,
  custom,
}

/// UTC-midnight dates, both included.
typedef SummaryRange = ({DateTime from, DateTime to});

/// The dates for [choice]. "Since last visit" starts at the latest visit
/// before today (or before [fromVisitDay], when opened from a visit), else
/// at the start of the pregnancy.
SummaryRange summaryRange(
  SummaryRangeChoice choice, {
  required DateTime today,
  required DateTime pregnancyStart,
  required List<DateTime> visitDays,
  DateTime? fromVisitDay,
  SummaryRange? custom,
}) {
  switch (choice) {
    case .sinceLastVisit:
      final before = fromVisitDay ?? today;
      // Visits before the one it's for, and never one still to come.
      final past =
          visitDays
              .where((d) => d.isBefore(before) && !d.isAfter(today))
              .toList()
            ..sort();
      return (from: past.isEmpty ? pregnancyStart : past.last, to: today);
    case .lastFourWeeks:
      final from = addDays(today, -28);
      return (
        from: from.isBefore(pregnancyStart) ? pregnancyStart : from,
        to: today,
      );
    case .wholePregnancy:
      return (from: pregnancyStart, to: today);
    case .custom:
      return custom ?? (from: pregnancyStart, to: today);
  }
}

typedef SummaryTable = ({List<String> header, List<List<String>> rows});

/// A heading, then lines (a line starting `## ` is printed bold), then an
/// optional table.
typedef SummaryBlock = ({
  String heading,
  List<String> lines,
  SummaryTable? table,
});

typedef SummaryDoc = ({
  String title,
  String subtitle,
  String? forLine,
  List<SummaryBlock> blocks,
  String footer,
});

/// Everything the summary may show, already limited to the range.
typedef SummaryData = ({
  String? name,
  Pregnancy pregnancy,
  Profile? profile,
  List<({String name, String asPrescribed, int daysTaken})> supplements,
  List<VitalReading> vitals,
  List<String> questions,
  List<KickSession> kicks,
  List<Contraction> contractions,
  List<Attachment> records,
  List<MoodEntry> moods,
  List<SymptomEntry> symptoms,
  List<SleepLog> sleep,
  List<WaterLog> water,
  List<({String prompt, String answer})> birthPlan,
});

String _time(DateTime t) => formatMinuteOfDay(t.hour * 60 + t.minute);

String _number(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

SummaryDoc visitSummaryContent(
  SummaryData data,
  SummaryRange range,
  Set<SummarySection> sections, {
  required AppLocalizations l10n,
  required DateTime today,
}) {
  SummaryBlock block(String heading, List<String> lines, [SummaryTable? t]) =>
      lines.isEmpty && (t == null || t.rows.isEmpty)
      ? (heading: heading, lines: [l10n.summaryNothing], table: null)
      : (heading: heading, lines: lines, table: t);

  final doctor = [
    data.profile?.doctorName,
    data.profile?.clinicName,
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');

  SummaryBlock pregnancy() {
    final p = data.pregnancy;
    final now = PregnancySnapshot.of(start: p.startDate, today: today);
    return block(l10n.summarySectionPregnancy, const [], (
      header: const [],
      rows: [
        if (data.name case final n? when n.isNotEmpty) [l10n.summaryName, n],
        [
          l10n.summaryDueDate,
          '${formatDate(p.dueDate)} · ${l10n.datedBy(p.datingMethod.name)}',
        ],
        [l10n.summaryToday, l10n.summaryWeekDay(now.weeks, now.days)],
        if (doctor.isNotEmpty) [l10n.summaryDoctor, doctor],
      ],
    ));
  }

  SummaryBlock supplements() =>
      block(l10n.summarySectionSupplements, const [], (
        header: [
          l10n.summaryName,
          l10n.summaryAsPrescribed,
          l10n.summaryMarkedTaken,
        ],
        rows: [
          for (final s in data.supplements)
            [
              s.name,
              s.asPrescribed,
              l10n.summaryDaysOf(
                s.daysTaken,
                daysBetween(range.from, range.to) + 1,
              ),
            ],
        ],
      ));

  SummaryBlock vitals() {
    final days = <DateTime, Map<VitalKind, List<String>>>{};
    for (final v in [...data.vitals]..sort((a, b) => b.at.compareTo(a.at))) {
      final at = v.at.toLocal();
      final value = switch (v.kind) {
        VitalKind.weight => '${_number(v.value1)} kg',
        VitalKind.bloodPressure =>
          '${v.value1.round()}/${v.value2?.round()} mmHg',
        VitalKind.bloodSugar => [
          '${v.value1.round()} mg/dL',
          [
            if (v.context case final c?) bloodSugarContextWord(l10n, c),
            _time(at),
          ].join(', '),
        ].join(' · '),
      };
      days
          .putIfAbsent(dateOnly(at), () => {})
          .putIfAbsent(v.kind, () => [])
          .add(value);
    }
    String cell(Map<VitalKind, List<String>> d, VitalKind k) =>
        d[k]?.join('; ') ?? '—';
    return block(l10n.summarySectionVitals, const [], (
      header: [
        l10n.summaryDate,
        l10n.weight,
        l10n.bloodPressure,
        l10n.bloodSugar,
      ],
      rows: [
        for (final MapEntry(key: day, value: d) in days.entries)
          [
            formatShortDate(day),
            cell(d, VitalKind.weight),
            cell(d, VitalKind.bloodPressure),
            cell(d, VitalKind.bloodSugar),
          ],
      ],
    ));
  }

  SummaryBlock kicks() {
    if (data.kicks.isEmpty && data.contractions.isEmpty) {
      return block(l10n.summarySectionKicks, const []);
    }
    final window = mostActiveWindow(data.kicks);
    final lengths = [
      for (final c in data.contractions) c.endedAt.difference(c.startedAt),
    ];
    final average = lengths.isEmpty
        ? null
        : lengths.fold(Duration.zero, (a, b) => a + b) ~/ lengths.length;
    return block(l10n.summarySectionKicks, [
      [
        l10n.summaryKickCount(data.kicks.length),
        if (window != null)
          l10n.summaryKickWindow(
            '${formatMinuteOfDay(window * 60)}–'
            '${formatMinuteOfDay((window + 2) % 24 * 60)}',
          ),
      ].join(' · '),
      [
        l10n.summaryContractionCount(data.contractions.length),
        if (average != null)
          l10n.summaryContractionAverage(
            l10n.summaryMinSec(
              average.inMinutes,
              average.inSeconds.remainder(60),
            ),
          ),
      ].join(' · '),
    ]);
  }

  SummaryBlock records() => block(l10n.summarySectionRecords, const [], (
    header: [l10n.summaryDate, l10n.summaryKind, l10n.summaryTitleColumn],
    rows: [
      for (final r in data.records)
        [
          formatShortDate(recordDay(r)),
          recordKindWord(l10n, r.category),
          recordLabel(l10n, r),
        ],
    ],
  ));

  SummaryBlock wellbeing() {
    final days = <DateTime, List<String>>{};
    void add(DateTime day, String s) => days.putIfAbsent(day, () => []).add(s);
    for (final m in data.moods) {
      add(m.day, l10n.mood(m.mood));
    }
    for (final s in data.symptoms) {
      add(
        dateOnly(s.loggedAt.toLocal()),
        '${l10n.symptomName(s)} (${l10n.severity(s.severity)})',
      );
    }
    for (final s in data.sleep) {
      final minutes = s.wokeAt.difference(s.bedAt).inMinutes + s.napMinutes;
      add(s.day, l10n.summarySleepLine(l10n.duration(minutes)));
    }
    for (final w in data.water) {
      add(w.day, l10n.summaryWaterLine(w.glasses));
    }
    final sorted = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return block(l10n.summarySectionWellbeing, [
      for (final d in sorted) '${formatShortDate(d)}: ${days[d]!.join('; ')}',
    ]);
  }

  final blocks = [
    for (final s in SummarySection.values)
      if (sections.contains(s))
        switch (s) {
          .pregnancy => pregnancy(),
          .supplements => supplements(),
          .vitals => vitals(),
          .questions => block(l10n.summarySectionQuestions, [
            for (final q in data.questions) '• $q',
          ]),
          .kicks => kicks(),
          .records => records(),
          .wellbeing => wellbeing(),
          .birthPlan => block(l10n.summarySectionBirthPlan, [
            for (final a in data.birthPlan) ...['## ${a.prompt}', a.answer],
          ]),
        },
  ];
  final dates = l10n.summaryRangeLine(
    formatShortDate(range.from),
    formatDate(range.to),
  );
  return (
    title: l10n.summaryTitle,
    subtitle: [
      if (data.name case final n? when n.isNotEmpty) n,
      dates,
    ].join(' · '),
    forLine: switch (data.profile?.doctorName?.trim()) {
      final d? when d.isNotEmpty => l10n.summaryForLine(d),
      _ => null,
    },
    blocks: blocks,
    footer: l10n.summaryFooter(formatDate(today)),
  );
}

/// Her last choice of sections, stored as comma-separated names; null (never
/// chosen) is the default set.
Set<SummarySection> parseSummarySections(String? stored) {
  if (stored == null) return defaultSummarySections;
  final names = stored.split(',').toSet();
  return {
    for (final s in SummarySection.values)
      if (names.contains(s.name)) s,
  };
}

String storeSummarySections(Set<SummarySection> sections) => [
  for (final s in SummarySection.values)
    if (sections.contains(s)) s.name,
].join(',');
