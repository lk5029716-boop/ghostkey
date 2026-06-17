import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PlatformUtil {
  static bool isDesktop() {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  }

  static bool isMobile() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static TextSelectionControls get selectionControls => Platform.isAndroid
      ? materialTextSelectionControls
      : Platform.isIOS
      ? cupertinoTextSelectionControls
      : desktopTextSelectionControls;

  static Future<void> openUrlInBrowser(String url) async {
    await launchUrlString(
      url,
      mode: isDesktop()
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  static Future<void> shareFile(
    String fileName,
    String extension,
    Uint8List bytes,
    MimeType type,
  ) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await FileSaver.instance.saveAs(
          name: fileName,
          ext: extension,
          bytes: bytes,
          mimeType: type,
        );
      } else {
        await FileSaver.instance.saveFile(
          name: fileName,
          ext: extension,
          bytes: bytes,
          mimeType: type,
        );
      }
    } catch (_) {}
  }

  // Desktop-only window refocussing — only runs on Windows in ente's
  // upstream code. GhostKey is mobile-first, so this is a no-op on
  // Android/iOS. (Skipped the `window_manager` dependency.)
  static Future<void> refocusWindows() async {
    // No-op on mobile. Desktop support is a future concern.
  }
}
