import 'package:hive/hive.dart';

part 'ai_settings_model.g.dart';

@HiveType(typeId: 10)
class AISettingsModel extends HiveObject {
  @HiveField(0, defaultValue: false)
  bool enableAIFeatures;

  @HiveField(1, defaultValue: '')
  String apiEndpoint;

  @HiveField(2, defaultValue: '')
  String apiKey;

  @HiveField(3, defaultValue: 'gpt-3.5-turbo')
  String modelName;

  @HiveField(4, defaultValue: true)
  bool enableAutoCategorization;

  @HiveField(5, defaultValue: true)
  bool enablePrioritySorting;

  @HiveField(6, defaultValue: true)
  bool enableMotivationalMessages;

  @HiveField(7, defaultValue: true)
  bool enableSmartNotifications;

  @HiveField(9, defaultValue: 1.0)
  double temperature;

  @HiveField(10, defaultValue: 10000)
  int maxTokens;

  @HiveField(11, defaultValue: 60000)
  int requestTimeout; // milliseconds

  @HiveField(12, defaultValue: 20)
  int maxRequestsPerMinute; // Rate limiting

  @HiveField(13, defaultValue: '')
  String customPersonaPrompt;

  @HiveField(14, defaultValue: 'openai')
  String apiFormat; // 'openai' or 'ollama'

  AISettingsModel({
    this.enableAIFeatures = false,
    this.apiEndpoint = '',
    this.apiKey = '',
    this.modelName = 'gpt-3.5-turbo',
    this.enableAutoCategorization = true,
    this.enablePrioritySorting = true,
    this.enableMotivationalMessages = true,
    this.enableSmartNotifications = true,
    this.temperature = 1.0,
    this.maxTokens = 10000,
    this.requestTimeout = 60000,
    this.maxRequestsPerMinute = 20,
    this.customPersonaPrompt = '',
    this.apiFormat = 'openai',
  });

  AISettingsModel copyWith({
    bool? enableAIFeatures,
    String? apiEndpoint,
    String? apiKey,
    String? modelName,
    bool? enableAutoCategorization,
    bool? enablePrioritySorting,
    bool? enableMotivationalMessages,
    bool? enableSmartNotifications,
    double? temperature,
    int? maxTokens,
    int? requestTimeout,
    int? maxRequestsPerMinute,
    String? customPersonaPrompt,
    String? apiFormat,
  }) {
    return AISettingsModel(
      enableAIFeatures: enableAIFeatures ?? this.enableAIFeatures,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      enableAutoCategorization:
          enableAutoCategorization ?? this.enableAutoCategorization,
      enablePrioritySorting:
          enablePrioritySorting ?? this.enablePrioritySorting,
      enableMotivationalMessages:
          enableMotivationalMessages ?? this.enableMotivationalMessages,
      enableSmartNotifications:
          enableSmartNotifications ?? this.enableSmartNotifications,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      maxRequestsPerMinute: maxRequestsPerMinute ?? this.maxRequestsPerMinute,
      customPersonaPrompt: customPersonaPrompt ?? this.customPersonaPrompt,
      apiFormat: apiFormat ?? this.apiFormat,
    );
  }

  factory AISettingsModel.create() {
    return AISettingsModel();
  }

  bool get isValid =>
      enableAIFeatures &&
      apiEndpoint.isNotEmpty &&
      modelName.isNotEmpty &&
      (apiFormat == 'ollama' || apiKey.isNotEmpty);

  Map<String, dynamic> toJson({bool includeApiKey = false}) {
    return {
      'enableAIFeatures': enableAIFeatures,
      'apiEndpoint': apiEndpoint,
      'apiKey': includeApiKey ? apiKey : '',
      'modelName': modelName,
      'enableAutoCategorization': enableAutoCategorization,
      'enablePrioritySorting': enablePrioritySorting,
      'enableMotivationalMessages': enableMotivationalMessages,
      'enableSmartNotifications': enableSmartNotifications,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'requestTimeout': requestTimeout,
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'customPersonaPrompt': customPersonaPrompt,
      'apiFormat': apiFormat,
    };
  }

  factory AISettingsModel.fromJson(Map<String, dynamic> json) {
    final defaults = AISettingsModel.create();
    return AISettingsModel(
      enableAIFeatures:
          (json['enableAIFeatures'] as bool?) ?? defaults.enableAIFeatures,
      apiEndpoint: (json['apiEndpoint'] as String?) ?? defaults.apiEndpoint,
      apiKey: (json['apiKey'] as String?) ?? defaults.apiKey,
      modelName: (json['modelName'] as String?) ?? defaults.modelName,
      enableAutoCategorization:
          (json['enableAutoCategorization'] as bool?) ??
          defaults.enableAutoCategorization,
      enablePrioritySorting:
          (json['enablePrioritySorting'] as bool?) ??
          defaults.enablePrioritySorting,
      enableMotivationalMessages:
          (json['enableMotivationalMessages'] as bool?) ??
          defaults.enableMotivationalMessages,
      enableSmartNotifications:
          (json['enableSmartNotifications'] as bool?) ??
          defaults.enableSmartNotifications,
      temperature:
          (json['temperature'] as num?)?.toDouble() ?? defaults.temperature,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? defaults.maxTokens,
      requestTimeout:
          (json['requestTimeout'] as num?)?.toInt() ?? defaults.requestTimeout,
      maxRequestsPerMinute:
          (json['maxRequestsPerMinute'] as num?)?.toInt() ??
          defaults.maxRequestsPerMinute,
      customPersonaPrompt:
          (json['customPersonaPrompt'] as String?) ??
          defaults.customPersonaPrompt,
      apiFormat: (json['apiFormat'] as String?) ?? defaults.apiFormat,
    );
  }
}
