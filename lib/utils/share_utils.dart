import 'dart:io';

import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

/// Minimal local-first replacement for ente's `share_utils.dart`.
///
/// Drops ente's `showDialogWidget` / `ButtonWidget` UI flow in favor of
/// direct `share_plus` calls. Uses the share_plus 7.x static API
/// (`Share.shareXFiles`, `Share.share`) since that's what the rest of
/// GhostKey's pubspec resolves to.
final _logger = Logger('ShareUtils');

/// Share a single file with the platform share sheet.
Future<void> shareFile(String filePath, {String? mimeType}) async {
  if (!File(filePath).existsSync()) {
    _logger.warning('shareFile: file not found at $filePath');
    return;
  }
  await Share.shareXFiles(
    [XFile(filePath, mimeType: mimeType)],
  );
}

/// Share a string payload (text, URL, etc.).
Future<void> shareText(String text, {String? subject}) async {
  await Share.share(text, subject: subject);
}

/// Detect iOS — kept as a thin wrapper because callers check this in
/// share-error branches.
bool get isIOS => Platform.isIOS;
