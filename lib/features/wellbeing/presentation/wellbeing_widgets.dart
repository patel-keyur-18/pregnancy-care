import 'package:flutter/material.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The words for the keys the database stores (Plan decision 43).
extension WellbeingWords on AppLocalizations {
  String mood(MoodWord m) => switch (m) {
    .calm => moodWordCalm,
    .happy => moodWordHappy,
    .okay => moodWordOkay,
    .tired => moodWordTired,
    .low => moodWordLow,
  };

  String symptom(SymptomKind k) => switch (k) {
    .nausea => symptomPickNausea,
    .heartburn => symptomPickHeartburn,
    .backache => symptomPickBackache,
    .swollenFeet => symptomPickSwollenFeet,
    .headache => symptomPickHeadache,
    .legCramps => symptomPickLegCramps,
    .constipation => symptomPickConstipation,
    .tiredness => symptomPickTiredness,
    .troubleSleeping => symptomPickTroubleSleeping,
    .bloating => symptomPickBloating,
  };

  String severity(Severity s) => switch (s) {
    .mild => severityMild,
    .moderate => severityModerate,
    .strong => severityStrong,
  };

  String rested(Rested r) => switch (r) {
    .rested => restedWordRested,
    .bitTired => restedWordBitTired,
    .veryTired => restedWordVeryTired,
  };

  /// A logged symptom's name: the pick-list word or her own.
  String symptomName(SymptomEntry e) => e.customName ?? symptom(e.symptomKey!);

  /// "7 h 45 min".
  String duration(int minutes) => hoursMinutes(minutes ~/ 60, minutes % 60);
}

/// A choice chip as drawn in the M7 screens: surface with a border, or
/// filled with the primary colour and a tick when chosen (a selection,
/// never a judgement). At least 48 dp tall.
class WordChip extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Mood and rested words are 16 px; symptom chips 14 px.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            width: 1.5,
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 18 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (selected)
                    NmIcon(
                      NavmaasIcon.check,
                      size: large ? 16 : 14,
                      strokeWidth: 3,
                      color: fg,
                    ),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: large ? 16 : 14,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
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

/// The 40 px rounded icon square used on Wellbeing tiles and rows.
class IconSquare extends StatelessWidget {
  const new(
    this.icon, {
    required this.background,
    required this.foreground,
    this.radius = 14,
    super.key,
  });

  final NavmaasIcon icon;
  final Color background;
  final Color foreground;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: NmIcon(icon, size: 20, color: foreground),
    ),
  );
}

/// Section heading (18 px, a header for screen readers).
class SectionTitle extends StatelessWidget {
  const new(this.text, {this.small = false, super.key});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium!;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: small ? style.copyWith(fontSize: 16, height: 22 / 16) : style,
      ),
    );
  }
}
