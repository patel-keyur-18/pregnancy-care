import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Me, M1 subset: profile + pregnancy dates, appearance, disclaimer.
class MeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final name = ref.watch(firstNameProvider).value;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final on = scheme.onPrimaryContainer;

    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.labelLarge!.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          24,
          AppTheme.gutter,
          24,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.meTitle, style: text.headlineSmall),
          ),
          const SizedBox(height: 18),
          if (pregnancy != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  spacing: 14,
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.primary,
                        child: Text(
                          (name ?? l10n.meNoName).characters.first
                              .toUpperCase(),
                          style: text.titleMedium!.copyWith(
                            fontSize: 20,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? l10n.meNoName,
                            style: text.titleMedium!.copyWith(
                              fontSize: 17,
                              color: on,
                            ),
                          ),
                          Text(
                            l10n.dueOn(formatDate(pregnancy.dueDate)),
                            style: text.bodyMedium!.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: on,
                            ),
                          ),
                          Text(
                            l10n.datedBy(pregnancy.datingMethod.name),
                            style: text.bodyMedium!.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: on,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurface,
                        minimumSize: const Size(64, 48),
                        textStyle: text.labelLarge,
                      ),
                      onPressed: () => context.go('/me/edit'),
                      child: Text(
                        l10n.editButton,
                        semanticsLabel: l10n.editDetailsLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          section(
            l10n.appearance,
            PillSegmented<ThemeMode>(
              segments: [
                (value: ThemeMode.light, label: l10n.themeLight, caption: null),
                (value: ThemeMode.dark, label: l10n.themeDark, caption: null),
                (
                  value: ThemeMode.system,
                  label: l10n.themeSystem,
                  caption: null,
                ),
              ],
              selected: mode,
              onChanged: (m) => setThemeMode(ref, m),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.disclaimer,
            style: text.bodySmall!.copyWith(
              fontSize: 12,
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
