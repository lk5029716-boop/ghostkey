import 'package:flutter/material.dart';

/// Minimal local-first replacement for ente's `dialog_util.dart`.
///
/// Provides the few helpers that GhostKey's UI actually calls:
///   - [showErrorDialog] — plain AlertDialog with title + body
///   - [showChoiceDialog] — AlertDialog with two action buttons
///   - [showGenericErrorDialog] — wraps [showErrorDialog] with a generic
///     "something went wrong" body.
///
/// Confetti / progress / action sheet / text-input variants from
/// ente's upstream are not ported — call sites that need them can be
/// added later.

const double mobileSmallThreshold = 600;

/// Show a simple error dialog.
Future<void> showErrorDialog(
  BuildContext context,
  String title,
  String? body, {
  bool isDismissable = true,
  bool showContactSupport = false,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: isDismissable,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Show a dialog with two action buttons.
Future<bool?> showChoiceDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String firstButtonLabel,
  String? secondButtonLabel = 'Cancel',
  bool isCritical = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        if (secondButtonLabel != null)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(secondButtonLabel),
          ),
        TextButton(
          style: isCritical
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(firstButtonLabel),
        ),
      ],
    ),
  );
}

/// Wraps [showErrorDialog] with a generic failure body.
Future<void> showGenericErrorDialog({
  required BuildContext context,
  required Object? error,
  bool isDismissible = true,
}) {
  return showErrorDialog(
    context,
    'Something went wrong',
    error?.toString(),
    isDismissable: isDismissible,
  );
}
