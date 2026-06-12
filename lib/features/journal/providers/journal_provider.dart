import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/journal_entry_model.dart';
import '../../../services/database_service.dart';

class JournalNotifier extends StateNotifier<List<JournalEntryModel>> {
  JournalNotifier() : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    state = DatabaseService.journalEntriesBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addEntry(JournalEntryModel entry) async {
    await DatabaseService.journalEntriesBox.put(entry.id, entry);
    _loadEntries();
  }

  Future<void> updateEntry(JournalEntryModel entry) async {
    await DatabaseService.journalEntriesBox.put(entry.id, entry);
    _loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await DatabaseService.journalEntriesBox.delete(id);
    _loadEntries();
  }
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, List<JournalEntryModel>>((ref) {
  return JournalNotifier();
});

final journalByDateProvider =
    Provider.family<List<JournalEntryModel>, DateTime>((ref, date) {
  final entries = ref.watch(journalProvider);
  return entries.where((e) {
    return e.createdAt.year == date.year &&
        e.createdAt.month == date.month &&
        e.createdAt.day == date.day;
  }).toList();
});
