import '../core/dates.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.status = 'not_started',
    this.priority = 'medium',
    this.phase = 'Research',
    this.subTeam = 'Full Team',
    this.assigneeIds = const [],
    this.assignedTo,
    this.startDate,
    this.endDate,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assigned_to'] as String?;
    final ids = (json['assignee_ids'] as List?)?.whereType<String>().toList() ?? [];
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'not_started',
      priority: json['priority'] as String? ?? 'medium',
      phase: json['phase'] as String? ?? 'Research',
      subTeam: json['sub_team'] as String? ?? 'Full Team',
      // assignee_ids is the source of truth; fall back to assigned_to for
      // rows written before the array existed.
      assigneeIds: ids.isEmpty && assignedTo != null ? [assignedTo] : ids,
      assignedTo: assignedTo,
      startDate: parseDbDate(json['start_date']),
      endDate: parseDbDate(json['end_date']),
      createdBy: json['created_by'] as String?,
      createdAt: parseTimestamp(json['created_at']),
      updatedAt: parseTimestamp(json['updated_at']),
    );
  }

  final String id;
  final String title;
  final String? description;

  /// Slug, e.g. `in_progress`. Resolve with StatusCatalog for display.
  final String status;
  final String priority;
  final String phase;
  final String subTeam;
  final List<String> assigneeIds;
  final String? assignedTo;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool isAssignedTo(String userId) => assigneeIds.contains(userId);

  /// Same rule as isGroupTaskFor() in the website's taskPeople.js: nobody is
  /// named on it, and it belongs to the whole team or to [mySubTeam].
  bool isGroupTaskFor(String? mySubTeam) =>
      assigneeIds.isEmpty &&
      (subTeam == 'Full Team' || (mySubTeam != null && subTeam == mySubTeam));

  /// "My tasks" as the website's dashboard counts them.
  bool isMineFor(String userId, String? mySubTeam) =>
      isAssignedTo(userId) || isGroupTaskFor(mySubTeam);

  Task copyWith({String? status}) => Task(
        id: id,
        title: title,
        description: description,
        status: status ?? this.status,
        priority: priority,
        phase: phase,
        subTeam: subTeam,
        assigneeIds: assigneeIds,
        assignedTo: assignedTo,
        startDate: startDate,
        endDate: endDate,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
