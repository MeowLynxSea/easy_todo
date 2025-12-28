import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:easy_todo/models/sync/key_bundle.dart';

/// Async scrypt implementation that yields to the event loop periodically.
///
/// This is intended for Flutter Web to avoid UI jank (main thread blocking).
///
/// Implementation follows RFC 7914.
class ScryptDartAsync {
  /// How often to check whether we should yield to the event loop.
  ///
  /// Smaller values yield more responsively (less UI jank), at the cost of some
  /// overhead.
  final int yieldEvery;

  /// Maximum CPU slice before yielding.
  final Duration maxCpuSlice;

  const ScryptDartAsync({
    this.yieldEvery = 1,
    this.maxCpuSlice = const Duration(milliseconds: 8),
  });

  Future<Uint8List> derive({
    required String passphrase,
    required Uint8List salt,
    required ScryptParams params,
  }) async {
    final n = params.n;
    final r = params.r;
    final p = params.p;
    final dkLen = params.dkLen;

    if (n <= 1 || (n & (n - 1)) != 0) {
      throw ArgumentError.value(n, 'n', 'must be a power of 2 and > 1');
    }
    if (r <= 0) throw ArgumentError.value(r, 'r', 'must be > 0');
    if (p <= 0) throw ArgumentError.value(p, 'p', 'must be > 0');
    if (dkLen <= 0) throw ArgumentError.value(dkLen, 'dkLen', 'must be > 0');

    final blockSize = 128 * r;
    final bLen = p * blockSize;

    final sliceStopwatch = Stopwatch()..start();

    final pbkdf2B = Pbkdf2.hmacSha256(iterations: 1, bits: bLen * 8);
    final bKey = await pbkdf2B.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final bBytes = Uint8List.fromList(await bKey.extractBytes());

    // ROMix each parallel block.
    for (var i = 0; i < p; i++) {
      final start = i * blockSize;
      final end = start + blockSize;
      // IMPORTANT: must be a view into `bBytes`, not a copy; ROMix mutates in place.
      final chunk = Uint8List.sublistView(bBytes, start, end);
      await _romixInPlace(chunk, n: n, r: r, sliceStopwatch: sliceStopwatch);

      // Yield between parallel blocks as well.
      await Future<void>.delayed(Duration.zero);
    }

    final pbkdf2DK = Pbkdf2.hmacSha256(iterations: 1, bits: dkLen * 8);
    final dkKey = await pbkdf2DK.deriveKeyFromPassword(
      password: passphrase,
      nonce: bBytes,
    );
    return Uint8List.fromList(await dkKey.extractBytes());
  }

  Future<void> _romixInPlace(
    Uint8List bBytes, {
    required int n,
    required int r,
    required Stopwatch sliceStopwatch,
  }) async {
    final xLen = 32 * r; // u32 words
    final x = _bytesToU32le(bBytes);
    final y = Uint32List(xLen);
    final v = Uint32List(n * xLen);

    for (var i = 0; i < n; i++) {
      v.setRange(i * xLen, (i + 1) * xLen, x);
      _blockMixSalsa8(x, y, r);
      if (i % yieldEvery == 0) {
        await _maybeYield(sliceStopwatch);
      }
    }

    for (var i = 0; i < n; i++) {
      final j = _integerifyIndex(x, r, n);
      _xorWithV(x, v, j * xLen);
      _blockMixSalsa8(x, y, r);
      if (i % yieldEvery == 0) {
        await _maybeYield(sliceStopwatch);
      }
    }

    _u32leToBytesInPlace(x, bBytes);
  }

  Future<void> _maybeYield(Stopwatch sliceStopwatch) async {
    if (sliceStopwatch.elapsed < maxCpuSlice) return;
    sliceStopwatch.reset();
    await Future<void>.delayed(Duration.zero);
  }

  static Uint32List _bytesToU32le(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final out = Uint32List(bytes.length ~/ 4);
    for (var i = 0; i < out.length; i++) {
      out[i] = bd.getUint32(i * 4, Endian.little);
    }
    return out;
  }

  static void _u32leToBytesInPlace(Uint32List words, Uint8List outBytes) {
    final bd = ByteData.sublistView(outBytes);
    for (var i = 0; i < words.length; i++) {
      bd.setUint32(i * 4, words[i], Endian.little);
    }
  }

  static int _integerifyIndex(Uint32List x, int r, int n) {
    final offset = (2 * r - 1) * 16;
    // N is a power of two; integerify is little-endian, so the low 32 bits are
    // enough for the modulo.
    return x[offset] & (n - 1);
  }

  static void _xorWithV(Uint32List x, Uint32List v, int vOffset) {
    for (var i = 0; i < x.length; i++) {
      x[i] ^= v[vOffset + i];
    }
  }

