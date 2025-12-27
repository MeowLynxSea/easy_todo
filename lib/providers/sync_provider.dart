import 'dart:async';
import 'dart:convert';

import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:easy_todo/models/pomodoro_model.dart';
import 'package:easy_todo/models/repeat_todo_model.dart';
import 'package:easy_todo/models/statistics_data_model.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync/sync_record_envelope.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:easy_todo/models/todo_model.dart';
import 'package:easy_todo/models/user_preferences_model.dart';
import 'package:easy_todo/services/crypto/sync_crypto.dart';
import 'package:easy_todo/services/dek_storage_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/repositories/pomodoro_repository.dart';
import 'package:easy_todo/services/repositories/ai_settings_repository.dart';
import 'package:easy_todo/services/repositories/repeat_todo_repository.dart';
import 'package:easy_todo/services/repositories/statistics_data_repository.dart';
import 'package:easy_todo/services/repositories/todo_repository.dart';
import 'package:easy_todo/services/repositories/user_preferences_repository.dart';
import 'package:easy_todo/services/sync/sync_api_client.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/hlc_clock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum SyncStatus { idle, running, error }

enum SyncErrorCode {
  passphraseMismatch,
  notConfigured,
  disabled,
  locked,
  invalidPassphrase,
  unauthorized,
  keyBundleNotFound,
  network,
  conflict,
  unknown,
}

class SyncRollbackDetectedException implements Exception {
  final int lastServerSeq;
  final int serverNextSince;
  const SyncRollbackDetectedException({
    required this.lastServerSeq,
    required this.serverNextSince,
  });

  @override
  String toString() =>
      'SyncRollbackDetectedException(last=$lastServerSeq,next=$serverNextSince)';
}

class SyncProvider extends ChangeNotifier {
  static const int _pullPageLimit = 200;
  static const int _pushBatchLimit = 50;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;
  final SyncCrypto _crypto;
  final DekStorageService _dekStorage;

  SyncState? _state;
  KeyBundle? _bundle;
  List<int>? _dek;

  SyncStatus _status = SyncStatus.idle;
  SyncErrorCode? _lastErrorCode;
  String? _lastErrorDetail;
  DateTime? _lastSyncAt;

  Completer<void>? _syncMutex;

