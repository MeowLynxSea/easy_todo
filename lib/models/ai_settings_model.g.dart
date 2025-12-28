// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AISettingsModelAdapter extends TypeAdapter<AISettingsModel> {
  @override
  final int typeId = 10;

  @override
  AISettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AISettingsModel(
      enableAIFeatures: fields[0] == null ? false : fields[0] as bool,
      apiEndpoint: fields[1] == null ? '' : fields[1] as String,
      apiKey: fields[2] == null ? '' : fields[2] as String,
      modelName: fields[3] == null ? 'gpt-3.5-turbo' : fields[3] as String,
      enableAutoCategorization: fields[4] == null ? true : fields[4] as bool,
      enablePrioritySorting: fields[5] == null ? true : fields[5] as bool,
      enableMotivationalMessages: fields[6] == null ? true : fields[6] as bool,
      enableSmartNotifications: fields[7] == null ? true : fields[7] as bool,
      syncApiKey: fields[8] == null ? false : fields[8] as bool,
      temperature: fields[9] == null ? 1.0 : fields[9] as double,
      maxTokens: fields[10] == null ? 10000 : fields[10] as int,
      requestTimeout: fields[11] == null ? 60000 : fields[11] as int,
      maxRequestsPerMinute: fields[12] == null ? 20 : fields[12] as int,
      customPersonaPrompt: fields[13] == null ? '' : fields[13] as String,
      apiFormat: fields[14] == null ? 'openai' : fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AISettingsModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.enableAIFeatures)
      ..writeByte(1)
      ..write(obj.apiEndpoint)
      ..writeByte(2)
      ..write(obj.apiKey)
      ..writeByte(3)
      ..write(obj.modelName)
      ..writeByte(4)
      ..write(obj.enableAutoCategorization)
      ..writeByte(5)
      ..write(obj.enablePrioritySorting)
      ..writeByte(6)
      ..write(obj.enableMotivationalMessages)
      ..writeByte(7)
      ..write(obj.enableSmartNotifications)
      ..writeByte(8)
      ..write(obj.syncApiKey)
      ..writeByte(9)
      ..write(obj.temperature)
      ..writeByte(10)
      ..write(obj.maxTokens)
      ..writeByte(11)
      ..write(obj.requestTimeout)
      ..writeByte(12)
      ..write(obj.maxRequestsPerMinute)
      ..writeByte(13)
      ..write(obj.customPersonaPrompt)
      ..writeByte(14)
      ..write(obj.apiFormat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AISettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
