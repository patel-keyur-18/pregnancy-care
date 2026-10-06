import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/third_trimester/presentation/tool_widgets.dart';
import 'package:navmaas/features/wellbeing/data/wellbeing_repository.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_widgets.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Mood check-in (prototype "Mood"): one of five words and an optional
/// note, once a day; today's can be changed until midnight.
class MoodScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  final _note = TextEditingController();
  MoodWord? _mood;
  var _touched = false;

  @override
  void initState() {
    super.initState();
    // Start from today's check-in, also when it loads after the screen.
    var ready = false;
    ref.listenManual(wellbeingWeekProvider, (_, week) {
      final saved = week.first.mood;
      if (_touched || saved == null) return;
      void seed() {
        _mood = saved.mood;
        _note.text = saved.note ?? '';
      }

      ready ? setState(seed) : seed();
    }, fireImmediately: true);
    ready = true;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final id = ref.read(activePregnancyProvider).value?.id;
    final mood = _mood;
    if (id == null || mood == null) return;
    final note = _note.text.trim();
    unawaited(
      ref
          .read(wellbeingRepositoryProvider)
          .setMood(
            pregnancyId: id,
            day: ref.read(todayProvider),
            mood: mood,
            note: note.isEmpty ? null : note,
          ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolHeader(
              title: l10n.moodTitle,
              subtitle: DateFormat('EEEE, d MMMM')
                  .format(ref.watch(todayProvider)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 14,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: NmIcon(
                                NavmaasIcon.heart,
                                color: scheme.secondary,
                              ),
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.moodQuestion,
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontFamily: 'Literata',
                                fontSize: 24,
                                height: 30 / 24,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          Semantics(
                            label: l10n.moodChoice,
                            container: true,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final m in MoodWord.values)
                                  WordChip(
                                    label: l10n.mood(m),
                                    selected: _mood == m,
                                    large: true,
                                    onTap: () => setState(() {
                                      _mood = m;
                                      _touched = true;
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _note,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.moodNoteLabel,
                      hintText: l10n.moodNoteHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.moodOnceADay,
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton(
                onPressed: _mood == null ? null : _save,
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
