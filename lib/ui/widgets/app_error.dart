import 'package:flutter/material.dart';
import 'package:ai_vehicle_counter/l10n/app_localizations.dart';

/// AppError: shows an error message and an optional "Try again" button.
class AppError extends StatelessWidget {
  const AppError({
    super.key,
    this.message = '',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final effectiveMessage =
        message.isNotEmpty ? message : (l10n?.genericError ?? 'Error');
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 32,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 8),
        Text(
          effectiveMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.tryAgain ?? 'Try again'),
          ),
        ],
      ],
    );
  }
}


