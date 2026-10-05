import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/onboarding/dating_form.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Re-dates the active pregnancy; saving re-runs the engine.
class EditDatesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<EditDatesScreen> createState() => _EditDatesScreenState();
}

class _EditDatesScreenState extends ConsumerState<EditDatesScreen> {
  DatingInput? _dating;
  var _saving = false;

  Future<void> _save(DatingInput d) async {
    setState(() => _saving = true);
    await ref
        .read(pregnancyRepositoryProvider)
        .saveDating(
          method: d.method,
          date: d.date!,
          cycleLength: d.cycleLength,
          embryoDay: d.embryoDay,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final pregnancy = ref.watch(activePregnancyProvider).value;
    final dating =
        _dating ??
        (pregnancy == null
            ? const DatingInput()
            : DatingInput.fromPregnancy(pregnancy));
    final start = dating.start;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editDates)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  8,
                  AppTheme.gutter,
                  20,
                ),
                children: [
                  DatingForm(
                    value: dating,
                    today: today,
                    onChanged: (v) => setState(() => _dating = v),
                  ),
                  if (start != null) ...[
                    const SizedBox(height: 20),
                    DatingResultCard(start: start, today: today),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                8,
                AppTheme.gutter,
                16,
              ),
              child: FilledButton(
                onPressed: !_saving && dating.isValidOn(today)
                    ? () => _save(dating)
                    : null,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
