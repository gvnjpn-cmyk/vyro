import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 1)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int streak;

  @HiveField(3)
  List<DateTime> completionHistory;

  @HiveField(4)
  String icon;

  @HiveField(5)
  String color;

  @HiveField(6)
  DateTime createdAt;

  HabitModel({
    String? id,
    required this.name,
    this.streak = 0,
    List<DateTime>? completionHistory,
    this.icon = '⭐',
    this.color = '#60A5FA',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        completionHistory = completionHistory ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final now = DateTime.now();
    return completionHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  double completionRate(int days) {
    if (days == 0) return 0;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final count = completionHistory.where((d) => d.isAfter(cutoff)).length;
    return count / days;
  }

  HabitModel copyWith({
    String? id,
    String? name,
    int? streak,
    List<DateTime>? completionHistory,
    String? icon,
    String? color,
    DateTime? createdAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      streak: streak ?? this.streak,
      completionHistory: completionHistory ?? this.completionHistory,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
