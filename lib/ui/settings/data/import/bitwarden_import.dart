import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import '../../../../models/code_display.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('BitwardenImport');

Future<void> showBitwardenImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from Bitwarden',
    body:
        'In Bitwarden web vault: Tools → Export vault → choose "JSON (unencrypted)". Save the file and select it here.',
    formatHint: 'bitwarden_export_*.json',
  );
  if (!proceed) return;
  await _pickBitwardenFile(context);
}

Future<void> _pickBitwardenFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Bitwarden export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  if (!context.mounted) return;
  await showGhostKeyProgress(context, 'Parsing…');

  try {
    final jsonString = await readPickedImportFileAsString(path);
    final codes = _parseBitwardenCodes(jsonString);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showImportProgress(context: context, codes: codes);
  } catch (e, s) {
    _logger.severe('Bitwarden import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import Bitwarden export.\nError: $e',
    );
  }
}

List<Code> _parseBitwardenCodes(String jsonString) {
  final data = jsonDecode(jsonString);
  final items = data['items'] as List<dynamic>? ?? [];

  final folderIdToName = <String, String>{};
  try {
    for (final f in (data['folders'] as List? ?? [])) {
      folderIdToName[f['id']] = f['name'];
    }
  } catch (e) {
    _logger.fine('Bitwarden folders not parseable: $e');
  }

  final codes = <Code>[];
  for (final item in items) {
    final login = item['login'];
    if (login == null) continue;
    final totp = login['totp'];
    if (totp == null) continue;

    try {
      final Code code;
      if (totp.toString().contains('otpauth://')) {
        code = Code.fromOTPAuthUrl(totp.toString());
      } else if (totp.toString().contains('steam://')) {
        final secret = totp.toString().split('steam://')[1];
        code = Code.fromAccountAndSecret(
          Type.steam,
          login['username']?.toString() ?? '',
          item['name']?.toString() ?? '',
          secret,
          null,
          Code.steamDigits,
        );
      } else {
        final issuer = item['name']?.toString() ?? '';
        final account = login['username']?.toString() ?? '';
        code = Code.fromAccountAndSecret(
          Type.totp,
          account,
          issuer,
          totp.toString(),
          null,
          Code.defaultDigits,
        );
      }

      final folderId = item['folderId']?.toString();
      if (folderId != null && folderIdToName.containsKey(folderId)) {
        codes.add(code.copyWith(
          display: CodeDisplay(tags: [folderIdToName[folderId]!]),
        ));
      } else {
        codes.add(code);
      }
    } catch (e, s) {
      _logger.warning('Failed to parse Bitwarden item', e, s);
    }
  }
  return codes;
}
