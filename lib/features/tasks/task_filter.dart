import '../../models/task.dart';

/// Client-side filters for the task list. `null` means "any".
class TaskFilter {
  const TaskFilter({this.subTeam, this.status});

  final String? subTeam;

  /// Status slug, e.g. `in_progress`.
  final String? status;

  bool get isActive => subTeam != null || status != null;

  bool matches(Task t) =>
      (subTeam == null || t.subTeam == subTeam) &&
      (status == null || t.status == status);

  List<Task> apply(List<Task> tasks) => tasks.where(matches).toList();
}
