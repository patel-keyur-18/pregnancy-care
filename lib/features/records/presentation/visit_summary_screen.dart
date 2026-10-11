import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/features/care/data/visit_repository.dart';
import 'package:navmaas/features/records/data/records_repository.dart';
import 'package:navmaas/features/records/data/summary_data.dart';
import 'package:navmaas/features/records/domain/summary_pdf.dart';
import 'package:navmaas/features/records/domain/visit_summary.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care → Visit summary (M9a): the dates and sections she picks, made into a
/// PDF on the phone and handed to the share sheet. Opened from a visit, the
/// dates start at the visit before it.
class VisitSummaryScreen extends ConsumerStatefulWidget {
  const new({this.visitId, super.key});

  final String? visitId;

  @override
  ConsumerState<VisitSummaryScreen> createState() => _VisitSummaryScreenState();
}

class _VisitSummaryScreenState extends ConsumerState<VisitSummaryScreen> {
  SummaryRangeChoice _choice = SummaryRangeChoice.sinceLastVisit;
  SummaryRange? _custom;
  Set<SummarySection> _sections = defaultSummarySections;
  bool _touched = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    var ready = false;
    ref.listenManual(summarySectionsProvider, (_, next) {
      final saved = next.value;
      if (_touched || saved == null) return;
      ready ? setState(() => _sections = saved) : _sections = saved;
    }, fireImmediately: true);
    ready = true;
  }

  SummaryRange? _range() {
    final pregnancy = ref.watch(activePregnancyProvider).value;
    if (pregnancy == null) return null;
    final visits = ref.watch(appointmentsProvider).value ?? const [];
    final from = visits.where((v) => v.id == widget.visitId).firstOrNull;
    return summaryRange(
      _choice,
      today: ref.watch(todayProvider),
      pregnancyStart: pregnancy.startDate,
      visitDays: [for (final v in visits) dateOnly(v.at.toLocal())],
      fromVisitDay: from == null ? null : dateOnly(from.at.toLocal()),
      custom: _custom,
    );
  }

  Future<void> _pickCustom(DateTime start) async {
    final today = ref.read(todayProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null) return;
    setState(() {
      _custom = (from: dateOnly(picked.start), to: dateOnly(picked.end));
      _choice = SummaryRangeChoice.custom;
    });
  }

  Future<void> _toggle(SummarySection s, bool on) async {
    setState(() {
      _touched = true;
      _sections = {..._sections}..removeWhere((x) => x == s);
      if (on) _sections.add(s);
    });
    await ref
        .read(settingsRepositoryProvider)
        .put(SettingKeys.summarySections, storeSummarySections(_sections));
  }

  Future<void> _make(SummaryRange range) async {
    final l10n = AppLocalizations.of(context);
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (pregnancy == null) return;
    setState(() => _working = true);
    try {
      final today = ref.read(todayProvider);
      final data = await loadSummaryData(
        ref.read(appDatabaseProvider),
        pregnancyId: pregnancy.id,
        range: range,
        visitId: widget.visitId,
        prompts: await ref.read(birthPlanPromptsProvider.future),
      );
      final doc = visitSummaryContent(
        data,
        range,
        _sections,
        l10n: l10n,
        today: today,
      );
      final bytes = await renderSummaryPdf(
        doc,
        await ref.read(pdfFontsProvider.future),
        pageLabel: l10n.summaryPage,
      );
      await shareRecordCopy(
        temp: await ref.read(recordsTempDirProvider.future),
        name:
            '${l10n.summaryTitle} '
            '${DateFormat('yyyy-MM-dd').format(localDay(clockNow()))}.pdf',
        bytes: bytes,
        share: ref.read(shareFileProvider),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final range = _range();
    final choices = <(SummaryRangeChoice, String)>[
      (SummaryRangeChoice.sinceLastVisit, l10n.summarySinceLastVisit),
      (SummaryRangeChoice.lastFourWeeks, l10n.summaryLastFourWeeks),
      (SummaryRangeChoice.wholePregnancy, l10n.summaryWholePregnancy),
      (SummaryRangeChoice.custom, l10n.summaryCustom),
    ];
    final sections = <(SummarySection, String, String)>[
      (
        .pregnancy,
        l10n.summarySectionPregnancy,
        l10n.summarySectionPregnancySub,
      ),
      (
        .supplements,
        l10n.summarySectionSupplements,
        l10n.summarySectionSupplementsSub,
      ),
      (.vitals, l10n.summarySectionVitals, l10n.summarySectionVitalsSub),
      (
        .questions,
        l10n.summarySectionQuestions,
        l10n.summarySectionQuestionsSub,
      ),
      (.kicks, l10n.summarySectionKicks, l10n.summarySectionKicksSub),
      (.records, l10n.summarySectionRecords, l10n.summarySectionRecordsSub),
      (
        .wellbeing,
        l10n.summarySectionWellbeing,
        l10n.summarySectionWellbeingSub,
      ),
      (
        .birthPlan,
        l10n.summarySectionBirthPlan,
        l10n.summarySectionBirthPlanSub,
      ),
    ];
    Widget heading(String s) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(s, style: theme.textTheme.titleMedium),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                0,
                AppTheme.gutter,
                20,
              ),
              children: [
                Text(
                  l10n.summaryIntro,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                heading(l10n.summaryDates),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (c, word) in choices)
                      ChoiceChip(
                        label: Text(word),
                        selected: _choice == c,
                        showCheckmark: false,
                        shape: const StadiumBorder(),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: (_) => c == SummaryRangeChoice.custom
                            ? (pregnancy == null
                                  ? null
                                  : _pickCustom(pregnancy.startDate))
                            : setState(() => _choice = c),
                      ),
                  ],
                ),
                if (range != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.summaryRangeLine(
                      formatShortDate(range.from),
                      formatDate(range.to),
                    ),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                heading(l10n.summaryInclude),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, (s, title, sub)) in sections.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _sections.contains(s),
                          title: Text(title),
                          subtitle: Text(sub),
                          onChanged: (on) => _toggle(s, on ?? false),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                10,
                AppTheme.gutter,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: range == null || _working || _sections.isEmpty
                        ? null
                        : () => _make(range),
                    icon: NmIcon(
                      NavmaasIcon.share,
                      size: 20,
                      color: scheme.onPrimary,
                    ),
                    label: Text(l10n.summaryMakePdf),
                  ),
                  Text(
                    l10n.summaryPdfNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
