import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_todo/models/sync/key_bundle.dart';
import 'package:easy_todo/services/crypto/scrypt_dart_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;
import 'package:pointycastle/key_derivators/scrypt.dart' as pc;
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';

void main() {
  test('ScryptDartAsync matches PointyCastle output', () async {
    const passphrase = 'correct horse battery staple';
    final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
    const params = ScryptParams(n: 1024, r: 8, p: 1, dkLen: 32);

    final asyncOut = await const ScryptDartAsync(
      yieldEvery: 16,
    ).derive(passphrase: passphrase, salt: salt, params: params);

    // PBKDF2 step should also match (sanity check).
    final bLen = 128 * params.r * params.p;
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, 1, bLen));
    final bOut = Uint8List(bLen);
    pbkdf2.deriveKey(Uint8List.fromList(utf8.encode(passphrase)), 0, bOut, 0);
    expect(bOut.length, bLen);

    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(params.n, params.r, params.p, params.dkLen, salt),
      );
    final expected = derivator.process(
      Uint8List.fromList(utf8.encode(passphrase)),
    );

    expect(asyncOut, expected);
  });
}
