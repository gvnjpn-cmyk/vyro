import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../features/tasks/providers/tasks_provider.dart';
import '../../../features/habits/providers/habits_provider.dart';
import '../../../features/focus/providers/focus_provider.dart';
import '../../../shared/widgets/vyro_widgets.dart';
import '../../../models/task_model.dart';
import '../../../models/habit_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final totalFocusMin = ref.watch(totalFocusMinutesProvider);
    final todayTasks = ref.watch(todayTasksProvider);

    final completedToday =
        todayTasks.where((t) => t.completed).length;
    final productivityScore = _calcScore(tasks, habits, totalFocusMin);

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
                    _buildHeader(context, theme),
                    const SizedBox(height: 20),
                    _buildProductivityCard(
                        context, theme, productivityScore, completedToday,
                        todayTasks.length, totalFocusMin),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    VyroSectionHeader(
                      title: "Today's Tasks",
                      actionLabel: 'See all',
                      onAction: () => context.go('/tasks'),
                    ),
                  ],
                ),
              ),
            ),
            if (todayTasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: VyroCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: VyroEmptyState(
                        emoji: '✅',
                        title: 'Nothing due today',
                        subtitle: 'Add tasks with today\'s due date to see them here.',
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskTile(task: todayTasks[i], ref: ref),
                    ),
                    childCount: todayTasks.take(4).length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: VyroSectionHeader(
                  title: "Habits Today",
                  actionLabel: 'See all',
                  onAction: () => context.go('/habits'),
                ),
              ),
            ),
            if (habits.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: VyroCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: VyroEmptyState(
                        emoji: '🔄',
                        title: 'No habits yet',
                        subtitle: 'Track daily habits to build consistency.',
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitTile(habit: habits[i], ref: ref),
                    ),
                    childCount: habits.take(4).length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  int _calcScore(List<TaskModel> tasks, List<HabitModel> habits, int focusMin) {
    int score = 0;
    final now = DateTime.now();
    final todayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
    if (todayTasks.isNotEmpty) {
      final int done = todayTasks.where((t) => t.completed).length;
      final int total = todayTasks.length;
      score += ((done / total) * 40).round();
    } else {
      score += 30;
    }
    if (habits.isNotEmpty) {
      final int doneHabits = habits.where((h) => h.isCompletedToday()).length;
      final int total = habits.length;
      score += ((doneHabits / total) * 40).round();
    } else {
      score += 30;
    }
    score += (((focusMin / 120) * 20).round()).clamp(0, 20);
    return score.clamp(0, 100);
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppUtils.getGreeting()} 👋',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, MMM d').format(now),
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => GoRouter.of(context).go('/settings'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityCard(
    BuildContext context,
    ThemeData theme,
    int score,
    int completedTasks,
    int totalTasks,
    int focusMin,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity Score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ScoreStat(
                      label: 'Tasks',
                      value: '$completedTasks/$totalTasks',
                    ),
                    const SizedBox(width: 16),
                    _ScoreStat(
                      label: 'Focus',
                      value: AppUtils.formatDuration(focusMin),
                    ),
                  ],
                ),
              ],
            ),
          ),
          VyroProgressRing(
            progress: score / 100,
            size: 72,
            strokeWidth: 6,
            color: Colors.white,
            child: Text(
              '${score}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_task_rounded,
          label: 'Add Task',
          color: AppTheme.primary,
          onTap: () => context.push('/tasks/add'),
        ),
        const SizedBox(width: 12),
        _QuickAction(
          icon: Icons.loop_rounded,
          label: 'Add Habit',
          color: AppTheme.success,
          onTap: () => context.push('/habits/add'),
        ),
        const SizedBox(width: 12),
        _QuickAction(
          icon: Icons.timer_rounded,
          label: 'Focus',
          color: AppTheme.warning,
          onTap: () => context.go('/focus'),
        ),
      ],
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final WidgetRef ref;

  const _TaskTile({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VyroCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(tasksProvider.notifier).toggleComplete(task.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: task.completed ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: task.completed
                      ? AppTheme.primary
                      : theme.dividerColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.completed
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                    color: task.completed
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : null,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppUtils.formatTime(task.dueDate!),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          VyroPriorityBadge(priority: task.priority),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final HabitModel habit;
  final WidgetRef ref;

  const _HabitTile({required this.habit, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = habit.isCompletedToday();

    return VyroCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(habit.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '🔥 ${habit.streak} day streak',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(habitsProvider.notifier).checkInToday(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done ? AppTheme.success : Colors.transparent,
                border: Border.all(
                  color: done ? AppTheme.success : theme.dividerColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
