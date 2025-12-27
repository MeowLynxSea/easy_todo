import 'package:cryptography/cryptography.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/models/sync/sync_record_envelope.dart';
import 'package:easy_todo/services/crypto/sync_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncCrypto', () {
    test('wrap/unwrap DEK roundtrip', () async {
      final crypto = SyncCrypto();

      final params = const ScryptParams(n: 16384, r: 8, p: 1, dkLen: 32);
      final salt = List<int>.filled(16, 7);
      final kek = await crypto.deriveKek(
        passphrase: 'correct horse battery staple',
        salt: salt,
        params: params,
      );

      final dek = List<int>.generate(32, (i) => i);
      const dekId = 'dek_test';

      final (nonceB64, wrappedDekB64) = await crypto.wrapDek(
        kek: kek,
        dek: dek,
        dekId: dekId,
      );

      final unwrapped = await crypto.unwrapDek(
        kek: kek,
        wrappedDekB64: wrappedDekB64,
        wrapNonceB64: nonceB64,
        dekId: dekId,
      );

      expect(unwrapped, dek);
    });

    test('unwrap with wrong passphrase fails', () async {
      final crypto = SyncCrypto();

      final params = const ScryptParams(n: 16384, r: 8, p: 1, dkLen: 32);
      final salt = List<int>.filled(16, 9);
      const dekId = 'dek_test';

      final kek = await crypto.deriveKek(
        passphrase: 'pw1',
        salt: salt,
        params: params,
      );
      final wrongKek = await crypto.deriveKek(
        passphrase: 'pw2',
        salt: salt,
        params: params,
      );

      final dek = List<int>.filled(32, 42);
      final (nonceB64, wrappedDekB64) = await crypto.wrapDek(
        kek: kek,
        dek: dek,
        dekId: dekId,
      );

      expect(
        () => crypto.unwrapDek(
          kek: wrongKek,
          wrappedDekB64: wrappedDekB64,
          wrapNonceB64: nonceB64,
          dekId: dekId,
        ),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });

    test('payload decrypt fails if AAD changes', () async {
      final crypto = SyncCrypto();
      final dek = List<int>.generate(32, (i) => 255 - i);

      final (nonceB64, ciphertextB64) = await crypto.encryptPayload(
        dek: dek,
        aad: 'aad1',
        plaintext: [1, 2, 3, 4],
      );

      expect(
        () => crypto.decryptPayload(
          dek: dek,
          aad: 'aad2',
          nonceB64: nonceB64,
          ciphertextB64: ciphertextB64,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('createKeyBundle + unlockDek works', () async {
      final crypto = SyncCrypto();
      final bundle = await crypto.createKeyBundle(
        dekId: 'dek_bundle_test',
        passphrase: 'pw',
      );

      final dek = await crypto.unlockDek(bundle: bundle, passphrase: 'pw');
      expect(dek, hasLength(32));

      expect(
        () => crypto.unlockDek(bundle: bundle, passphrase: 'wrong'),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });

    test('rewrapKeyBundle changes passphrase without changing DEK', () async {
      final crypto = SyncCrypto();
      final bundle = await crypto.createKeyBundle(
        dekId: 'dek_bundle_test',
        passphrase: 'old_pw',
      );
      final dek = await crypto.unlockDek(bundle: bundle, passphrase: 'old_pw');

      final updatedBundle = await crypto.rewrapKeyBundle(
        current: bundle,
        dek: dek,
        newPassphrase: 'new_pw',
        expectedBundleVersion: bundle.bundleVersion,
      );

      final dek2 = await crypto.unlockDek(
        bundle: updatedBundle,
        passphrase: 'new_pw',
      );
      expect(dek2, dek);

      expect(
        () => crypto.unlockDek(bundle: updatedBundle, passphrase: 'old_pw'),
        throwsA(isA<InvalidPassphraseException>()),
      );
    });

    test('encryptRecord/decryptRecordPayload roundtrip', () async {
      final crypto = SyncCrypto();
      final dek = List<int>.generate(32, (i) => i * 3 % 256);

      const type = 'todo';
      const recordId = 'r1';
      const hlc = HlcJson(wallTimeMsUtc: 1, counter: 2, deviceId: 'dev');
      const schemaVersion = 1;
      const dekId = 'dek1';

      final envelope = await crypto.encryptRecord(
        type: type,
        recordId: recordId,
        hlc: hlc,
        deletedAtMsUtc: null,
        schemaVersion: schemaVersion,
        dekId: dekId,
        dek: dek,
        payloadPlaintext: [10, 20, 30],
      );

      final payload = await crypto.decryptRecordPayload(
        envelope: envelope,
        dek: dek,
      );
      expect(payload, [10, 20, 30]);

      final tampered = SyncRecordEnvelope(
        type: envelope.type,
        recordId: 'r2',
        hlc: envelope.hlc,
        deletedAtMsUtc: envelope.deletedAtMsUtc,
        schemaVersion: envelope.schemaVersion,
        dekId: envelope.dekId,
        payloadAlgo: envelope.payloadAlgo,
        nonce: envelope.nonce,
        ciphertext: envelope.ciphertext,
      );

      expect(
        () => crypto.decryptRecordPayload(envelope: tampered, dek: dek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}
