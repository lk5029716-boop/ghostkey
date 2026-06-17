import 'package:flutter/material.dart';

const double _bottomControlToastMargin = 96;

/// Replacement for ente's `toast_util.dart` that uses Flutter's built-in
/// `SnackBar` instead of the `fluttertoast` package. Keeps the same
/// `showToast(context, message)` signature so call sites don't change.
void showToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    // No scaffold (e.g. dialog-only context) — fall back to a print.
    debugPrint('Toast: $message');
    return;
  }
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: _bottomControlToastMargin,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
