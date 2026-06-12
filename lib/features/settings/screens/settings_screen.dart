import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../habits/providers/habits_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../focus/providers/focus_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/task_model.dart';
import '../../../models/habit_model.dart';
import '../../../models/journal_entry_model.dart';
import '../../../models/focus_session_model.dart';
import '../../../shared/widgets/vyro_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          VyroSectionHeader(title: 'Appearance'),
          VyroCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ThemeOption(
                  label: 'Light Mode',
                  icon: Icons.light_mode_outlined,
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1),
                _ThemeOption(
                  label: 'Dark Mode',
                  icon: Icons.dark_mode_outlined,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 1),
                _ThemeOption(
                  label: 'System Default',
                  icon: Icons.brightness_auto_outlined,
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          VyroSectionHeader(title: 'Data Management'),
          VyroCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ActionTile(
                  label: 'Export Data',
                  subtitle: 'Save a backup of all your data',
                  icon: Icons.upload_outlined,
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                _ActionTile(
                  label: 'Import Data',
                  subtitle: 'Restore data from a backup file',
                  icon: Icons.download_outlined,
                  onTap: () => _showImportDialog(context, ref),
                ),
                const Divider(height: 1),
                _ActionTile(
                  label: 'Local Backup',
                  subtitle: 'Backup stored on this device',
                  icon: Icons.backup_outlined,
                  onTap: () => _localBackup(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          VyroSectionHeader(title: 'About'),
          VyroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'V',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vyro', style: theme.textTheme.titleMedium),
                        Text(
                          'Stay Focused. Stay Consistent.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildExportMap() {
    final tasks = DatabaseService.tasksBox.values
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'category': t.category,
              'priority': t.priority,
              'dueDate': t.dueDate?.toIso8601String(),
              'completed': t.completed,
              'createdAt': t.createdAt.toIso8601String(),
              'repeatSchedule': t.repeatSchedule,
            })
        .toList();

    final habits = DatabaseService.habitsBox.values
        .map((h) => {
              'id': h.id,
              'name': h.name,
              'streak': h.streak,
              'completionHistory':
                  h.completionHistory.map((d) => d.toIso8601String()).toList(),
              'icon': h.icon,
              'color': h.color,
              'createdAt': h.createdAt.toIso8601String(),
            })
        .toList();

    final journal = DatabaseService.journalEntriesBox.values
        .map((j) => {
              'id': j.id,
              'title': j.title,
              'content': j.content,
              'mood': j.mood,
              'createdAt': j.createdAt.toIso8601String(),
            })
        .toList();

    final focusSessions = DatabaseService.focusSessionsBox.values
        .map((f) => {
              'id': f.id,
              'durationMinutes': f.durationMinutes,
              'completedAt': f.completedAt.toIso8601String(),
              'wasCompleted': f.wasCompleted,
            })
        .toList();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks,
      'habits': habits,
      'journal': journal,
      'focusSessions': focusSessions,
    };
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final data = _buildExportMap();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data copied to clipboard as JSON')),
      );
    }
  }

  Future<void> _localBackup(BuildContext context, WidgetRef ref) async {
    try {
      final data = _buildExportMap();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/vyro_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste exported JSON data below.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Paste JSON here',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final data = jsonDecode(controller.text);
                await _importData(data, ref);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data imported successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(Map<String, dynamic> data, WidgetRef ref) async {
    if (data['tasks'] != null) {
      for (final t in data['tasks']) {
        final task = TaskModel(
          id: t['id'],
          title: t['title'],
          description: t['description'] ?? '',
          category: t['category'] ?? 'Personal',
          priority: t['priority'] ?? 1,
          dueDate: t['dueDate'] != null ? DateTime.parse(t['dueDate']) : null,
          completed: t['completed'] ?? false,
          createdAt: DateTime.parse(t['createdAt']),
          repeatSchedule: t['repeatSchedule'] ?? 'none',
        );
        await DatabaseService.tasksBox.put(task.id, task);
      }
    }
    if (data['habits'] != null) {
      for (final h in data['habits']) {
        final habit = HabitModel(
          id: h['id'],
          name: h['name'],
          streak: h['streak'] ?? 0,
          completionHistory: (h['completionHistory'] as List)
              .map((d) => DateTime.parse(d))
              .toList(),
          icon: h['icon'] ?? '⭐',
          color: h['color'] ?? '#60A5FA',
          createdAt: DateTime.parse(h['createdAt']),
        );
        await DatabaseService.habitsBox.put(habit.id, habit);
      }
    }
    if (data['journal'] != null) {
      for (final j in data['journal']) {
        final entry = JournalEntryModel(
          id: j['id'],
          title: j['title'] ?? '',
          content: j['content'],
          mood: j['mood'] ?? 2,
          createdAt: DateTime.parse(j['createdAt']),
        );
        await DatabaseService.journalEntriesBox.put(entry.id, entry);
      }
    }
    if (data['focusSessions'] != null) {
      for (final f in data['focusSessions']) {
        final session = FocusSessionModel(
          id: f['id'],
          durationMinutes: f['durationMinutes'],
          completedAt: DateTime.parse(f['completedAt']),
          wasCompleted: f['wasCompleted'] ?? true,
        );
        await DatabaseService.focusSessionsBox.put(session.id, session);
      }
    }

    // Refresh all providers
    ref.invalidate(tasksProvider);
    ref.invalidate(habitsProvider);
    ref.invalidate(journalProvider);
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.primary)
          : null,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(label),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.3)),
    );
  }
}
