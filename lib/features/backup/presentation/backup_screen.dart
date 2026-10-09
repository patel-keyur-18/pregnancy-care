import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/platform/build_info.dart';
import 'package:navmaas/core/reminders/data_reminders.dart';
import 'package:navmaas/core/reminders/planner.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/core/utils/date_only.dart';
import 'package:navmaas/core/widgets/notice_box.dart';
import 'package:navmaas/core/widgets/pill_segmented.dart';
import 'package:navmaas/features/backup/data/backup_file.dart';
import 'package:navmaas/features/backup/data/backup_log.dart';
import 'package:navmaas/features/backup/data/backup_service.dart';
import 'package:navmaas/features/sessions/data/library_repository.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// "2.4 MB", "820 KB".
String formatBytes(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).ceil()} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// "Sat 3 Oct, 9:12 pm".
String formatMoment(DateTime t) {
  final local = t.toLocal();
  return '${DateFormat('EEE d MMM').format(local)}, '
      '${formatMinuteOfDay(local.hour * 60 + local.minute)}';
}

String _errorText(AppLocalizations l10n, BackupError e) => switch (e) {
  BackupError.wrongPassword => l10n.errorWrongPassword,
  BackupError.notABackup => l10n.errorNotABackup,
  BackupError.tooNew => l10n.errorTooNew,
  BackupError.damaged => l10n.errorDamaged,
};

enum _Tab { backup, restore }

/// Backup & restore (prototype "Backup & restore", ARCHITECTURE §11): a
/// password-protected `.navmaas` file she saves wherever she likes, and
/// restoring one, which replaces everything or changes nothing.
class BackupScreen extends ConsumerStatefulWidget {
  const new({this.restore = false, super.key});

  /// Opens on the Restore tab (from onboarding).
  final bool restore;

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late _Tab _tab = widget.restore ? _Tab.restore : _Tab.backup;
  final _password = TextEditingController();
  final _again = TextEditingController();
  final _restorePassword = TextEditingController();
  var _show = false;
  var _includeLibrary = false;
  var _working = false;
  String? _error;
  BackupResult? _made;
  File? _picked;
  int _pickedSize = 0;
  BackupHeader? _header;
  RestoreResult? _restored;

