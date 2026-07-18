import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/core_providers.dart';
import '../../screens/achievements/achievements_screen.dart';
import '../../screens/ai_assistant/ai_assistant_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/student_dashboard_screen.dart';
import '../../screens/diagnostic/diagnostic_test_screen.dart';
import '../../screens/games/game_player_screen.dart';
import '../../screens/games/games_screen.dart';
import '../../screens/landing/landing_screen.dart';
import '../../screens/parent/parent_dashboard_screen.dart';
import '../../screens/progress_tree/progress_tree_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/teacher/teacher_dashboard_screen.dart';
import '../../screens/units/units_screen.dart';
import 'go_router_refresh_stream.dart';

String _homeRouteFor(UserRole role) => switch (role) {
      UserRole.teacher => '/teacher',
      UserRole.parent => '/parent',
      UserRole.student => '/dashboard',
    };

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final session = client.auth.currentSession;

      // Guests may browse the public landing page and the auth screen;
      // anything else sends them home to the landing page.
      if (session == null) {
        const guestLocations = {'/', '/login'};
        return guestLocations.contains(location) ? null : '/';
      }

      if (location == '/' || location == '/splash' || location == '/login') {
        final profile = await ref.read(authServiceProvider).loadCurrentProfile();
        if (profile == null) return '/login';
        if (profile.role == UserRole.student) {
          final progress = await client
              .from('student_progress')
              .select('current_level')
              .eq('student_id', profile.id)
              .maybeSingle();
          final hasDiagnostic = progress != null; // row exists once created at sign-up
          if (!hasDiagnostic) return '/diagnostic';
        }
        return _homeRouteFor(profile.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          startInSignUp: state.uri.queryParameters['mode'] == 'signup',
        ),
      ),
      GoRoute(path: '/diagnostic', builder: (context, state) => const DiagnosticTestScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const StudentDashboardScreen()),
      GoRoute(path: '/progress-tree', builder: (context, state) => const ProgressTreeScreen()),
      GoRoute(path: '/units', builder: (context, state) => const UnitsScreen()),
      GoRoute(
        path: '/units/:unitKey',
        builder: (context, state) => GamesScreen(unitKey: state.pathParameters['unitKey']!),
      ),
      GoRoute(
        path: '/games/:gameKey',
        builder: (context, state) => GamePlayerScreen(gameKey: state.pathParameters['gameKey']!),
      ),
      GoRoute(path: '/ai-assistant', builder: (context, state) => const AiAssistantScreen()),
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/teacher', builder: (context, state) => const TeacherDashboardScreen()),
      GoRoute(path: '/parent', builder: (context, state) => const ParentDashboardScreen()),
    ],
  );
});
