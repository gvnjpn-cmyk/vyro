import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../models/habit_model.dart';
import '../../../services/database_service.dart';

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  HabitsNotifier() : super([]) {
    _loadHabits();
  }

  Box<HabitModel> get _box => DatabaseService.habitsBox;

  void _loadHabits() {
    state = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    _loadHabits();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    _loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
    _loadHabits();
  }

  Future<void> checkInToday(String id) async {
    final habit = _box.get(id);
    if (habit == null) return;

    final now = DateTime.now();
    final alreadyDone = habit.completionHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );

    if (alreadyDone) {
      // Un-check
      final updated = habit.copyWith(
        completionHistory: habit.completionHistory
            .where((d) =>
                !(d.year == now.year &&
                    d.month == now.month &&
                    d.day == now.day))
            .toList(),
        streak: habit.streak > 0 ? habit.streak - 1 : 0,
      );
      await _box.put(id, updated);
    } else {
      // Check in
      final history = List<DateTime>.from(habit.completionHistory)..add(now);
      final streak = _calculateStreak(history);
      final updated = habit.copyWith(
        completionHistory: history,
        streak: streak,
      );
      await _box.put(id, updated);
    }
    _loadHabits();
  }

  int _calculateStreak(List<DateTime> history) {
    if (history.isEmpty) return 0;
    final sorted = history..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = DateTime.now();

    for (final date in sorted) {
      final diff = DateTime(current.year, current.month, current.day)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        current = date;
      } else {
        break;
      }
    }
    return streak;
  }

  int get bestStreak {
    if (state.isEmpty) return 0;
    return state.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
  }

  double get todayCompletionRate {
    if (state.isEmpty) return 0;
    final completed = state.where((h) => h.isCompletedToday()).length;
    return completed / state.length;
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  return HabitsNotifier();
});

final todayHabitsCompletionProvider = Provider<double>((ref) {
  final habits = ref.watch(habitsProvider);
  if (habits.isEmpty) return 0;
  final completed = habits.where((h) => h.isCompletedToday()).length;
  return completed / habits.length;
});
