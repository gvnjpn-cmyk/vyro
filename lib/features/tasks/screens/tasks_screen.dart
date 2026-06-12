import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../../../shared/widgets/vyro_widgets.dart';
import '../../../core/constants/app_constants.dart';

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _selectedFilterProvider = StateProvider<String>((ref) => 'All');

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allTasks = ref.watch(tasksProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final filter = ref.watch(_selectedFilterProvider);

    var filtered = allTasks.where((t) {
      if (selectedCategory != null && t.category != selectedCategory)
        return false;
      if (filter == 'Pending') return !t.completed;
      if (filter == 'Done') return t.completed;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        return b.priority.compareTo(a.priority);
      });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tasks', style: theme.textTheme.titleLarge),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/tasks/add'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStats(context, theme, allTasks),
                    const SizedBox(height: 16),
                    _buildFilters(context, ref, filter),
                    const SizedBox(height: 12),
                    _buildCategories(context, ref, selectedCategory),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: VyroEmptyState(
                  emoji: '📋',
                  title: 'No tasks here',
                  subtitle: 'Tap "+ New" to create your first task.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(task: filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
      BuildContext context, ThemeData theme, List<TaskModel> tasks) {
    final completed = tasks.where((t) => t.completed).length;
    final pending = tasks.where((t) => !t.completed).length;
    final high = tasks.where((t) => t.priority == 2 && !t.completed).length;

    return Row(
      children: [
        _StatBox(label: 'Total', value: '${tasks.length}', theme: theme),
        const SizedBox(width: 10),
        _StatBox(
          label: 'Done',
          value: '$completed',
          color: AppTheme.success,
          theme: theme,
        ),
        const SizedBox(width: 10),
        _StatBox(
          label: 'Pending',
          value: '$pending',
          color: AppTheme.warning,
          theme: theme,
        ),
        const SizedBox(width: 10),
        _StatBox(
          label: 'High Priority',
          value: '$high',
          color: AppTheme.danger,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, String current) {
    final filters = ['All', 'Pending', 'Done'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: current == f,
                    onSelected: (_) =>
                        ref.read(_selectedFilterProvider.notifier).state = f,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCategories(
      BuildContext context, WidgetRef ref, String? current) {
    final cats = ['All', ...AppConstants.taskCategories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: (c == 'All' && current == null) || c == current,
                    onSelected: (_) {
                      ref.read(_selectedCategoryProvider.notifier).state =
                          c == 'All' ? null : c;
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final ThemeData theme;

  const _StatBox({
    required this.label,
    required this.value,
    this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: c,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOverdue =
        task.dueDate != null && AppUtils.isOverdue(task.dueDate) && !task.completed;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.danger),
      ),
      onDismissed: (_) =>
          ref.read(tasksProvider.notifier).deleteTask(task.id),
      child: VyroCard(
        onTap: () => context.push('/tasks/edit/${task.id}'),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  ref.read(tasksProvider.notifier).toggleComplete(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      task.completed ? AppTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? AppTheme.primary : theme.dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.completed
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      VyroCategoryChip(category: task.category, small: true),
                      if (task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppTheme.danger.withOpacity(0.1)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: isOverdue
                                    ? AppTheme.danger
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppUtils.formatDate(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? AppTheme.danger
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VyroPriorityBadge(priority: task.priority),
          ],
        ),
      ),
    );
  }
}
