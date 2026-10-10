import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/birth_prep/data/birth_plan_repository.dart';
import 'package:navmaas/features/care/presentation/care_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care → Birth plan (M8a): original prompts she answers in her own words,
/// under "Talk this through with your doctor". The prompts suggest no
/// medical choice.
class BirthPlanScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prompts =
        ref.watch(birthPlanPromptsProvider).value ?? const <BirthPlanPrompt>[];
    final answers = ref.watch(birthPlanAnswersProvider).value ?? const {};
    Future<void> edit(BirthPlanPrompt p) async {
      final text = await showDialog<String>(
        context: context,
        builder: (_) =>
            TextEntryDialog(title: p.title, initial: answers[p.key]),
      );
      final pregnancy = ref.read(activePregnancyProvider).value;
      if (text == null || pregnancy == null) return;
      await ref
          .read(birthPlanRepositoryProvider)
          .save(pregnancyId: pregnancy.id, promptKey: p.key, answer: text);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.birthPlanTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          28,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 12,
                children: [
                  NmIcon(
                    NavmaasIcon.birthPlan,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                  Expanded(
                    child: Text(
                      l10n.birthPlanDoctorLine,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final p in prompts)
            Card(
              margin: const EdgeInsets.only(top: 12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => edit(p),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Text(
                        p.title,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        p.hint,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (answers[p.key] case final answer?)
                        Text(
                          answer,
                          style: AppTheme.reading.copyWith(
                            fontSize: 16,
                            height: 24 / 16,
                            color: scheme.onSurface,
                          ),
                        )
                      else
                        Text(
                          l10n.birthPlanAddThoughts,
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
