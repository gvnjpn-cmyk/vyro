import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AppUtils {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  static String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static Color priorityColor(int priority) {
    switch (priority) {
      case 0:
        return AppTheme.success;
      case 1:
        return AppTheme.warning;
      case 2:
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'School':
        return const Color(0xFF8B5CF6);
      case 'Personal':
        return AppTheme.primary;
      case 'Health':
        return AppTheme.success;
      case 'Work':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  static String categoryEmoji(String category) {
    switch (category) {
      case 'School':
        return '📚';
      case 'Personal':
        return '👤';
      case 'Health':
        return '🏃';
      case 'Work':
        return '💼';
      default:
        return '📌';
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }
}
