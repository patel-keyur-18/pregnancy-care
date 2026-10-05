import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/placeholder_screen.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/onboarding/onboarding_screen.dart';
import 'package:navmaas/features/settings/edit_dates_screen.dart';
import 'package:navmaas/features/settings/me_screen.dart';
import 'package:navmaas/features/today/today_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-run the redirect whenever the active pregnancy appears or goes away.
  final refresh = ValueNotifier(0);
  ref
    ..listen(activePregnancyProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final pregnancy = ref.read(activePregnancyProvider);
      if (!pregnancy.hasValue) return null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (pregnancy.value == null) return onboarding ? null : '/onboarding';
      return onboarding ? '/today' : null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell),
        branches: [
          _branch('/today', (_) => const TodayScreen()),
          _branch(
            '/journey',
            (l10n) => PlaceholderScreen(
              title: l10n.tabJourney,
              body: l10n.journeyBody,
            ),
          ),
          _branch(
            '/sessions',
            (l10n) => PlaceholderScreen(
              title: l10n.tabSessions,
              body: l10n.sessionsBody,
            ),
          ),
          _branch(
            '/care',
            (l10n) =>
                PlaceholderScreen(title: l10n.tabCare, body: l10n.careBody),
          ),
          _branch(
            '/me',
            (_) => const MeScreen(),
            routes: [
              GoRoute(
                path: 'dates',
                builder: (_, _) => const EditDatesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

StatefulShellBranch _branch(
  String path,
  Widget Function(AppLocalizations l10n) screen, {
  List<RouteBase> routes = const [],
}) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (context, _) => screen(AppLocalizations.of(context)),
      routes: routes,
    ),
  ],
);

class _Shell extends StatelessWidget {
  const new(this.shell);

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavmaasTabBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        tabs: [
          (icon: NavmaasIcon.home, label: l10n.tabToday),
          (icon: NavmaasIcon.sprout, label: l10n.tabJourney),
          (icon: NavmaasIcon.lotus, label: l10n.tabSessions),
          (icon: NavmaasIcon.heart, label: l10n.tabCare),
          (icon: NavmaasIcon.person, label: l10n.tabMe),
        ],
      ),
    );
  }
}
