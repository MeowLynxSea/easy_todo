import 'package:flutter/material.dart';
import 'package:easy_todo/l10n/generated/app_localizations.dart';
import 'package:easy_todo/utils/ai_status_constants.dart';

class AILoadingIndicator extends StatelessWidget {
  final String status;
  final bool isLoading;
  final double size;
  final Color? color;

  const AILoadingIndicator({
    super.key,
    required this.status,
    required this.isLoading,
    this.size = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          )
        else
          Icon(
            Icons.check_circle,
            size: size,
            color: color ?? Colors.green,
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isLoading
                  ? Theme.of(context).colorScheme.primary
                  : Colors.green,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RepeatTodoAIStatus extends StatelessWidget {
  final String repeatTodoId;
  final bool isProcessing;
  final bool isLoading;
  final String? status;

  const RepeatTodoAIStatus({
    super.key,
    required this.repeatTodoId,
    required this.isProcessing,
    required this.isLoading,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProcessing && status == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isProcessing || isLoading)
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isProcessing || isLoading)
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: AILoadingIndicator(
        status: _getLocalizedStatus(status, isProcessing, l10n),
        isLoading: isProcessing || isLoading,
        size: 14,
      ),
    );
  }

  String _getLocalizedStatus(String? status, bool isProcessing, AppLocalizations l10n) {
    if (status != null) {
      // Convert hardcoded status strings to localized ones
      switch (status) {
        case AIStatusConstants.categorizingTask:
          return l10n.categorizingTask;
        case AIStatusConstants.processingAI:
          return l10n.processingAIStatus;
      }
    }

    // Fallback for when status is null
    return isProcessing ? l10n.processingAI : l10n.aiProcessingCompleted;
  }
}