// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      username: fields[0] as String,
      passwordHash: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.passwordHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatientRecordAdapter extends TypeAdapter<PatientRecord> {
  @override
  final int typeId = 1;

  @override
  PatientRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientRecord(
      ownerUserId: fields[0] as String,
      patientName: fields[1] as String,
      recordDate: fields[3] as DateTime,
      recordDataJson: fields[4] as String,
      // GÜNCELLEME: fields[5] eklendi ve null olabilir olarak okundu
      pdfFilePath: fields[5] as String?, 
    )..recordId = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, PatientRecord obj) {
    writer
      ..writeByte(6) // Alan sayısı 5'ten 6'ya yükseltildi (0'dan 5'e kadar alanlar)
      ..writeByte(0)
      ..write(obj.ownerUserId)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.recordId)
      ..writeByte(3)
      ..write(obj.recordDate)
      ..writeByte(4)
      ..write(obj.recordDataJson)
      // GÜNCELLEME: fields[5] eklendi
      ..writeByte(5)
      ..write(obj.pdfFilePath); 
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}