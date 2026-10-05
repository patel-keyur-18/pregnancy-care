import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/care_repository.dart';
import 'package:navmaas/features/care/data/vitals_repository.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Thu, 8 Oct · 11:00 am".
String formatDateTime(DateTime t) =>
    '${formatShortDate(t)} · ${formatMinuteOfDay(t.hour * 60 + t.minute)}';

/// Icon and soft colours per kind (prototype Care: tests amber, vaccines
/// lavender, visits and scans sage).
(NavmaasIcon, Color, Color) careStyle(BuildContext context, CareKind? kind) {
  final scheme = Theme.of(context).colorScheme;
  final brand = context.navmaas;
  return switch (kind) {
    CareKind.test => (NavmaasIcon.flask, brand.amberSoft, brand.onAmberSoft),
    CareKind.vaccine => (
      NavmaasIcon.shield,
      scheme.tertiaryContainer,
      scheme.onTertiaryContainer,
    ),
    CareKind.scan => (
      NavmaasIcon.scan,
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    ),
    null => (
      NavmaasIcon.calendar,
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    ),
  };
}

/// "Booked Tue, 20 Oct · 10:00 am", "Due weeks 24–28 · not booked yet", …
String careSubtitle(AppLocalizations l10n, CareItem item, int currentWeek) {
  if (item.doneAt != null) return l10n.careDone;
  if (item.scheduledAt case final at?) {
    return l10n.careBooked(formatDateTime(at));
  }
  // Due only while the window is open; before or after it, just the weeks
  // (no nagging about a window that has passed).
  return currentWeek >= item.fromWeek && currentWeek <= item.toWeek
      ? l10n.careDueWeeks(item.fromWeek, item.toWeek)
      : l10n.careLater(item.fromWeek, item.toWeek);
}

/// A list row: icon tile, title, subtitle and an optional trailing widget.
class CareRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final NavmaasIcon icon;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              IconTile(
                background: background,
                child: NmIcon(icon, size: 20, color: foreground),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Book, re-book, clear, or mark done a test / scan / vaccine.
Future<void> showCareItemSheet(
  BuildContext context,
  WidgetRef ref,
  CareItem item, {
  String? note,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(careRepositoryProvider);
    Future<void> act(Future<void> Function() f) async {
      await f();
      if (context.mounted) Navigator.pop(context);
    }

    Future<void> book() async {
      final now = DateTime.now();
      final initial = item.scheduledAt ?? now;
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 1, 12, 31),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          item.scheduledAt ?? DateTime(2000, 1, 1, 10),
        ),
      );
      if (time == null) return;
      await act(
        () => repo.book(
          item.id,
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        ),
      );
    }

    final (icon, bg, fg) = careStyle(context, item.kind);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                IconTile(
                  background: bg,
                  child: NmIcon(icon, size: 20, color: fg),
                ),
                Expanded(
                  child: Text(item.title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (note != null)
              Text(
                note,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (item.doneAt == null) ...[
              FilledButton(
                onPressed: book,
                child: Text(
                  item.scheduledAt == null ? l10n.bookItem : l10n.changeBooking,
                ),
              ),
              if (item.scheduledAt != null)
                OutlinedButton(
                  onPressed: () => act(() => repo.book(item.id, null)),
                  child: Text(l10n.clearBooking),
                ),
            ],
            OutlinedButton(
              onPressed: () =>
                  act(() => repo.markDone(item.id, done: item.doneAt == null)),
              child: Text(
                item.doneAt == null ? l10n.markDoneItem : l10n.markNotDone,
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// Opens the dialler with the clinic's number.
Future<void> callClinic(String phone) => launchUrl(
  Uri(scheme: 'tel', path: phone.replaceAll(RegExp('[^0-9+]'), '')),
);

/// Directions to [address]: Apple Maps or Google Maps on iPhone, the maps
/// app on Android. Navmaas itself makes no network call.
Future<void> openDirections(BuildContext context, String address) async {
  final q = Uri.encodeQueryComponent(address);
  if (!Platform.isIOS) {
    await launchUrl(Uri.parse('geo:0,0?q=$q'));
    return;
  }
  final google = Uri.parse('comgooglemaps://?q=$q');
  final hasGoogle = await canLaunchUrl(google);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const NmIcon(NavmaasIcon.pin),
            title: Text(l10n.appleMaps),
            onTap: () {
              Navigator.pop(context);
              unawaited(launchUrl(Uri.parse('maps://?q=$q')));
            },
          ),
          if (hasGoogle)
            ListTile(
              leading: const NmIcon(NavmaasIcon.pin),
              title: Text(l10n.googleMaps),
              onTap: () {
                Navigator.pop(context);
                unawaited(launchUrl(google));
              },
            ),
        ],
      ),
    ),
  );
}

/// Logs a weight (kg) or blood pressure (systolic / diastolic).
Future<void> logVital(
  BuildContext context,
  WidgetRef ref,
  VitalKind kind,
) async {
  final values = await showDialog<(double, double?)>(
    context: context,
    builder: (_) => _VitalDialog(kind: kind),
  );
  final pregnancy = ref.read(activePregnancyProvider).value;
  if (values == null || pregnancy == null) return;
  await ref
      .read(vitalsRepositoryProvider)
      .add(
        pregnancyId: pregnancy.id,
        kind: kind,
        value1: values.$1,
        value2: values.$2,
      );
}

/// Owns its text fields, so they outlive the dialog's closing animation.
class _VitalDialog extends StatefulWidget {
  const new({required this.kind});

  final VitalKind kind;

  @override
  State<_VitalDialog> createState() => _VitalDialogState();
}

class _VitalDialogState extends State<_VitalDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _save() {
    final v1 = double.tryParse(_a.text);
    final v2 = double.tryParse(_b.text);
    final bp = widget.kind == VitalKind.bloodPressure;
    if (v1 == null || (bp && v2 == null)) return;
    Navigator.pop(context, (v1, bp ? v2 : null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bp = widget.kind == VitalKind.bloodPressure;
    final numberOnly = [
      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
      LengthLimitingTextInputFormatter(5),
    ];
    return AlertDialog(
      title: Text(bp ? l10n.logBp : l10n.logWeight),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(
              controller: _a,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numberOnly,
              decoration: InputDecoration(
                labelText: bp ? l10n.systolicLabel : l10n.weightLabel,
              ),
            ),
            if (bp)
              TextField(
                controller: _b,
                keyboardType: TextInputType.number,
                inputFormatters: numberOnly,
                decoration: InputDecoration(labelText: l10n.diastolicLabel),
              ),
            Text(l10n.vitalsNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

/// A text dialog that returns the edited text, or null. Multi-line unless
/// [singleLine].
class TextEntryDialog extends StatefulWidget {
  const new({
    required this.title,
    this.initial,
    this.singleLine = false,
    super.key,
  });

  final String title;
  final String? initial;
  final bool singleLine;

  @override
  State<TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<TextEntryDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: widget.singleLine ? 1 : 6,
        minLines: widget.singleLine ? 1 : 3,
        inputFormatters: [
          LengthLimitingTextInputFormatter(widget.singleLine ? 120 : 2000),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _c.text),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
