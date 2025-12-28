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
import 'package:easy_todo/services/sync/sync_auth_storage.dart';
import 'package:easy_todo/services/sync/sync_server_auth_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:easy_todo/utils/hlc_clock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:easy_todo/services/web_url_utils_stub.dart'
    if (dart.library.html) 'package:easy_todo/services/web_url_utils_web.dart';

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
  quotaExceeded,
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

class SyncPushRejectedException implements Exception {
  final Map<String, int> rejectedByReason;
  const SyncPushRejectedException(this.rejectedByReason);

  @override
  String toString() => 'SyncPushRejectedException($rejectedByReason)';
}

class SyncProvider extends ChangeNotifier {
  static const int _pullPageLimit = 200;
  static const int _pushBatchLimit = 50;

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;
  final SyncCrypto _crypto;
  final DekStorageService _dekStorage;
  final SyncAuthStorage _authStorage;
  final SyncServerAuthService _authService;

  SyncState? _state;
  KeyBundle? _bundle;
  List<int>? _dek;
  SyncAuthTokens? _authTokens;
  List<String> _availableProviders = const [];

  SyncStatus _status = SyncStatus.idle;
  SyncErrorCode? _lastErrorCode;
  String? _lastErrorDetail;
  DateTime? _lastSyncAt;

