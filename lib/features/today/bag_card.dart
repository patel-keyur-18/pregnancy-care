import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/birth_prep/data/bag_repository.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/care/presentation/tests_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Today's Hospital bag card, from week 32 like Care's Getting ready: how
/// much is packed, one tap to the bag. It stays once everything is packed
/// (owner, 2026-10-10).
class BagCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentWeek(ref) < gettingReadyFromWeek) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.navmaas;
    final bag = ref.watch(bagProvider).value ?? const [];
    // Still loading (or no template): nothing rather than "0 of 0 packed".
    if (bag.isEmpty) return const SizedBox.shrink();
    final packed = bag.where((r) => r.packed).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/care/bag'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 14,
              children: [
                IconTile(
                  size: 44,
                  background: brand.amberSoft,
                  child: NmIcon(
                    NavmaasIcon.bag,
                    size: 22,
                    color: brand.onAmberSoft,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bagTitle,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        packed == bag.length
                            ? l10n.bagAllPacked
                            : l10n.bagPacked(packed, bag.length),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                NmIcon(
                  NavmaasIcon.chevronRight,
                  size: 20,
                  strokeWidth: 2,
                  color: scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
