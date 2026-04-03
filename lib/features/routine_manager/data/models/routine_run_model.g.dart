// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_run_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineRunModelAdapter extends TypeAdapter<RoutineRunModel> {
  @override
  final int typeId = 3;

  @override
  RoutineRunModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineRunModel(
      id: fields[0] as String,
      routineId: fields[1] as String,
      routineName: fields[2] as String,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      statusName: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineRunModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.routineId)
      ..writeByte(2)
      ..write(obj.routineName)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.statusName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineRunModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