  Completer<void>? _syncMutex;

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[Sync] $message');
  }

  SyncProvider({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
    SyncCrypto? crypto,
    DekStorageService? dekStorage,
    SyncAuthStorage? authStorage,
    SyncServerAuthService? authService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService(),
       _crypto = crypto ?? SyncCrypto(),
       _dekStorage = dekStorage ?? DekStorageService(),
       _authStorage = authStorage ?? SyncAuthStorage(),
       _authService = authService ?? createSyncServerAuthService() {
    unawaited(_init());
  }

  SyncStatus get status => _status;
  SyncErrorCode? get lastErrorCode => _lastErrorCode;
  String? get lastErrorDetail => _lastErrorDetail;
  DateTime? get lastSyncAt => _lastSyncAt;

  bool get syncEnabled => _state?.syncEnabled ?? false;
  bool get isServerConfigured => (_state?.serverUrl.trim().isNotEmpty ?? false);
  bool get isConfigured => isServerConfigured && isLoggedIn;
  bool get isUnlocked => _dek != null;
  bool get isLoggedIn => (_authTokens?.accessToken.trim().isNotEmpty ?? false);
  List<String> get availableProviders => _availableProviders;
  String get authUserId => _state?.authUserId ?? '';

  String get serverUrl => _state?.serverUrl ?? '';
  String get authProvider => _state?.authProvider ?? '';
  String? get dekId => _state?.dekId;
  int get lastServerSeq => _state?.lastServerSeq ?? 0;
  String get deviceId => _state?.deviceId ?? '';

  Future<void> _init() async {
    final state = await _ensureStateLoaded();
    _authTokens = await _authStorage.read();

    if (kIsWeb) {
      final ticket = currentWebUrl().queryParameters['ticket'];
      final ticketFallback = currentWebUrl().queryParameters['amp;ticket'];
      final ticketValue = (ticket ?? ticketFallback)?.trim();
      if (ticketValue != null &&
          ticketValue.isNotEmpty &&
          state.serverUrl.trim().isNotEmpty) {
        try {
          final tokens = await _authService.exchange(
            serverUrl: state.serverUrl,
            ticket: ticketValue,
          );
          await _onAuthTokensUpdated(tokens);

          final current = currentWebUrl();
          final qp = Map<String, String>.from(current.queryParameters);
          qp.remove('ticket');
          qp.remove('amp;ticket');
          replaceWebUrl(current.replace(queryParameters: qp));
        } catch (e) {
          _status = SyncStatus.error;
          _lastErrorCode = SyncErrorCode.unauthorized;
          _lastErrorDetail = e.toString();

          final current = currentWebUrl();
          final qp = Map<String, String>.from(current.queryParameters);
          qp.remove('ticket');
          qp.remove('amp;ticket');
          replaceWebUrl(current.replace(queryParameters: qp));
        }
      }
    }

    if (state.serverUrl.trim().isNotEmpty) {
      unawaited(refreshProviders());
    }

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

  Future<void> configure({required String serverUrl}) async {
    final state = await _ensureStateLoaded();
    final nextUrl = serverUrl.trim();
    final prevUrl = state.serverUrl.trim();
    final normalizedPrev = prevUrl.endsWith('/')
        ? prevUrl.substring(0, prevUrl.length - 1)
        : prevUrl;
    final normalizedNext = nextUrl.endsWith('/')
        ? nextUrl.substring(0, nextUrl.length - 1)
        : nextUrl;

    if (normalizedPrev.isNotEmpty && normalizedPrev != normalizedNext) {
      await _resetForNewSyncServer(state: state);
    }

    final updated = state.copyWith(serverUrl: nextUrl);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    await _authStorage.clear();
    _authTokens = null;
    _availableProviders = const [];
    notifyListeners();
    unawaited(refreshProviders());
  }

  Future<void> setAuthProvider(String provider) async {
    final state = await _ensureStateLoaded();
    final updated = state.copyWith(authProvider: provider.trim());
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    notifyListeners();
  }

  Future<void> refreshProviders() async {
    final state = await _ensureStateLoaded();
    if (state.serverUrl.trim().isEmpty) {
      _availableProviders = const [];
      notifyListeners();
      return;
    }
    try {
      final providers = await _authService.listProviders(
        serverUrl: state.serverUrl,
      );
      _availableProviders = providers;
      if (_availableProviders.isNotEmpty && state.authProvider.trim().isEmpty) {
        await setAuthProvider(_availableProviders.first);
      } else {
        notifyListeners();
      }
    } catch (_) {
      _availableProviders = const [];
      notifyListeners();
    }
  }

  Future<void> login({String client = 'easy_todo'}) async {
    if (!isServerConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }
    if (authProvider.trim().isEmpty) {
      _setError(SyncErrorCode.notConfigured, detail: 'missing authProvider');
      return;
    }

    await _withStatus(SyncStatus.running, () async {
      final state = await _ensureStateLoaded();
      final tokens = await _authService.login(
        serverUrl: state.serverUrl,
        provider: state.authProvider,
        client: client,
      );
      if (tokens != null) {
        await _onAuthTokensUpdated(tokens);
      }
    });
  }

  Future<void> logout() async {
    final state = await _ensureStateLoaded();
    final tokens = await _authStorage.read();
    final refreshToken = tokens?.refreshToken;
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      try {
        await _authService.logout(
          serverUrl: state.serverUrl,
          refreshToken: refreshToken,
        );
      } catch (_) {}
    }
    await _authStorage.clear();
    _authTokens = null;
    _bundle = null;
    _dek = null;
    if (state.dekId != null) {
      await _dekStorage.deleteDek(dekId: state.dekId!);
    }
    final updated = state.copyWith(syncEnabled: false, dekId: null);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    notifyListeners();
  }

  Future<void> _onAuthTokensUpdated(SyncAuthTokens tokens) async {
    await _authStorage.write(tokens);
    _authTokens = tokens;

    final newUserId = _tryParseJwtSub(tokens.accessToken)?.trim();
    if (newUserId == null || newUserId.isEmpty) {
      _debugLog('Auth tokens updated but failed to parse userId from JWT sub');
      notifyListeners();
      return;
    }

    final state = await _ensureStateLoaded();
    final prevUserId = state.authUserId.trim();

    if (prevUserId.isNotEmpty && prevUserId != newUserId) {
      await _resetForAccountChange(state: state, newUserId: newUserId);
      notifyListeners();
      return;
    }

    final updated = state.copyWith(authUserId: newUserId);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    if (prevUserId != newUserId) {
      _debugLog('Auth userId set: $newUserId');
    }
    notifyListeners();
  }

  Future<void> _resetForAccountChange({
    required SyncState state,
    required String newUserId,
  }) async {
    _debugLog('Reset for account change: ${state.authUserId} -> $newUserId');
    final prevDekId = state.dekId;

    await _hiveService.syncOutboxBox.clear();
    await _hiveService.syncMetaBox.clear();

    if (prevDekId != null) {
      await _dekStorage.deleteDek(dekId: prevDekId);
    }

    _bundle = null;
    _dek = null;

    final updated = state.copyWith(
      authUserId: newUserId,
      syncEnabled: false,
      lastServerSeq: 0,
      didBootstrapLocalRecords: false,
      didBootstrapSettings: false,
      didBackfillOutboxFromMeta: false,
      dekId: null,
    );
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  Future<void> _resetForNewSyncServer({required SyncState state}) async {
    _debugLog('Reset for new sync server: ${state.serverUrl}');
    final prevDekId = state.dekId;

    await _hiveService.syncOutboxBox.clear();
    await _hiveService.syncMetaBox.clear();

    if (prevDekId != null) {
      await _dekStorage.deleteDek(dekId: prevDekId);
    }

    _bundle = null;
    _dek = null;

    final updated = state.copyWith(
      authProvider: '',
      authUserId: '',
      syncEnabled: false,
      lastServerSeq: 0,
      didBootstrapLocalRecords: false,
      didBootstrapSettings: false,
      didBackfillOutboxFromMeta: false,
      dekId: null,
    );
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  String? _tryParseJwtSub(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final bytes = base64Url.decode(normalized);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      final sub = decoded['sub'];
      if (sub is String) return sub;
      if (sub is num) return sub.toString();
      return null;
    } catch (_) {
      return null;
    }
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
    if (!isLoggedIn) {
      _authTokens = await _authStorage.read();
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

        _debugLog(
          'syncNow begin user=${authUserId.isEmpty ? "(unknown)" : authUserId} '
          'device=$deviceId lastSeq=$lastServerSeq',
        );
        _debugLog(
          'local counts todos=${_hiveService.todosBox.length} '
          'repeat=${_hiveService.repeatTodosBox.length} '
          'stats=${_hiveService.statisticsDataBox.length} '
          'pomodoro=${_hiveService.pomodoroBox.length} '
          'meta=${_hiveService.syncMetaBox.length} outbox=${_hiveService.syncOutboxBox.length} '
          'bootLocal=${_state?.didBootstrapLocalRecords} bootSettings=${_state?.didBootstrapSettings} '
          'backfillOutbox=${_state?.didBackfillOutboxFromMeta}',
        );

        await _bootstrapLocalRecordsIfNeeded();
        await _bootstrapSettingsIfNeeded();
        await _backfillOutboxFromExistingMetaIfNeeded();

        final state = await _ensureStateLoaded();
        final sinceBefore = state.lastServerSeq;

        await _pushOutbox(client);
        await _pullAndMerge(
          client,
          sinceBefore: sinceBefore,
          allowRollback: allowRollback,
        );

        _lastSyncAt = DateTime.now();
        _debugLog('syncNow end lastSeq=${_state?.lastServerSeq ?? 0}');
      });
    } finally {
      if (!mutex.isCompleted) mutex.complete();
      _syncMutex = null;
    }
  }

  Future<void> _backfillOutboxFromExistingMetaIfNeeded() async {
    final state = await _ensureStateLoaded();
    if (state.didBackfillOutboxFromMeta) return;

    final metaBox = _hiveService.syncMetaBox;
    final outbox = _hiveService.syncOutboxBox;
    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;

    int enqueued = 0;

    Future<void> enqueueIfNeeded(
      String type,
      String recordId,
      int schemaVersion,
    ) async {
      await _syncWriteService.ensureMetaExists(
        type: type,
        recordId: recordId,
        schemaVersion: schemaVersion,
      );
      final key = SyncWriteService.metaKeyOf(type, recordId);
      final meta = metaBox.get(key);
      if (meta == null) return;
      if (meta.deletedAtMsUtc != null) return;
      if (outbox.containsKey(key)) return;

      await outbox.put(
        key,
        SyncOutboxItem(
          type: type,
          recordId: recordId,
          lastEnqueuedAtMsUtc: nowMsUtc,
        ),
      );
      enqueued++;
    }

    for (final todo in _hiveService.todosBox.values) {
      await enqueueIfNeeded(
        SyncTypes.todo,
        todo.id,
        TodoRepository.schemaVersion,
      );
    }
    for (final repeat in _hiveService.repeatTodosBox.values) {
      await enqueueIfNeeded(
        SyncTypes.repeatTodo,
        repeat.id,
        RepeatTodoRepository.schemaVersion,
      );
    }
    for (final stat in _hiveService.statisticsDataBox.values) {
      await enqueueIfNeeded(
        SyncTypes.statisticsData,
        stat.id,
        StatisticsDataRepository.schemaVersion,
      );
    }
    for (final session in _hiveService.pomodoroBox.values) {
      await enqueueIfNeeded(
        SyncTypes.pomodoro,
        session.id,
        PomodoroRepository.schemaVersion,
      );
    }

    // Also enqueue tombstones that may have been lost from outbox.
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
      enqueued++;
    }

    if (enqueued > 0) {
      _debugLog('backfillOutboxFromMeta: enqueued=$enqueued');
    }

    final updated = state.copyWith(didBackfillOutboxFromMeta: true);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
  }

  Future<void> _bootstrapLocalRecordsIfNeeded() async {
    final state = await _ensureStateLoaded();
    final metaBox = _hiveService.syncMetaBox;

    // If meta/outbox was cleared (or a legacy migration bug happened) but the
    // flag stayed true, we'd never upload existing todos/repeats/etc and new
    // devices would only see singleton settings. Re-bootstrap when we detect any
    // missing meta for existing local records.
    if (state.didBootstrapLocalRecords) {
      bool hasMissingMeta = false;

      bool isMetaMissing(String type, String recordId) =>
          !metaBox.containsKey(SyncWriteService.metaKeyOf(type, recordId));

      for (final todo in _hiveService.todosBox.values) {
        if (isMetaMissing(SyncTypes.todo, todo.id)) {
          hasMissingMeta = true;
          break;
        }
      }
      if (!hasMissingMeta) {
        for (final repeat in _hiveService.repeatTodosBox.values) {
          if (isMetaMissing(SyncTypes.repeatTodo, repeat.id)) {
            hasMissingMeta = true;
            break;
          }
        }
      }
      if (!hasMissingMeta) {
        for (final stat in _hiveService.statisticsDataBox.values) {
          if (isMetaMissing(SyncTypes.statisticsData, stat.id)) {
            hasMissingMeta = true;
            break;
          }
        }
      }
      if (!hasMissingMeta) {
        for (final session in _hiveService.pomodoroBox.values) {
          if (isMetaMissing(SyncTypes.pomodoro, session.id)) {
            hasMissingMeta = true;
            break;
          }
        }
      }

      if (!hasMissingMeta) return;
    }

    _debugLog(
      'bootstrapLocalRecords: todos=${_hiveService.todosBox.length} '
      'repeat=${_hiveService.repeatTodosBox.length} '
      'stats=${_hiveService.statisticsDataBox.length} '
      'pomodoro=${_hiveService.pomodoroBox.length} '
      'meta=${metaBox.length} outbox=${_hiveService.syncOutboxBox.length}',
    );

    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final outbox = _hiveService.syncOutboxBox;

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
    return SyncApiClient.tokens(
      serverUrl: state.serverUrl,
      authStorage: _authStorage,
      authService: _authService,
    );
  }

  Future<void> checkServerHealth() async {
    if (!isServerConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }
    await _withStatus(SyncStatus.running, () async {
      await _ensureStateLoaded();
      await _client().health();
      await refreshProviders();
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
      } else if (e is SyncPushRejectedException) {
        if (e.rejectedByReason.length == 1 &&
            e.rejectedByReason.keys.single == 'quota_exceeded') {
          _lastErrorCode = SyncErrorCode.quotaExceeded;
          _lastErrorDetail =
              'quota_exceeded x${e.rejectedByReason.values.single}';
        } else {
          _lastErrorCode = SyncErrorCode.unknown;
          _lastErrorDetail = 'push rejected: ${e.rejectedByReason}';
        }
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
      _lastErrorDetail ??= e.toString();
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
    if (outbox.isEmpty) {
      _debugLog('pushOutbox: empty');
      return;
    }

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

    final countsByType = <String, int>{};
    for (final entry in items) {
      countsByType[entry.$2.type] = (countsByType[entry.$2.type] ?? 0) + 1;
    }
    _debugLog('pushOutbox: queued=${items.length} byType=$countsByType');

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
        if (envelope == null) {
          _debugLog(
            'pushOutbox: missing payload type=${item.type} id=${item.recordId}',
          );
          continue;
        }

        toPush.add(envelope);
        pushedKeys.add(key);
      }

      if (toPush.isEmpty) continue;

      _debugLog('pushOutbox: pushing ${toPush.length} records');
      final resp = await client.push(records: toPush);

      // Older HLC is benign (already have a newer version server-side), but other
      // rejections mean the server did not store the record. If we ignore this,
      // the UI may show "synced" while another device won't receive data.
      final rejectedByReason = <String, int>{};
      for (final r in resp.rejected) {
        if (r.reason == 'older_hlc') continue;
        rejectedByReason[r.reason] = (rejectedByReason[r.reason] ?? 0) + 1;
      }
      if (rejectedByReason.isNotEmpty) {
        throw SyncPushRejectedException(rejectedByReason);
      }

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
        final box = _hiveService.todosBox;
        var todo = box.get(recordId);
        // Legacy Hive box keys might not equal `TodoModel.id`.
        todo ??= box.values
            .where((t) => t.id == recordId)
            .cast<TodoModel?>()
            .firstOrNull;
        return todo?.toJson();
      case SyncTypes.repeatTodo:
        final box = _hiveService.repeatTodosBox;
        var repeat = box.get(recordId);
        repeat ??= box.values
            .where((t) => t.id == recordId)
            .cast<RepeatTodoModel?>()
            .firstOrNull;
        return repeat?.toJson();
      case SyncTypes.statisticsData:
        final box = _hiveService.statisticsDataBox;
        var stat = box.get(recordId);
        stat ??= box.values
            .where((t) => t.id == recordId)
            .cast<StatisticsDataModel?>()
            .firstOrNull;
        return stat?.toJson();
      case SyncTypes.pomodoro:
        final box = _hiveService.pomodoroBox;
        var pomodoro = box.get(recordId);
        pomodoro ??= box.values
            .where((t) => t.id == recordId)
            .cast<PomodoroModel?>()
            .firstOrNull;
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
