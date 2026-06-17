import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import '../../../../store/code_store.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';

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
  await showGhostKeyProgress(context, 'Importing…');

  try {
    final count = await compute(_processLastpassInIsolate, path);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    if (count != null) await showGhostKeySuccess(context, count);
  } catch (e, s) {
    _logger.severe('LastPass import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import LastPass export.\nError: $e',
    );
  }
}

Future<int?> _processLastpassInIsolate(String path) async {
  final jsonString = await readPickedImportFileAsString(path);
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final accounts = data['accounts'] as List<dynamic>? ?? [];

  final codes = <Code>[];
  for (final item in accounts) {
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
  }

  for (final code in codes) {
    await CodeStore.instance.addCode(code);
  }
  return codes.length;
}
