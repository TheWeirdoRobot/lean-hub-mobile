import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'comment_repository.dart';
import 'file_repository.dart';
import 'phase_repository.dart';
import 'profile_repository.dart';
import 'status_repository.dart';
import 'task_repository.dart';

/// All repositories, created once in main() and handed down the tree.
class Repositories {
  Repositories(SupabaseClient client)
      : auth = AuthRepository(client),
        tasks = TaskRepository(client),
        profiles = ProfileRepository(client),
        comments = CommentRepository(client),
        files = FileRepository(client),
        statuses = StatusRepository(client),
        phases = PhaseRepository(client);

  final AuthRepository auth;
  final TaskRepository tasks;
  final ProfileRepository profiles;
  final CommentRepository comments;
  final FileRepository files;
  final StatusRepository statuses;
  final PhaseRepository phases;
}

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({super.key, required this.repos, required super.child});

  final Repositories repos;

  static Repositories of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepositoryScope>()!.repos;

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) => repos != oldWidget.repos;
}