  @override
  void initState() {
    super.initState();
    for (final c in [_password, _again, _restorePassword]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    _restorePassword.dispose();
    super.dispose();
  }

  Future<BackupService> get _service => ref.read(backupServiceProvider.future);

  Future<void> _create() async {
    setState(() {
      _working = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      final made = await (await _service).create(
        password: _password.text,
        includeLibrary: _includeLibrary,
        includeVoice: ref.read(backupVoiceProvider).value ?? false,
      );
      if (mounted) setState(() => _made = made);
    } on Object catch (e) {
      debugPrint('Navmaas: backup failed ($e)');
      if (mounted) setState(() => _error = l10n.errorBackupFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _resetBackup() => setState(() {
    _made = null;
    _show = false;
    _password.clear();
    _again.clear();
  });

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref.read(pickFileProvider)(const []);
    if (picked == null || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final service = await _service;
      final (:file, :size) = await service.receive(picked.bytes);
      final header = await service.inspect(file);
      if (mounted) {
        setState(() {
          _picked = file;
          _pickedSize = size;
          _header = header;
        });
      }
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = _errorText(l10n, e.error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final restored = await (await _service).restore(
        _picked!,
        _restorePassword.text,
      );
      ref.read(reminderSyncProvider.notifier).refresh();
      if (mounted) setState(() => _restored = restored);
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = _errorText(l10n, e.error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Back where she came from; when Backup & restore is the base route
  /// (from onboarding or the quiet page), the router picks the screen.
  void _leave() => context.canPop() ? context.pop() : context.go('/today');

  void _resetRestore() => setState(() {
    _picked = null;
    _header = null;
    _error = null;
    _restorePassword.clear();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final Widget body;
    if (_tab == _Tab.backup) {
      body = _made == null ? _backupForm(context) : _backupDone(context);
    } else if (_restored != null) {
      body = _restoreDone(context);
    } else if (_picked != null) {
      body = _restoreForm(context);
    } else {
      body = _restorePick(context);
    }

    return PopScope(
      canPop: !_working && context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_working) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                child: Row(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: l10n.backTooltip,
                      onPressed: _working ? null : _leave,
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
                          l10n.backupTitle,
                          style: text.titleMedium!.copyWith(
                            fontSize: 20,
                            height: 26 / 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    8,
                    AppTheme.gutter,
                    28,
                  ),
                  children: [
                    const _StatusCard(),
                    const SizedBox(height: 16),
                    PillSegmented<_Tab>(
                      segments: [
                        (
                          value: _Tab.backup,
                          label: l10n.backupTab,
                          caption: null,
                        ),
                        (
                          value: _Tab.restore,
                          label: l10n.restoreTab,
                          caption: null,
                        ),
                      ],
                      selected: _tab,
                      onChanged: _working
                          ? (_) {}
                          : (t) => setState(() {
                              _tab = t;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 16),
                    body,
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              NmIcon(
                                NavmaasIcon.clock,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                              Expanded(
                                child: Text(
                                  l10n.freeAppleIdNote,
                                  style: text.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: children,
      ),
    ),
  );

  Widget _label(String s) => Text(
    s,
    style: Theme.of(context).textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget? _errorLine() {
    final error = _error;
    if (error == null) return null;
    return Semantics(
      liveRegion: true,
      child: Text(
        error,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _backupForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pw = _password.text;
    final longEnough = pw.length >= 8;
    final match = longEnough && pw == _again.text;
    final (hint, hintColor) = match
        ? (l10n.passwordsMatch, scheme.primary)
        : longEnough && _again.text.isNotEmpty
        ? (l10n.passwordsDiffer, scheme.error)
        : (l10n.passwordTooShort, scheme.outline);
    final sizes = ref.watch(backupSizesProvider).value;
    final includeVoice = ref.watch(backupVoiceProvider).value ?? false;

    return _card([
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          _label(l10n.backupPassword),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: TextField(
                  controller: _password,
                  obscureText: !_show,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: l10n.passwordHint,
                    labelText: l10n.backupPassword,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => setState(() => _show = !_show),
                child: Text(
                  _show ? l10n.hideButton : l10n.showButton,
                  semanticsLabel: _show ? l10n.hidePassword : l10n.showPassword,
                ),
              ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          _label(l10n.typeItAgain),
          TextField(
            controller: _again,
            obscureText: !_show,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.typeItAgain,
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              hint,
              style: text.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: hintColor,
              ),
            ),
          ),
        ],
      ),
      MergeSemantics(
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.includeLibrary,
                    style: text.bodyLarge!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (sizes != null)
                    Text(
                      _includeLibrary
                          ? l10n.includeLibraryOn(
                              formatBytes(sizes.base + sizes.library),
                            )
                          : l10n.includeLibraryOff(formatBytes(sizes.base)),
                      style: text.bodySmall!.copyWith(color: scheme.outline),
                    ),
                ],
              ),
            ),
            Switch(
              value: _includeLibrary,
              onChanged: _working
                  ? null
                  : (v) => setState(() => _includeLibrary = v),
            ),
          ],
        ),
      ),
      // Voice letters (E3): off by default, remembered.
      MergeSemantics(
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.includeVoice,
                    style: text.bodyLarge!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    includeVoice
                        ? l10n.includeVoiceOn(formatBytes(sizes?.voice ?? 0))
                        : l10n.includeVoiceOff,
                    style: text.bodySmall!.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
            Switch(
              value: includeVoice,
              onChanged: _working
                  ? null
                  : (v) => ref
                        .read(settingsRepositoryProvider)
                        .put(SettingKeys.backupVoice, '$v'),
            ),
          ],
        ),
      ),
      NoticeBox(text: l10n.writePasswordDown),
      ?_errorLine(),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 54)),
        onPressed: match && !_working ? _create : null,
        child: Text(
          _working ? l10n.encrypting : l10n.createBackup,
          textAlign: TextAlign.center,
        ),
      ),
    ]);
  }

  Widget _fileBox(String name, String detail) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              name,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detail,
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneTitle(String title, {String? subtitle}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      spacing: 12,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: NmIcon(
              NavmaasIcon.check,
              size: 20,
              strokeWidth: 3,
              color: scheme.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium!.copyWith(fontSize: 17),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backupDone(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final made = _made!;
    final entries = NumberFormat.decimalPattern('en_IN').format(made.entries);
    return _card([
      _doneTitle(l10n.backupReady, subtitle: l10n.backupEncrypted),
      _fileBox(
        made.file.uri.pathSegments.last,
        l10n.backupSummary(formatBytes(made.sizeBytes), entries, made.photos),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 54)),
        onPressed: () => ref.read(shareFileProvider)(made.file),
        icon: const NmIcon(NavmaasIcon.download, size: 18, strokeWidth: 2),
        label: Text(l10n.saveOrShare, textAlign: TextAlign.center),
      ),
      OutlinedButton(onPressed: _resetBackup, child: Text(l10n.doneButton)),
    ]);
  }

  Widget _restorePick(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _card([
      Text(
        l10n.restoreIntro,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      ?_errorLine(),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 54)),
        onPressed: _working ? null : _pick,
        icon: const NmIcon(NavmaasIcon.upload, size: 18, strokeWidth: 2),
        label: Text(l10n.chooseBackupFile, textAlign: TextAlign.center),
      ),
    ]);
  }

  Widget _restoreForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final header = _header!;
    return _card([
      _fileBox(
        'navmaas-backup-'
        '${DateFormat('yyyy-MM-dd').format(header.createdAt.toLocal())}'
        '.navmaas',
        l10n.backupMade(
          formatMoment(header.createdAt),
          formatBytes(_pickedSize),
          header.appVersion,
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          _label(l10n.backupPassword),
          TextField(
            controller: _restorePassword,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.backupPassword,
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          ?_errorLine(),
        ],
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l10n.restoreWarning,
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onErrorContainer,
            ),
          ),
        ),
      ),
      FilledButton(
        // Red: restoring replaces her data (DESIGN_SYSTEM §1).
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
        onPressed: _restorePassword.text.isEmpty || _working ? null : _restore,
        child: Text(
          _working ? l10n.restoring : l10n.replaceAndRestore,
          textAlign: TextAlign.center,
        ),
      ),
      TextButton(
        onPressed: _working ? null : _resetRestore,
        child: Text(l10n.chooseDifferentFile),
      ),
    ]);
  }

  Widget _restoreDone(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final restored = _restored!;
    final entries = NumberFormat.decimalPattern('en_IN')
        .format(restored.entries);
    return _card([
      _doneTitle(
        l10n.restoredFrom(
          DateFormat('EEE d MMM').format(restored.madeAt.toLocal()),
        ),
      ),
      Text(
        l10n.restoredBody(entries, restored.photos),
        style: theme.textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      FilledButton(
        onPressed: () => context.go('/today'),
        child: Text(l10n.doneButton),
      ),
    ]);
  }
}

