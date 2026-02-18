import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'go_router_refresh_stream.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/practice/presentation/pages/practice_page.dart';
import '../../features/practice/presentation/pages/custom_topic_form_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/lessons/presentation/pages/lessons_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/chat/presentation/pages/live_speech_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/practice', // The Hub
    navigatorKey: rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentSession != null;
      final isAuthRoute = state.uri.path == '/auth';



      if (!isLoggedIn && !isAuthRoute) {
        return '/auth';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/practice';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGate(),
      ),
      // Full Screen Chat (Outside Shell)
      GoRoute(
        path: '/chat/:scenarioId',
        parentNavigatorKey: rootNavigatorKey, // Explicitly cover shell
        builder: (context, state) {
          final scenarioId = state.pathParameters['scenarioId'] ?? 'default';
          return ChatPage(scenarioId: scenarioId);
        },
      ),
      GoRoute(
        path: '/live',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LiveSpeechPage(),
      ),
      GoRoute(
        path: '/practice/custom/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CustomTopicFormPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lessons',
                builder: (context, state) => const LessonsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/practice',
                builder: (context, state) => const PracticePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
