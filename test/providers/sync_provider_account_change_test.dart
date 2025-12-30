import 'dart:convert';
import 'dart:io';

import 'package:easy_todo/adapters/sync_meta_adapter.dart';
import 'package:easy_todo/adapters/sync_outbox_item_adapter.dart';
import 'package:easy_todo/adapters/sync_state_adapter.dart';
import 'package:easy_todo/models/sync_meta.dart';
import 'package:easy_todo/models/sync_outbox_item.dart';
import 'package:easy_todo/models/sync_state.dart';
import 'package:easy_todo/providers/sync_provider.dart';
import 'package:easy_todo/services/dek_storage_service.dart';
import 'package:easy_todo/services/hive_service.dart';
import 'package:easy_todo/services/sync/sync_auth_storage.dart';
import 'package:easy_todo/services/sync/sync_server_auth_service.dart';
import 'package:easy_todo/services/sync_write_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _InMemorySyncAuthStorage extends SyncAuthStorage {
  SyncAuthTokens? _tokens;

  _InMemorySyncAuthStorage({SyncAuthTokens? initial}) : _tokens = initial;

  @override
  Future<SyncAuthTokens?> read() async => _tokens;

  @override
  Future<void> write(SyncAuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

class _InMemoryDekStorageService extends DekStorageService {
  final Map<String, List<int>> _store = <String, List<int>>{};

  @override
  Future<void> writeDek({required String dekId, required List<int> dek}) async {
    _store[dekId] = dek;
  }

  @override
  Future<List<int>?> readDek({required String dekId}) async => _store[dekId];

  @override
  Future<void> deleteDek({required String dekId}) async {
    _store.remove(dekId);
  }
}

class _FakeSyncServerAuthService implements SyncServerAuthService {
  @override
  Uri buildStartUri({
    required String serverUrl,
    required String provider,
    required String appRedirect,
    required String client,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SyncAuthTokens> exchange({
    required String serverUrl,
    required String ticket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listProviders({required String serverUrl}) async =>
      const [];

  @override
  Future<SyncAuthTokens?> login({
    required String serverUrl,
    required String provider,
    required String client,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({
    required String serverUrl,
    required String refreshToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SyncAuthTokens> refresh({
    required String serverUrl,
    required String refreshToken,
  }) {
    throw UnimplementedError();
  }
}

String _jwtWithSub(String sub) {
  final header = base64Url
      .encode(
        utf8.encode(jsonEncode(<String, Object>{'alg': 'HS256', 'typ': 'JWT'})),
      )
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(<String, Object>{'sub': sub})))
      .replaceAll('=', '');
  return '$header.$payload.sig';
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp(
      'easy_todo_sync_provider_test_',
    );
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(SyncStateAdapter().typeId)) {
      Hive.registerAdapter(SyncStateAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncMetaAdapter().typeId)) {
      Hive.registerAdapter(SyncMetaAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncOutboxItemAdapter().typeId)) {
      Hive.registerAdapter(SyncOutboxItemAdapter());
    }

    await Hive.openBox<SyncState>('sync_state_box');
    await Hive.openBox<SyncMeta>('sync_meta_box');
    await Hive.openBox<SyncOutboxItem>('sync_outbox_box');
  });

  setUp(() async {
    await Hive.box<SyncState>('sync_state_box').clear();
    await Hive.box<SyncMeta>('sync_meta_box').clear();
    await Hive.box<SyncOutboxItem>('sync_outbox_box').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('resets sync cursor when auth user changes out-of-band', () async {
    final initialState = SyncState.create(deviceId: 'device_a').copyWith(
      serverUrl: 'https://example.invalid',
      syncEnabled: true,
      lastServerSeq: 123,
      didBootstrapLocalRecords: true,
      didBootstrapSettings: true,
      didBackfillOutboxFromMeta: true,
      authUserId: 'user_1',
      authProvider: 'provider',
      dekId: 'dek_1',
    );
    await Hive.box<SyncState>(
      'sync_state_box',
    ).put(SyncWriteService.stateKey, initialState);

    final metaKey = SyncWriteService.metaKeyOf(SyncTypes.todo, 't_1');
    await Hive.box<SyncMeta>('sync_meta_box').put(
      metaKey,
      SyncMeta(
        type: SyncTypes.todo,
        recordId: 't_1',
        hlcWallMsUtc: 1,
        hlcCounter: 0,
        hlcDeviceId: 'device_a',
        deletedAtMsUtc: null,
        schemaVersion: 1,
      ),
    );
    await Hive.box<SyncOutboxItem>('sync_outbox_box').put(
      metaKey,
      SyncOutboxItem(
        type: SyncTypes.todo,
        recordId: 't_1',
        lastEnqueuedAtMsUtc: 1,
      ),
    );

    final authStorage = _InMemorySyncAuthStorage(
      initial: SyncAuthTokens(
        accessToken: _jwtWithSub('user_2'),
        refreshToken: 'r',
        expiresAtMsUtc: null,
      ),
    );
    final dekStorage = _InMemoryDekStorageService();
    await dekStorage.writeDek(dekId: 'dek_1', dek: <int>[1, 2, 3]);

    final hiveService = HiveService();
    final provider = SyncProvider(
      hiveService: hiveService,
      syncWriteService: SyncWriteService(hiveService: hiveService),
      authStorage: authStorage,
      dekStorage: dekStorage,
      authService: _FakeSyncServerAuthService(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(provider.lastErrorCode, SyncErrorCode.accountChanged);
    expect(provider.syncEnabled, isFalse);
    expect(provider.lastServerSeq, 0);
    expect(provider.authUserId, 'user_2');

    expect(Hive.box<SyncMeta>('sync_meta_box').isEmpty, isTrue);
    expect(Hive.box<SyncOutboxItem>('sync_outbox_box').isEmpty, isTrue);
    expect(await dekStorage.readDek(dekId: 'dek_1'), isNull);

    provider.dispose();
  });
}
