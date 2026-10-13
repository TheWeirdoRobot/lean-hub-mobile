import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_file.dart';

/// The `files` table and the private `task-files` storage bucket.
///
/// Uploads follow the website's convention in TaskModal.jsx so they show up
/// there: object path `{userId}/{taskId}/{timestamp}-{safeName}`, then a
/// `files` row with task_id, uploaded_by, file_name, file_path, file_size.
class FileRepository {
  FileRepository(this._client);

  static const bucket = 'task-files';

  final SupabaseClient _client;

  /// Same as `file.name.replace(/[^a-zA-Z0-9._-]/g, '_')` on the web.
  static String safeFileName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  /// Storage path for a task attachment, matching TaskModal.jsx exactly.
  static String taskFilePath({
    required String userId,
    required String taskId,
    required String fileName,
    required DateTime now,
  }) =>
      '$userId/$taskId/${now.millisecondsSinceEpoch}-${safeFileName(fileName)}';

  Future<List<TaskFile>> fetchForTask(String taskId) async {
    final rows = await _client
        .from('files')
        .select('*, profiles(full_name)')
        .eq('task_id', taskId)
        .order('created_at', ascending: false);
    return rows.map(TaskFile.fromJson).toList();
  }

  /// Uploads [bytes] and records them in `files`. If the row can't be
  /// inserted, the orphaned object is removed so storage stays in sync.
  Future<void> uploadToTask({
    required String userId,
    required String taskId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = taskFilePath(
        userId: userId, taskId: taskId, fileName: fileName, now: DateTime.now());
    final storage = _client.storage.from(bucket);
    await storage.uploadBinary(path, bytes,
        fileOptions: FileOptions(contentType: contentType));
    try {
      await _client.from('files').insert({
        'task_id': taskId,
        'uploaded_by': userId,
        'file_name': fileName,
        'file_path': path,
        'file_size': bytes.length,
      });
    } catch (_) {
      await storage.remove([path]).catchError((_) => <FileObject>[]);
      rethrow;
    }
  }

  /// Short-lived URLs for reading private objects, keyed by file path.
  /// Paths whose object is missing from storage are left out.
  Future<Map<String, String>> signedUrls(List<String> paths,
      {int expiresInSeconds = 3600}) async {
    if (paths.isEmpty) return const {};
    final results = await _client.storage
        .from(bucket)
        .createSignedUrlsResult(paths, expiresInSeconds);
    return {
      for (final r in results)
        if (r case SignedUrlSuccess(:final path, :final signedUrl)) path: signedUrl,
    };
  }
}
