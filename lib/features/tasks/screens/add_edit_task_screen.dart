import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../../../core/constants/app_constants.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const AddEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Personal';
  int _priority = 1;
  DateTime? _dueDate;
  String _repeat = 'none';
  bool _isEditing = false;
  TaskModel? _existingTask;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tasks = ref.read(tasksProvider);
        _existingTask = tasks.firstWhere(
          (t) => t.id == widget.taskId,
          orElse: () => TaskModel(title: ''),
        );
        if (_existingTask != null) {
          _titleController.text = _existingTask!.title;
          _descController.text = _existingTask!.description;
          setState(() {
            _category = _existingTask!.category;
            _priority = _existingTask!.priority;
            _dueDate = _existingTask!.dueDate;
            _repeat = _existingTask!.repeatSchedule ?? 'none';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    if (_isEditing && _existingTask != null) {
      final updated = _existingTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
        repeatSchedule: _repeat,
      );
      await ref.read(tasksProvider.notifier).updateTask(updated);
    } else {
      final task = TaskModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
        repeatSchedule: _repeat,
      );
      await ref.read(tasksProvider.notifier).addTask(task);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
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
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: theme.textTheme.titleMedium,
              decoration: const InputDecoration(
                hintText: 'Task title',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add description (optional)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 32),
            _buildSection(
              context: context,
              icon: Icons.folder_outlined,
              label: 'Category',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.taskCategories.map((cat) {
                  return ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context: context,
              icon: Icons.flag_outlined,
              label: 'Priority',
              child: Row(
                children: [
                  _PriorityChip(
                    label: 'Low',
                    color: AppTheme.success,
                    selected: _priority == 0,
                    onTap: () => setState(() => _priority = 0),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'Medium',
                    color: AppTheme.warning,
                    selected: _priority == 1,
                    onTap: () => setState(() => _priority = 1),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'High',
                    color: AppTheme.danger,
                    selected: _priority == 2,
                    onTap: () => setState(() => _priority = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Due Date',
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    setState(() {
                      _dueDate = time != null
                          ? DateTime(picked.year, picked.month, picked.day,
                              time.hour, time.minute)
                          : picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 16,
                        color: _dueDate != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? DateFormat('EEE, MMM d • h:mm a')
                                .format(_dueDate!)
                            : 'Set due date',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dueDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context: context,
              icon: Icons.repeat_rounded,
              label: 'Repeat',
              child: Wrap(
                spacing: 8,
                children: ['none', 'daily', 'weekly'].map((r) {
                  return ChoiceChip(
                    label: Text(r == 'none'
                        ? 'No repeat'
                        : r[0].toUpperCase() + r.substring(1)),
                    selected: _repeat == r,
                    onSelected: (_) => setState(() => _repeat = r),
                  );
                }).toList(),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text(
                            'Are you sure you want to delete this task?'),
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
                          .read(tasksProvider.notifier)
                          .deleteTask(widget.taskId!);
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger),
                  label: const Text(
                    'Delete Task',
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

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
