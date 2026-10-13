import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../data/repositories.dart';
import '../../models/app_settings.dart';
import '../../models/taxonomy.dart';

/// Device-local preferences (shared_preferences) plus account actions.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repos = RepositoryScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: repos.settings,
        builder: (context, _) {
          final s = repos.settings.value;
          void save(AppSettings next) => repos.settings.update(next);

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const _Header('Uploads'),
              SwitchListTile(
                secondary: const Icon(Icons.wifi),
                title: const Text('Wi-Fi-only uploads'),
                subtitle: const Text('Ask before uploading photos over cellular data'),
                value: s.wifiOnlyUploads,
                onChanged: (v) => save(s.copyWith(wifiOnlyUploads: v)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_size_select_large),
                title: const Text('Photo quality'),
                subtitle: Text(s.photoQuality.description),
                trailing: _Menu<PhotoQuality>(
                  value: s.photoQuality,
                  items: {for (final q in PhotoQuality.values) q: q.label},
                  onSelected: (q) => save(s.copyWith(photoQuality: q)),
                ),
              ),

              const _Header('Tasks'),
              ListTile(
                leading: const Icon(Icons.group_work_outlined),
                title: const Text('Default sub-team filter'),
                subtitle: const Text('Pre-selected when My Tasks opens'),
                trailing: _Menu<String?>(
                  value: s.defaultSubTeam,
                  items: {
                    null: 'All',
                    for (final t in SubTeams.all) t.name: t.name,
                  },
                  onSelected: (t) => save(s.copyWith(defaultSubTeam: () => t)),
                ),
              ),

              const _Header('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemePreference>(
                  segments: [
                    for (final t in ThemePreference.values)
                      ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {s.theme},
                  onSelectionChanged: (sel) => save(s.copyWith(theme: sel.first)),
                  showSelectedIcon: false,
                ),
              ),

              const _Header('Account'),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Signed in as'),
                subtitle: Text(repos.auth.currentEmail ?? '—'),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Sign out',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _signOut(context, repos),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, Repositories repos) async {
    try {
      await repos.auth.signOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.8,
              ),
        ),
      );
}

/// A compact dropdown showing the current choice, for the end of a ListTile.
class _Menu<T> extends StatelessWidget {
  const _Menu({required this.value, required this.items, required this.onSelected});

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        menuChildren: [
          for (final MapEntry(:key, value: label) in items.entries)
            MenuItemButton(
              leadingIcon: Icon(key == value ? Icons.check : null, size: 18),
              onPressed: () => onSelected(key),
              child: Text(label),
            ),
        ],
        builder: (context, controller, _) => TextButton.icon(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_drop_down),
          label: Text(items[value] ?? ''),
        ),
      );
}
