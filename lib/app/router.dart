import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navmaas/app/tab_bar.dart';
import 'package:navmaas/core/db/pregnancy_repository.dart';
import 'package:navmaas/core/db/tables.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';
import 'package:navmaas/features/backup/presentation/backup_screen.dart';
import 'package:navmaas/features/care/presentation/care_screen.dart';
import 'package:navmaas/features/care/presentation/edit_supplement_screen.dart';
import 'package:navmaas/features/care/presentation/edit_visit_screen.dart';
import 'package:navmaas/features/care/presentation/supplements_screen.dart';
import 'package:navmaas/features/care/presentation/tests_screen.dart';
import 'package:navmaas/features/care/presentation/visit_screen.dart';
import 'package:navmaas/features/journey/journey_screen.dart';
import 'package:navmaas/features/onboarding/onboarding_screen.dart';
import 'package:navmaas/features/screen_rest/presentation/app_limits_screen.dart';
import 'package:navmaas/features/screen_rest/presentation/screen_rest_screen.dart';
import 'package:navmaas/features/sessions/presentation/breathing_screen.dart';
import 'package:navmaas/features/sessions/presentation/exercise_screen.dart';
import 'package:navmaas/features/sessions/presentation/letters_screen.dart';
import 'package:navmaas/features/sessions/presentation/listen_screen.dart';
import 'package:navmaas/features/sessions/presentation/meditation_screen.dart';
import 'package:navmaas/features/sessions/presentation/reader_screen.dart';
import 'package:navmaas/features/sessions/presentation/sessions_screen.dart';
import 'package:navmaas/features/sessions/presentation/walk_screen.dart';
import 'package:navmaas/features/settings/doctor_screen.dart';
import 'package:navmaas/features/settings/edit_details_screen.dart';
import 'package:navmaas/features/settings/me_screen.dart';
import 'package:navmaas/features/settings/tracking_stopped_screen.dart';
import 'package:navmaas/features/third_trimester/presentation/contraction_screen.dart';
import 'package:navmaas/features/third_trimester/presentation/kick_counter_screen.dart';
import 'package:navmaas/features/today/today_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/mood_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/sleep_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/symptoms_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/water_screen.dart';
import 'package:navmaas/features/wellbeing/presentation/wellbeing_screen.dart';
import 'package:navmaas/l10n/gen/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Re-run the redirect whenever a pregnancy appears or changes status.
  final refresh = ValueNotifier(0);
  ref
    ..listen(latestPregnancyProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final latest = ref.read(latestPregnancyProvider);
      if (!latest.hasValue) return null;
      final pregnancy = latest.value;
      final at = state.matchedLocation;
      // No pregnancy yet: onboarding.
      // Backup & restore is open in every state (a new phone restores
      // from onboarding). Onboarding and the quiet page *go* there rather
      // than push: a refresh re-checks the route underneath, which would
      // close it as soon as the restored data appears.
      if (at == '/backup') return null;
      if (pregnancy == null) return at == '/onboarding' ? null : '/onboarding';
      // Paused, ended or delivered: only the quiet page (and onboarding, to
      // start a new pregnancy).
      if (pregnancy.status != PregnancyStatus.active) {
        return at == '/stopped' || at == '/onboarding' ? null : '/stopped';
      }
      return at == '/onboarding' || at == '/stopped' ? '/today' : null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/stopped',
        builder: (_, _) => const TrackingStoppedScreen(),
      ),
      // Full screen, above the tab bar (prototype Reader, Listen, Walk,
      // Exercise, Kick counter, Contraction timer, Screen Rest and Backup &
      // restore).
      GoRoute(
        path: '/read',
        builder: (_, state) => ReaderScreen(itemId: state.extra! as String),
      ),
      GoRoute(
        path: '/listen',
        // `?screen=off` opens in screen-off mode (the wind-down reminder);
        // `?as=meditation` plays her audio as meditation (M7b).
        builder: (_, state) => ListenScreen(
          itemId: state.extra! as String,
          screenOff: state.uri.queryParameters['screen'] == 'off',
          meditation: state.uri.queryParameters['as'] == 'meditation',
        ),
      ),
      GoRoute(path: '/walk', builder: (_, _) => const WalkScreen()),
      GoRoute(
        path: '/exercise',
        builder: (_, state) =>
            ExerciseScreen(routineKey: state.extra! as String),
      ),
      GoRoute(path: '/breathe', builder: (_, _) => const BreathingScreen()),
      GoRoute(path: '/meditate', builder: (_, _) => const MeditationScreen()),
      GoRoute(path: '/kicks', builder: (_, _) => const KickCounterScreen()),
      GoRoute(
        path: '/screen-rest',
        builder: (_, _) => const ScreenRestScreen(),
      ),
      GoRoute(path: '/app-limits', builder: (_, _) => const AppLimitsScreen()),
      GoRoute(
        path: '/backup',
        builder: (_, state) => BackupScreen(restore: state.extra == true),
      ),
      GoRoute(
        path: '/contractions',
        builder: (_, _) => const ContractionScreen(),
      ),
      GoRoute(
        path: '/wellbeing',
        builder: (_, _) => const WellbeingScreen(),
        routes: [
          GoRoute(path: 'mood', builder: (_, _) => const MoodScreen()),
          GoRoute(path: 'symptoms', builder: (_, _) => const SymptomsScreen()),
          GoRoute(path: 'sleep', builder: (_, _) => const SleepScreen()),
          GoRoute(path: 'water', builder: (_, _) => const WaterScreen()),
        ],
      ),
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
                    builder: (_, state) => EditLetterScreen(
                      letterId: state.extra as String?,
                      speak: state.uri.queryParameters['speak'] == '1',
                    ),
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
