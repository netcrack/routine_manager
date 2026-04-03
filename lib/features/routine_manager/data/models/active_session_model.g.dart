// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActiveSessionModelAdapter extends TypeAdapter<ActiveSessionModel> {
  @override
  final int typeId = 2;

  @override
  ActiveSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveSessionModel(
      routineId: fields[0] as String,
      activeAlarmIndex: fields[1] as int,
      elapsedSeconds: fields[2] as int,
      anchorTime: fields[3] as DateTime?,
      statusName: fields[4] as String,
      sessionStartTime: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveSessionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.routineId)
      ..writeByte(1)
      ..write(obj.activeAlarmIndex)
      ..writeByte(2)
      ..write(obj.elapsedSeconds)
      ..writeByte(3)
      ..write(obj.anchorTime)
      ..writeByte(4)
      ..write(obj.statusName)
      ..writeByte(5)
      ..write(obj.sessionStartTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
