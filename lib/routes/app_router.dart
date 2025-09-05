import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import for ProviderScope
import 'package:tickit/auth/login_page.dart';
import 'package:tickit/home/task_page.dart';
import 'package:tickit/settings/setting_page.dart';
import 'package:tickit/widgets/scaffold_with_navbar.dart';
import 'package:tickit/services/auth_service.dart'; // Import for authServiceProvider

class AppRoutes {
  static const String login = 'login';
  static const String tasks = 'tasks';
  static const String settings = 'settings';
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/tasks',
    routes: [
      GoRoute(
        name: AppRoutes.login,
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.tasks,
                path: '/tasks',
                builder: (context, state) => const TaskPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.settings,
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // We need to use a ProviderContainer to access Riverpod providers in a static context
      // like GoRouter's redirect. This is a common pattern for authentication checks.
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authServiceProvider);

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // If the user is not logged in and is not on the login page, redirect to login.
      if (!isLoggedIn && !isLoggingIn) {
        return state.namedLocation(AppRoutes.login);
      }

      // If the user is logged in and is on the login page, redirect to tasks.
      if (isLoggedIn && isLoggingIn) {
        return state.namedLocation(AppRoutes.tasks);
      }

      // No redirect needed
      return null;
    },
  );
}
