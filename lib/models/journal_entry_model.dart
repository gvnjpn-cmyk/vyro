import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'journal_entry_model.g.dart';

@HiveType(typeId: 3)
class JournalEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  int mood; // 0=VeryBad, 1=Bad, 2=Neutral, 3=Good, 4=Excellent

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String title;

  JournalEntryModel({
    String? id,
    required this.content,
    this.mood = 2,
    DateTime? createdAt,
    this.title = '',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get moodLabel {
    switch (mood) {
      case 0:
        return 'Very Bad';
      case 1:
        return 'Bad';
      case 2:
        return 'Neutral';
      case 3:
        return 'Good';
      case 4:
        return 'Excellent';
      default:
        return 'Neutral';
    }
  }

  String get moodEmoji {
    switch (mood) {
      case 0:
        return '😞';
      case 1:
        return '😕';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😄';
      default:
        return '😐';
    }
  }

  JournalEntryModel copyWith({
    String? id,
    String? content,
    int? mood,
    DateTime? createdAt,
    String? title,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }
}
