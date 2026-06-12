import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../models/task_model.dart';
import '../../../services/database_service.dart';
import '../../../core/constants/app_constants.dart';

class TasksNotifier extends StateNotifier<List<TaskModel>> {
  TasksNotifier() : super([]) {
    _loadTasks();
  }

  Box<TaskModel> get _box => DatabaseService.tasksBox;

  void _loadTasks() {
    state = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addTask(TaskModel task) async {
    await _box.put(task.id, task);
    _loadTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    await _box.put(task.id, task);
    _loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
    _loadTasks();
  }

  Future<void> toggleComplete(String id) async {
    final task = _box.get(id);
    if (task != null) {
      final updated = task.copyWith(completed: !task.completed);
      await _box.put(id, updated);
      _loadTasks();
    }
  }

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return state.where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<TaskModel> get pendingTasks =>
      state.where((t) => !t.completed).toList();

  List<TaskModel> get completedTasks =>
      state.where((t) => t.completed).toList();

  List<TaskModel> tasksByCategory(String category) =>
      state.where((t) => t.category == category).toList();
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<TaskModel>>((ref) {
  return TasksNotifier();
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.dueDate == null) return false;
    final d = t.dueDate!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
});

final pendingTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(tasksProvider).where((t) => !t.completed).toList();
});

final completedTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref.watch(tasksProvider).where((t) => t.completed).toList();
});
