import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/utils/hlc_clock.dart';
import 'package:easy_todo/utils/random_id.dart';
import 'package:hive/hive.dart';

class SyncTypes {
  static const String todo = 'todo';
  static const String repeatTodo = 'repeat_todo';
  static const String statisticsData = 'statistics_data';
  static const String pomodoro = 'pomodoro';
  static const String userPrefs = 'user_prefs';
  static const String aiSettings = 'ai_settings';
}

class SyncRecordIds {
  static const String singleton = 'singleton';
}

class SyncWriteService {
  static const String stateKey = 'state';

  final HiveService _hiveService;

  SyncWriteService({HiveService? hiveService})
    : _hiveService = hiveService ?? HiveService();

  Box<SyncState> get _stateBox => _hiveService.syncStateBox;
  Box<SyncMeta> get _metaBox => _hiveService.syncMetaBox;
  Box<SyncOutboxItem> get _outboxBox => _hiveService.syncOutboxBox;

  Future<SyncState> ensureState() async {
    final existing = _stateBox.get(stateKey);
    if (existing != null) return existing;

    final deviceId = generateUrlSafeRandomId(byteLength: 16);
    final created = SyncState.create(deviceId: deviceId);
    await _stateBox.put(stateKey, created);
    return created;
  }

  Future<String> getDeviceId() async {
    final state = await ensureState();
    return state.deviceId;
  }

  Future<SyncMeta?> getMeta(String type, String recordId) async {
    return _metaBox.get(_metaKey(type, recordId));
  }

  SyncMeta? getMetaSync(String type, String recordId) {
    return _metaBox.get(_metaKey(type, recordId));
  }

  Future<bool> isTombstoned(String type, String recordId) async {
    final meta = _metaBox.get(_metaKey(type, recordId));
    return meta?.deletedAtMsUtc != null;
  }

  bool isTombstonedSync(String type, String recordId) {
    final meta = _metaBox.get(_metaKey(type, recordId));
    return meta?.deletedAtMsUtc != null;
  }

  Future<void> upsertRecord({
    required String type,
    required String recordId,
    required int schemaVersion,
    required Future<void> Function() writeBusinessData,
  }) async {
    final state = await ensureState();
    final clock = HlcClock(
      deviceId: state.deviceId,
      lastWallMsUtc: state.lastHlcWallMsUtc,
      lastCounter: state.lastHlcCounter,
    );

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final hlc = clock.tick(nowMsUtc);

    await writeBusinessData();

    final metaKey = _metaKey(type, recordId);
    final updatedMeta = SyncMeta(
      type: type,
      recordId: recordId,
      hlcWallMsUtc: hlc.wallTimeMsUtc,
      hlcCounter: hlc.counter,
      hlcDeviceId: hlc.deviceId,
      deletedAtMsUtc: null,
      schemaVersion: schemaVersion,
    );
    await _metaBox.put(metaKey, updatedMeta);

    await _outboxBox.put(
      metaKey,
      SyncOutboxItem(
        type: type,
        recordId: recordId,
        lastEnqueuedAtMsUtc: nowMsUtc,
      ),
    );

    await _stateBox.put(
      stateKey,
      state.copyWith(
        lastHlcWallMsUtc: clock.lastWallMsUtc,
        lastHlcCounter: clock.lastCounter,
      ),
    );
  }

  Future<void> tombstoneRecord({
    required String type,
    required String recordId,
    required int schemaVersion,
  }) async {
    final state = await ensureState();
    final clock = HlcClock(
      deviceId: state.deviceId,
      lastWallMsUtc: state.lastHlcWallMsUtc,
      lastCounter: state.lastHlcCounter,
    );

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final hlc = clock.tick(nowMsUtc);

    final metaKey = _metaKey(type, recordId);
    final existing = _metaBox.get(metaKey);
    final updatedMeta =
        existing?.copyWith(
          hlcWallMsUtc: hlc.wallTimeMsUtc,
          hlcCounter: hlc.counter,
          hlcDeviceId: hlc.deviceId,
          deletedAtMsUtc: nowMsUtc,
          schemaVersion: schemaVersion,
        ) ??
        SyncMeta(
          type: type,
          recordId: recordId,
          hlcWallMsUtc: hlc.wallTimeMsUtc,
          hlcCounter: hlc.counter,
          hlcDeviceId: hlc.deviceId,
          deletedAtMsUtc: nowMsUtc,
          schemaVersion: schemaVersion,
        );
    await _metaBox.put(metaKey, updatedMeta);

    await _outboxBox.put(
      metaKey,
      SyncOutboxItem(
        type: type,
        recordId: recordId,
        lastEnqueuedAtMsUtc: nowMsUtc,
      ),
    );

    await _stateBox.put(
      stateKey,
      state.copyWith(
        lastHlcWallMsUtc: clock.lastWallMsUtc,
        lastHlcCounter: clock.lastCounter,
      ),
    );
  }

  /// Backfill missing meta for existing records (e.g. after upgrading).
  Future<void> ensureMetaExists({
    required String type,
    required String recordId,
    required int schemaVersion,
  }) async {
    final metaKey = _metaKey(type, recordId);
    if (_metaBox.containsKey(metaKey)) return;

    final state = await ensureState();
    final clock = HlcClock(
      deviceId: state.deviceId,
      lastWallMsUtc: state.lastHlcWallMsUtc,
      lastCounter: state.lastHlcCounter,
    );
    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final hlc = clock.tick(nowMsUtc);

    await _metaBox.put(
      metaKey,
      SyncMeta(
        type: type,
        recordId: recordId,
        hlcWallMsUtc: hlc.wallTimeMsUtc,
        hlcCounter: hlc.counter,
        hlcDeviceId: hlc.deviceId,
        deletedAtMsUtc: null,
        schemaVersion: schemaVersion,
      ),
    );

    await _stateBox.put(
      stateKey,
      state.copyWith(
        lastHlcWallMsUtc: clock.lastWallMsUtc,
        lastHlcCounter: clock.lastCounter,
      ),
    );
  }

  static String _metaKey(String type, String recordId) => '$type:$recordId';
}
