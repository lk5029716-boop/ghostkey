import 'package:flutter/material.dart';

/// M3 progress dialog for long-running imports.
/// Show with [showGhostKeyProgress], dismiss with [Navigator.pop].
Future<void> showGhostKeyProgress(BuildContext context, String message) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 20),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

Future<void> hideGhostKeyProgress(BuildContext context) async {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// M3 success dialog with an OK button.
Future<void> showGhostKeySuccess(BuildContext context, int count) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.check_circle_outline,
        color: Theme.of(ctx).colorScheme.primary,
        size: 48,
      ),
      title: const Text('Import complete'),
      content: Text(
        count == 1
            ? '1 code added to your vault.'
            : '$count codes added to your vault.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// M3 error dialog.
Future<void> showGhostKeyError(
  BuildContext context,
  String title,
  String message,
) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: Theme.of(ctx).colorScheme.error,
        size: 48,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Standard "select file" instruction dialog used by most import flows.
/// Returns `true` if user tapped "Select file", `false` on cancel/close.
Future<bool> showImportInstructionDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String formatHint,
  String selectButtonLabel = 'Select file',
  String cancelButtonLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(body),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formatHint,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(selectButtonLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// M3 password prompt for encrypted imports. Returns null on cancel.
Future<String?> showGhostKeyPasswordPrompt(
  BuildContext context, {
  required String title,
  String? hint,
}) async {
  final controller = TextEditingController();
  try {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint ?? 'Enter password',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    return result;
  } finally {
    controller.dispose();
  }
}
