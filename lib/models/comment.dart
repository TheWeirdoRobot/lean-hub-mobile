import '../core/dates.dart';

class Comment {
  const Comment({
    required this.id,
    required this.taskId,
    required this.content,
    this.authorId,
    this.authorName,
    this.createdAt,
  });

  /// Expects the shape returned by `select('*, profiles(full_name)')`.
  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        taskId: json['task_id'] as String,
        content: json['content'] as String? ?? '',
        authorId: json['author_id'] as String?,
        authorName: (json['profiles'] as Map?)?['full_name'] as String?,
        createdAt: parseTimestamp(json['created_at']),
      );

  final String id;
  final String taskId;
  final String content;
  final String? authorId;
  final String? authorName;
  final DateTime? createdAt;
}
