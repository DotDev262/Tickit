import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tickit/auth/login_page.dart';
import 'package:tickit/home/task_page.dart';
import 'package:tickit/services/auth_service.dart';
import 'package:tickit/settings/settings_page.dart'; // Added
import 'package:tickit/services/fcm_service.dart'; // Added

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Move _calculateSelectedIndex before GoRouter definition
  int calculateSelectedIndex(BuildContext context) {
    final String location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString(); // Fix location getter
    if (location == '/') {
      return 0;
    }
    if (location == '/settings') {
      return 1;
    }
    return 0; // Default to tasks
  }

  return GoRouter(
    initialLocation: '/login',
    routes: [
      ShellRoute(
        // New ShellRoute
        builder: (context, state, child) {
          // This builder will contain the Scaffold and NavigationBar
          // The child is the currently active sub-route's page
          return Scaffold(
            body: child, // The animated content
            bottomNavigationBar: NavigationBar(
              selectedIndex: calculateSelectedIndex(
                context,
              ), // Calculate selected index based on current route
              onDestinationSelected: (index) {
                if (index == 0) {
                  context.go('/'); // Navigate to Tasks
                } else if (index == 1) {
                  context.go('/settings'); // Navigate to Settings
                }
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.task), label: 'Tasks'),
                NavigationDestination(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
        routes: [
          // Nested sub-routes
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child:
                  const TaskPage(), // TaskPage will now only return its body content
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(
                            -1.0,
                            0.0,
                          ), // Slide in from left for Tasks
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
            ),
          ),
          GoRoute(
            path: '/settings', // Added settings route
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child:
                  const SettingsPage(), // SettingsPage will now only return its body content
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(
                            1.0,
                            0.0,
                          ), // Slide in from right for Settings
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
            ),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Initialize FCMService after authentication
      if (isAuthenticated) {
        FCMService().initialize(); // Initialize FCM service
      }

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      return null;
    },
  );
});
