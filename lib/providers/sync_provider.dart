import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'package:easy_todo/services/notification_service.dart';
import 'package:easy_todo/services/secure_storage_service.dart';
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

enum SyncStatus { idle, running, error }

enum SyncRunTrigger { manual, auto }

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

  static const Duration _autoSyncIndicatorMinVisible = Duration(
    milliseconds: 800,
  );
  static const Duration _autoSyncDebounceWindow = Duration(seconds: 2);
  static const Duration _autoSyncRetryBaseDelay = Duration(seconds: 5);
  static const Duration _autoSyncMaxBackoff = Duration(minutes: 5);

  static final Random _jitterRandom = Random.secure();

  final HiveService _hiveService;
  final SyncWriteService _syncWriteService;
  final SyncCrypto _crypto;
  final DekStorageService _dekStorage;
  final SecureStorageService _secureStorage;
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
  double? _kdfProgress;
  int _autoSyncCompletedRevision = 0;

  Completer<void>? _syncMutex;
  bool _autoSyncInProgress = false;
  int? _autoSyncIndicatorStartMs;
  Timer? _autoSyncIndicatorHideTimer;

  StreamSubscription? _outboxSub;
  Timer? _autoSyncTimer;
  Timer? _autoSyncDebounceTimer;
  int _autoSyncFailureCount = 0;
  bool _appActive = true;

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[Sync] $message');
  }

  SyncProvider({
    HiveService? hiveService,
    SyncWriteService? syncWriteService,
    SyncCrypto? crypto,
    DekStorageService? dekStorage,
    SecureStorageService? secureStorage,
    SyncAuthStorage? authStorage,
    SyncServerAuthService? authService,
  }) : _hiveService = hiveService ?? HiveService(),
       _syncWriteService = syncWriteService ?? SyncWriteService(),
       _crypto = crypto ?? SyncCrypto(),
       _dekStorage = dekStorage ?? DekStorageService(),
       _secureStorage = secureStorage ?? SecureStorageService(),
       _authStorage = authStorage ?? SyncAuthStorage(),
       _authService = authService ?? createSyncServerAuthService() {
    unawaited(_init());
  }

  SyncStatus get status => _status;
  SyncErrorCode? get lastErrorCode => _lastErrorCode;
  String? get lastErrorDetail => _lastErrorDetail;
  DateTime? get lastSyncAt => _lastSyncAt;
  double? get kdfProgress => _kdfProgress;
  bool get isAutoSyncInProgress => _autoSyncInProgress;
  int get autoSyncCompletedRevision => _autoSyncCompletedRevision;

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
  int get autoSyncIntervalSeconds =>
      _state?.autoSyncIntervalSeconds ??
      SyncState.defaultAutoSyncIntervalSeconds;

  Future<void> _init() async {
    final state = await _ensureStateLoaded();
    _authTokens = await _authStorage.read();

    if (state.serverUrl.trim().isNotEmpty) {
      unawaited(refreshProviders());
    }

    if (state.syncEnabled && state.dekId != null) {
      final cached = await _dekStorage.readDek(dekId: state.dekId!);
      if (cached != null) {
        _dek = cached;
      }
    }

    _startAutoSync();
    notifyListeners();
  }

  void onAppResumed() {
    _appActive = true;
    _scheduleDebouncedAutoSync(reason: 'resume');
  }

  void onAppPaused() {
    _appActive = false;
  }

  void _startAutoSync() {
    _outboxSub ??= _hiveService.syncOutboxBox.watch().listen((_) {
      if (!_appActive) return;
      if (_hiveService.syncOutboxBox.isEmpty) return;
      _scheduleDebouncedAutoSync(reason: 'outbox');
    });

    _scheduleNextAutoSync(after: const Duration(seconds: 2));
  }

  void _scheduleDebouncedAutoSync({required String reason}) {
    _autoSyncDebounceTimer?.cancel();
    _autoSyncDebounceTimer = Timer(_autoSyncDebounceWindow, () {
      unawaited(_attemptAutoSync(reason: reason));
    });
  }

  void _scheduleNextAutoSync({required Duration after}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(_withJitter(after), () {
      unawaited(_attemptAutoSync(reason: 'timer'));
    });
  }

  Duration _withJitter(Duration base) {
    final jitterMs = _jitterRandom.nextInt(700);
    return base + Duration(milliseconds: jitterMs);
  }

  Duration _computeBackoffDelay() {
    final exp = _autoSyncFailureCount.clamp(0, 6);
    final multiplier = 1 << exp;
    final candidateMs = _autoSyncRetryBaseDelay.inMilliseconds * multiplier;
    final cappedMs = min(candidateMs, _autoSyncMaxBackoff.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }

  bool _canAutoSync() {
    if (!_appActive) return false;
    if (!syncEnabled) return false;
    if (!isConfigured) return false;
    if (!isUnlocked) return false;
    if (status == SyncStatus.running) return false;
    return true;
  }

  Future<void> _attemptAutoSync({required String reason}) async {
    if (!_canAutoSync()) {
      _scheduleNextAutoSync(after: _autoSyncInterval());
      return;
    }

    // Avoid hammering when logged out/expired: let user re-login explicitly.
    if (!isLoggedIn) {
      _scheduleNextAutoSync(after: _autoSyncInterval());
      return;
    }

    try {
      _debugLog(
        'autoSync attempt reason=$reason outbox=${_hiveService.syncOutboxBox.length}',
      );
      await syncNow(trigger: SyncRunTrigger.auto);
      _autoSyncFailureCount = 0;
      _scheduleNextAutoSync(after: _autoSyncInterval());
    } catch (e) {
      // Surface error state via SyncProvider, but keep auto-sync resilient.
      if (e is SyncApiException) {
        final statusCode = e.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          _autoSyncFailureCount = 0;
          _scheduleNextAutoSync(after: _autoSyncInterval());
          return;
        }
      }

      _autoSyncFailureCount++;
      _scheduleNextAutoSync(after: _computeBackoffDelay());
    }
  }

  Duration _autoSyncInterval() {
    final seconds = autoSyncIntervalSeconds.clamp(
      SyncState.minAutoSyncIntervalSeconds,
      24 * 60 * 60,
    );
    return Duration(seconds: seconds);
  }

  Future<void> setAutoSyncIntervalSeconds(int seconds) async {
    final state = await _ensureStateLoaded();
    final normalized = seconds < SyncState.minAutoSyncIntervalSeconds
        ? SyncState.minAutoSyncIntervalSeconds
        : seconds;
    final updated = state.copyWith(autoSyncIntervalSeconds: normalized);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    _scheduleNextAutoSync(after: _autoSyncInterval());
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

    final didChangeServer = normalizedPrev != normalizedNext;
    if (normalizedPrev.isNotEmpty && didChangeServer) {
      await _resetForNewSyncServer(state: state);
    }

    final updated = state.copyWith(serverUrl: nextUrl);
    await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
    _state = updated;
    if (didChangeServer) {
      await _authStorage.clear();
      _authTokens = null;
      _availableProviders = const [];
    }
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

  Future<void> exchangeAuthTicket(String ticket) async {
    final normalized = ticket.trim();
    if (normalized.isEmpty) {
      _setError(SyncErrorCode.unauthorized, detail: 'missing ticket');
      return;
    }

    final state = await _ensureStateLoaded();
    if (state.serverUrl.trim().isEmpty) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }

    await _withStatus(SyncStatus.running, () async {
      final tokens = await _authService.exchange(
        serverUrl: state.serverUrl,
        ticket: normalized,
      );
      await _onAuthTokensUpdated(tokens);
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

  @override
  void dispose() {
    unawaited(_outboxSub?.cancel());
    _autoSyncTimer?.cancel();
    _autoSyncDebounceTimer?.cancel();
    _autoSyncIndicatorHideTimer?.cancel();
    super.dispose();
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
      _clearKdfProgress();
      try {
        final existing = await client.getKeyBundle();
        if (existing == null) {
          final dekId = const Uuid().v4();
          final (createdBundle, createdDek) = await _crypto
              .createKeyBundleWithDek(
                dekId: dekId,
                passphrase: passphrase,
                onKdfProgress: _updateKdfProgress,
              );
          _bundle = await client.putKeyBundle(
            expectedBundleVersion: 0,
            bundle: createdBundle,
          );
          _dek = createdDek;
        } else {
          _bundle = existing;
        }

        final bundle = _bundle!;
        final cached = await _dekStorage.readDek(dekId: bundle.dekId);
        _dek =
            cached ??
            _dek ??
            await _crypto.unlockDek(
              bundle: bundle,
              passphrase: passphrase,
              onKdfProgress: _updateKdfProgress,
            );
        await _dekStorage.writeDek(dekId: bundle.dekId, dek: _dek!);

        final state = await _ensureStateLoaded();
        final updated = state.copyWith(syncEnabled: true, dekId: bundle.dekId);
        await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
        _state = updated;
      } finally {
        _clearKdfProgress();
      }
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
      _clearKdfProgress();
      try {
        final cached = await _dekStorage.readDek(dekId: bundle.dekId);
        _dek =
            cached ??
            await _crypto.unlockDek(
              bundle: bundle,
              passphrase: passphrase,
              onKdfProgress: _updateKdfProgress,
            );
        await _dekStorage.writeDek(dekId: bundle.dekId, dek: _dek!);

        final state = await _ensureStateLoaded();
        final updated = state.copyWith(dekId: bundle.dekId);
        await _hiveService.syncStateBox.put(SyncWriteService.stateKey, updated);
        _state = updated;
      } finally {
        _clearKdfProgress();
      }
    });
  }

  Future<void> changePassphrase({
    required String newPassphrase,
    String? confirmNewPassphrase,
    String? currentPassphrase,
  }) async {
    if (confirmNewPassphrase != null && newPassphrase != confirmNewPassphrase) {
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
      final bundle = await client.getKeyBundle();
      if (bundle == null) {
        throw const SyncApiException('key bundle not found', statusCode: 404);
      }
      _bundle = bundle;

      var dek = _dek;
      dek ??= await _dekStorage.readDek(dekId: bundle.dekId);

      if (dek == null) {
        final current = (currentPassphrase ?? '').trim();
        if (current.isEmpty) {
          throw const InvalidPassphraseException('Missing current passphrase');
        }
        _clearKdfProgress();
        try {
          dek = await _crypto.unlockDek(
            bundle: bundle,
            passphrase: current,
            onKdfProgress: _updateKdfProgress,
          );
        } finally {
          _clearKdfProgress();
        }
      }

      _clearKdfProgress();
      try {
        final nextBundle = await _crypto.rewrapKeyBundle(
          current: bundle,
          dek: dek,
          newPassphrase: newPassphrase,
          expectedBundleVersion: bundle.bundleVersion,
          onKdfProgress: _updateKdfProgress,
        );
        final updated = await client.putKeyBundle(
          expectedBundleVersion: bundle.bundleVersion,
          bundle: nextBundle,
        );

        _bundle = updated;
        _dek = dek;
        await _dekStorage.writeDek(dekId: updated.dekId, dek: dek);

        final state = await _ensureStateLoaded();
        final updatedState = state.copyWith(dekId: updated.dekId);
        await _hiveService.syncStateBox.put(
          SyncWriteService.stateKey,
          updatedState,
        );
        _state = updatedState;
      } finally {
        _clearKdfProgress();
      }
    });
  }

  void _updateKdfProgress(double progress) {
    final next = progress.clamp(0.0, 1.0);
    final current = _kdfProgress;
    if (current != null &&
        (next - current).abs() < 0.01 &&
        next != 0 &&
        next != 1) {
      return;
    }
    _kdfProgress = next;
    notifyListeners();
  }

  void _clearKdfProgress() {
    if (_kdfProgress == null) return;
    _kdfProgress = null;
    notifyListeners();
  }

  Future<void> syncNow({
    bool allowRollback = false,
    SyncRunTrigger trigger = SyncRunTrigger.manual,
  }) async {
    await _ensureStateLoaded();
    if (!syncEnabled) {
      _setError(SyncErrorCode.disabled);
      return;
    }
    _authTokens = await _authStorage.read();
    if (!isConfigured) {
      _setError(SyncErrorCode.notConfigured);
      return;
    }
    if (_dek == null) {
      _setError(SyncErrorCode.locked);
      return;
    }

    if (_syncMutex != null) return _syncMutex!.future;
    if (trigger == SyncRunTrigger.auto) {
      _autoSyncIndicatorHideTimer?.cancel();
      _autoSyncInProgress = true;
      _autoSyncIndicatorStartMs = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    }
    final mutex = Completer<void>();
    _syncMutex = mutex;

    var succeeded = false;
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

        // Fresh sync state (e.g. switching accounts, first device, or after
        // clearing sync state). If the server already has data, avoid pushing
        // local defaults/outbox first which could overwrite server state
        // (especially singleton settings).
        final stateBefore = await _ensureStateLoaded();
        if (_isFreshSyncState(stateBefore)) {
          final probe = await client.pull(since: 0, limit: 1);
          final serverHasData =
              probe.records.isNotEmpty || probe.nextSince > 0;
          if (serverHasData) {
            _debugLog('fresh sync: server has data, adopting server state');
            await _clearLocalBusinessDataForServerAdoption();
            await _pullAndMerge(
              client,
              sinceBefore: 0,
              allowRollback: allowRollback,
            );
            final afterPull = await _ensureStateLoaded();
            final adopted = afterPull.copyWith(
              didBootstrapLocalRecords: true,
              didBootstrapSettings: true,
              didBackfillOutboxFromMeta: true,
            );
            await _hiveService.syncStateBox.put(
              SyncWriteService.stateKey,
              adopted,
            );
            _state = adopted;
            return;
          }
        }

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
      succeeded = true;
    } finally {
      if (!mutex.isCompleted) mutex.complete();
      _syncMutex = null;
      if (trigger == SyncRunTrigger.auto && _autoSyncInProgress) {
        final startedAt = _autoSyncIndicatorStartMs;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = startedAt == null ? 0 : (nowMs - startedAt);
        final remainingMs =
            _autoSyncIndicatorMinVisible.inMilliseconds - elapsedMs;

        if (remainingMs > 0) {
          _autoSyncIndicatorHideTimer?.cancel();
          _autoSyncIndicatorHideTimer = Timer(
            Duration(milliseconds: remainingMs),
            () {
              _autoSyncInProgress = false;
              _autoSyncIndicatorStartMs = null;
              notifyListeners();
            },
          );
        } else {
          _autoSyncInProgress = false;
          _autoSyncIndicatorStartMs = null;
          notifyListeners();
        }
      }

      if (trigger == SyncRunTrigger.auto && succeeded) {
        _autoSyncCompletedRevision++;
        notifyListeners();
      }
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
      await UserPreferencesRepository(
        hiveService: _hiveService,
        syncWriteService: _syncWriteService,
      ).load();
    }
    await enqueue(
      type: SyncTypes.userPrefs,
      recordId: SyncRecordIds.singleton,
      schemaVersion: UserPreferencesRepository.schemaVersion,
    );

    final aiBox = _hiveService.aiSettingsBox;
    if (!aiBox.containsKey(AISettingsRepository.hiveKey)) {
      await AISettingsRepository(
        hiveService: _hiveService,
        syncWriteService: _syncWriteService,
      ).save(AISettingsModel.create());
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

  bool _isFreshSyncState(SyncState state) {
    if (state.lastServerSeq != 0) return false;
    if (state.didBootstrapLocalRecords) return false;
    if (state.didBootstrapSettings) return false;
    if (state.didBackfillOutboxFromMeta) return false;
    if (_hiveService.syncMetaBox.isNotEmpty) return false;
    if (_hiveService.syncOutboxBox.isNotEmpty) return false;
    return true;
  }

  Future<void> _clearLocalBusinessDataForServerAdoption() async {
    await _hiveService.todosBox.clear();
    await _hiveService.repeatTodosBox.clear();
    await _hiveService.statisticsDataBox.clear();
    await _hiveService.pomodoroBox.clear();

    // Local-only derived stats/history.
    await _hiveService.statisticsBox.clear();

    // Avoid pushing device-local preferences over existing server settings.
    await _hiveService.userPreferencesBox.clear();
    await _hiveService.aiSettingsBox.clear();
    await _secureStorage.deleteAiApiKey();

    // Ensure no stale sync state remains.
    await _hiveService.syncOutboxBox.clear();
    await _hiveService.syncMetaBox.clear();
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
        } else if (e.statusCode == 402) {
          _lastErrorCode = SyncErrorCode.quotaExceeded;
          _lastErrorDetail = e.message;
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
        if (settings == null) return null;
        if (!settings.syncApiKey) {
          return settings.toJson(includeApiKey: false);
        }
        final apiKey = await _secureStorage.readAiApiKey();
        return settings
            .copyWith(apiKey: apiKey ?? '')
            .toJson(includeApiKey: true);
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
    var touchedTodos = false;

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
        if (remote.type == SyncTypes.todo) {
          touchedTodos = true;
        }

        if (remote.deletedAtMsUtc == null) {
          if (state.dekId != null && remote.dekId != state.dekId) {
            throw StateError(
              'DEK mismatch: expected=${state.dekId} got=${remote.dekId} '
              'type=${remote.type} id=${remote.recordId}',
            );
          }

          final payloadBytes = await _crypto.decryptRecordPayload(
            envelope: remote,
            dek: dek,
          );
          final decoded = jsonDecode(utf8.decode(payloadBytes));
          if (decoded is! Map<String, dynamic>) {
            throw StateError(
              'invalid record payload json: expected object, got ${decoded.runtimeType} '
              'type=${remote.type} id=${remote.recordId}',
            );
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

    if (touchedTodos) {
      try {
        await NotificationService.instance.rescheduleAllReminders();
      } catch (e) {
        debugPrint('[Sync] Failed to reschedule reminders after pull: $e');
      }
    }
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
        final decoded = AISettingsModel.fromJson(payload);
        final apiKey = decoded.apiKey.trim();
        if (decoded.syncApiKey) {
          if (apiKey.isNotEmpty) {
            await _secureStorage.writeAiApiKey(apiKey);
          }
        } else {
          // When apiKey syncing is disabled, do not keep any synced key on disk.
          await _secureStorage.deleteAiApiKey();
        }
        await _hiveService.aiSettingsBox.put(
          AISettingsRepository.hiveKey,
          decoded.copyWith(apiKey: ''),
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
