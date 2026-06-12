import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/journal_entry_model.dart';
import '../providers/journal_provider.dart';

const _moodLabels = ['Very Bad', 'Bad', 'Neutral', 'Good', 'Excellent'];
const _moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];

class AddEditJournalScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const AddEditJournalScreen({super.key, this.entryId});

  @override
  ConsumerState<AddEditJournalScreen> createState() =>
      _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends ConsumerState<AddEditJournalScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _mood = 2;
  bool _isEditing = false;
  JournalEntryModel? _existingEntry;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final entries = ref.read(journalProvider);
        _existingEntry = entries.firstWhere(
          (e) => e.id == widget.entryId,
          orElse: () => JournalEntryModel(content: ''),
        );
        if (_existingEntry != null) {
          _titleController.text = _existingEntry!.title;
          _contentController.text = _existingEntry!.content;
          setState(() => _mood = _existingEntry!.mood);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving')),
      );
      return;
    }

    if (_isEditing && _existingEntry != null) {
      final updated = _existingEntry!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _mood,
      );
      await ref.read(journalProvider.notifier).updateEntry(updated);
    } else {
      final entry = JournalEntryModel(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _mood,
      );
      await ref.read(journalProvider.notifier).addEntry(entry);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
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
            Text('How are you feeling?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final selected = _mood == i;
                return GestureDetector(
                  onTap: () => setState(() => _mood = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 64,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withOpacity(0.12)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : theme.dividerColor,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_moodEmojis[i],
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          _moodLabels[i],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.primary
                                : theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 32),
            TextField(
              controller: _titleController,
              style: theme.textTheme.titleMedium,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              autofocus: !_isEditing,
              minLines: 8,
              maxLines: 20,
              decoration: InputDecoration(
                hintText: "What's on your mind today?",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Entry'),
                        content: const Text(
                            'Are you sure you want to delete this journal entry?'),
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
                          .read(journalProvider.notifier)
                          .deleteEntry(widget.entryId!);
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger),
                  label: const Text(
                    'Delete Entry',
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
