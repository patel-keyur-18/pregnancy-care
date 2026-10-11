import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/utils/format_bytes.dart';
import 'package:navmaas/features/records/data/records_repository.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

String recordKindWord(AppLocalizations l10n, RecordCategory c) => switch (c) {
  RecordCategory.report => l10n.recordKindReport,
  RecordCategory.scan => l10n.recordKindScan,
  RecordCategory.prescription => l10n.recordKindPrescription,
  RecordCategory.other => l10n.recordKindOther,
};

/// Her title, or the kind's word when she gave none.
String recordLabel(AppLocalizations l10n, Attachment a) =>
    a.title.isEmpty ? recordKindWord(l10n, a.category) : a.title;

/// The record's date: the one on it, else the day it was added.
DateTime recordDay(Attachment a) => a.takenOn ?? dateOnly(a.createdAt);

/// Care → Records (M9a): her reports, scans and prescriptions, encrypted on
/// the phone. Nothing here reads or judges them.
class RecordsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  /// Null shows all kinds.
  RecordCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final all = ref.watch(recordsProvider).value ?? const <Attachment>[];
    final shown = [
      for (final a in all)
        if (_filter == null || a.category == _filter) a,
    ];
    final months = <String, List<Attachment>>{};
    for (final a in shown) {
      months
          .putIfAbsent(DateFormat('MMMM yyyy').format(recordDay(a)), () => [])
          .add(a);
    }
    final filters = <(RecordCategory?, String)>[
      (null, l10n.recordsAll),
      (RecordCategory.report, l10n.recordsFilterReport),
      (RecordCategory.scan, l10n.recordsFilterScan),
      (RecordCategory.prescription, l10n.recordsFilterPrescription),
      (RecordCategory.other, l10n.recordsFilterOther),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordsTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              4,
              AppTheme.gutter,
              4,
            ),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.push('/care/visit-summary'),
              icon: NmIcon(
                NavmaasIcon.birthPlan,
                size: 20,
                color: scheme.onSurface,
              ),
              label: Text(l10n.summaryMake),
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? _Empty(l10n: l10n)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.gutter,
                      8,
                      AppTheme.gutter,
                      20,
                    ),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (c, word) in filters)
                            ChoiceChip(
                              label: Text(word),
                              selected: _filter == c,
                              showCheckmark: false,
                              shape: const StadiumBorder(),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              onSelected: (_) => setState(() => _filter = c),
                            ),
                        ],
                      ),
                      for (final MapEntry(key: month, value: rows)
                          in months.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Semantics(
                            header: true,
                            child: Text(
                              month,
                              style: theme.textTheme.titleSmall!.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final (i, a) in rows.indexed) ...[
                                if (i > 0) const Divider(height: 1),
                                _RecordRow(record: a),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        l10n.recordsPrivacy,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                8,
                AppTheme.gutter,
                16,
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => showAddRecord(context, ref),
                icon: NmIcon(
                  NavmaasIcon.plus,
                  size: 20,
                  strokeWidth: 2.2,
                  color: scheme.onPrimary,
                ),
                label: Text(l10n.recordAdd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const new({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.navmaas.amberSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: NmIcon(
                NavmaasIcon.folder,
                size: 30,
                color: context.navmaas.onAmberSoft,
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                l10n.recordsEmptyTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              l10n.recordsEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A PDF glyph or a picture icon: the list never decrypts a record.
class RecordThumb extends StatelessWidget {
  const new({required this.record, this.size = 48, super.key});

  final Attachment record;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pdf = record.mimeType == 'application/pdf';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pdf ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: pdf
          ? Text(
              'PDF',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: scheme.onPrimaryContainer,
              ),
            )
          : NmIcon(NavmaasIcon.scan, size: 22, color: scheme.onSurfaceVariant),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const new({required this.record});

  final Attachment record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sub = [
      l10n.recordRowSub(
        recordKindWord(l10n, record.category),
        formatShortDate(recordDay(record)),
        formatBytes(record.sizeBytes ?? 0),
      ),
      if (record.appointmentId != null) l10n.recordFromVisit,
    ].join(' · ');
    return ListTile(
      minTileHeight: 68,
      leading: RecordThumb(record: record),
      title: Text(
        recordLabel(l10n, record),
        style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(sub),
      trailing: NmIcon(
        NavmaasIcon.chevronRight,
        size: 20,
        strokeWidth: 2,
        color: theme.colorScheme.outline,
      ),
      onTap: () => context.push('/care/records/view', extra: record.id),
    );
  }
}

typedef RecordDetailsResult = ({
  RecordCategory category,
  String title,
  DateTime takenOn,
});

enum _Source { camera, photos, file }

/// Add a record: camera, photos or a file (PDF or image, up to 25 MB), then
/// its details. From a visit it's linked there, a prescription by default.
Future<void> showAddRecord(
  BuildContext context,
  WidgetRef ref, {
  String? appointmentId,
  DateTime? visitDay,
}) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<_Source>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.recordAdd,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.camera),
              title: Text(l10n.recordTakePhoto),
              onTap: () => Navigator.pop(context, _Source.camera),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.scan),
              title: Text(l10n.recordChoosePhoto),
              onTap: () => Navigator.pop(context, _Source.photos),
            ),
            ListTile(
              leading: const NmIcon(NavmaasIcon.notes),
              title: Text(l10n.recordChooseFile),
              subtitle: Text(l10n.recordChooseFileSub),
              onTap: () => Navigator.pop(context, _Source.file),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(l10n.recordKeptEncrypted),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  final repo = await ref.read(recordsRepositoryProvider.future);
  Uint8List? bytes;
  var mime = 'image/jpeg';
  try {
    if (source == _Source.file) {
      final f = await ref.read(pickFileProvider)(const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
      ]);
      if (f != null) {
        bytes = await repo.readCapped(f.bytes);
        mime = mimeForName(f.name);
      }
    } else {
      bytes = await ref.read(pickImageProvider)(
        camera: source == _Source.camera,
      );
    }
  } on RecordTooLarge {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.navmaas.amberSoft,
          content: Text(
            l10n.recordTooLarge,
            style: TextStyle(color: context.navmaas.onAmberSoft),
          ),
        ),
      );
    }
    return;
  }
  if (bytes == null || !context.mounted) return;
  final details = await showDialog<RecordDetailsResult>(
    context: context,
    builder: (_) => RecordDetailsDialog(
      initialCategory: appointmentId == null
          ? RecordCategory.other
          : RecordCategory.prescription,
      initialDay: visitDay ?? dateOnly(clockNow()),
    ),
  );
  final pregnancyId = ref.read(activePregnancyProvider).value?.id;
  if (details == null || pregnancyId == null || !context.mounted) return;
  // Sealing a large PDF takes a moment in pure Dart: say so.
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SavingDialog(label: l10n.recordSaving),
    ),
  );
  try {
    await repo.add(
      pregnancyId: pregnancyId,
      bytes: bytes,
      mimeType: mime,
      category: details.category,
      title: details.title,
      takenOn: details.takenOn,
      appointmentId: appointmentId,
    );
  } finally {
    navigator.pop();
  }
}

