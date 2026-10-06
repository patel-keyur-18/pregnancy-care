import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/domain/fold.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Symptom log (prototype "Symptoms"): pick a common discomfort or add her
/// own, how strong in words, and a note. A log for her and her doctor:
/// never advice, never a warning list (Plan decision 39).
class SymptomsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  final _own = TextEditingController();
  final _note = TextEditingController();

  /// A [SymptomKind], or the name of one of her own from before.
  Object? _pick;
  var _ownOpen = false;
  var _showAll = false;
  Severity _severity = .mild;

  @override
  void initState() {
    super.initState();
    _own.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _own.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _ownOpen ? _own.text.trim().isNotEmpty : _pick != null;

  void _save() {
    final id = ref.read(activePregnancyProvider).value?.id;
    if (id == null || !_canSave) return;
    final pick = _pick;
    final note = _note.text.trim();
    unawaited(
      ref
          .read(wellbeingRepositoryProvider)
          .addSymptom(
            pregnancyId: id,
            kind: _ownOpen ? null : pick as SymptomKind?,
            customName: _ownOpen
                ? _own.text.trim()
                : (pick is String ? pick : null),
            severity: _severity,
            note: note.isEmpty ? null : note,
          ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recent = ref.watch(recentSymptomsProvider).value ?? const [];
    final today = ref.watch(wellbeingWeekProvider).first.symptoms;

    // Her recent ones first (her own names too), then the rest in order.
    final choices = <Object>{
      for (final e in recent) e.symptomKey ?? e.customName!,
      ...SymptomKind.values,
    }.toList();
    String name(Object c) => c is SymptomKind ? l10n.symptom(c) : c as String;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(
              title: l10n.symptomsTitle,
              subtitle: l10n.symptomsSubtitle,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SectionTitle(l10n.symptomsWhat),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _ownOpen = !_ownOpen;
                          if (_ownOpen) _pick = null;
                        }),
                        icon: const NmIcon(
                          NavmaasIcon.plus,
                          size: 14,
                          strokeWidth: 2.4,
                        ),
                        label: Text(l10n.symptomAddOwn),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, box) =>
                        _chips(context, choices, name, box.maxWidth),
                  ),
                  if (_ownOpen) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _own,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.symptomOwnLabel,
                        hintText: l10n.symptomOwnHint,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SectionTitle(l10n.symptomsHowStrong),
                  const SizedBox(height: 10),
                  PillSegmented<Severity>(
                    segments: [
                      for (final s in Severity.values)
                        (value: s, label: l10n.severity(s), caption: null),
                    ],
                    selected: _severity,
                    onChanged: (s) => setState(() => _severity = s),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.noteOptional,
                      hintText: l10n.symptomNoteHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (today.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionTitle(l10n.symptomsLoggedToday, small: true),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, e) in today.reversed.indexed) ...[
                            if (i > 0) const Divider(height: 1),
                            _LoggedRow(e),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The chips, folded to what fits in two rows (with "More · N") until she
  /// asks for all. The one she picked always shows.
  Widget _chips(
    BuildContext context,
    List<Object> choices,
    String Function(Object) name,
    double maxWidth,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );
    double width(String label, {double extra = 0}) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      // Padding 14 + 14, border 1.5 + 1.5, a pixel to spare.
      final w = painter.width + 32 + extra;
      painter.dispose();
      return w;
    }

    final tick = scaler.scale(14) + 6;
    final widths = [
      for (final c in choices) width(name(c), extra: c == _pick ? tick : 0),
    ];
    final fit = chipsThatFit(
      widths,
      moreWidth: width(l10n.symptomMore(choices.length), extra: 24),
      maxWidth: maxWidth,
    );
    var shown = choices;
    if (!_showAll && fit < choices.length) {
      shown = choices.take(fit).toList();
      final pick = _pick;
      if (pick != null && !shown.contains(pick)) {
        shown = [...shown.take(fit - 1), pick];
      }
    }
    final folded = fit < choices.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in shown)
          WordChip(
            label: name(c),
            selected: !_ownOpen && _pick == c,
            onTap: () => setState(() {
              _pick = c;
              _ownOpen = false;
            }),
          ),
        if (folded)
          _MoreChip(
            label: _showAll
                ? l10n.symptomFewer
                : l10n.symptomMore(choices.length - shown.length),
            expanded: _showAll,
            onTap: () => setState(() => _showAll = !_showAll),
          ),
      ],
    );
  }
}

/// The dashed "More · N" / "Fewer" chip.
class _MoreChip extends StatelessWidget {
  const new({required this.label, required this.expanded, required this.onTap});

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      expanded: expanded,
      child: CustomPaint(
        painter: _DashedStadium(scheme.outlineVariant),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: expanded ? 3 : 1,
                      child: NmIcon(
                        NavmaasIcon.chevronRight,
                        size: 16,
                        strokeWidth: 2.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1.5 px dashed stadium outline (the prototype's dashed chip).
class _DashedStadium extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.75);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadium old) => old.color != color;
}

/// A symptom logged today: name · strength, time, note, and remove.
class _LoggedRow extends ConsumerWidget {
  const new(this.entry);

  final SymptomEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = l10n.symptomName(entry);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      Text(
                        l10n.symptomWithSeverity(
                          name,
                          l10n.severity(entry.severity),
                        ),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        formatTime(entry.loggedAt.toLocal()),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (entry.note != null)
                    Text(
                      entry.note!,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.symptomRemove(name),
            onPressed: () => unawaited(
              ref.read(wellbeingRepositoryProvider).removeSymptom(entry.id),
            ),
            icon: NmIcon(
              NavmaasIcon.close,
              size: 18,
              strokeWidth: 2,
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
