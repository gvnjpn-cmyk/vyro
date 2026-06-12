import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/journal_entry_model.dart';
import '../providers/journal_provider.dart';
import '../../../shared/widgets/vyro_widgets.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(journalProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Journal', style: theme.textTheme.titleLarge),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/journal/add'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Write'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(
                child: VyroEmptyState(
                  emoji: '📖',
                  title: 'No entries yet',
                  subtitle:
                      'Writing daily keeps your mind clear and helps you reflect on your progress.',
                  action: ElevatedButton(
                    onPressed: () => context.push('/journal/add'),
                    child: const Text('Write your first entry'),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildMoodSummary(context, theme, entries),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = entries[i];
                      final showDate = i == 0 ||
                          !_isSameDay(
                              entries[i - 1].createdAt, entry.createdAt);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) ...[
                            if (i > 0) const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10, top: 4),
                              child: Text(
                                _formatSectionDate(entry.createdAt),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: JournalCard(entry: entry),
                          ),
                        ],
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatSectionDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildMoodSummary(
      BuildContext context, ThemeData theme, List<JournalEntryModel> entries) {
    final moodCounts = <int, int>{};
    for (final e in entries.take(14)) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
    }

    final mostCommon = moodCounts.entries.isEmpty
        ? null
        : moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);

    return VyroCard(
      child: Row(
        children: [
          if (mostCommon != null)
            Text(
              JournalEntryModel(content: '').copyWith(mood: mostCommon.key)
                  .moodEmoji,
              style: const TextStyle(fontSize: 32),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entries.length} entries total',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  mostCommon != null
                      ? 'Usually feeling ${JournalEntryModel(content: '').copyWith(mood: mostCommon.key).moodLabel}'
                      : 'Start journaling to see your mood trends',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JournalCard extends ConsumerWidget {
  final JournalEntryModel entry;

  const JournalCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.danger),
      ),
      onDismissed: (_) =>
          ref.read(journalProvider.notifier).deleteEntry(entry.id),
      child: VyroCard(
        onTap: () => context.push('/journal/edit/${entry.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.moodEmoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  entry.title.isNotEmpty ? entry.title : 'Journal Entry',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(entry.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _moodColor(entry.mood).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entry.moodLabel,
                style: TextStyle(
                  color: _moodColor(entry.mood),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _moodColor(int mood) {
    switch (mood) {
      case 4:
        return AppTheme.success;
      case 3:
        return AppTheme.primary;
      case 2:
        return const Color(0xFF94A3B8);
      case 1:
        return AppTheme.warning;
      case 0:
        return AppTheme.danger;
      default:
        return AppTheme.primary;
    }
  }
}
