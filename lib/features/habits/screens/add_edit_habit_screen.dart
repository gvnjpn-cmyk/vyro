import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/habit_model.dart';
import '../providers/habits_provider.dart';

const _icons = ['⭐', '📚', '🏃', '💧', '😴', '🧘', '💪', '🎯', '🍎', '✍️', '🎵', '🧹'];

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final String? habitId;

  const AddEditHabitScreen({super.key, this.habitId});

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _nameController = TextEditingController();
  String _icon = '⭐';
  bool _isEditing = false;
  HabitModel? _existingHabit;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final habits = ref.read(habitsProvider);
        _existingHabit =
            habits.firstWhere((h) => h.id == widget.habitId,
                orElse: () => HabitModel(name: ''));
        if (_existingHabit != null) {
          _nameController.text = _existingHabit!.name;
          setState(() => _icon = _existingHabit!.icon);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    if (_isEditing && _existingHabit != null) {
      final updated = _existingHabit!.copyWith(
        name: _nameController.text.trim(),
        icon: _icon,
      );
      await ref.read(habitsProvider.notifier).updateHabit(updated);
    } else {
      final habit = HabitModel(
        name: _nameController.text.trim(),
        icon: _icon,
      );
      await ref.read(habitsProvider.notifier).addHabit(habit);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(_icon, style: const TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: theme.textTheme.titleMedium,
              decoration: const InputDecoration(
                hintText: 'Habit name',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 32),
            Text(
              'Choose an icon',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, i) {
                final icon = _icons[i];
                final selected = _icon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.15)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : theme.dividerColor,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
            if (_isEditing) ...[
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Habit'),
                        content: const Text(
                            'This will permanently delete the habit and all history.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await ref
                          .read(habitsProvider.notifier)
                          .deleteHabit(widget.habitId!);
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger),
                  label: const Text(
                    'Delete Habit',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
