import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';

class StatisticsDataRepository {
  static const int schemaVersion = 1;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;

  StatisticsDataRepository({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService();

  Future<void> upsert(StatisticsDataModel data) async {
    await _syncWriteService.upsertRecord(
      type: SyncTypes.statisticsData,
      recordId: data.id,
      schemaVersion: schemaVersion,
      writeBusinessData: () =>
          _hiveService.statisticsDataBox.put(data.id, data),
    );
  }

  Future<void> tombstone(String id) async {
    await _syncWriteService.tombstoneRecord(
      type: SyncTypes.statisticsData,
      recordId: id,
      schemaVersion: schemaVersion,
    );
  }
}
