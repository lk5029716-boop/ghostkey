import 'package:flutter/material.dart';

/// M3 progress dialog for long-running imports.
/// Shows a spinning indicator + message.
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

/// M3 success dialog with count of imported codes.
Future<void> showGhostKeySuccess(BuildContext context, int count) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.check_circle_outline,
        color: Color(0xFF0D631B),
        size: 48,
      ),
      title: const Text('Import complete'),
      content: Text(
        count == 1
            ? '1 code added to your vault.'
            : '$count codes added to your vault.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
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
      icon: const Icon(
        Icons.error_outline,
        color: Color(0xFFBA1A1A),
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
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController();
      return AlertDialog(
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
            onPressed: () {
              controller.dispose();
              Navigator.of(ctx).pop(null);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text;
              controller.dispose();
              Navigator.of(ctx).pop(text);
            },
            child: const Text('Unlock'),
          ),
        ],
      );
    },
  );
  return result;
}
