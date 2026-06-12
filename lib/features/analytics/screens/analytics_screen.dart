import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../habits/providers/habits_provider.dart';
import '../../focus/providers/focus_provider.dart';
import '../../../shared/widgets/vyro_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final sessions = ref.watch(focusSessionsProvider);
    final totalFocusMin = ref.watch(totalFocusMinutesProvider);

    final completedTasks = tasks.where((t) => t.completed).length;
    final habitSuccessRate = habits.isEmpty
        ? 0.0
        : habits.map((h) => h.completionRate(30)).reduce((a, b) => a + b) /
            habits.length;
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Analytics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricCard(
                  icon: Icons.check_circle_outline,
                  label: 'Completed Tasks',
                  value: '$completedTasks',
                  color: AppTheme.primary,
                ),
                _MetricCard(
                  icon: Icons.loop_rounded,
                  label: 'Habit Success Rate',
                  value: '${(habitSuccessRate * 100).round()}%',
                  color: AppTheme.success,
                ),
                _MetricCard(
                  icon: Icons.timer_outlined,
                  label: 'Total Focus Time',
                  value: AppUtils.formatDuration(totalFocusMin),
                  color: AppTheme.warning,
                ),
                _MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Best Streak',
                  value: '$bestStreak days',
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 28),
            VyroSectionHeader(title: 'This Week'),
            VyroCard(
              child: SizedBox(
                height: 200,
                child: _WeeklyFocusChart(sessions: sessions, theme: theme),
              ),
            ),
            const SizedBox(height: 28),
            VyroSectionHeader(title: 'Monthly Task Completion'),
            VyroCard(
              child: SizedBox(
                height: 200,
                child: _MonthlyTasksChart(tasks: tasks, theme: theme),
              ),
            ),
            const SizedBox(height: 28),
            if (habits.isNotEmpty) ...[
              VyroSectionHeader(title: 'Habit Performance'),
              ...habits.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HabitProgressBar(
                      name: h.name,
                      icon: h.icon,
                      rate: h.completionRate(7),
                      theme: theme,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyFocusChart extends StatelessWidget {
  final List sessions;
  final ThemeData theme;

  const _WeeklyFocusChart({required this.sessions, required this.theme});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailyMinutes = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return sessions
          .where((s) => AppUtils.isSameDay(s.completedAt, day))
          .fold<int>(0, (sum, s) => sum + (s.durationMinutes as int));
    });

    final maxY = (dailyMinutes.isEmpty
                ? 60
                : dailyMinutes.reduce((a, b) => a > b ? a : b))
            .toDouble() +
        20;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyMinutes[i].toDouble(),
                color: AppTheme.primary,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MonthlyTasksChart extends StatelessWidget {
  final List tasks;
  final ThemeData theme;

  const _MonthlyTasksChart({required this.tasks, required this.theme});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Last 4 weeks
    final weeklyCompleted = List.generate(4, (i) {
      final weekStart = now.subtract(Duration(days: (3 - i) * 7 + 6));
      final weekEnd = now.subtract(Duration(days: (3 - i) * 7));
      return tasks.where((t) {
        if (!t.completed) return false;
        return t.createdAt.isAfter(weekStart) &&
            t.createdAt.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;
    });

    final maxY = (weeklyCompleted.isEmpty
                ? 10
                : weeklyCompleted.reduce((a, b) => a > b ? a : b))
            .toDouble() +
        2;

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'W${value.toInt() + 1}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              4,
              (i) => FlSpot(i.toDouble(), weeklyCompleted[i].toDouble()),
            ),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitProgressBar extends StatelessWidget {
  final String name;
  final String icon;
  final double rate;
  final ThemeData theme;

  const _HabitProgressBar({
    required this.name,
    required this.icon,
    required this.rate,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return VyroCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0, 1),
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(rate * 100).round()}%',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
