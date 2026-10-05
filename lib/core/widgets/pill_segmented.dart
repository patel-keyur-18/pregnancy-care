import 'package:flutter/material.dart';

/// One choice in a `PillSegmented`; `caption` is an optional second line.
typedef PillSegment<T> = ({T value, String label, String? caption});

/// The prototype's segmented control (DESIGN_SYSTEM §6): a `surface-2` pill
/// track; the selected segment is `surface` with a soft shadow in light mode.
/// Segments are 48 dp tall (the prototype draws 40–44).
class PillSegmented<T> extends StatelessWidget {
  const new({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<PillSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              for (final s in segments)
                Expanded(
                  child: _Segment(
                    segment: s,
                    selected: s.value == selected,
                    shadow: light,
                    onTap: () => onChanged(s.value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const new({
    required this.segment,
    required this.selected,
    required this.shadow,
    required this.onTap,
  });

  final PillSegment<T> segment;
  final bool selected;
  final bool shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          shape: const StadiumBorder(),
          shadows: selected && shadow
              ? const [
                  BoxShadow(
                    color: Color(0x0D3C281E),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Color(0x0D3C281E),
                    offset: Offset(0, 6),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      segment.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge!.copyWith(color: fg),
                    ),
                    if (segment.caption != null)
                      Text(
                        segment.caption!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall!.copyWith(
                          fontSize: 12,
                          height: 14 / 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
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