  SyncProvider({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
    SyncCrypto? crypto,
    DekStorageService? dekStorage,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService(),
       _crypto = crypto ?? SyncCrypto(),
       _dekStorage = dekStorage ?? DekStorageService() {
    unawaited(_init());
  }

  SyncStatus get status => _status;
  SyncErrorCode? get lastErrorCode => _lastErrorCode;
  String? get lastErrorDetail => _lastErrorDetail;
  DateTime? get lastSyncAt => _lastSyncAt;

  bool get syncEnabled => _state?.syncEnabled ?? false;
  bool get isConfigured =>
      (_state?.serverUrl.trim().isNotEmpty ?? false) &&
      (_state?.authToken.trim().isNotEmpty ?? false);
  bool get isUnlocked => _dek != null;

  String get serverUrl => _state?.serverUrl ?? '';
  String get authToken => _state?.authToken ?? '';
  String? get dekId => _state?.dekId;
  int get lastServerSeq => _state?.lastServerSeq ?? 0;
  String get deviceId => _state?.deviceId ?? '';

  Future<void> _init() async {
    final state = await _ensureStateLoaded();
    if (state.syncEnabled && state.dekId != null) {
      final cached = await _dekStorage.readDek(dekId: state.dekId!);
      if (cached != null) {
        _dek = cached;
      }
    }
    notifyListeners();
  }

  Future<SyncState> _ensureStateLoaded() async {
    final loaded = await _syncWriteService.ensureState();
    _state = loaded;
    return loaded;
  }

  Future<void> configure({
    required String serverUrl,
    required String authToken,
  }) async {
    final state = await _ensureStateLoaded();
    final updated = state.copyWith(
      serverUrl: serverUrl.trim(),
      authToken: authToken.trim(),
    );
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    notifyListeners();
  }

  Future<void> disableSync({bool forgetDek = true}) async {
    final state = await _ensureStateLoaded();
    final dekId = state.dekId;
    final updated = state.copyWith(syncEnabled: false);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    _bundle = null;
    _dek = null;
    if (forgetDek && dekId != null) {
      await _dekStorage.deleteDek(dekId: dekId);
    }
    notifyListeners();
  }

  Future<void> enableSync({
    required String passphrase,
    String? confirmPassphrase,
  }) async {
    if (confirmPassphrase != null && passphrase != confirmPassphrase) {
      _setError(SyncErrorCode.passphraseMismatch);
      return;
    }
    if (!isConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }

    await _withStatus(SyncStatus.running, () async {
      await _ensureStateLoaded();
      final client = _client();
      final existing = await client.getKeyBundle();
      if (existing == null) {
        final dekId = const Uuid().v4();
        final created = await _crypto.createKeyBundle(
          dekId: dekId,
          passphrase: passphrase,
        );
        _bundle = await client.putKeyBundle(
          expectedBundleVersion: 0,
          bundle: created,
        );
      } else {
        _bundle = existing;
      }

      final bundle = _bundle!;
      final cached = await _dekStorage.readDek(dekId: bundle.dekId);
      _dek =
          cached ??
          await _crypto.unlockDek(bundle: bundle, passphrase: passphrase);
      await _dekStorage.writeDek(dekId: bundle.dekId, dek: _dek!);

      final state = await _ensureStateLoaded();
      final updated = state.copyWith(syncEnabled: true, dekId: bundle.dekId);
      await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
      _state = updated;
    });
  }

  Future<void> unlock({required String passphrase}) async {
    if (!isConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }

    await _withStatus(SyncStatus.running, () async {
      await _ensureStateLoaded();
      final client = _client();
      final bundle = await client.getKeyBundle();
      if (bundle == null) {
        throw const SyncApiException('key bundle not found', statusCode: 404);
      }
      _bundle = bundle;
      final cached = await _dekStorage.readDek(dekId: bundle.dekId);
      _dek =
          cached ??
          await _crypto.unlockDek(bundle: bundle, passphrase: passphrase);
      await _dekStorage.writeDek(dekId: bundle.dekId, dek: _dek!);

      final state = await _ensureStateLoaded();
      final updated = state.copyWith(dekId: bundle.dekId);
      await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
      _state = updated;
    });
  }

  Future<void> syncNow({bool allowRollback = false}) async {
    await _ensureStateLoaded();
    if (!syncEnabled) {
      _setError(SyncErrorCode.disabled);
      return;
    }
    if (!isConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }
    if (_dek == null) {
      _setError(SyncErrorCode.locked);
      return;
    }

    if (_syncMutex != null) return _syncMutex!.future;
    final mutex = Completer<void>();
    _syncMutex = mutex;

    try {
      await _withStatus(SyncStatus.running, () async {
        final client = _client();

        await _bootstrapLocalRecordsIfNeeded();
        await _bootstrapSettingsIfNeeded();

        final state = await _ensureStateLoaded();
        final sinceBefore = state.lastServerSeq;

        await _pushOutbox(client);
        await _pullAndMerge(
          client,
          sinceBefore: sinceBefore,
          allowRollback: allowRollback,
        );

        _lastSyncAt = DateTime.now();
      });
    } finally {
      if (!mutex.isCompleted) mutex.complete();
      _syncMutex = null;
    }
  }

  Future<void> _bootstrapLocalRecordsIfNeeded() async {
    final state = await _ensureStateLoaded();
    if (state.didBootstrapLocalRecords) return;

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final outbox = _hiveService.syncOutboxBox;
    final metaBox = _hiveService.syncMetaBox;

    Future<void> enqueue({
      required String type,
      required String recordId,
      required int schemaVersion,
    }) async {
      await _syncWriteService.ensureMetaExists(
        type: type,
        recordId: recordId,
        schemaVersion: schemaVersion,
      );

      final key = SyncWriteService.metaKeyOf(type, recordId);
      final meta = metaBox.get(key);
      if (meta == null) return;

      await outbox.put(
        key,
        SyncOutboxItem(
          type: type,
          recordId: recordId,
          lastEnqueuedAtMsUtc: nowMsUtc,
        ),
      );
    }

    for (final todo in _hiveService.todosBox.values) {
      await enqueue(
        type: SyncTypes.todo,
        recordId: todo.id,
        schemaVersion: TodoRepository.schemaVersion,
      );
    }

    for (final repeat in _hiveService.repeatTodosBox.values) {
      await enqueue(
        type: SyncTypes.repeatTodo,
        recordId: repeat.id,
        schemaVersion: RepeatTodoRepository.schemaVersion,
      );
    }

    for (final stat in _hiveService.statisticsDataBox.values) {
      await enqueue(
        type: SyncTypes.statisticsData,
        recordId: stat.id,
        schemaVersion: StatisticsDataRepository.schemaVersion,
      );
    }

    for (final session in _hiveService.pomodoroBox.values) {
      await enqueue(
        type: SyncTypes.pomodoro,
        recordId: session.id,
        schemaVersion: PomodoroRepository.schemaVersion,
      );
    }

    // Ensure tombstones are not lost (e.g. deleted before enabling sync).
    for (final key in metaBox.keys.cast<String>()) {
      final meta = metaBox.get(key);
      if (meta == null || meta.deletedAtMsUtc == null) continue;
      if (outbox.containsKey(key)) continue;

      await outbox.put(
        key,
        SyncOutboxItem(
          type: meta.type,
          recordId: meta.recordId,
          lastEnqueuedAtMsUtc: nowMsUtc,
        ),
      );
    }

    final latest = await _ensureStateLoaded();
    final updated = latest.copyWith(didBootstrapLocalRecords: true);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  Future<void> _bootstrapSettingsIfNeeded() async {
    final state = await _ensureStateLoaded();
    if (state.didBootstrapSettings) return;

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final outbox = _hiveService.syncOutboxBox;
    final metaBox = _hiveService.syncMetaBox;

    Future<void> enqueue({
      required String type,
      required String recordId,
      required int schemaVersion,
    }) async {
      await _syncWriteService.ensureMetaExists(
        type: type,
        recordId: recordId,
        schemaVersion: schemaVersion,
      );

      final key = SyncWriteService.metaKeyOf(type, recordId);
      final meta = metaBox.get(key);
      if (meta == null) return;

      await outbox.put(
        key,
        SyncOutboxItem(
          type: type,
          recordId: recordId,
          lastEnqueuedAtMsUtc: nowMsUtc,
        ),
      );
    }

    final prefsBox = _hiveService.userPreferencesBox;
    if (!prefsBox.containsKey(UserPreferencesRepository.hiveKey)) {
      await prefsBox.put(
        UserPreferencesRepository.hiveKey,
        UserPreferencesModel.create(),
      );
    }
    await enqueue(
      type: SyncTypes.userPrefs,
      recordId: SyncRecordIds.singleton,
      schemaVersion: UserPreferencesRepository.schemaVersion,
    );

    final aiBox = _hiveService.aiSettingsBox;
    if (!aiBox.containsKey(AISettingsRepository.hiveKey)) {
      await aiBox.put(AISettingsRepository.hiveKey, AISettingsModel.create());
    }
    await enqueue(
      type: SyncTypes.aiSettings,
      recordId: SyncRecordIds.singleton,
      schemaVersion: AISettingsRepository.schemaVersion,
    );

    final latest = await _ensureStateLoaded();
    final updated = latest.copyWith(didBootstrapSettings: true);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  SyncApiClient _client() {
    final state = _state;
    if (state == null) {
      throw StateError('SyncState not initialized');
    }
    return SyncApiClient(
      serverUrl: state.serverUrl,
      bearerToken: state.authToken,
    );
  }

  Future<void> checkServerHealth() async {
    if (!isConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }
    await _withStatus(SyncStatus.running, () async {
      await _ensureStateLoaded();
      await _client().health();
    });
  }

  Future<bool> keyBundleExistsOnServer() async {
    if (!isConfigured) return false;
    final bundle = await _client().getKeyBundle();
    _bundle = bundle;
    return bundle != null;
  }

  void _setError(SyncErrorCode code, {String? detail}) {
    _status = SyncStatus.error;
    _lastErrorCode = code;
    _lastErrorDetail = detail;
    notifyListeners();
  }

  Future<void> _withStatus(
    SyncStatus status,
    Future<void> Function() fn,
  ) async {
    _status = status;
    _lastErrorCode = null;
    _lastErrorDetail = null;
    notifyListeners();
    // Give the UI a chance to repaint before heavy CPU work (e.g. scrypt) blocks.
    await Future<void>.delayed(Duration.zero);

    try {
      await fn();
      _status = SyncStatus.idle;
      notifyListeners();
    } catch (e) {
      _status = SyncStatus.error;
      if (e is InvalidPassphraseException) {
        _lastErrorCode = SyncErrorCode.invalidPassphrase;
      } else if (e is SyncApiException) {
        if (e.statusCode == null) {
          _lastErrorCode = SyncErrorCode.network;
        } else if (e.statusCode == 401 || e.statusCode == 403) {
          _lastErrorCode = SyncErrorCode.unauthorized;
        } else if (e.statusCode == 404) {
          _lastErrorCode = SyncErrorCode.keyBundleNotFound;
        } else if (e.statusCode == 409) {
          _lastErrorCode = SyncErrorCode.conflict;
        } else {
          _lastErrorCode = SyncErrorCode.unknown;
        }
      } else {
        _lastErrorCode = SyncErrorCode.unknown;
      }
      _lastErrorDetail = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _pushOutbox(SyncApiClient client) async {
    final dek = _dek!;
    final state = await _ensureStateLoaded();
    final dekId = _bundle?.dekId ?? state.dekId;
    if (dekId == null) throw StateError('Missing dekId');

    final outbox = _hiveService.syncOutboxBox;
    if (outbox.isEmpty) return;

    final metaBox = _hiveService.syncMetaBox;

    final items = <(String key, SyncOutboxItem item)>[];
    for (final key in outbox.keys.cast<String>()) {
      final item = outbox.get(key);
      if (item == null) continue;
      items.add((key, item));
    }
    items.sort(
      (a, b) => a.$2.lastEnqueuedAtMsUtc.compareTo(b.$2.lastEnqueuedAtMsUtc),
    );

    for (var offset = 0; offset < items.length; offset += _pushBatchLimit) {
      final batch = items
          .skip(offset)
          .take(_pushBatchLimit)
          .toList(growable: false);

      final toPush = <SyncRecordEnvelope>[];
      final pushedKeys = <String>[];

      for (final entry in batch) {
        final key = entry.$1;
        final item = entry.$2;

        final meta = metaBox.get(key);
        if (meta == null) continue;

        final envelope = await _buildEnvelopeForLocalRecord(
          type: item.type,
          recordId: item.recordId,
          meta: meta,
          dekId: dekId,
          dek: dek,
        );
        if (envelope == null) continue;

        toPush.add(envelope);
        pushedKeys.add(key);
      }

      if (toPush.isEmpty) continue;

      final resp = await client.push(records: toPush);

      final acceptedKeys = <String>{};
      for (final a in resp.accepted) {
        acceptedKeys.add('${a.type}:${a.recordId}');
      }
      final olderKeys = <String>{};
      for (final r in resp.rejected) {
        if (r.reason == 'older_hlc') {
          olderKeys.add('${r.type}:${r.recordId}');
        }
      }

      for (final key in pushedKeys) {
        if (acceptedKeys.contains(key) || olderKeys.contains(key)) {
          await outbox.delete(key);
        }
      }

      if (outbox.isEmpty) return;
    }
  }

  Future<SyncRecordEnvelope?> _buildEnvelopeForLocalRecord({
    required String type,
    required String recordId,
    required SyncMeta meta,
    required String dekId,
    required List<int> dek,
  }) async {
    final payloadJson = await _readLocalPayloadJson(
      type: type,
      recordId: recordId,
    );
    if (payloadJson == null && meta.deletedAtMsUtc == null) {
      return null;
    }

    final hlc = HlcJson(
      wallTimeMsUtc: meta.hlcWallMsUtc,
      counter: meta.hlcCounter,
      deviceId: meta.hlcDeviceId,
    );

    final payloadBytes = utf8.encode(jsonEncode(payloadJson ?? const {}));
    return _crypto.encryptRecord(
      type: type,
      recordId: recordId,
      hlc: hlc,
      deletedAtMsUtc: meta.deletedAtMsUtc,
      schemaVersion: meta.schemaVersion,
      dekId: dekId,
      dek: dek,
      payloadPlaintext: payloadBytes,
    );
  }

  Future<Map<String, dynamic>?> _readLocalPayloadJson({
    required String type,
    required String recordId,
  }) async {
    switch (type) {
      case SyncTypes.todo:
        final todo = _hiveService.todosBox.get(recordId);
        return todo?.toJson();
      case SyncTypes.repeatTodo:
        final repeat = _hiveService.repeatTodosBox.get(recordId);
        return repeat?.toJson();
      case SyncTypes.statisticsData:
        final stat = _hiveService.statisticsDataBox.get(recordId);
        return stat?.toJson();
      case SyncTypes.pomodoro:
        final pomodoro = _hiveService.pomodoroBox.get(recordId);
        return pomodoro?.toJson();
      case SyncTypes.userPrefs:
        final prefs = _hiveService.userPreferencesBox.get(
          UserPreferencesRepository.hiveKey,
        );
        return prefs?.toJson();
      case SyncTypes.aiSettings:
        final settings = _hiveService.aiSettingsBox.get(
          AISettingsRepository.hiveKey,
        );
        return settings?.toJson(includeApiKey: false);
      default:
        return null;
    }
  }

  Future<void> _pullAndMerge(
    SyncApiClient client, {
    required int sinceBefore,
    required bool allowRollback,
  }) async {
    final dek = _dek!;
    final state = await _ensureStateLoaded();
    final deviceId = state.deviceId;

    final metaBox = _hiveService.syncMetaBox;
    final outbox = _hiveService.syncOutboxBox;
    var nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;

    var cursor = sinceBefore;
    var sawRollback = false;

    final clock = HlcClock(
      deviceId: deviceId,
      lastWallMsUtc: state.lastHlcWallMsUtc,
      lastCounter: state.lastHlcCounter,
    );

    while (true) {
      final pull = await client.pull(since: cursor, limit: _pullPageLimit);
      if (pull.nextSince < cursor) {
        sawRollback = true;
      }

      if (sawRollback && !allowRollback) {
        throw SyncRollbackDetectedException(
          lastServerSeq: cursor,
          serverNextSince: pull.nextSince,
        );
      }

      if (pull.records.isEmpty) {
        cursor = pull.nextSince;
        break;
      }

      for (final remote in pull.records) {
        final key = '${remote.type}:${remote.recordId}';
        final localMeta = metaBox.get(key);

        final remoteHlc = HlcTimestamp(
          wallTimeMsUtc: remote.hlc.wallTimeMsUtc,
          counter: remote.hlc.counter,
          deviceId: remote.hlc.deviceId,
        );

        final shouldApply = localMeta == null
            ? true
            : HlcClock.compare(
                    remoteHlc,
                    HlcTimestamp(
                      wallTimeMsUtc: localMeta.hlcWallMsUtc,
                      counter: localMeta.hlcCounter,
                      deviceId: localMeta.hlcDeviceId,
                    ),
                  ) >
                  0;

        if (!shouldApply) continue;

        nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;

        if (remote.deletedAtMsUtc == null) {
          if (state.dekId != null && remote.dekId != state.dekId) {
            continue;
          }

          final payloadBytes = await _crypto.decryptRecordPayload(
            envelope: remote,
            dek: dek,
          );
          final decoded = jsonDecode(utf8.decode(payloadBytes));
          if (decoded is! Map<String, dynamic>) {
            continue;
          }
          await _applyRemotePayload(
            type: remote.type,
            recordId: remote.recordId,
            payload: decoded,
          );
        }

        await metaBox.put(
          key,
          SyncMeta(
            type: remote.type,
            recordId: remote.recordId,
            hlcWallMsUtc: remote.hlc.wallTimeMsUtc,
            hlcCounter: remote.hlc.counter,
            hlcDeviceId: remote.hlc.deviceId,
            deletedAtMsUtc: remote.deletedAtMsUtc,
            schemaVersion: remote.schemaVersion,
          ),
        );

        if (outbox.containsKey(key)) {
          await outbox.delete(key);
        }

        clock.observe(remoteHlc, nowMsUtc);
      }

      cursor = pull.nextSince;
    }

    final updated = state.copyWith(
      lastServerSeq: cursor,
      lastHlcWallMsUtc: clock.lastWallMsUtc,
      lastHlcCounter: clock.lastCounter,
    );
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  Future<void> _applyRemotePayload({
    required String type,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    switch (type) {
      case SyncTypes.todo:
        await _hiveService.todosBox.put(recordId, TodoModel.fromJson(payload));
        return;
      case SyncTypes.repeatTodo:
        await _hiveService.repeatTodosBox.put(
          recordId,
          RepeatTodoModel.fromJson(payload),
        );
        return;
      case SyncTypes.statisticsData:
        await _hiveService.statisticsDataBox.put(
          recordId,
          StatisticsDataModel.fromJson(payload),
        );
        return;
      case SyncTypes.pomodoro:
        await _hiveService.pomodoroBox.put(
          recordId,
          PomodoroModel.fromJson(payload),
        );
        return;
      case SyncTypes.userPrefs:
        await _hiveService.userPreferencesBox.put(
          UserPreferencesRepository.hiveKey,
          UserPreferencesModel.fromJson(payload),
        );
        return;
      case SyncTypes.aiSettings:
        await _hiveService.aiSettingsBox.put(
          AISettingsRepository.hiveKey,
          AISettingsModel.fromJson(payload),
        );
        return;
      default:
        return;
    }
  }
}
