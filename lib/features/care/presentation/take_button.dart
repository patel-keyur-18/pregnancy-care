import 'package:flutter/material.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// The prototype's "Take" / "Taken" pill (48 dp tall; the prototype draws 40).
class TakeButton extends StatelessWidget {
  const new({
    required this.name,
    required this.taken,
    required this.onPressed,
    super.key,
  });

  final String name;
  final bool taken;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      // Its own node: Cards merge their children otherwise.
      container: true,
      button: true,
      toggled: taken,
      label: taken ? l10n.takenName(name) : l10n.markTaken(name),
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: taken ? scheme.primary : scheme.surface,
          foregroundColor: taken ? scheme.onPrimary : scheme.onSurface,
          side: BorderSide(
            color: taken ? scheme.primary : scheme.outlineVariant,
            width: 1.5,
          ),
          textStyle: theme.textTheme.labelLarge,
        ),
        child: Text(taken ? l10n.taken : l10n.take),
      ),
    );
  }
}

/// 40 dp rounded tile with a soft background behind an icon (list rows).
class IconTile extends StatelessWidget {
  const new({
    required this.child,
    required this.background,
    this.size = 40,
    super.key,
  });

  final Widget child;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: child,
  );
}
