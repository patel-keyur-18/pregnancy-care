import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/features/care/presentation/edit_supplement_screen.dart';
import 'package:navmaas/features/care/presentation/edit_visit_screen.dart';
import 'package:navmaas/features/care/presentation/supplements_screen.dart';
import 'package:navmaas/features/care/presentation/tests_screen.dart';
import 'package:navmaas/features/care/presentation/visit_screen.dart';
import 'package:navmaas/features/journey/journey_screen.dart';
import 'package:navmaas/features/onboarding/onboarding_screen.dart';
import 'package:navmaas/features/sessions/presentation/breathing_screen.dart';
import 'package:navmaas/features/sessions/presentation/exercise_screen.dart';
import 'package:navmaas/features/sessions/presentation/letters_screen.dart';
import 'package:navmaas/features/sessions/presentation/listen_screen.dart';
import 'package:navmaas/features/sessions/presentation/reader_screen.dart';
import 'package:navmaas/features/sessions/presentation/sessions_screen.dart';
import 'package:navmaas/features/sessions/presentation/walk_screen.dart';
import 'package:navmaas/features/settings/doctor_screen.dart';
import 'package:navmaas/features/settings/edit_details_screen.dart';
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
      // Full screen, above the tab bar (prototype Reader, Listen, Walk and
      // Exercise).
      GoRoute(
        path: '/read',
        builder: (_, state) => ReaderScreen(itemId: state.extra! as String),
      ),
      GoRoute(
        path: '/listen',
        builder: (_, state) => ListenScreen(itemId: state.extra! as String),
      ),
      GoRoute(path: '/walk', builder: (_, _) => const WalkScreen()),
      GoRoute(
        path: '/exercise',
        builder: (_, state) =>
            ExerciseScreen(routineKey: state.extra! as String),
      ),
      GoRoute(path: '/breathe', builder: (_, _) => const BreathingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell),
        branches: [
          _branch('/today', (_) => const TodayScreen()),
          _branch('/journey', (_) => const JourneyScreen()),
          _branch(
            '/sessions',
            (_) => const SessionsScreen(),
            routes: [
              GoRoute(
                path: 'letters',
                builder: (_, _) => const LettersScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) =>
                        EditLetterScreen(letterId: state.extra as String?),
                  ),
                ],
              ),
            ],
          ),
          _branch(
            '/care',
            (_) => const CareScreen(),
            routes: [
              GoRoute(path: 'tests', builder: (_, _) => const TestsScreen()),
              GoRoute(
                path: 'visit',
                builder: (_, state) =>
                    VisitScreen(visitId: state.extra as String? ?? ''),
              ),
              // A sibling, not a child: adding a visit has no visit to show
              // underneath.
              GoRoute(
                path: 'visit-edit',
                builder: (_, state) =>
                    EditVisitScreen(visitId: state.extra as String?),
              ),
              GoRoute(
                path: 'supplements',
                builder: (_, _) => const SupplementsScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => EditSupplementScreen(
                      supplementId: state.extra as String?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _branch(
            '/me',
            (_) => const MeScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, _) => const EditDetailsScreen(),
              ),
              GoRoute(path: 'doctor', builder: (_, _) => const DoctorScreen()),
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
