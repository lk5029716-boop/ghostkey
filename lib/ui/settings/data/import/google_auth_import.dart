import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../qr_scanner_screen.dart';
import '../../../../store/code_store.dart';
import 'google_auth_qr_parser.dart';
import 'import_helpers.dart';

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
  await showGhostKeyProgress(context, 'Importing…');

  try {
    final codes = parseGoogleAuth(code);
    for (final c in codes) {
      await CodeStore.instance.addCode(c);
    }
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeySuccess(context, codes.length);
  } catch (e, s) {
    _logger.severe('Google Auth QR import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not parse the Google Authenticator QR.\nError: $e',
    );
  }
}
