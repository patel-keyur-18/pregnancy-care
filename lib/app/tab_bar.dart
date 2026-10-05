import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/widgets/motion.dart';

typedef NavmaasTab = ({NavmaasIcon icon, String label});

/// The prototype's tab bar (DESIGN_SYSTEM §6): 84 dp on `surface` with a top
/// border; the active tab sits on a 56 × 30 sage pill and its icon draws
/// itself in (§5).
class NavmaasTabBar extends StatelessWidget {
  const new({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavmaasTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 18),
        // Labels stop growing at 1.5× so five tabs still fit; the screens
        // themselves follow the full text size.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                for (final (i, tab) in tabs.indexed)
                  Expanded(
                    child: _Tab(
                      tab: tab,
                      active: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({required this.tab, required this.active, required this.onTap});

  final NavmaasTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = active ? scheme.onPrimaryContainer : scheme.outline;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: active,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: PressScale(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 2,
              children: [
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: active
                        ? scheme.primaryContainer
                        : scheme.primaryContainer.withValues(alpha: 0),
                    shape: const StadiumBorder(),
                  ),
                  child: DrawOnIcon(
                    tab.icon,
                    active: active,
                    size: 22,
                    color: fg,
                  ),
                ),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall!.copyWith(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
