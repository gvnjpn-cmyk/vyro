import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String category;

  @HiveField(4)
  int priority; // 0=Low, 1=Medium, 2=High

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  bool completed;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String? repeatSchedule; // 'daily','weekly','none'

  TaskModel({
    String? id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = 1,
    this.dueDate,
    this.completed = false,
    DateTime? createdAt,
    this.repeatSchedule = 'none',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    bool? completed,
    DateTime? createdAt,
    String? repeatSchedule,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      repeatSchedule: repeatSchedule ?? this.repeatSchedule,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Medium';
    }
  }
}
