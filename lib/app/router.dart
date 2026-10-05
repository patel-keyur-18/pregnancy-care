import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/placeholder_screen.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
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

/// Bottom tab bar (DESIGN_SYSTEM §6): 84 dp, active tab on a sage pill.
class _Shell extends StatelessWidget {
  const new(this.shell);

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    NavigationDestination tab(IconData icon, IconData selected, String label) =>
        NavigationDestination(
          icon: Icon(icon),
          selectedIcon: Icon(selected),
          label: label,
        );
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        // Tab labels stop growing at 1.5× so five tabs still fit; the
        // screens themselves follow the full text size.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              tab(Icons.home_outlined, Icons.home_rounded, l10n.tabToday),
              tab(Icons.eco_outlined, Icons.eco_rounded, l10n.tabJourney),
              tab(Icons.spa_outlined, Icons.spa_rounded, l10n.tabSessions),
              tab(
                Icons.favorite_border_rounded,
                Icons.favorite_rounded,
                l10n.tabCare,
              ),
              tab(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                l10n.tabMe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
