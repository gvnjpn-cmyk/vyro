// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session_model.dart';

class FocusSessionModelAdapter extends TypeAdapter<FocusSessionModel> {
  @override
  final int typeId = 2;

  @override
  FocusSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSessionModel(
      id: fields[0] as String?,
      durationMinutes: fields[1] as int,
      completedAt: fields[2] as DateTime?,
      wasCompleted: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.completedAt)
      ..writeByte(3)
      ..write(obj.wasCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
