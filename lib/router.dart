import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'data/auth_repository.dart';
import 'features/capture/capture_screen.dart';
import 'features/components/components_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/sign_in/sign_in_screen.dart';
import 'features/task_detail/task_detail_screen.dart';
import 'features/tasks/my_tasks_screen.dart';
import 'features/timeline/timeline_screen.dart';

class Routes {
  Routes._();

  static const signIn = '/sign-in';
  static const tasks = '/tasks';
  static const timeline = '/timeline';
  static const components = '/components';
  static const settings = '/settings';

  static String task(String id) => '$tasks/$id';

  /// Pass the task title as `extra` to show it in the app bar.
  static String capture(String taskId) => '$tasks/$taskId/capture';
}

/// Pure redirect rule so it can be unit-tested without Supabase:
/// signed-out users always land on Sign-in; signed-in users never see it.
String? authRedirect({required bool signedIn, required String location}) {
  final atSignIn = location == Routes.signIn;
  if (!signedIn) return atSignIn ? null : Routes.signIn;
  if (atSignIn) return Routes.tasks;
  return null;
}

GoRouter createRouter(AuthRepository auth) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.tasks,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      signedIn: auth.isSignedIn,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tasks,
                builder: (_, _) => const MyTasksScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        TaskDetailScreen(taskId: state.pathParameters['id']!),
                    routes: [
                      // Full screen, above the bottom nav.
                      GoRoute(
                        path: 'capture',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) => CaptureScreen(
                          taskId: state.pathParameters['id']!,
                          taskTitle: state.extra as String?,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.timeline,
                builder: (_, _) => const TimelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.components,
                builder: (_, _) => const ComponentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      // Tapping the current tab again pops back to its root.
      onDestinationSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.view_timeline_outlined),
          selectedIcon: Icon(Icons.view_timeline),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Icons.widgets_outlined),
          selectedIcon: Icon(Icons.widgets),
          label: 'Components',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    ),
  );
}
