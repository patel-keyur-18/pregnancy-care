import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/features/care/data/supplement_repository.dart';
import 'package:navmaas/features/care/domain/dose_slots.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

class _TimeRow {
  new({required this.minute, this.id, String? label})
    : label = TextEditingController(text: label);

  final String? id;
  int minute;
  final TextEditingController label;
}

/// Adds or edits a supplement exactly as prescribed. The quick-pick only
/// fills in a common name; the app never suggests a dose (Plan decision 5).
class EditSupplementScreen extends ConsumerStatefulWidget {
  const new({this.supplementId, super.key});

  /// Null to add a new one.
  final String? supplementId;

  @override
  ConsumerState<EditSupplementScreen> createState() =>
      _EditSupplementScreenState();
}

class _EditSupplementScreenState extends ConsumerState<EditSupplementScreen> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _notes = TextEditingController();
  final _stock = TextEditingController();
  final _refill = TextEditingController();
  final _times = <_TimeRow>[_TimeRow(minute: 9 * 60)];
  var _days = 0x7F;
  var _loaded = false;
  var _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _dose, _notes, _stock, _refill]) {
      c.dispose();
    }
    for (final t in _times) {
      t.label.dispose();
    }
    super.dispose();
  }

  /// Fills the form once from the saved supplement when editing.
  void _load(List<SupplementPlan> plans) {
    if (_loaded) return;
    _loaded = true;
    final plan = plans
        .where((p) => p.supplement.id == widget.supplementId)
        .firstOrNull;
    if (plan == null) return;
    final s = plan.supplement;
    _name.text = s.name;
    _dose.text = s.doseText;
    _notes.text = s.notes ?? '';
    _stock.text = s.stock?.toString() ?? '';
    _refill.text = s.refillAt?.toString() ?? '';
    if (plan.schedules.isNotEmpty) {
      _times
        ..clear()
        ..addAll([
          for (final t in plan.schedules)
            _TimeRow(id: t.id, minute: t.minuteOfDay, label: t.label),
        ]);
      _days = plan.schedules.first.weekdayMask;
    }
  }

  Future<void> _save(String pregnancyId) async {
    setState(() => _saving = true);
    await ref
        .read(supplementRepositoryProvider)
        .save(
          id: widget.supplementId,
          pregnancyId: pregnancyId,
          name: _name.text,
          doseText: _dose.text,
          notes: _notes.text,
          stock: int.tryParse(_stock.text),
          refillAt: int.tryParse(_refill.text),
          times: [
            for (final t in _times)
              (
                id: t.id,
                minuteOfDay: t.minute,
                weekdayMask: _days,
                label: t.label.text,
              ),
          ],
        );
    if (mounted) context.pop();
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeSupplement),
        content: Text(l10n.removeSupplementNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.backButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeSupplement),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(supplementRepositoryProvider).remove(widget.supplementId!);
    if (mounted) context.pop();
  }

  Future<void> _pickTime(_TimeRow row) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: row.minute ~/ 60, minute: row.minute % 60),
    );
    if (picked != null) {
      setState(() => row.minute = picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final plans = ref.watch(supplementPlansProvider).value;
    if (widget.supplementId != null && plans != null) _load(plans);
    final canSave =
        !_saving &&
        pregnancy != null &&
        _name.text.trim().isNotEmpty &&
        _days != 0;

    Widget label(String s, {bool optional = false}) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        optional ? '$s · ${l10n.optional}' : s,
        style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final common = [
      l10n.supplementFolic,
      l10n.supplementIronFolic,
      l10n.supplementCalciumD,
      l10n.supplementD3,
      l10n.supplementB12,
      l10n.supplementDha,
      l10n.supplementMulti,
    ];
    final monday = DateTime(2024); // 1 Jan 2024 was a Monday.

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.supplementId == null
              ? l10n.addSupplementTitle
              : l10n.editSupplementTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  0,
                  AppTheme.gutter,
                  24,
                ),
                children: [
                  label(l10n.commonSupplements),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in common)
                        ChoiceChip(
                          label: Text(name),
                          selected: _name.text == name,
                          showCheckmark: false,
                          shape: const StadiumBorder(),
                          onSelected: (_) => setState(() => _name.text = name),
                        ),
                    ],
                  ),
                  label(l10n.supplementName),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    decoration: InputDecoration(
                      hintText: l10n.supplementNameHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  label(l10n.doseLabel, optional: true),
                  TextField(
                    controller: _dose,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    decoration: InputDecoration(hintText: l10n.doseHint),
                  ),
                  label(l10n.timesLabel),
                  for (final row in _times)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _pickTime(row),
                            child: Text(formatMinuteOfDay(row.minute)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: row.label,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(40),
                              ],
                              decoration: InputDecoration(
                                hintText: l10n.timeLabelHint,
                              ),
                            ),
                          ),
                          if (_times.length > 1)
                            IconButton(
                              tooltip: l10n.removeTime,
                              onPressed: () => setState(() {
                                _times.remove(row);
                                row.label.dispose();
                              }),
                              icon: NmIcon(
                                NavmaasIcon.close,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => _times.add(
                          _TimeRow(
                            minute: (_times.last.minute + 4 * 60) % 1440,
                          ),
                        ),
                      ),
                      icon: NmIcon(
                        NavmaasIcon.plus,
                        size: 18,
                        strokeWidth: 2.2,
                        color: scheme.primary,
                      ),
                      label: Text(l10n.addTime),
                    ),
                  ),
                  label(l10n.daysLabel),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: _DayToggle(
                            letter: DateFormat('EEEEE')
                                .format(monday.add(Duration(days: i))),
                            name: DateFormat('EEEE')
                                .format(monday.add(Duration(days: i))),
                            on: _days & (1 << i) != 0,
                            onTap: () => setState(() => _days ^= 1 << i),
                          ),
                        ),
                    ],
                  ),
                  label(l10n.notesLabel, optional: true),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    minLines: 1,
                    inputFormatters: [LengthLimitingTextInputFormatter(200)],
                    decoration: InputDecoration(hintText: l10n.notesHint),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            label(l10n.stockLabel, optional: true),
                            TextField(
                              controller: _stock,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            label(l10n.refillLabel, optional: true),
                            TextField(
                              controller: _refill,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.supplementId != null) ...[
                    const SizedBox(height: 28),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.removeSupplementNote,
                          style: text.bodySmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: _remove,
                      child: Text(l10n.removeSupplement),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                8,
                AppTheme.gutter,
                16,
              ),
              child: FilledButton(
                onPressed: canSave ? () => _save(pregnancy.id) : null,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const new({
    required this.letter,
    required this.name,
    required this.on,
    required this.onTap,
  });

  final String letter;
  final String name;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      // Its own node: Cards merge their children otherwise.
      container: true,
      label: name,
      toggled: on,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? scheme.primary : Colors.transparent,
                border: Border.all(
                  color: on ? scheme.primary : scheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Text(
                letter,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: on ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
