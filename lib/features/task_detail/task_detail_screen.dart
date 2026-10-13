import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';
import '../../models/comment.dart';
import '../../models/profile.dart';
import '../../models/task.dart';
import '../../models/task_file.dart';
import '../../models/taxonomy.dart';
import '../../router.dart';
import 'photo_grid.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailData {
  _TaskDetailData({
    required this.task,
    required this.comments,
    required this.files,
    required this.profiles,
    required this.statuses,
    required this.phases,
    required this.photoUrls,
  });

  Task task;
  final List<Comment> comments;
  final List<TaskFile> files;
  final Map<String, Profile> profiles;
  final StatusCatalog statuses;
  final PhaseCatalog phases;

  /// Signed URL per image file_path.
  final Map<String, String> photoUrls;

  List<TaskFile> get photos =>
      files.where((f) => f.isImage).toList();

  List<TaskFile> get otherFiles =>
      files.where((f) => !f.isImage).toList();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Repositories _repos;
  bool _started = false;
  _TaskDetailData? _data;
  Object? _error;
  bool _savingStatus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _repos = RepositoryScope.of(context);
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        _repos.tasks.fetchTask(widget.taskId),
        _repos.comments.fetchForTask(widget.taskId),
        _repos.files.fetchForTask(widget.taskId),
        _repos.profiles.fetchAll(),
        _repos.statuses.fetchCatalog(),
        _repos.phases.fetchCatalog(),
      ]);
      final files = r[2] as List<TaskFile>;
      // A signing failure shouldn't hide the rest of the task; the
      // thumbnails just show as broken.
      final photoUrls = await _repos.files
          .signedUrls([
            for (final f in files)
              if (f.isImage) f.filePath,
          ])
          .catchError((_) => <String, String>{});
      if (!mounted) return;
      setState(() {
        _error = null;
        _data = _TaskDetailData(
          task: r[0] as Task,
          comments: r[1] as List<Comment>,
          files: files,
          profiles: r[3] as Map<String, Profile>,
          statuses: r[4] as StatusCatalog,
          phases: r[5] as PhaseCatalog,
          photoUrls: photoUrls,
        );
      });
    } catch (e) {
      if (!mounted) return;
      if (_data == null) {
        setState(() => _error = e);
      } else {
        _snack(friendlyError(e));
      }
    }
  }

  Future<void> _changeStatus(String value) async {
    final data = _data!;
    if (value == data.task.status) return;
    final previous = data.task;
    setState(() {
      _savingStatus = true;
      data.task = previous.copyWith(status: value); // optimistic
    });
    try {
      final saved = await _repos.tasks.updateStatus(previous.id, value);
      if (mounted) setState(() => data.task = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => data.task = previous);
      _snack("Couldn't update status: ${friendlyError(e)}");
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _addPhoto() async {
    final added = await context.push<bool>(
      Routes.capture(widget.taskId),
      extra: _data?.task.title,
    );
    if (added == true) await _load();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add photo'),
            ),
      body: _error != null
          ? ErrorView(
              error: _error!,
              onRetry: () {
                setState(() => _error = null);
                _load();
              },
            )
          : data == null
              ? const LoadingView()
              : RefreshIndicator(onRefresh: _load, child: _buildContent(data)),
    );
  }

  Widget _buildContent(_TaskDetailData d) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final task = d.task;
    final team = SubTeams.resolve(task.subTeam);
    final assignees = task.assigneeIds
        .map((id) => d.profiles[id] ?? Profile(id: id, fullName: 'Unknown member'))
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(task.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Status (editable)
        _Section(
          title: 'Status',
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(task.status),
                  initialValue: task.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    for (final s in d.statuses.optionsIncluding(task.status))
                      DropdownMenuItem(
                        value: s.value,
                        child: Row(children: [
                          Icon(Icons.circle, size: 12, color: s.color),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ]),
                      ),
                  ],
                  onChanged: _savingStatus ? null : (v) => v == null ? null : _changeStatus(v),
                ),
              ),
              if (_savingStatus) ...[
                const SizedBox(width: 12),
                const SizedBox.square(
                    dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
        ),

        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Priority',
                  child: Pill(
                      label: Priority.label(task.priority),
                      color: Priority.color(task.priority)),
                ),
                _InfoRow(
                  label: 'Phase',
                  child: Pill(label: task.phase, color: d.phases.colorFor(task.phase)),
                ),
                _InfoRow(label: 'Sub-team', child: Pill(label: team.name, color: team.color)),
                _InfoRow(label: 'Start', child: Text(fmtDate(task.startDate))),
                _InfoRow(label: 'Due', last: true, child: Text(fmtDate(task.endDate))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _Section(
          title: 'Description',
          child: Text(
            (task.description?.trim().isNotEmpty ?? false)
                ? task.description!
                : 'No description.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: (task.description?.trim().isNotEmpty ?? false) ? null : muted,
              height: 1.45,
            ),
          ),
        ),

        _Section(
          title: 'Assignees (${assignees.length})',
          child: assignees.isEmpty
              ? Text('Unassigned', style: TextStyle(color: muted))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in assignees)
                      Chip(
                        avatar: CircleAvatar(
                          child: Text(p.displayName.characters.first.toUpperCase()),
                        ),
                        label: Text(p.isPlaceholder
                            ? '${p.displayName} (no account)'
                            : p.displayName),
                      ),
                  ],
                ),
        ),

        _Section(
          title: 'Photos (${d.photos.length})',
          child: d.photos.isEmpty
              ? Text('No photos yet. Tap Add photo to attach one.',
                  style: TextStyle(color: muted))
              : PhotoGrid(photos: d.photos, urls: d.photoUrls),
        ),

        _Section(
          title: 'Other files (${d.otherFiles.length})',
          child: d.otherFiles.isEmpty
              ? Text('No other files attached.', style: TextStyle(color: muted))
              : Card(
                  child: Column(
                    children: [
                      for (final f in d.otherFiles)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.attach_file),
                          title: Text(f.fileName, overflow: TextOverflow.ellipsis),
                          subtitle: Text([
                            if (f.uploaderName != null) f.uploaderName!,
                            if (f.formattedSize.isNotEmpty) f.formattedSize,
                          ].join(' · ')),
                        ),
                    ],
                  ),
                ),
        ),

        _Section(
          title: 'Comments (${d.comments.length})',
          child: d.comments.isEmpty
              ? Text('No comments yet.', style: TextStyle(color: muted))
              : Column(
                  children: [
                    for (final c in d.comments) _CommentTile(comment: c),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            Flexible(child: Align(alignment: Alignment.centerLeft, child: child)),
          ],
        ),
      );
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (comment.authorName?.trim().isNotEmpty ?? false)
        ? comment.authorName!
        : 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(name.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: theme.textTheme.labelLarge,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fmtDate(comment.createdAt, pattern: 'MMM d, h:mm a', fallback: ''),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
