class AppConstants {
  static const String appName = 'Vyro';
  static const String appTagline = 'Stay Focused. Stay Consistent.';

  // Hive Box Names
  static const String tasksBox = 'tasks';
  static const String habitsBox = 'habits';
  static const String focusSessionsBox = 'focus_sessions';
  static const String journalEntriesBox = 'journal_entries';
  static const String settingsBox = 'settings';

  // Settings Keys
  static const String themeKey = 'theme_mode';
  static const String notificationsKey = 'notifications_enabled';

  // Task Categories
  static const List<String> taskCategories = [
    'Personal',
    'School',
    'Health',
    'Work',
    'Other',
  ];

  static const List<String> categoryEmojis = [
    '👤',
    '📚',
    '🏃',
    '💼',
    '📌',
  ];

  // Priorities
  static const List<String> priorities = ['Low', 'Medium', 'High'];

  // Default Focus Duration
  static const int defaultFocusMinutes = 25;
  static const int defaultBreakMinutes = 5;

  // Notification IDs
  static const int taskNotificationId = 1000;
  static const int habitNotificationId = 2000;
  static const int focusNotificationId = 3000;
  static const int sleepNotificationId = 4000;
}
