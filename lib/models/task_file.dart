import '../core/dates.dart';

/// A row in the `files` table. The object itself lives in the private
/// `task-files` bucket at [filePath] (`{userId}/{taskId}/{timestamp}-{safeName}`).
class TaskFile {
  const TaskFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.taskId,
    this.uploadedBy,
    this.uploaderName,
    this.fileSize,
    this.createdAt,
  });

  /// Expects the shape returned by `select('*, profiles(full_name)')`.
  factory TaskFile.fromJson(Map<String, dynamic> json) => TaskFile(
        id: json['id'] as String,
        taskId: json['task_id'] as String?,
        uploadedBy: json['uploaded_by'] as String?,
        uploaderName: (json['profiles'] as Map?)?['full_name'] as String?,
        fileName: json['file_name'] as String? ?? '',
        filePath: json['file_path'] as String? ?? '',
        fileSize: (json['file_size'] as num?)?.toInt(),
        createdAt: parseTimestamp(json['created_at']),
      );

  final String id;
  final String? taskId;
  final String? uploadedBy;
  final String? uploaderName;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final DateTime? createdAt;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};

  /// Image types get a thumbnail; same extension list as the web's Files page
  /// (minus svg, which Flutter can't decode) plus heic.
  bool get isImage {
    final dot = fileName.lastIndexOf('.');
    return dot != -1 &&
        _imageExtensions.contains(fileName.substring(dot + 1).toLowerCase());
  }

  /// Same output as formatBytes() in TaskModal.jsx.
  String get formattedSize {
    final b = fileSize;
    if (b == null || b == 0) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