class _SavingDialog extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Semantics(header: true, child: Text(label)),
    content: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [CircularProgressIndicator()],
    ),
  );
}

/// A record's title, kind and date. Owns its text field, so it outlives the
/// closing animation.
class RecordDetailsDialog extends StatefulWidget {
  const new({
    required this.initialCategory,
    required this.initialDay,
    this.record,
    super.key,
  });

  final Attachment? record;
  final RecordCategory initialCategory;

  /// A date-only (UTC midnight) day.
  final DateTime initialDay;

  @override
  State<RecordDetailsDialog> createState() => _RecordDetailsDialogState();
}

class _RecordDetailsDialogState extends State<RecordDetailsDialog> {
  late final _title = TextEditingController(text: widget.record?.title);
  late RecordCategory _category = widget.initialCategory;
  late DateTime _day = widget.initialDay;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = localDay(clockNow());
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_day.year, _day.month, _day.day),
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) setState(() => _day = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Semantics(header: true, child: Text(l10n.recordDetails)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(80)],
              decoration: InputDecoration(labelText: l10n.recordTitleOptional),
            ),
            Text(
              l10n.recordKind,
              style: theme.textTheme.labelLarge!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in RecordCategory.values)
                  ChoiceChip(
                    label: Text(recordKindWord(l10n, c)),
                    selected: _category == c,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            OutlinedButton(
              key: const ValueKey('date-field'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _pickDay,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  children: [Text(l10n.recordDate), Text(formatDate(_day))],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<RecordDetailsResult>(context, (
            category: _category,
            title: _title.text,
            takenOn: _day,
          )),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
