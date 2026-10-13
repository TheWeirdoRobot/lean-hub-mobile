import 'package:flutter_test/flutter_test.dart';
import 'package:lean_hub/features/tasks/task_filter.dart';
import 'package:lean_hub/models/comment.dart';
import 'package:lean_hub/models/profile.dart';
import 'package:lean_hub/models/task.dart';
import 'package:lean_hub/models/task_file.dart';

void main() {
  group('Task.fromJson', () {
    test('reads a full row', () {
      final t = Task.fromJson({
        'id': 't1',
        'title': 'Build frame',
        'description': 'Weld it',
        'status': 'in_progress',
        'priority': 'high',
        'phase': 'Fabrication',
        'sub_team': 'Mechanical',
        'assignee_ids': ['u1', 'u2'],
        'assigned_to': 'u1',
        'start_date': '2026-09-01',
        'end_date': '2026-10-15',
        'created_at': '2026-08-30T12:00:00Z',
      });
      expect(t.title, 'Build frame');
      expect(t.status, 'in_progress');
      expect(t.subTeam, 'Mechanical');
      expect(t.assigneeIds, ['u1', 'u2']);
      expect(t.isAssignedTo('u2'), isTrue);
      expect(t.endDate, DateTime(2026, 10, 15));
    });

    test('assignee_ids wins over assigned_to; falls back when missing', () {
      expect(
        Task.fromJson({'id': 'a', 'title': 'x', 'assignee_ids': [], 'assigned_to': 'u9'})
            .assigneeIds,
        ['u9'],
      );
      expect(
        Task.fromJson({'id': 'a', 'title': 'x', 'assignee_ids': null}).assigneeIds,
        isEmpty,
      );
    });

    test('applies column defaults for nulls', () {
      final t = Task.fromJson({'id': 'a', 'title': 'x'});
      expect(t.status, 'not_started');
      expect(t.priority, 'medium');
      expect(t.subTeam, 'Full Team');
    });

    test('malformed or out-of-range dates become null (like the web)', () {
      final t = Task.fromJson({
        'id': 'a',
        'title': 'x',
        'start_date': '20255-01-01',
        'end_date': '0202-03-04',
      });
      expect(t.startDate, isNull);
      expect(t.endDate, isNull);
    });

    test('copyWith only changes status', () {
      final t = Task.fromJson({'id': 'a', 'title': 'x', 'assignee_ids': ['u1']});
      final u = t.copyWith(status: 'done');
      expect(u.status, 'done');
      expect(u.assigneeIds, ['u1']);
    });
  });

  test('Profile reads is_placeholder and has a display name fallback', () {
    final p = Profile.fromJson({'id': 'p1', 'full_name': '', 'is_placeholder': true});
    expect(p.isPlaceholder, isTrue);
    expect(p.displayName, 'Unnamed member');
    expect(Profile.fromJson({'id': 'p2', 'full_name': 'Ada'}).isPlaceholder, isFalse);
  });

  test('Comment reads the embedded profile name', () {
    final c = Comment.fromJson({
      'id': 'c1',
      'task_id': 't1',
      'author_id': 'u1',
      'content': 'Looks good',
      'profiles': {'full_name': 'Ada'},
    });
    expect(c.authorName, 'Ada');
    expect(c.content, 'Looks good');
  });

  group('TaskFile', () {
    test('reads a files row', () {
      final f = TaskFile.fromJson({
        'id': 'f1',
        'task_id': 't1',
        'uploaded_by': 'u1',
        'file_name': 'frame.jpg',
        'file_path': 'u1/t1/1700000000000-frame.jpg',
        'file_size': 2048,
        'profiles': null,
      });
      expect(f.filePath, 'u1/t1/1700000000000-frame.jpg');
      expect(f.uploaderName, isNull);
    });

    test('formattedSize matches formatBytes() on the web', () {
      TaskFile sized(int? n) =>
          TaskFile(id: 'f', fileName: 'a', filePath: 'b', fileSize: n);
      expect(sized(null).formattedSize, '');
      expect(sized(512).formattedSize, '512 B');
      expect(sized(2048).formattedSize, '2.0 KB');
      expect(sized(3 * 1024 * 1024).formattedSize, '3.0 MB');
    });
  });

  test('TaskFilter matches sub-team and status slug', () {
    final tasks = [
      Task.fromJson({'id': '1', 'title': 'a', 'sub_team': 'Mechanical', 'status': 'done'}),
      Task.fromJson({'id': '2', 'title': 'b', 'sub_team': 'CSE', 'status': 'done'}),
      Task.fromJson({'id': '3', 'title': 'c', 'sub_team': 'CSE', 'status': 'review'}),
    ];
    expect(const TaskFilter().apply(tasks), hasLength(3));
    expect(const TaskFilter(subTeam: 'CSE').apply(tasks).map((t) => t.id), ['2', '3']);
    expect(const TaskFilter(subTeam: 'CSE', status: 'done').apply(tasks).single.id, '2');
  });
}
