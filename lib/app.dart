import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/widgets.dart';
import 'data/repositories.dart';
import 'router.dart';

class LeanHubApp extends StatefulWidget {
  const LeanHubApp({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<LeanHubApp> createState() => _LeanHubAppState();
}

class _LeanHubAppState extends State<LeanHubApp> {
  late final Repositories _repos = Repositories(widget.client);
  late final GoRouter _router = createRouter(_repos.auth);

  @override
  void dispose() {
    _router.dispose();
    _repos.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryScope(
        repos: _repos,
        child: MaterialApp.router(
          title: 'LEAN Hub',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: _router,
        ),
      );
}

/// Shown when the app was built without --dart-define-from-file.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: MessageView(
            icon: Icons.settings_suggest_outlined,
            title: 'Supabase is not configured',
            message: 'Run with --dart-define-from-file=env.json.\n'
                'See README.md for setup steps.',
          ),
        ),
      );
}
