import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "Screen off" (Listen, Meditation): near-black, so the screen rests and the
/// phone may lock as usual; a tap anywhere wakes it.
class ScreenOff extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.line,
    required this.onWake,
    super.key,
  });

  final NavmaasIcon icon;
  final String title;
  final String line;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    final brand = context.navmaas;
    final style = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontWeight: FontWeight.w600, color: brand.sleepText);
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).wakeScreen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onWake,
        child: ColoredBox(
          color: brand.sleep,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  NmIcon(
                    icon,
                    size: 28,
                    strokeWidth: 1.6,
                    color: brand.sleepText,
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: style.copyWith(fontSize: 15),
                  ),
                  Text(line, textAlign: TextAlign.center, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
