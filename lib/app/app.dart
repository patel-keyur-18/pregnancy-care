import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navmaas/app/home_widget.dart';
import 'package:navmaas/app/reminders.dart';
import 'package:navmaas/app/router.dart';
import 'package:navmaas/app/theme_mode.dart';
import 'package:navmaas/core/content/content_pack.dart';
import 'package:navmaas/core/db/app_database.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/settings_repository.dart';
import 'package:navmaas/core/reminders/scheduler.dart';
import 'package:navmaas/core/theme/app_theme.dart';
import 'package:navmaas/core/utils/clock.dart';
import 'package:navmaas/features/app_lock/app_lock.dart';
import 'package:navmaas/features/app_lock/lock_screen.dart';
import 'package:navmaas/features/screen_rest/data/screen_use.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';

/// Opens the database and waits for the first pregnancy and theme values
/// and the content pack,
/// behind the native splash, so the first frame is already the right screen
/// in the right theme. Listens rather than reads: Riverpod pauses streams
/// nobody listens to, and drift would never emit.
Future<void> loadFirstValues(ProviderContainer container) => Future.wait([
  container.listen(activePregnancyProvider.future, (_, _) {}).read(),
  container.listen(latestPregnancyProvider.future, (_, _) {}).read(),
  container.listen(themeModeProvider.future, (_, _) {}).read(),
  container.listen(contentPackProvider.future, (_, _) {}).read(),
  container.listen(appLockSettingsProvider.future, (_, _) {}).read(),
]);

class NavmaasApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NavmaasApp> createState() => _NavmaasAppState();
}

class _NavmaasAppState extends ConsumerState<NavmaasApp> {
  late final AppLifecycleListener _lifecycle;

  /// Away from the foreground (app switcher, a system sheet): with app lock
  /// on, a plain cover hides her data.
  var _away = false;

  @override
  void initState() {
    super.initState();
    // Time on screen counts towards "In Navmaas today" (Screen Rest).
    final use = ref.read(screenUseProvider.notifier);
    final lock = ref.read(appLockProvider.notifier);
    _lifecycle = AppLifecycleListener(
      // A new day may have started while the app was in the background.
      onResume: _onResume,
      onShow: () {
        use.shown();
        lock.returned();
      },
      onHide: () {
        lock.left();
        unawaited(use.hidden());
      },
      onStateChange: (s) =>
          setState(() => _away = s != AppLifecycleState.resumed),
    );
  }

  Future<void> _onResume() async {
    // A new day may have started, the time zone may have changed, and a
    // reminder's "Taken" may have written to the DB from another isolate.
    ref
      ..invalidate(todayProvider)
      ..invalidate(nowProvider);
    final db = ref.read(appDatabaseProvider);
    db.markTablesUpdated([db.doseLogs, db.supplements]);
    await ref.read(reminderSchedulerProvider).refreshTimeZone();
    ref.read(reminderSyncProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    ref
      ..listen(reminderSyncProvider, (_, _) {})
      ..listen(widgetSyncProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.system,
      themeAnimationDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOut,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      // App lock covers every route; what is underneath keeps its state, and
      // notification or widget taps navigate there behind the lock.
      builder: (context, child) {
        final locked = ref.watch(appLockProvider);
        final lockOn = ref.watch(appLockSettingsProvider).value?.on ?? false;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: locked,
              child: TickerMode(enabled: !locked, child: child!),
            ),
            if (locked) const LockScreen(),
            if (lockOn && _away) const PrivacyCover(),
          ],
        );
      },
    );
  }
}
