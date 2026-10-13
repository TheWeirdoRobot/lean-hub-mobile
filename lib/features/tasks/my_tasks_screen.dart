import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/widgets.dart';
import '../../data/repositories.dart';
import '../../models/profile.dart';
import '../../models/task.dart';
import '../../models/taxonomy.dart';
import '../../router.dart';
import 'task_filter.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  late Repositories _repos;
  Future<void> Function()? _unsubscribe;
  Timer? _debounce;
  int _requestId = 0;

  bool _mineOnly = true;
  TaskFilter _filter = const TaskFilter();

  List<Task>? _tasks;
  Map<String, Profile> _profiles = const {};
  StatusCatalog _statuses = StatusCatalog.defaults;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_unsubscribe != null) return;
    _repos = RepositoryScope.of(context);
    _load();
    // Any change to tasks (from the website or another phone) triggers a
    // quiet reload, debounced so a burst of edits causes one fetch.
    _unsubscribe = _repos.tasks.subscribe(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), _load);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _unsubscribe?.call();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    try {
      final results = await Future.wait([
        _repos.tasks.fetchTasks(),
        _repos.profiles.fetchAll(),
        _repos.statuses.fetchCatalog(),
      ]);
      // Drop responses that were overtaken by a newer request.
      if (!mounted || id != _requestId) return;
      setState(() {
        _tasks = results[0] as List<Task>;
        _profiles = results[1] as Map<String, Profile>;
        _statuses = results[2] as StatusCatalog;
        _error = null;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      if (_tasks == null) {
        setState(() => _error = e);
      } else {
        // Keep showing the last good list; just report the failed refresh.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  void _setMineOnly(bool value) => setState(() => _mineOnly = value);

  String get _userId => _repos.auth.currentUserId ?? '';

  String? get _mySubTeam => _profiles[_userId]?.subTeam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mineOnly ? 'My Tasks' : 'Team Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: _FilterBar(
            mineOnly: _mineOnly,
            onMineOnlyChanged: _setMineOnly,
            filter: _filter,
            statuses: _statuses,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: () {
          setState(() => _error = null);
          _load();
        },
      );
    }
    final all = _tasks;
    if (all == null) return const LoadingView();

    final tasks = _mineOnly
        ? all.where((t) => t.isMineFor(_userId, _mySubTeam)).toList()
        : all;
    final visible = _filter.apply(tasks);
    return RefreshIndicator(
      onRefresh: _load,
      child: visible.isEmpty
          ? _scrollable(_emptyState(tasks.isEmpty))
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TaskCard(
                task: visible[i],
                statuses: _statuses,
                profiles: _profiles,
                isGroupTask: !visible[i].isAssignedTo(_userId) &&
                    visible[i].isGroupTaskFor(_mySubTeam),
                onTap: () => context.go(Routes.task(visible[i].id)),
              ),
            ),
    );
  }

  /// RefreshIndicator needs a scrollable even when there's nothing to show.
  Widget _scrollable(Widget child) => LayoutBuilder(
        builder: (_, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: constraints.maxHeight, child: child)],
        ),
      );

  Widget _emptyState(bool noTasksAtAll) {
    if (!noTasksAtAll) {
      return MessageView(
        icon: Icons.filter_alt_off_outlined,
        title: 'No tasks match these filters',
        actionLabel: 'Clear filters',
        onAction: () => setState(() => _filter = const TaskFilter()),
      );
    }
    if (_mineOnly) {
      return MessageView(
        icon: Icons.inbox_outlined,
        title: 'Nothing assigned to you',
        message: 'Tasks assigned to you, and unassigned tasks for your '
            'sub-team or the full team, show up here.',
        actionLabel: 'Show all team tasks',
        onAction: () => _setMineOnly(false),
      );
    }
    return const MessageView(
      icon: Icons.inbox_outlined,
      title: 'No tasks yet',
      message: 'Create tasks on the LEAN Hub website.',
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.mineOnly,
    required this.onMineOnlyChanged,
    required this.filter,
    required this.statuses,
    required this.onFilterChanged,
  });

  final bool mineOnly;
  final ValueChanged<bool> onMineOnlyChanged;
  final TaskFilter filter;
  final StatusCatalog statuses;
  final ValueChanged<TaskFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Assigned to me'), icon: Icon(Icons.person)),
                ButtonSegment(value: false, label: Text('All team'), icon: Icon(Icons.groups)),
              ],
              selected: {mineOnly},
              onSelectionChanged: (s) => onMineOnlyChanged(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MenuChip<String>(
                  label: filter.subTeam ?? 'All sub-teams',
                  selected: filter.subTeam != null,
                  icon: Icons.group_work_outlined,
                  items: [for (final t in SubTeams.all) (t.name, t.name, t.color)],
                  onSelected: (v) =>
                      onFilterChanged(TaskFilter(subTeam: v, status: filter.status)),
                ),
                const SizedBox(width: 8),
                _MenuChip<String>(
                  label: filter.status == null
                      ? 'All statuses'
                      : statuses.resolve(filter.status!).name,
                  selected: filter.status != null,
                  icon: Icons.flag_outlined,
                  items: [for (final s in statuses.options) (s.value, s.name, s.color)],
                  onSelected: (v) =>
                      onFilterChanged(TaskFilter(subTeam: filter.subTeam, status: v)),
                ),
                if (filter.isActive) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    onPressed: () => onFilterChanged(const TaskFilter()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip that opens a menu of (value, label, color) items plus "All".
class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final List<(T, String, Color)> items;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(onPressed: () => onSelected(null), child: const Text('All')),
        for (final (value, name, color) in items)
          MenuItemButton(
            leadingIcon: Icon(Icons.circle, size: 12, color: color),
            onPressed: () => onSelected(value),
            child: Text(name),
          ),
      ],
      builder: (context, controller, _) => FilterChip(
        avatar: Icon(icon, size: 16),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
        ),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.statuses,
    required this.profiles,
    required this.isGroupTask,
    required this.onTap,
  });

  final Task task;
  final StatusCatalog statuses;
  final Map<String, Profile> profiles;
  final bool isGroupTask;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final status = statuses.resolve(task.status);
    final team = SubTeams.resolve(task.subTeam);
    final names = task.assigneeIds
        .map((id) => profiles[id]?.displayName)
        .whereType<String>()
        .toList();
    final overdue = task.endDate != null &&
        task.status != 'done' &&
        task.endDate!.isBefore(DateUtils.dateOnly(DateTime.now()));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tooltip(
                    message: '${Priority.label(task.priority)} priority',
                    child: Icon(Icons.circle, size: 10, color: Priority.color(task.priority)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(task.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pill(label: status.name, color: status.color, dense: true),
                  Pill(label: team.abbr, color: team.color, dense: true),
                  if (isGroupTask)
                    Pill(label: 'Group task', color: muted, dense: true),
                  if (task.endDate != null)
                    Text(
                      'Due ${fmtDate(task.endDate, pattern: 'MMM d')}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: overdue ? theme.colorScheme.error : muted),
                    ),
                ],
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        names.length <= 2
                            ? names.join(', ')
                            : '${names.take(2).join(', ')} +${names.length - 2}',
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
