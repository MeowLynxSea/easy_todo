import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AISettingsModel JSON', () {
    test('syncApiKey defaults to false', () {
      final settings = AISettingsModel.create();
      expect(settings.syncApiKey, isFalse);
    });

    test('toJson excludes apiKey by default', () {
      final settings = AISettingsModel(
        enableAIFeatures: true,
        apiEndpoint: 'https://example.com',
        apiKey: 'sk-test',
        modelName: 'gpt-4',
        syncApiKey: true,
      );

      final json = settings.toJson();
      expect(json['syncApiKey'], isTrue);
      expect(json['apiKey'], '');
    });

    test('toJson can include apiKey', () {
      final settings = AISettingsModel(
        enableAIFeatures: true,
        apiEndpoint: 'https://example.com',
        apiKey: 'sk-test',
        modelName: 'gpt-4',
        syncApiKey: true,
      );

      final json = settings.toJson(includeApiKey: true);
      expect(json['syncApiKey'], isTrue);
      expect(json['apiKey'], 'sk-test');
    });

    test('fromJson falls back when missing syncApiKey', () {
      final decoded = AISettingsModel.fromJson({
        'enableAIFeatures': true,
        'apiEndpoint': 'https://example.com',
        'apiKey': '',
        'modelName': 'gpt-4',
      });
      expect(decoded.syncApiKey, isFalse);
    });
  });
}
