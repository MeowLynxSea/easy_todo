import 'package:easy_todo/services/api_request_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ApiRequestManager manager;

  setUp(() {
    manager = ApiRequestManager();
    manager.dispose();
  });

  tearDown(() {
    manager.dispose();
  });

  test('deduplicates identical in-flight requests', () async {
    var calls = 0;

    Future<int> request() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return 42;
    }

    final results = await Future.wait([
      manager.makeRequest<int>('endpoint', {'a': 1, 'b': 2}, request),
      manager.makeRequest<int>('endpoint', {'a': 1, 'b': 2}, request),
    ]);

    expect(results, [42, 42]);
    expect(calls, 1);
  });

  test(
    'deduplicates requests with equivalent map values regardless of key order',
    () async {
      var calls = 0;

      Future<String> request() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'ok';
      }

      final data1 = <String, dynamic>{'a': 1, 'b': 2};
      final data2 = <String, dynamic>{'b': 2, 'a': 1};

      final results = await Future.wait([
        manager.makeRequest<String>('endpoint', data1, request),
        manager.makeRequest<String>('endpoint', data2, request),
      ]);

      expect(results, ['ok', 'ok']);
      expect(calls, 1);
    },
  );
}
