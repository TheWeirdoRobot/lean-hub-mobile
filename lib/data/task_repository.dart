import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

class TaskRepository {
  TaskRepository(this._client);

  final SupabaseClient _client;

  /// All tasks, soonest due first. "Mine" is decided client-side with
  /// Task.isMineFor because it also counts unassigned group tasks, which a
  /// single PostgREST filter can't express cleanly.
  Future<List<Task>> fetchTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .order('end_date', ascending: true, nullsFirst: false);
    return rows.map(Task.fromJson).toList();
  }

  Future<Task> fetchTask(String id) async {
    final row = await _client.from('tasks').select().eq('id', id).single();
    return Task.fromJson(row);
  }

  /// Writes the status slug only; assignees and other columns are untouched.
  Future<Task> updateStatus(String id, String statusValue) async {
    final row = await _client
        .from('tasks')
        .update({'status': statusValue})
        .eq('id', id)
        .select()
        .single();
    return Task.fromJson(row);
  }

  /// Calls [onChange] for any insert/update/delete on `tasks`.
  /// Returns a function that unsubscribes.
  Future<void> Function() subscribe(void Function() onChange) {
    final channel = _client
        .channel('mobile-tasks-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          callback: (_) => onChange(),
        )
        .subscribe();
    return () => _client.removeChannel(channel);
  }
}
