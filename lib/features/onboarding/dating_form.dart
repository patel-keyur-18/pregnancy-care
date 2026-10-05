import 'package:flutter/material.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/pregnancy/pregnancy_engine.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/core/widgets/step_button.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// What the user has entered so far; [date] stays null until picked.
@immutable
class DatingInput {
  const new({
    this.method = DatingMethod.lmp,
    this.date,
    this.cycleLength = 28,
    this.embryoDay = 5,
  });

  factory fromPregnancy(Pregnancy p) => DatingInput(
    method: p.datingMethod,
    date: p.lmp ?? p.anchorDate,
    cycleLength: p.cycleLength ?? 28,
    embryoDay: p.embryoDay ?? 5,
  );

  final DatingMethod method;
  final DateTime? date;
  final int cycleLength;
  final int embryoDay;

  DateTime? get start => date == null
      ? null
      : pregnancyStart(
          method: method,
          date: date!,
          cycleLength: cycleLength,
          embryoDay: embryoDay,
        );

  /// A date picked and inside a plausible pregnancy on [today].
  bool isValidOn(DateTime today) =>
      start != null &&
      !PregnancySnapshot.of(start: start!, today: today).needsReview;

  DatingInput copyWith({DateTime? date, int? cycleLength, int? embryoDay}) =>
      DatingInput(
        method: method,
        date: date ?? this.date,
        cycleLength: cycleLength ?? this.cycleLength,
        embryoDay: embryoDay ?? this.embryoDay,
      );

  /// A different method means a different kind of date, so it starts empty.
  DatingInput withMethod(DatingMethod m) => m == method
      ? this
      : DatingInput(method: m, cycleLength: cycleLength, embryoDay: embryoDay);
}

/// Dating method, date and cycle length / embryo day (onboarding step 2 and
/// "Edit pregnancy dates").
class DatingForm extends StatelessWidget {
  const new({
    required this.value,
    required this.today,
    required this.onChanged,
    super.key,
  });

  final DatingInput value;
  final DateTime today;
  final ValueChanged<DatingInput> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    Widget option(DatingMethod m, String title, String sub) => _MethodCard(
      title: title,
      subtitle: sub,
      selected: value.method == m,
      onTap: () => onChanged(value.withMethod(m)),
    );

    final (fieldLabel, first, last) = switch (value.method) {
      .lmp => (l10n.fieldLmp, addDays(today, -300), today),
      .conception => (l10n.fieldConception, addDays(today, -300), today),
      .ivf => (l10n.fieldIvf, addDays(today, -300), today),
      .scan => (l10n.fieldScan, addDays(today, -28), addDays(today, 300)),
    };

    Future<void> pickDate() async {
      DateTime local(DateTime d) => DateTime(d.year, d.month, d.day);
      final initial =
          value.date ?? (value.method == .scan ? addDays(today, 140) : today);
      final picked = await showDatePicker(
        context: context,
        initialDate: local(initial),
        firstDate: local(first),
        lastDate: local(last),
        helpText: fieldLabel,
      );
      if (picked != null) onChanged(value.copyWith(date: dateOnly(picked)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            spacing: 10,
            children: [
              _pair(
                option(.lmp, l10n.methodLmp, l10n.methodLmpSub),
                option(
                  .conception,
                  l10n.methodConception,
                  l10n.methodConceptionSub,
                ),
              ),
              _pair(
                option(.ivf, l10n.methodIvf, l10n.methodIvfSub),
                option(.scan, l10n.methodScan, l10n.methodScanSub),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  fieldLabel,
                  style: text.bodySmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Material(
                  color: scheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('date-field'),
                    onTap: pickDate,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: Text(
                                value.date == null
                                    ? l10n.pickDate
                                    : formatDate(value.date!),
                                style: text.bodyLarge!.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: value.date == null
                                      ? scheme.outline
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            NmIcon(
                              NavmaasIcon.calendar,
                              size: 22,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (value.method == .ivf) ...[
                  Text(
                    l10n.embryoDayLabel,
                    style: text.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  PillSegmented<int>(
                    segments: [
                      for (final day in [3, 5])
                        (value: day, label: l10n.embryoDay(day), caption: null),
                    ],
                    selected: value.embryoDay,
                    onChanged: (day) =>
                        onChanged(value.copyWith(embryoDay: day)),
                  ),
                ],
                if (value.method == .lmp)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Text(
                        l10n.cycleLength,
                        style: text.bodyLarge!.copyWith(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          StepButton(
                            symbol: '−',
                            tooltip: l10n.cycleShorter,
                            onPressed: value.cycleLength > minCycleLength
                                ? () => onChanged(
                                    value.copyWith(
                                      cycleLength: value.cycleLength - 1,
                                    ),
                                  )
                                : null,
                          ),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 60),
                              child: Text(
                                l10n.cycleDays(value.cycleLength),
                                textAlign: TextAlign.center,
                                style: text.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          StepButton(
                            symbol: '+',
                            tooltip: l10n.cycleLonger,
                            onPressed: value.cycleLength < maxCycleLength
                                ? () => onChanged(
                                    value.copyWith(
                                      cycleLength: value.cycleLength + 1,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _pair(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Expanded(child: a),
        Expanded(child: b),
      ],
    ),
  );
}

class _MethodCard extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "That means today you are 24 weeks 5 days · Month 6 · …" (sage), or a
/// gentle amber note when the dates look outside a typical pregnancy.
class DatingResultCard extends StatelessWidget {
  const new({required this.start, required this.today, super.key});

  final DateTime start;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = PregnancySnapshot.of(start: start, today: today);

    if (s.needsReview) {
      final brand = context.navmaas;
      return _panel(
        color: brand.amberSoft,
        children: [
          Text(
            l10n.datesNeedReview,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: brand.onAmberSoft,
            ),
          ),
        ],
      );
    }

    final on = scheme.onPrimaryContainer;
    final detail = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w600,
      color: on,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: _panel(
        color: scheme.primaryContainer,
        children: [
          Text(
            l10n.resultLead,
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: on,
            ),
          ),
          Text(
            l10n.weeksDays(s.weeks, s.days),
            style: theme.textTheme.headlineSmall!.copyWith(
              fontSize: 24,
              height: 30 / 24,
              color: on,
            ),
          ),
          Text(l10n.monthTrimester(s.month, s.trimester), style: detail),
          Text(l10n.dueOn(formatDate(s.dueDate)), style: detail),
        ],
      ),
    );
  }

  static Widget _panel({
    required Color color,
    required List<Widget> children,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: children,
      ),
    ),
  );
}
