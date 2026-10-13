import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  final (settings, _) = await (
    SettingsRepository.load(),
    Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey),
  ).wait;
  runApp(LeanHubApp(client: Supabase.instance.client, settings: settings));
}
