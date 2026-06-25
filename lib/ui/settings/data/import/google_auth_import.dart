import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import '../../../../qr_scanner_screen.dart';
import 'google_auth_qr_parser.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('GoogleAuthImport');

/// Open the GhostKey QR scanner; if a Google Authenticator migration QR is
/// detected, parse it and import all codes.
Future<void> showGoogleAuthInstruction(BuildContext context) async {
  final code = await showDialog<String?>(
    context: context,
    builder: (ctx) => const Dialog(
      child: SizedBox(
        width: 320,
        height: 400,
        child: QrScannerScreen(),
      ),
    ),
  );
  if (code == null) return;
  if (!isGoogleAuthExportQr(code)) {
    await showGhostKeyError(
      context,
      'Not a Google Authenticator export',
      'This QR code is not a Google Authenticator migration QR. '
      'To export from Google Authenticator: ⋮ → Transfer accounts → Export.',
    );
    return;
  }

  if (!context.mounted) return;
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parseGoogleAuthCodes(code, onProgress),
    );
  } catch (e, s) {
    _logger.severe('Google Auth QR import failed', e, s);
    if (!context.mounted) return;
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not parse the Google Authenticator QR.\nError: $e',
    );
  }
}

Future<List<Code>> _parseGoogleAuthCodes(
  String qrCodeData,
  void Function(int current, int total) onProgress,
) async {
  final codes = parseGoogleAuth(qrCodeData);
  // Report progress for each parsed code so the dialog shows movement
  for (var i = 0; i < codes.length; i++) {
    onProgress(i + 1, codes.length);
  }
  return codes;
}
