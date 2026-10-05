import 'package:flutter/material.dart';
import 'package:navmaas/core/widgets/motion.dart';

/// Round "−" / "+" button from the prototype's steppers (48 dp).
class StepButton extends StatelessWidget {
  const new({
    required this.symbol,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String symbol;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: PressScale(
          child: Material(
            color: scheme.surface,
            shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Text(
                    symbol,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 20,
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
