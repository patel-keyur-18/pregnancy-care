import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/reminder_settings.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/birth_prep/data/bag_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

String bagSectionWord(AppLocalizations l10n, BagSection s) => switch (s) {
  BagSection.forMe => l10n.bagForMe,
  BagSection.forBaby => l10n.bagForBaby,
  BagSection.documents => l10n.bagDocuments,
};

/// Care → Hospital bag (M8a): the original template with her ticks, her own
/// items, and one optional "Pack the hospital bag" reminder.
class BagScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = ref.watch(bagProvider).value ?? const <BagRow>[];
    final packed = rows.where((r) => r.packed).length;
    final pregnancyId = ref.watch(activePregnancyProvider).value?.id;
    final repo = ref.read(bagRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bagTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          28,
        ),
        children: [
          Text(
            l10n.bagPacked(packed, rows.length),
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 16),
          const _ReminderCard(),
          for (final section in BagSection.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Semantics(
                header: true,
                child: Text(
                  bagSectionWord(l10n, section),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              semanticContainer: false,
              child: Column(
                children: [
                  for (final (i, r)
                      in rows.where((r) => r.section == section).indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: r.packed,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              r.label,
                              style: r.packed
                                  ? TextStyle(color: scheme.outline)
                                  : null,
                            ),
                            onChanged: pregnancyId == null
                                ? null
                                : (on) => repo.setPacked(
                                    pregnancyId: pregnancyId,
                                    row: r,
                                    packed: on ?? false,
                                  ),
                          ),
                        ),
                        if (r.templateKey == null)
                          IconButton(
                            tooltip: l10n.bagRemoveItem(r.label),
                            onPressed: () => repo.deleteOwn(r.id!),
                            icon: NmIcon(
                              NavmaasIcon.close,
                              size: 18,
                              color: scheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: pregnancyId == null
                ? null
                : () async {
                    final add = await showDialog<_OwnItem>(
                      context: context,
                      builder: (_) => const _AddOwnDialog(),
                    );
                    if (add == null) return;
                    await repo.addOwn(
                      pregnancyId: pregnancyId,
                      label: add.label,
                      section: add.section,
                    );
                  },
            child: Text(l10n.bagAddOwn),
          ),
        ],
      ),
    );
  }
}

/// "Remind me to pack": one date and time she picks, or none.
class _ReminderCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reminders = ref.watch(reminderSettingsProvider).value;
    // A time that has passed rings no more: show it as none.
    final at = switch (reminders?.bagAt) {
      final t? when t.isAfter(clockNow()) => t,
      _ => null,
    };
    final off = reminders != null && !reminders.on;
    final settings = ref.read(settingsRepositoryProvider);
    Future<void> pick() async {
      final now = clockNow();
      final initial = at ?? now;
      final date = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(now) ? now : initial,
        firstDate: now,
        lastDate: DateTime(now.year + 1, 12, 31),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(at ?? DateTime(2000, 1, 1, 10)),
      );
      if (time == null || !context.mounted) return;
      final chosen = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (!chosen.isAfter(clockNow())) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.bagRemindPast)));
        return;
      }
      await settings.put(SettingKeys.bagRemindAt, chosen.toIso8601String());
      if (!off || !context.mounted) return;
      // She asked for a reminder: offer to turn reminders on.
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Semantics(header: true, child: Text(l10n.offerRemindersTitle)),
          content: Text(l10n.bagRemindOfferBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.turnOnReminders),
            ),
          ],
        ),
      );
      if (yes == true &&
          await ref.read(reminderSchedulerProvider).requestPermission()) {
        await settings.put(SettingKeys.remindersOn, 'true');
      }
    }

    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bagRemind,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  at == null
                      ? l10n.bagRemindOff
                      : l10n.bagRemindAt(
                          formatShortDate(at),
                          formatMinuteOfDay(at.hour * 60 + at.minute),
                        ),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (at != null && off)
                  Text(
                    l10n.bagRemindsOff,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: context.navmaas.onAmberSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: pick,
                  child: Text(
                    at == null ? l10n.bagRemindSet : l10n.bagRemindChange,
                  ),
                ),
                if (at != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => settings.remove(SettingKeys.bagRemindAt),
                    child: Text(l10n.bagRemindClear),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef _OwnItem = ({String label, BagSection section});

/// Add your own item under a section. Owns its text field.
class _AddOwnDialog extends StatefulWidget {
  const new();

  @override
  State<_AddOwnDialog> createState() => _AddOwnDialogState();
}

class _AddOwnDialogState extends State<_AddOwnDialog> {
  final _label = TextEditingController();
  BagSection _section = BagSection.forMe;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Semantics(header: true, child: Text(l10n.bagAddOwn)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            PillSegmented<BagSection>(
              segments: [
                for (final s in BagSection.values)
                  (value: s, label: bagSectionWord(l10n, s), caption: null),
              ],
              selected: _section,
              onChanged: (s) => setState(() => _section = s),
            ),
            TextField(
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: InputDecoration(labelText: l10n.bagOwnItem),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<_OwnItem>(context, (
            label: _label.text,
            section: _section,
          )),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
