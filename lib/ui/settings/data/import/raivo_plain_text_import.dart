import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('RaivoImport');

Future<void> showRaivoImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from Raivo OTP',
    body:
        'In Raivo: Settings → Export vault → choose JSON. Unzip if needed and select the JSON file here.',
    formatHint: 'raivo-otp-export.json',
  );
  if (!proceed) return;
  await _pickRaivoFile(context);
}

Future<void> _pickRaivoFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Raivo export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  if (path.endsWith('.zip')) {
    await showGhostKeyError(
      context,
      'ZIP not supported',
      'Please unzip the Raivo export and select the JSON file inside.',
    );
    return;
  }

  if (!context.mounted) return;
  await showGhostKeyProgress(context, 'Parsing…');

  try {
    final jsonString = await readPickedImportFileAsString(path);
    final codes = _parseRaivoCodes(jsonString);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showImportProgress(context: context, codes: codes);
  } catch (e, s) {
    _logger.severe('Raivo import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import Raivo export.\nError: $e',
    );
  }
}

List<Code> _parseRaivoCodes(String jsonString) {
  final items = jsonDecode(jsonString) as List<dynamic>;

  final codes = <Code>[];
  for (final item in items) {
    try {
      final kind = (item['kind'] as String).toLowerCase();
      final algorithm = item['algorithm']?.toString() ?? 'SHA1';
      final timer = item['timer'] ?? 30;
      final digits = item['digits'] ?? 6;
      final issuer = item['issuer']?.toString() ?? '';
      final secret = item['secret']?.toString() ?? '';
      final account = item['account']?.toString() ?? '';
      final counter = item['counter'] ?? 0;

      final String otpUrl;
      if (kind == 'totp') {
        otpUrl =
            'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&period=$timer';
      } else if (kind == 'hotp') {
        otpUrl =
            'otpauth://hotp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&counter=$counter';
      } else {
        throw Exception('Invalid OTP type: $kind');
      }
      codes.add(Code.fromOTPAuthUrl(otpUrl));
    } catch (e, s) {
      _logger.warning('Failed to parse Raivo entry', e, s);
    }
  }
  return codes;
}
