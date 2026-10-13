import 'package:flutter_test/flutter_test.dart';
import 'package:lean_hub/data/file_repository.dart';
import 'package:lean_hub/models/profile.dart';
import 'package:lean_hub/models/task.dart';
import 'package:lean_hub/models/task_file.dart';

void main() {
  group('upload path (must match TaskModal.jsx so the website sees photos)', () {
    test('safeFileName replaces everything outside [a-zA-Z0-9._-]', () {
      expect(FileRepository.safeFileName('IMG_20261013_101500.jpg'),
          'IMG_20261013_101500.jpg');
      expect(FileRepository.safeFileName('wheel photo (1).jpg'), 'wheel_photo__1_.jpg');
      expect(FileRepository.safeFileName('café.png'), 'caf_.png');
    });

    test('taskFilePath is {userId}/{taskId}/{millis}-{safeName}', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1760000000000);
      expect(
        FileRepository.taskFilePath(
            userId: 'user-1', taskId: 'task-9', fileName: 'my pic.jpg', now: now),
        'user-1/task-9/1760000000000-my_pic.jpg',
      );
    });

    test('the first path segment is the uploader id (storage delete policy)', () {
      final path = FileRepository.taskFilePath(
          userId: 'abc', taskId: 't', fileName: 'x.jpg', now: DateTime(2026));
      expect(path.split('/').first, 'abc');
    });
  });

  test('TaskFile.isImage checks the extension case-insensitively', () {
    TaskFile named(String n) => TaskFile(id: 'f', fileName: n, filePath: 'p');
    expect(named('IMG_1.JPG').isImage, isTrue);
    expect(named('photo.heic').isImage, isTrue);
    expect(named('wiring.pdf').isImage, isFalse);
    expect(named('README').isImage, isFalse);
  });

  group('"mine" matches taskPeople.js on the website', () {
    Task task({List<String> ids = const [], String subTeam = 'Full Team'}) =>
        Task.fromJson({'id': 't', 'title': 'x', 'assignee_ids': ids, 'sub_team': subTeam});

    test('tasks naming me are mine regardless of sub-team', () {
      expect(task(ids: ['me'], subTeam: 'Electrical').isMineFor('me', 'CSE'), isTrue);
    });

    test('tasks naming someone else are not mine, even for my sub-team', () {
      expect(task(ids: ['other'], subTeam: 'CSE').isMineFor('me', 'CSE'), isFalse);
    });

    test('unassigned Full Team or my-sub-team tasks are group tasks for me', () {
      expect(task().isGroupTaskFor('CSE'), isTrue);
      expect(task(subTeam: 'CSE').isGroupTaskFor('CSE'), isTrue);
      expect(task(subTeam: 'Mechanical').isGroupTaskFor('CSE'), isFalse);
      expect(task(subTeam: 'Mechanical').isGroupTaskFor(null), isFalse);
    });

    test('Profile reads sub_team, defaulting to Full Team', () {
      expect(Profile.fromJson({'id': 'p', 'full_name': 'A', 'sub_team': 'CSE'}).subTeam,
          'CSE');
      expect(Profile.fromJson({'id': 'p', 'full_name': 'A'}).subTeam, 'Full Team');
    });
  });
}
