import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/habit_model.dart';
import '../providers/habits_provider.dart';
import '../../../shared/widgets/vyro_widgets.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final completionRate = ref.watch(todayHabitsCompletionProvider);

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
                        Text('Habits', style: theme.textTheme.titleLarge),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/habits/add'),
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
                    if (habits.isNotEmpty) ...[
                      _buildSummaryCard(
                          context, theme, habits, completionRate),
                      const SizedBox(height: 20),
                    ],
                    VyroSectionHeader(title: "Today's Habits"),
                  ],
                ),
              ),
            ),
            if (habits.isEmpty)
              SliverFillRemaining(
                child: VyroEmptyState(
                  emoji: '🔄',
                  title: 'No habits yet',
                  subtitle:
                      'Build consistency by tracking daily habits like studying, exercise, or hydration.',
                  action: ElevatedButton(
                    onPressed: () => context.push('/habits/add'),
                    child: const Text('Create your first habit'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HabitCard(habit: habits[i]),
                    ),
                    childCount: habits.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ThemeData theme,
      List<HabitModel> habits, double completionRate) {
    final doneCount = habits.where((h) => h.isCompletedToday()).length;
    final bestStreak =
        habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return VyroCard(
      child: Row(
        children: [
          VyroProgressRing(
            progress: completionRate,
            size: 72,
            strokeWidth: 6,
            color: AppTheme.success,
            child: Text(
              '${(completionRate * 100).round()}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$doneCount/${habits.length} done today',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Best streak: $bestStreak days 🔥',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: AppTheme.success.withOpacity(0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.success),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HabitCard extends ConsumerWidget {
  final HabitModel habit;

  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = habit.isCompletedToday();
    final last7 = _getLast7Days(habit);

    return Dismissible(
      key: Key(habit.id),
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
          ref.read(habitsProvider.notifier).deleteHabit(habit.id),
      child: VyroCard(
        onTap: () => context.push('/habits/edit/${habit.id}'),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child:
                        Text(habit.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.streak} day streak',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(habitsProvider.notifier)
                      .checkInToday(habit.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: done ? AppTheme.success : Colors.transparent,
                      border: Border.all(
                        color:
                            done ? AppTheme.success : theme.dividerColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: last7.map((completed) {
                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppTheme.success
                        : AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  List<bool> _getLast7Days(HabitModel habit) {
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return habit.completionHistory.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
      );
    });
  }
}
