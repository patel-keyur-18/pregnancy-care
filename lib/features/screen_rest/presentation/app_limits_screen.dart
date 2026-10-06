import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/platform/app_usage.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/take_button.dart';
import 'package:navmaas/features/screen_rest/data/app_limits.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Limits for other apps (prototype "Limits for other apps" and "Usage
/// access", Plan decisions 51–53; Android only). Without Usage access it
/// explains and opens Settings; once she turns it off again her limits are
/// paused, not lost.
class AppLimitsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends ConsumerState<AppLimitsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from Settings: she may have turned Usage access on or off.
    _lifecycle = AppLifecycleListener(onResume: () => refreshUsage(ref));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final access = ref.watch(usageAccessProvider).value;
    final limits = ref.watch(appLimitsProvider).value;
    final minutes = ref.watch(limitMinutesTodayProvider).value ?? const {};
    final icons = ref.watch(installedAppsProvider).value ?? const {};

    final Widget body;
    if (access == null || limits == null) {
      body = const SizedBox.shrink();
    } else if (!access) {
      body = _AccessNeeded(paused: limits.isNotEmpty);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            l10n.appLimitsIntro,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontSize: 15,
              height: 22 / 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final limit in limits)
                  _LimitRow(
                    limit: limit,
                    icon: icons[limit.package]?.icon,
                    used: minutes[limit.package] ?? 0,
                    onTap: () => _edit(
                      context,
                      package: limit.package,
                      label: limit.label,
                      minutes: limit.minutes,
                      existing: true,
                    ),
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 56),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () => unawaited(_add(context, limits)),
                  icon: NmIcon(NavmaasIcon.plus, color: scheme.primary),
                  label: Text(l10n.appLimitsAdd),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appLimitsPrivacy,
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.outline,
            ),
          ),
          if (limits.isNotEmpty) ...[
            const SizedBox(height: 16),
            _NoticePreview(limit: limits.first),
          ],
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.backTooltip,
                    onPressed: () => context.pop(),
                    icon: const NmIcon(
                      NavmaasIcon.chevronLeft,
                      size: 22,
                      strokeWidth: 2,
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.appLimitsTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontSize: 17,
                          height: 24 / 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, List<AppLimit> limits) async {
    final chosen = {for (final l in limits) l.package};
    final apps = [
      for (final a in (await ref.read(installedAppsProvider.future)).values)
        if (!chosen.contains(a.package)) a,
    ];
    if (!context.mounted) return;
    final app = await showModalBottomSheet<InstalledApp>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ChooseApp(apps: apps),
    );
    if (app == null || !context.mounted) return;
    await _edit(
      context,
      package: app.package,
      label: app.label,
      minutes: defaultAppLimit,
      existing: false,
    );
  }

  Future<void> _edit(
    BuildContext context, {
    required String package,
    required String label,
    required int minutes,
    required bool existing,
  }) async {
    final repo = ref.read(appLimitsRepositoryProvider);
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          _MinutesSheet(label: label, minutes: minutes, existing: existing),
    );
    if (result == null) return;
    if (result == 0) {
      await repo.remove(package);
    } else {
      await repo.save(package: package, label: label, minutes: result);
    }
  }
}

/// Re-reads Usage access and today's minutes.
void refreshUsage(WidgetRef ref) => ref
  ..invalidate(usageAccessProvider)
  ..invalidate(limitMinutesTodayProvider);

/// Before Usage access is given, or once it has been turned off.
class _AccessNeeded extends ConsumerWidget {
  const new({required this.paused});

