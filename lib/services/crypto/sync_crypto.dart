import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/models/sync/sync_record_envelope.dart';
import 'package:easy_todo/services/crypto/scrypt_dart_async.dart';
import 'package:easy_todo/utils/base64_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;
import 'package:pointycastle/key_derivators/scrypt.dart' as pc;

class InvalidPassphraseException implements Exception {
  final String message;
  const InvalidPassphraseException([this.message = 'Invalid passphrase']);
  @override
  String toString() => 'InvalidPassphraseException: $message';
}

class SyncCrypto {
  static const String kdfName = 'scrypt';
  static const String aeadName = 'aes-256-gcm';

  static const int dekLengthBytes = 32;
  static const int nonceLengthBytes = 12;
  static const int gcmTagLengthBytes = 16;

  final Cipher _aead;

  static final Random _random = Random.secure();

  SyncCrypto() : _aead = AesGcm.with256bits();

  static List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  Future<List<int>> generateDek() async => _randomBytes(dekLengthBytes);

  Future<SecretKey> deriveKek({
    required String passphrase,
    required List<int> salt,
    required ScryptParams params,
  }) async {
    if (kIsWeb) {
      final derived = await const ScryptDartAsync().derive(
        passphrase: passphrase,
        salt: Uint8List.fromList(salt),
        params: params,
      );
      return SecretKey(derived);
    }

    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          params.n,
          params.r,
          params.p,
          params.dkLen,
          Uint8List.fromList(salt),
        ),
      );

    final derived = derivator.process(
      Uint8List.fromList(utf8.encode(passphrase)),
    );
    return SecretKey(derived);
  }

  List<int> randomSalt({int lengthBytes = 16}) => _randomBytes(lengthBytes);

  List<int> randomNonce({int lengthBytes = nonceLengthBytes}) =>
      _randomBytes(lengthBytes);

  Future<(String nonceB64, String wrappedDekB64)> wrapDek({
    required SecretKey kek,
    required List<int> dek,
    required String dekId,
  }) async {
    final nonce = randomNonce();
    final secretBox = await _aead.encrypt(
      dek,
      secretKey: kek,
      nonce: nonce,
      aad: utf8.encode(dekId),
    );

    final combined = <int>[...secretBox.cipherText, ...secretBox.mac.bytes];
    return (base64UrlNoPadEncode(nonce), base64UrlNoPadEncode(combined));
  }

  Future<List<int>> unwrapDek({
    required SecretKey kek,
    required String wrappedDekB64,
    required String wrapNonceB64,
    required String dekId,
  }) async {
    final nonce = base64UrlNoPadDecode(wrapNonceB64);
    final combined = base64UrlNoPadDecode(wrappedDekB64);
    if (combined.length < gcmTagLengthBytes) {
      throw const InvalidPassphraseException('Invalid wrapped DEK');
    }
    final cipherText = combined.sublist(0, combined.length - gcmTagLengthBytes);
    final macBytes = combined.sublist(combined.length - gcmTagLengthBytes);

    try {
      return await _aead.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: kek,
        aad: utf8.encode(dekId),
      );
    } on SecretBoxAuthenticationError {
      throw const InvalidPassphraseException();
    }
  }

  String buildAadV1({
    required String type,
    required String recordId,
    required HlcJson hlc,
    required int? deletedAtMsUtc,
    required int schemaVersion,
    required String dekId,
  }) {
    final deleted = deletedAtMsUtc == null ? '' : deletedAtMsUtc.toString();
    return 'v1|$type|$recordId|${hlc.wallTimeMsUtc}|${hlc.counter}|${hlc.deviceId}|$deleted|$schemaVersion|$dekId';
  }

  Future<(String nonceB64, String ciphertextB64)> encryptPayload({
    required List<int> dek,
    required String aad,
    required List<int> plaintext,
  }) async {
    final nonce = randomNonce();
    final secretBox = await _aead.encrypt(
      plaintext,
      secretKey: SecretKey(dek),
      nonce: nonce,
      aad: utf8.encode(aad),
    );
    final combined = <int>[...secretBox.cipherText, ...secretBox.mac.bytes];
    return (base64UrlNoPadEncode(nonce), base64UrlNoPadEncode(combined));
  }

  Future<List<int>> decryptPayload({
    required List<int> dek,
    required String aad,
    required String nonceB64,
    required String ciphertextB64,
  }) async {
    final nonce = base64UrlNoPadDecode(nonceB64);
    final combined = base64UrlNoPadDecode(ciphertextB64);
    if (combined.length < gcmTagLengthBytes) {
      throw SecretBoxAuthenticationError();
    }
    final cipherText = combined.sublist(0, combined.length - gcmTagLengthBytes);
    final macBytes = combined.sublist(combined.length - gcmTagLengthBytes);
    return _aead.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
      secretKey: SecretKey(dek),
      aad: utf8.encode(aad),
    );
  }

  Future<KeyBundle> createKeyBundle({
    required String dekId,
    required String passphrase,
    ScryptParams? params,
  }) async {
    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final salt = randomSalt();
    final kdfParams =
        params ?? const ScryptParams(n: 16384, r: 8, p: 1, dkLen: 32);
    final kek = await deriveKek(
      passphrase: passphrase,
      salt: salt,
      params: kdfParams,
    );
    final dek = await generateDek();
    final (wrapNonce, wrappedDek) = await wrapDek(
      kek: kek,
      dek: dek,
      dekId: dekId,
    );
    return KeyBundle(
      bundleVersion: 0,
      dekId: dekId,
      kdf: kdfName,
      salt: base64UrlNoPadEncode(salt),
      kdfParams: kdfParams,
      wrapAlgo: aeadName,
      wrappedDek: wrappedDek,
      wrapNonce: wrapNonce,
      updatedAtMsUtc: nowMsUtc,
    );
  }

  Future<List<int>> unlockDek({
    required KeyBundle bundle,
    required String passphrase,
  }) async {
    if (bundle.kdf != kdfName) {
      throw UnsupportedError('Unsupported KDF: ${bundle.kdf}');
    }
    if (bundle.wrapAlgo != aeadName) {
      throw UnsupportedError('Unsupported wrap algo: ${bundle.wrapAlgo}');
    }
    final salt = base64UrlNoPadDecode(bundle.salt);
    final kek = await deriveKek(
      passphrase: passphrase,
      salt: salt,
      params: bundle.kdfParams,
    );
    return unwrapDek(
      kek: kek,
      wrappedDekB64: bundle.wrappedDek,
      wrapNonceB64: bundle.wrapNonce,
      dekId: bundle.dekId,
    );
  }

  Future<KeyBundle> rewrapKeyBundle({
    required KeyBundle current,
    required List<int> dek,
    required String newPassphrase,
    required int expectedBundleVersion,
    ScryptParams? params,
  }) async {
    final nowMsUtc = DateTime.now().toUtc().millisecondsSinceEpoch;
    final salt = randomSalt();
    final kdfParams =
        params ?? const ScryptParams(n: 16384, r: 8, p: 1, dkLen: 32);
    final kek = await deriveKek(
      passphrase: newPassphrase,
      salt: salt,
      params: kdfParams,
    );
    final (wrapNonce, wrappedDek) = await wrapDek(
      kek: kek,
      dek: dek,
      dekId: current.dekId,
    );
    return KeyBundle(
      bundleVersion: expectedBundleVersion,
      dekId: current.dekId,
      kdf: kdfName,
      salt: base64UrlNoPadEncode(salt),
      kdfParams: kdfParams,
      wrapAlgo: aeadName,
      wrappedDek: wrappedDek,
      wrapNonce: wrapNonce,
      updatedAtMsUtc: nowMsUtc,
    );
  }

  Future<SyncRecordEnvelope> encryptRecord({
    required String type,
    required String recordId,
    required HlcJson hlc,
    required int? deletedAtMsUtc,
    required int schemaVersion,
    required String dekId,
    required List<int> dek,
    required List<int> payloadPlaintext,
  }) async {
    final aad = buildAadV1(
      type: type,
      recordId: recordId,
      hlc: hlc,
      deletedAtMsUtc: deletedAtMsUtc,
      schemaVersion: schemaVersion,
      dekId: dekId,
    );
    final (nonce, ciphertext) = await encryptPayload(
      dek: dek,
      aad: aad,
      plaintext: payloadPlaintext,
    );
    return SyncRecordEnvelope(
      type: type,
      recordId: recordId,
      hlc: hlc,
      deletedAtMsUtc: deletedAtMsUtc,
      schemaVersion: schemaVersion,
      dekId: dekId,
      payloadAlgo: aeadName,
      nonce: nonce,
      ciphertext: ciphertext,
    );
  }

  Future<List<int>> decryptRecordPayload({
    required SyncRecordEnvelope envelope,
    required List<int> dek,
  }) async {
    if (envelope.payloadAlgo != aeadName) {
      throw UnsupportedError(
        'Unsupported payload algo: ${envelope.payloadAlgo}',
      );
    }
    final aad = buildAadV1(
      type: envelope.type,
      recordId: envelope.recordId,
      hlc: envelope.hlc,
      deletedAtMsUtc: envelope.deletedAtMsUtc,
      schemaVersion: envelope.schemaVersion,
      dekId: envelope.dekId,
    );
    return decryptPayload(
      dek: dek,
      aad: aad,
      nonceB64: envelope.nonce,
      ciphertextB64: envelope.ciphertext,
    );
  }
}
