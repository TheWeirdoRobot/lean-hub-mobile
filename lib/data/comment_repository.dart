import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment.dart';

class CommentRepository {
  CommentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Comment>> fetchForTask(String taskId) async {
    final rows = await _client
        .from('comments')
        .select('*, profiles(full_name)')
        .eq('task_id', taskId)
        .order('created_at', ascending: true);
    return rows.map(Comment.fromJson).toList();
  }

  Future<void> add({
    required String taskId,
    required String authorId,
    required String content,
  }) =>
      _client.from('comments').insert({
        'task_id': taskId,
        'author_id': authorId,
        'content': content,
      });
}
