import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('LastPassImport');

Future<void> showLastpassImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from LastPass Authenticator',
    body:
        'Open LastPass Authenticator → ⋯ menu → Export. Choose JSON format and select the file here.',
    formatHint: 'lastpass-export.json',
  );
  if (!proceed) return;
  await _pickLastpassFile(context);
}

Future<void> _pickLastpassFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select LastPass export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  if (!context.mounted) return;
  final jsonString = await readPickedImportFileAsString(path);
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parseLastpassCodes(jsonString, onProgress),
    );
  } catch (e, s) {
    _logger.severe('LastPass import failed', e, s);
    if (!context.mounted) return;
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import LastPass export.\nError: $e',
    );
  }
}

List<Code> _parseLastpassCodes(
  String jsonString,
  void Function(int current, int total) onProgress,
) {
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final accounts = data['accounts'] as List<dynamic>? ?? [];

  final total = accounts.length;
  final codes = <Code>[];
  for (var i = 0; i < accounts.length; i++) {
    final item = accounts[i];
    try {
      final algorithm = item['algorithm']?.toString() ?? 'SHA1';
      final timer = item['timeStep'] ?? 30;
      final digits = item['digits'] ?? 6;
      final issuer = item['issuerName']?.toString() ?? '';
      final secret = item['secret']?.toString() ?? '';
      final account = item['userName']?.toString() ?? '';

      final otpUrl =
          'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&period=$timer';
      codes.add(Code.fromOTPAuthUrl(otpUrl));
    } catch (e, s) {
      _logger.warning('Failed to parse LastPass entry', e, s);
    }
    onProgress(i + 1, total);
  }
  return codes;
}