  static void _blockMixSalsa8(Uint32List x, Uint32List y, int r) {
    // x and y are 2r blocks of 16 u32 each.
    final blocks = 2 * r;
    final t = Uint32List(16);

    // T = X[2r - 1]
    final lastOffset = (blocks - 1) * 16;
    for (var i = 0; i < 16; i++) {
      t[i] = x[lastOffset + i];
    }

    for (var i = 0; i < blocks; i++) {
      final off = i * 16;
      for (var k = 0; k < 16; k++) {
        t[k] ^= x[off + k];
      }
      _salsa208(t);
      for (var k = 0; k < 16; k++) {
        y[off + k] = t[k];
      }
    }

    // Recombine output into x: even blocks then odd blocks.
    for (var i = 0; i < r; i++) {
      final src = (2 * i) * 16;
      final dst = i * 16;
      for (var k = 0; k < 16; k++) {
        x[dst + k] = y[src + k];
      }
    }
    for (var i = 0; i < r; i++) {
      final src = (2 * i + 1) * 16;
      final dst = (i + r) * 16;
      for (var k = 0; k < 16; k++) {
        x[dst + k] = y[src + k];
      }
    }
  }

  static int _rotl32(int v, int c) {
    final x = v & 0xffffffff;
    return ((x << c) | (x >> (32 - c))) & 0xffffffff;
  }

  static void _salsa208(Uint32List b) {
    final x = Uint32List.fromList(b);

    for (var i = 0; i < 8; i += 2) {
      // Column rounds
      x[4] ^= _rotl32((x[0] + x[12]) & 0xffffffff, 7);
      x[8] ^= _rotl32((x[4] + x[0]) & 0xffffffff, 9);
      x[12] ^= _rotl32((x[8] + x[4]) & 0xffffffff, 13);
      x[0] ^= _rotl32((x[12] + x[8]) & 0xffffffff, 18);

      x[9] ^= _rotl32((x[5] + x[1]) & 0xffffffff, 7);
      x[13] ^= _rotl32((x[9] + x[5]) & 0xffffffff, 9);
      x[1] ^= _rotl32((x[13] + x[9]) & 0xffffffff, 13);
      x[5] ^= _rotl32((x[1] + x[13]) & 0xffffffff, 18);

      x[14] ^= _rotl32((x[10] + x[6]) & 0xffffffff, 7);
      x[2] ^= _rotl32((x[14] + x[10]) & 0xffffffff, 9);
      x[6] ^= _rotl32((x[2] + x[14]) & 0xffffffff, 13);
      x[10] ^= _rotl32((x[6] + x[2]) & 0xffffffff, 18);

      x[3] ^= _rotl32((x[15] + x[11]) & 0xffffffff, 7);
      x[7] ^= _rotl32((x[3] + x[15]) & 0xffffffff, 9);
      x[11] ^= _rotl32((x[7] + x[3]) & 0xffffffff, 13);
      x[15] ^= _rotl32((x[11] + x[7]) & 0xffffffff, 18);

      // Row rounds
      x[1] ^= _rotl32((x[0] + x[3]) & 0xffffffff, 7);
      x[2] ^= _rotl32((x[1] + x[0]) & 0xffffffff, 9);
      x[3] ^= _rotl32((x[2] + x[1]) & 0xffffffff, 13);
      x[0] ^= _rotl32((x[3] + x[2]) & 0xffffffff, 18);

      x[6] ^= _rotl32((x[5] + x[4]) & 0xffffffff, 7);
      x[7] ^= _rotl32((x[6] + x[5]) & 0xffffffff, 9);
      x[4] ^= _rotl32((x[7] + x[6]) & 0xffffffff, 13);
      x[5] ^= _rotl32((x[4] + x[7]) & 0xffffffff, 18);

      x[11] ^= _rotl32((x[10] + x[9]) & 0xffffffff, 7);
      x[8] ^= _rotl32((x[11] + x[10]) & 0xffffffff, 9);
      x[9] ^= _rotl32((x[8] + x[11]) & 0xffffffff, 13);
      x[10] ^= _rotl32((x[9] + x[8]) & 0xffffffff, 18);

      x[12] ^= _rotl32((x[15] + x[14]) & 0xffffffff, 7);
      x[13] ^= _rotl32((x[12] + x[15]) & 0xffffffff, 9);
      x[14] ^= _rotl32((x[13] + x[12]) & 0xffffffff, 13);
      x[15] ^= _rotl32((x[14] + x[13]) & 0xffffffff, 18);
    }

    for (var i = 0; i < 16; i++) {
      b[i] = (b[i] + x[i]) & 0xffffffff;
    }
  }
}
