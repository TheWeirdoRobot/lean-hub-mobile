import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../data/repositories.dart';

/// Placeholder until the real settings (Wi-Fi-only uploads, photo quality,
/// default sub-team, theme) arrive. Sign out is here so auth can be tested.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = RepositoryScope.of(context).auth;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Signed in as'),
            subtitle: Text(auth.currentEmail ?? '—'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              try {
                await auth.signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(friendlyError(e))));
              }
            },
          ),
          const Divider(),
          const SizedBox(
            height: 220,
            child: MessageView(
              icon: Icons.tune,
              title: 'More settings coming soon',
              message: 'Wi-Fi-only uploads, photo quality, default sub-team and theme.',
            ),
          ),
        ],
      ),
    );
  }
}
