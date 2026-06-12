import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'focus_session_model.g.dart';

@HiveType(typeId: 2)
class FocusSessionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int durationMinutes;

  @HiveField(2)
  DateTime completedAt;

  @HiveField(3)
  bool wasCompleted;

  FocusSessionModel({
    String? id,
    required this.durationMinutes,
    DateTime? completedAt,
    this.wasCompleted = true,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();
}
