// lib/data/models/radio_station.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Run `flutter pub run build_runner build` to regenerate.

part of 'radio_station.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RadioStationAdapter extends TypeAdapter<RadioStation> {
  @override
  final int typeId = 0;

  @override
  RadioStation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RadioStation(
      id: fields[0] as String,
      name: fields[1] as String,
      primaryUrl: fields[2] as String,
      backupUrl1: fields[3] as String?,
      backupUrl2: fields[4] as String?,
      logoUrl: fields[5] as String?,
      category: fields[6] as String,
      country: fields[7] as String?,
      language: fields[8] as String?,
      isCustomStation: fields[9] as bool,
      bitrate: fields[10] as int?,
      description: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RadioStation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.primaryUrl)
      ..writeByte(3)
      ..write(obj.backupUrl1)
      ..writeByte(4)
      ..write(obj.backupUrl2)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.country)
      ..writeByte(8)
      ..write(obj.language)
      ..writeByte(9)
      ..write(obj.isCustomStation)
      ..writeByte(10)
      ..write(obj.bitrate)
      ..writeByte(11)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioStationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TvChannelAdapter extends TypeAdapter<TvChannel> {
  @override
  final int typeId = 1;

  @override
  TvChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TvChannel(
      id: fields[0] as String,
      name: fields[1] as String,
      primaryUrl: fields[2] as String,
      backupUrl1: fields[3] as String?,
      backupUrl2: fields[4] as String?,
      logoUrl: fields[5] as String?,
      category: fields[6] as String,
      isCustomChannel: fields[7] as bool,
      description: fields[8] as String?,
      country: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TvChannel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.primaryUrl)
      ..writeByte(3)
      ..write(obj.backupUrl1)
      ..writeByte(4)
      ..write(obj.backupUrl2)
      ..writeByte(5)
      ..write(obj.logoUrl)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isCustomChannel)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.country);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
