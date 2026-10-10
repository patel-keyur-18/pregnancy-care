import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/features/nutrition/data/avoid_food_repository.dart';
import 'package:navmaas/features/nutrition/presentation/nourishly_section.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Care → Nutrition: the meals she logged in Nourishly (M8b), then the
/// foods she avoids, with her own reasons (M8a). No food advice.
class NutritionScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foods = ref.watch(avoidFoodsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.nutritionTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          28,
        ),
        children: [
          Text(
            l10n.nutritionSubtitle,
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 20),
          const NourishlySection(),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              l10n.avoidFoodsTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 10),
          if (foods.isEmpty)
            Text(l10n.avoidFoodsEmpty, style: theme.textTheme.bodyMedium)
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, f) in foods.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      minTileHeight: 64,
                      title: Text(
                        f.name,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: f.reason == null ? null : Text(f.reason!),
                      onTap: () => _edit(context, ref, f),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _edit(context, ref, null),
            child: Text(l10n.avoidFoodAdd),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.avoidFoodsFooter,
            style: theme.textTheme.bodySmall!.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AvoidFood? f) async {
    final result = await showDialog<_FoodResult>(
      context: context,
      builder: (_) => _AvoidFoodDialog(food: f),
    );
    final pregnancy = ref.read(activePregnancyProvider).value;
    if (result == null || pregnancy == null) return;
    final repo = ref.read(avoidFoodRepositoryProvider);
    if (result.remove) {
      await repo.delete(f!.id);
    } else {
      await repo.save(
        id: f?.id,
        pregnancyId: pregnancy.id,
        name: result.name,
        reason: result.reason,
      );
    }
  }
}

typedef _FoodResult = ({String name, String reason, bool remove});

/// Add or edit a food she avoids. Owns its text fields, so they outlive the
/// closing animation.
class _AvoidFoodDialog extends StatefulWidget {
  const new({required this.food});

  final AvoidFood? food;

  @override
  State<_AvoidFoodDialog> createState() => _AvoidFoodDialogState();
}

class _AvoidFoodDialogState extends State<_AvoidFoodDialog> {
  late final _name = TextEditingController(text: widget.food?.name);
  late final _reason = TextEditingController(text: widget.food?.reason);

  @override
  void dispose() {
    _name.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.food != null;
    return AlertDialog(
      title: Semantics(
        header: true,
        child: Text(editing ? l10n.avoidFoodEdit : l10n.avoidFoodAdd),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: InputDecoration(labelText: l10n.avoidFoodName),
            ),
            TextField(
              controller: _reason,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(
                labelText: l10n.avoidFoodReason,
                hintText: l10n.avoidFoodReasonHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (editing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.pop<_FoodResult>(context, (
              name: '',
              reason: '',
              remove: true,
            )),
            child: Text(l10n.avoidFoodRemove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.backButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<_FoodResult>(context, (
            name: _name.text,
            reason: _reason.text,
            remove: false,
          )),
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
