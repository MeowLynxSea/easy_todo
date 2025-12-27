import 'package:easy_todo/models/device_settings_model.dart';
import 'package:hive/hive.dart';

class DeviceSettingsModelAdapter extends TypeAdapter<DeviceSettingsModel> {
  @override
  final int typeId = 11;

  @override
  DeviceSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceSettingsModel(
      biometricLockEnabled: fields[0] == null ? false : fields[0] as bool,
      autoUpdateEnabled: fields[1] == null ? true : fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceSettingsModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.biometricLockEnabled)
      ..writeByte(1)
      ..write(obj.autoUpdateEnabled);
  }
}