/// The last backup, the next reminder, and the weekly reminder's day.
class _StatusCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = scheme.onPrimaryContainer;
    final last = ref.watch(lastBackupProvider).value;
    final day = ref.watch(backupDayProvider).value ?? DateTime.sunday;
    final expiry = ref.watch(buildExpiryProvider).value;
    final now = clockNow();
    final next =
        [
            ...buildExpiryCandidates(expiry: expiry, l10n: l10n),
            ...backupCandidates(
              now: now,
              day: day,
              lastBackup: last,
              expiry: expiry,
              l10n: l10n,
              days: 15,
            ),
          ].where((c) => c.at.isAfter(now)).toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final String nextLine;
    if (next.isEmpty) {
      nextLine = l10n.backupRemindersOff;
    } else {
      final date = DateFormat('EEE d MMM').format(next.first.at);
      nextLine = next.first.kind == ReminderKind.buildExpiry
          ? l10n.nextBackupReminderExpiry(date)
          : l10n.nextBackupReminder(date);
    }
    final days = [
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        // 2024-01-01 was a Monday.
        (d, DateFormat('EEEE').format(DateTime(2024, 1, d))),
    ];
    final dayName = day == 0
        ? l10n.backupReminderOff
        : days.firstWhere((d) => d.$1 == day).$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: NmIcon(
                      NavmaasIcon.lock,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        last == null
                            ? l10n.noBackupYet
                            : l10n.lastBackup(formatMoment(last)),
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: on,
                        ),
                      ),
                      Text(
                        nextLine,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: on,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            container: true,
            button: true,
            child: InkWell(
              onTap: () async {
                final picked = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(l10n.backupReminderDay),
                    children: [
                      for (final (value, name) in [
                        ...days,
                        (0, l10n.backupReminderOff),
                      ])
                        SimpleDialogOption(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          onPressed: () => Navigator.pop(context, value),
                          child: Text(
                            name,
                            style: value == day
                                ? const TextStyle(fontWeight: FontWeight.w800)
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
                if (picked == null) return;
                await ref
                    .read(settingsRepositoryProvider)
                    .put(SettingKeys.backupDay, '$picked');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      NmIcon(
                        NavmaasIcon.bell,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Text(
                          l10n.backupReminderDay,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        dayName,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
