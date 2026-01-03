import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/models/ai_settings_model.dart';
import 'package:easy_todo/screens/ai_debug_screen.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiEndpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _maxRequestsPerMinuteController = TextEditingController();
  final _customPersonaController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _timeoutController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    _maxRequestsPerMinuteController.dispose();
    _customPersonaController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    final settings = aiProvider.settings;

    _apiEndpointController.text = settings.apiEndpoint;
    _apiKeyController.text = settings.apiKey;
    _modelNameController.text = settings.modelName;
    _timeoutController.text = settings.requestTimeout.toString();
    _temperatureController.text = settings.temperature.toString();
    _maxTokensController.text = settings.maxTokens.toString();
    _maxRequestsPerMinuteController.text = settings.maxRequestsPerMinute
        .toString();
    _customPersonaController.text = settings.customPersonaPrompt;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    final newSettings = AISettingsModel(
      enableAIFeatures: aiProvider.settings.enableAIFeatures,
      apiEndpoint: _apiEndpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelName: _modelNameController.text.trim(),
      enableAutoCategorization: aiProvider.settings.enableAutoCategorization,
      enablePrioritySorting: aiProvider.settings.enablePrioritySorting,
      enableImportanceRating: aiProvider.settings.enableImportanceRating,
      enableMotivationalMessages:
          aiProvider.settings.enableMotivationalMessages,
      enableSmartNotifications: aiProvider.settings.enableSmartNotifications,
      syncApiKey: aiProvider.settings.syncApiKey,
      temperature: double.tryParse(_temperatureController.text) ?? 1.0,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 10000,
      requestTimeout: int.tryParse(_timeoutController.text) ?? 60000,
      maxRequestsPerMinute:
          int.tryParse(_maxRequestsPerMinuteController.text) ?? 20,
      customPersonaPrompt: _customPersonaController.text.trim(),
      apiFormat: aiProvider.settings.apiFormat,
    );

    // Check if any critical settings have changed that require cache clearing
    final oldSettings = aiProvider.settings;
    bool shouldClearCache = false;

    if (oldSettings.apiEndpoint != newSettings.apiEndpoint ||
        oldSettings.apiKey != newSettings.apiKey ||
        oldSettings.modelName != newSettings.modelName ||
        oldSettings.temperature != newSettings.temperature ||
        oldSettings.maxTokens != newSettings.maxTokens ||
        oldSettings.customPersonaPrompt != newSettings.customPersonaPrompt) {
      shouldClearCache = true;
    }

    // Clear cache if critical settings changed
    if (shouldClearCache) {
      await aiProvider.clearAllAICache();
    }

    aiProvider.updateSettings(newSettings);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    // Temporarily update settings for testing - preserve current API format
    final testSettings = AISettingsModel(
      enableAIFeatures: true,
      apiEndpoint: _apiEndpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelName: _modelNameController.text.trim(),
      enableAutoCategorization: aiProvider.settings.enableAutoCategorization,
      enablePrioritySorting: aiProvider.settings.enablePrioritySorting,
      enableImportanceRating: aiProvider.settings.enableImportanceRating,
      enableMotivationalMessages: aiProvider.settings.enableMotivationalMessages,
      enableSmartNotifications: aiProvider.settings.enableSmartNotifications,
      syncApiKey: aiProvider.settings.syncApiKey,
      temperature: double.tryParse(_temperatureController.text) ?? 1.0,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 10000,
      requestTimeout: int.tryParse(_timeoutController.text) ?? 60000,
      maxRequestsPerMinute:
          int.tryParse(_maxRequestsPerMinuteController.text) ?? 20,
      customPersonaPrompt: aiProvider.settings.customPersonaPrompt,
      apiFormat: aiProvider.settings.apiFormat, // Preserve current API format
    );

    aiProvider.updateSettings(testSettings);

    try {
      final success = await aiProvider.testConnection();
      if (mounted) {
        setState(() {
          _testResult = success
              ? AppLocalizations.of(context)!.connectionSuccessful
              : AppLocalizations.of(context)!.connectionFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '${AppLocalizations.of(context)!.connectionFailed}: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aiProvider = Provider.of<AIProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _saveSettings();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.aiSettings), centerTitle: true),
        body: Form(
          key: _formKey,
          child: WebDesktopContent(
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  elevation: 1,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiFeatures,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            l10n.enableAIFeatures,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            l10n.enableAIFeaturesSubtitle,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          value: aiProvider.settings.enableAIFeatures,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            final newSettings = aiProvider.settings.copyWith(
                              enableAIFeatures: value,
                            );
                            aiProvider.updateSettings(newSettings);
                          },
                        ),
                        if (aiProvider.settings.enableAIFeatures) ...[
                          const SizedBox(height: 16),
                          _buildSectionTitle(l10n.apiConfiguration),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _apiEndpointController,
                            label: l10n.apiEndpoint,
                            hint: aiProvider.settings.apiFormat == 'ollama'
                                ? 'http://localhost:11434/api/generate'
                                : 'https://api.openai.com/v1/chat/completions',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterApiEndpoint;
                              }
                              if (!Uri.tryParse(
                                value.trim(),
                              )!.hasAbsolutePath) {
                                return l10n.invalidApiEndpoint;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _apiKeyController,
                            label: l10n.apiKey,
                            hint: aiProvider.settings.apiFormat == 'ollama'
                                ? '(Optional for Ollama)'
                                : 'sk-...',
                            obscureText:
                                !_showPassword &&
                                aiProvider.settings.apiFormat != 'ollama',
                            validator: (value) {
                              if (aiProvider.settings.apiFormat != 'ollama' &&
                                  (value == null || value.trim().isEmpty)) {
                                return l10n.pleaseEnterApiKey;
                              }
                              return null;
                            },
                            suffixIcon:
                                aiProvider.settings.apiFormat != 'ollama'
                                ? IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.syncAiApiKeyTitle),
                            subtitle: Text(l10n.syncAiApiKeySubtitle),
                            value: aiProvider.settings.syncApiKey,
                            onChanged: aiProvider.settings.apiFormat == 'ollama'
                                ? null
                                : (value) async {
                                    if (value &&
                                        !aiProvider.settings.syncApiKey) {
                                      final confirmed =
                                          (await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                  l10n.syncAiApiKeyWarningTitle,
                                                ),
                                                content: Text(
                                                  l10n.syncAiApiKeyWarningMessage,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: Text(l10n.cancel),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: Text(l10n.ok),
                                                  ),
                                                ],
                                              );
                                            },
                                          )) ??
                                          false;
                                      if (!confirmed) return;
                                    }

                                    HapticFeedback.lightImpact();
                                    aiProvider.updateSettings(
                                      aiProvider.settings.copyWith(
                                        syncApiKey: value,
                                      ),
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _modelNameController,
                            label: l10n.modelName,
                            hint: aiProvider.settings.apiFormat == 'ollama'
                                ? 'llama3.2'
                                : 'gpt-3.5-turbo',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.pleaseEnterModelName;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle(l10n.advancedSettings),
                          const SizedBox(height: 8),
                          _buildApiFormatSelector(l10n),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _timeoutController,
                                  label: l10n.timeout,
                                  hint: '60000',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterTimeout;
                                    }
                                    final timeout = int.tryParse(value);
                                    if (timeout == null || timeout < 1000) {
                                      return l10n.invalidTimeout;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _temperatureController,
                                  label: l10n.temperature,
                                  hint: '1.0',
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterTemperature;
                                    }
                                    final temp = double.tryParse(value);
                                    if (temp == null || temp < 0 || temp > 2) {
                                      return l10n.invalidTemperature;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle(l10n.rateAndTokenLimits),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: _maxRequestsPerMinuteController,
                                  label: l10n.rateLimit,
                                  hint: '20',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterRateLimit;
                                    }
                                    final rate = int.tryParse(value);
                                    if (rate == null ||
                                        rate < 1 ||
                                        rate > 100) {
                                      return l10n.invalidRateLimit;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _maxTokensController,
                                  label: l10n.maxTokens,
                                  hint: '10000',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.pleaseEnterMaxTokens;
                                    }
                                    final tokens = int.tryParse(value);
                                    if (tokens == null || tokens < 1) {
                                      return l10n.invalidMaxTokens;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_testResult != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    _testResult!.contains(
                                      l10n.connectionSuccessful,
                                    )
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3)
                                    : Theme.of(context)
                                          .colorScheme
                                          .errorContainer
                                          .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      _testResult!.contains(
                                        l10n.connectionSuccessful,
                                      )
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3)
                                      : Theme.of(context).colorScheme.error
                                            .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  color:
                                      _testResult!.contains(
                                        l10n.connectionSuccessful,
                                      )
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _testConnection,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l10n.testConnection),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (aiProvider.settings.enableAIFeatures)
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    elevation: 1,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(l10n.aiFeaturesToggle),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              l10n.autoCategorization,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              l10n.autoCategorizationSubtitle,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            value: aiProvider.settings.enableAutoCategorization,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              final newSettings = aiProvider.settings.copyWith(
                                enableAutoCategorization: value,
                              );
                              aiProvider.updateSettings(newSettings);
                            },
                          ),
                          SwitchListTile(
                            title: Text(
                              l10n.prioritySorting,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              l10n.prioritySortingSubtitle,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            value: aiProvider.settings.enablePrioritySorting,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              final newSettings = aiProvider.settings.copyWith(
                                enablePrioritySorting: value,
                              );
                              aiProvider.updateSettings(newSettings);
                            },
                          ),
                          SwitchListTile(
                            title: Text(
                              l10n.importanceRating,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              l10n.importanceRatingSubtitle,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            value: aiProvider.settings.enableImportanceRating,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              final newSettings = aiProvider.settings.copyWith(
                                enableImportanceRating: value,
                              );
                              aiProvider.updateSettings(newSettings);
                            },
                          ),
                          SwitchListTile(
                            title: Text(
                              l10n.motivationalMessages,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              l10n.motivationalMessagesSubtitle,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            value:
                                aiProvider.settings.enableMotivationalMessages,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              final newSettings = aiProvider.settings.copyWith(
                                enableMotivationalMessages: value,
                              );
                              aiProvider.updateSettings(newSettings);
                            },
                          ),
                          SwitchListTile(
                            title: Text(
                              l10n.smartNotifications,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              l10n.smartNotificationsSubtitle,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            value: aiProvider.settings.enableSmartNotifications,
                            onChanged: (value) {
                              HapticFeedback.lightImpact();
                              final newSettings = aiProvider.settings.copyWith(
                                enableSmartNotifications: value,
                              );
                              aiProvider.updateSettings(newSettings);
                            },
                          ),
                          if (aiProvider.settings.enableSmartNotifications ||
                              aiProvider
                                  .settings
                                  .enableMotivationalMessages) ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle(l10n.customPersona),
                            const SizedBox(height: 8),
                            _buildPersonaPromptField(l10n),
                            const SizedBox(height: 16),
                            _buildPersonaExamples(l10n),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  elevation: 1,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListTile(
                      leading: Icon(
                        Icons.bug_report_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        l10n.aiDebugInfoTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        l10n.aiDebugInfoSubtitle,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIDebugScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines ?? 1,
      onChanged: (value) {
        _autoSaveSettings();
      },
    );
  }

  void _autoSaveSettings() {
    if (!_formKey.currentState!.validate()) return;

    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    final newSettings = AISettingsModel(
      enableAIFeatures: aiProvider.settings.enableAIFeatures,
      apiEndpoint: _apiEndpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelName: _modelNameController.text.trim(),
      enableAutoCategorization: aiProvider.settings.enableAutoCategorization,
      enablePrioritySorting: aiProvider.settings.enablePrioritySorting,
      enableImportanceRating: aiProvider.settings.enableImportanceRating,
      enableMotivationalMessages:
          aiProvider.settings.enableMotivationalMessages,
      enableSmartNotifications: aiProvider.settings.enableSmartNotifications,
      syncApiKey: aiProvider.settings.syncApiKey,
      temperature: double.tryParse(_temperatureController.text) ?? 1.0,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 10000,
      requestTimeout: int.tryParse(_timeoutController.text) ?? 60000,
      maxRequestsPerMinute:
          int.tryParse(_maxRequestsPerMinuteController.text) ?? 20,
      customPersonaPrompt: _customPersonaController.text.trim(),
      apiFormat: aiProvider.settings.apiFormat,
    );

    // Check if any critical settings have changed that require cache clearing
    final oldSettings = aiProvider.settings;
    bool shouldClearCache = false;

    if (oldSettings.apiEndpoint != newSettings.apiEndpoint ||
        oldSettings.apiKey != newSettings.apiKey ||
        oldSettings.modelName != newSettings.modelName ||
        oldSettings.temperature != newSettings.temperature ||
        oldSettings.maxTokens != newSettings.maxTokens ||
        oldSettings.customPersonaPrompt != newSettings.customPersonaPrompt) {
      shouldClearCache = true;
    }

    // Clear cache if critical settings changed
    if (shouldClearCache) {
      aiProvider.clearAllAICache();
    }

    aiProvider.updateSettings(newSettings);
  }

  Widget _buildPersonaPromptField(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.personaPrompt,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _customPersonaController,
              decoration: InputDecoration(
                hintText: l10n.personaPromptHint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              maxLines: 3,
              minLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                _autoSaveSettings();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              l10n.personaPromptDescription,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiFormatSelector(AppLocalizations l10n) {
    final aiProvider = Provider.of<AIProvider>(context);

    // Reset to 'openai' if current value is not 'openai' or 'ollama'
    final currentValue = aiProvider.settings.apiFormat;
    if (currentValue != 'openai' && currentValue != 'ollama') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newSettings = aiProvider.settings.copyWith(apiFormat: 'openai');
        aiProvider.updateSettings(newSettings);
      });
    }

    return DropdownButtonFormField<String>(
      value: currentValue == 'openai' || currentValue == 'ollama'
          ? currentValue
          : 'openai',
      decoration: InputDecoration(
        labelText: l10n.apiFormat,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: 'openai',
          child: Text(l10n.openaiFormat),
        ),
        DropdownMenuItem<String>(value: 'ollama', child: const Text('Ollama')),
      ],
      onChanged: (value) {
        if (value != null) {
          HapticFeedback.lightImpact();
          final newSettings = aiProvider.settings.copyWith(apiFormat: value);
          aiProvider.updateSettings(newSettings);

          // Update endpoint hint when format changes
          if (value == 'ollama') {
            _apiEndpointController.text = 'http://localhost:11434/api/generate';
          } else if (value == 'openai') {
            _apiEndpointController.text =
                'https://api.openai.com/v1/chat/completions';
          }
        }
      },
      icon: Icon(Icons.api, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildPersonaExamples(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Examples',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...[
            l10n.personaExample1,
            l10n.personaExample2,
            l10n.personaExample3,
            l10n.personaExample4,
          ].map(
            (example) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
