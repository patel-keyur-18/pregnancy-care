import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Shown instead of the tabs while tracking is paused, ended or the baby has
/// arrived (Plan: pregnancy loss handling). One quiet page: no baby content,
/// no week numbers, nothing to stumble on. Her data stays saved.
class TrackingStoppedScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pregnancy = ref.watch(latestPregnancyProvider).value;
    if (pregnancy == null) return const Scaffold();
    final status = pregnancy.status;
    final (title, body) = switch (status) {
      PregnancyStatus.paused => (
        l10n.stoppedPausedTitle,
        l10n.stoppedPausedBody,
      ),
      PregnancyStatus.delivered => (
        l10n.stoppedDeliveredTitle,
        l10n.stoppedDeliveredBody,
      ),
      _ => (l10n.stoppedEndedTitle, l10n.stoppedEndedBody),
    };
    Future<void> resume() => ref
        .read(pregnancyRepositoryProvider)
        .setStatus(pregnancy.id, PregnancyStatus.active);

    final buttons = <Widget>[
      if (status == PregnancyStatus.paused)
        FilledButton(onPressed: resume, child: Text(l10n.resumeTracking))
      else ...[
        FilledButton(
          onPressed: () => context.push('/onboarding'),
          child: Text(l10n.startNewPregnancy),
        ),
        OutlinedButton(onPressed: resume, child: Text(l10n.resumeTracking)),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            56,
            AppTheme.gutter,
            24,
          ),
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: NmIcon(
                    NavmaasIcon.moon,
                    size: 36,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            for (final b in buttons) ...[b, const SizedBox(height: 12)],
          ],
        ),
      ),
    );
  }
}

/// Me → "Pause or end pregnancy tracking": pause, baby has arrived, or end.
/// Never asks why. Any choice can be undone with Resume.
Future<void> showPauseOrEnd(
  BuildContext context,
  WidgetRef ref,
  String pregnancyId,
) async {
  final l10n = AppLocalizations.of(context);
  final status = await showModalBottomSheet<PregnancyStatus>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      Widget option(PregnancyStatus value, String title, String sub) =>
          ListTile(
            minTileHeight: 64,
            title: Text(title, style: text.titleMedium),
            subtitle: Text(sub),
            onTap: () => Navigator.pop(context, value),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l10n.pauseOrEnd, style: text.titleLarge),
              ),
              option(
                PregnancyStatus.paused,
                l10n.pauseTracking,
                l10n.pauseTrackingSub,
              ),
              option(
                PregnancyStatus.delivered,
                l10n.babyArrived,
                l10n.babyArrivedSub,
              ),
              option(
                PregnancyStatus.ended,
                l10n.endTracking,
                l10n.endTrackingSub,
              ),
            ],
          ),
        ),
      );
    },
  );
  if (status == null) return;
  await ref.read(pregnancyRepositoryProvider).setStatus(pregnancyId, status);
}
