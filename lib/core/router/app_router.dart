import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/tasks/screens/add_edit_task_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/habits/screens/add_edit_habit_screen.dart';
import '../../features/focus/screens/focus_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/journal/screens/add_edit_journal_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/habits',
          name: 'habits',
          builder: (context, state) => const HabitsScreen(),
        ),
        GoRoute(
          path: '/focus',
          name: 'focus',
          builder: (context, state) => const FocusScreen(),
        ),
        GoRoute(
          path: '/journal',
          name: 'journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/tasks/add',
      name: 'add-task',
      builder: (context, state) => const AddEditTaskScreen(),
    ),
    GoRoute(
      path: '/tasks/edit/:id',
      name: 'edit-task',
      builder: (context, state) => AddEditTaskScreen(
        taskId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/habits/add',
      name: 'add-habit',
      builder: (context, state) => const AddEditHabitScreen(),
    ),
    GoRoute(
      path: '/habits/edit/:id',
      name: 'edit-habit',
      builder: (context, state) => AddEditHabitScreen(
        habitId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/journal/add',
      name: 'add-journal',
      builder: (context, state) => const AddEditJournalScreen(),
    ),
    GoRoute(
      path: '/journal/edit/:id',
      name: 'edit-journal',
      builder: (context, state) => AddEditJournalScreen(
        entryId: state.pathParameters['id'],
      ),
    ),
  ],
);
