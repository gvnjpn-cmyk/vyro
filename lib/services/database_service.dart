import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/focus_session_model.dart';
import '../models/journal_entry_model.dart';
import '../core/constants/app_constants.dart';

class DatabaseService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FocusSessionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(JournalEntryModelAdapter());
    }

    // Open boxes
    await Hive.openBox<TaskModel>(AppConstants.tasksBox);
    await Hive.openBox<HabitModel>(AppConstants.habitsBox);
    await Hive.openBox<FocusSessionModel>(AppConstants.focusSessionsBox);
    await Hive.openBox<JournalEntryModel>(AppConstants.journalEntriesBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  static Box<TaskModel> get tasksBox =>
      Hive.box<TaskModel>(AppConstants.tasksBox);
  static Box<HabitModel> get habitsBox =>
      Hive.box<HabitModel>(AppConstants.habitsBox);
  static Box<FocusSessionModel> get focusSessionsBox =>
      Hive.box<FocusSessionModel>(AppConstants.focusSessionsBox);
  static Box<JournalEntryModel> get journalEntriesBox =>
      Hive.box<JournalEntryModel>(AppConstants.journalEntriesBox);
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
}