  /// Limits are set but access was turned off.
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<NavmaasColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              spacing: 14,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: paused ? colors.amberSoft : scheme.primaryContainer,
                  ),
                  child: NmIcon(
                    NavmaasIcon.clock,
                    size: 36,
                    color: paused
                        ? colors.onAmberSoft
                        : scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  paused
                      ? l10n.appLimitsPausedTitle
                      : l10n.appLimitsAccessTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  paused ? l10n.appLimitsPausedBody : l10n.appLimitsAccessBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.appLimitsAccessNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: FilledButton(
            onPressed: () => ref.read(appUsageProvider).openAccessSettings(),
            child: Text(
              paused ? l10n.appLimitsPausedButton : l10n.appLimitsAccessButton,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// The app's own icon, or its first letter on a soft tile.
class AppIcon extends StatelessWidget {
  const new({required this.label, required this.icon, super.key});

  final String label;
  final Uint8List? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bytes = icon;
    return ExcludeSemantics(
      child: bytes == null
          ? IconTile(
              background: scheme.surfaceContainerHighest,
              child: Text(
                label.characters.firstOrNull?.toUpperCase() ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, width: 40, height: 40),
            ),
    );
  }
}

/// "YouTube · 18 of 30 min today" with a thin bar; past the limit the line
/// says so, calmly (no warning colour).
class LimitProgress extends StatelessWidget {
  const new({required this.limit, required this.used, super.key});

  final AppLimit limit;
  final int used;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              limit.label,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              used >= limit.minutes
                  ? l10n.appLimitsPast(used, limit.minutes)
                  : l10n.appLimitsUsed(used, limit.minutes),
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.outline,
              ),
            ),
          ],
        ),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: math.min(1, used / limit.minutes),
              minHeight: 6,
              color: scheme.primary,
              backgroundColor: theme.extension<NavmaasColors>()!.track,
            ),
          ),
        ),
      ],
    );
  }
}

class _LimitRow extends StatelessWidget {
  const new({
    required this.limit,
    required this.icon,
    required this.used,
    required this.onTap,
  });

  final AppLimit limit;
  final Uint8List? icon;
  final int used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              spacing: 12,
              children: [
                AppIcon(label: limit.label, icon: icon),
                Expanded(
                  child: LimitProgress(limit: limit, used: used),
                ),
                Text(
                  l10n.minutesShort(limit.minutes),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
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

/// What the notice says, for her first limit.
class _NoticePreview extends StatelessWidget {
  const new({required this.limit});

  final AppLimit limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              l10n.appLimitsPreview,
              style: theme.textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.outline,
              ),
            ),
            Text(
              l10n.appLimitNoticeTitle,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l10n.appLimitNoticeBody(limit.minutes, limit.label),
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Choose an app": the apps on her launcher without a limit yet.
class _ChooseApp extends StatelessWidget {
  const new({required this.apps});

  final List<InstalledApp> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.appLimitsChoose,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final a in apps)
              ListTile(
                minTileHeight: 56,
                leading: AppIcon(label: a.label, icon: a.icon),
                title: Text(a.label),
                onTap: () => Navigator.pop(context, a),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Daily limit for YouTube": 15 to 120 minutes (Plan decision 52). Pops
/// the minutes, or 0 to remove the limit.
class _MinutesSheet extends StatefulWidget {
  const new({
    required this.label,
    required this.minutes,
    required this.existing,
  });

  final String label;
  final int minutes;
  final bool existing;

  @override
  State<_MinutesSheet> createState() => _MinutesSheetState();
}

class _MinutesSheetState extends State<_MinutesSheet> {
  late int _minutes = widget.minutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.appLimitsDailyFor(widget.label),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Semantics(
              label: l10n.appLimitsMinutesLabel,
              container: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in appLimitMinutes)
                    ChoiceChip(
                      key: ValueKey('$m-${m == _minutes}'),
                      label: Text(l10n.minutesShort(m)),
                      selected: m == _minutes,
                      showCheckmark: false,
                      selectedColor: scheme.primary,
                      labelStyle: theme.textTheme.labelLarge!.copyWith(
                        color: m == _minutes
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() => _minutes = m),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _minutes),
              child: Text(l10n.saveButton),
            ),
            if (widget.existing)
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                onPressed: () => Navigator.pop(context, 0),
                child: Text(l10n.appLimitsRemove),
              ),
          ],
        ),
      ),
    );
  }
}
