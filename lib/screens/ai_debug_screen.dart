import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_todo/providers/ai_provider.dart';
import 'package:easy_todo/providers/todo_provider.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/widgets/web_desktop_content.dart';

class AIDebugScreen extends StatefulWidget {
  const AIDebugScreen({super.key});

  @override
  State<AIDebugScreen> createState() => _AIDebugScreenState();
}

class _AIDebugScreenState extends State<AIDebugScreen> {
  AIProvider? _aiProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _aiProvider = Provider.of<AIProvider>(context, listen: false);
        _aiProvider?.startDebugUpdates();
      }
    });
  }

  @override
  void dispose() {
    _aiProvider?.stopDebugUpdates();
    _aiProvider = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiDebugInfo),
        centerTitle: true,
      ),
      body: WebDesktopContent(
        padding: EdgeInsets.zero,
        child: Consumer2<AIProvider, TodoProvider>(
          builder: (context, aiProvider, todoProvider, child) {
            final l10n = AppLocalizations.of(context)!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: l10n.aiSettingsStatus,
                  children: [
                    _buildInfoRow(
                      l10n.aiFeaturesEnabled,
                      aiProvider.settings.enableAIFeatures.toString(),
                    ),
                    _buildInfoRow(
                      l10n.aiServiceValid,
                      aiProvider.isAIServiceValid.toString(),
                    ),
                    _buildInfoRow(
                      l10n.apiEndpoint,
                      aiProvider.settings.apiEndpoint.isEmpty
                          ? l10n.notConfigured
                          : aiProvider.settings.apiEndpoint,
                    ),
                    _buildInfoRow(
                      l10n.modelName,
                      aiProvider.settings.modelName,
                    ),
                    _buildInfoRow(
                      l10n.apiKey,
                      aiProvider.settings.apiKey.isEmpty
                          ? l10n.notConfigured
                          : l10n.configured(aiProvider.settings.apiKey.length),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: l10n.aiFeatureToggles,
                  children: [
                    _buildInfoRow(
                      l10n.autoCategorization,
                      aiProvider.settings.enableAutoCategorization.toString(),
                    ),
                    _buildInfoRow(
                      l10n.prioritySorting,
                      aiProvider.settings.enablePrioritySorting.toString(),
                    ),
                    _buildInfoRow(
                      l10n.motivationalMessages,
                      aiProvider.settings.enableMotivationalMessages.toString(),
                    ),
                    _buildInfoRow(
                      l10n.smartNotifications,
                      aiProvider.settings.enableSmartNotifications.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: l10n.aiTodoProviderConnection,
                  children: [
                    _buildInfoRow(
                      l10n.aiProviderConnected,
                      todoProvider.aiProvider != null ? l10n.yes : l10n.no,
                    ),
                    _buildInfoRow(
                      l10n.totalTodos,
                      todoProvider.allTodos.length.toString(),
                    ),
                    _buildInfoRow(
                      l10n.aiProcessedTodos,
                      todoProvider.allTodos
                          .where((t) => t.aiProcessed)
                          .length
                          .toString(),
                    ),
                    _buildInfoRow(
                      l10n.todosWithAICategory,
                      todoProvider.allTodos
                          .where((t) => t.aiCategory != null)
                          .length
                          .toString(),
                    ),
                    _buildInfoRow(
                      l10n.todosWithAIPriority,
                      todoProvider.allTodos
                          .where((t) => t.aiPriority > 0)
                          .length
                          .toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: l10n.aiMessages,
                  children: [
                    _buildInfoRow(
                      l10n.motivationalMessages,
                      aiProvider.motivationalMessages.length.toString(),
                    ),
                    _buildInfoRow(
                      l10n.completionMessages,
                      aiProvider.completionMessages.length.toString(),
                    ),
                    if (aiProvider.lastError != null)
                      _buildInfoRow(
                        l10n.lastError,
                        aiProvider.lastError!,
                        isError: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: l10n.aiApiRequestManager,
                  children: [
                    if (aiProvider.isAIServiceValid) ...[
                      _buildInfoRow(
                        l10n.pendingRequests,
                        aiProvider
                                .getRequestManagerStats()['pending_requests']
                                ?.toString() ??
                            '0',
                      ),
                      _buildInfoRow(
                        l10n.currentWindowRequests,
                        aiProvider
                                .getRequestManagerStats()['current_window_requests']
                                ?.toString() ??
                            '0',
                      ),
                      _buildInfoRow(
                        l10n.maxRequestsPerMinute,
                        aiProvider
                                .getRequestManagerStats()['max_requests_per_minute']
                                ?.toString() ??
                            '20',
                      ),
                      const SizedBox(height: 8),
                      _buildSubSection(
                        title: l10n.aiCurrentRequestQueue,
                        child: _buildRequestQueueList(
                          aiProvider.getRequestQueueInfo(),
                          l10n,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSubSection(
                        title: l10n.aiRecentRequests,
                        child: _buildRecentRequestsList(
                          aiProvider.getRecentRequests(),
                          l10n,
                        ),
                      ),
                    ] else
                      _buildInfoRow(
                        l10n.status,
                        l10n.aiServiceNotAvailable,
                        isError: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final l10n = AppLocalizations.of(context)!;
                    await todoProvider.processUnprocessedTodosWithAI();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.processingUnprocessedTodos)),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.processAllTodosWithAI,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );
  }

  Widget _buildRequestQueueList(
    List<Map<String, dynamic>> queue,
    AppLocalizations l10n,
  ) {
    if (queue.isEmpty) {
      return Text(
        l10n.noPendingRequests,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      children: queue.map((request) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.request}: ${request['request_key']?.toString().split('_').last ?? l10n.unknown}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.waiting}: ${request['wait_time_formatted'] ?? l10n.unknown}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentRequestsList(
    List<Map<String, dynamic>> requests,
    AppLocalizations l10n,
  ) {
    if (requests.isEmpty) {
      return Text(
        l10n.noRecentRequests,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    }

    return Column(
      children: requests.take(5).map((request) {
        // Show only last 5 requests
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.requestCompleted,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                request['age_formatted'] ?? l10n.unknown,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
