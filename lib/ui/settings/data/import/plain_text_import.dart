import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('PlainTextImport');

Future<void> showPlainTextImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import codes',
    body:
        'Select a text file that contains one otpauth:// URI per line, '
        'or comma-separated URIs, or a JSON file exported by an authenticator app.',
    formatHint: 'otpauth://totp/...',
  );
  if (!proceed) return;
  await _pickImportFile(context);
}

Future<void> _pickImportFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles();
  if (result == null) return;
  final path = result.files.single.path!;

  if (!context.mounted) return;
  await showGhostKeyProgress(context, 'Parsing…');

  try {
    final contents = await File(path).readAsString();
    final codes = _parsePlainTextCodes(contents);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showImportProgress(context: context, codes: codes);
  } catch (e, s) {
    _logger.severe('Plain text import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import the file.\nError: $e',
    );
  }
}

List<Code> _parsePlainTextCodes(String contents) {
  final codes = <Code>[];

  if (contents.trim().startsWith('otpauth://')) {
    var split = contents.split(',');
    if (split.length == 1) {
      split = const LineSplitter().convert(contents);
    }
    for (final c in split) {
      final trimmed = c.trim();
      if (trimmed.isEmpty) continue;
      try {
        codes.add(Code.fromOTPAuthUrl(trimmed));
      } catch (e) {
        _logger.warning('Could not parse code: $e');
      }
    }
  } else {
    final decoded = jsonDecode(contents);
    final items = (decoded as Map)['items'] as List? ?? [];
    for (final item in items) {
      try {
        codes.add(Code.fromExportJson(item as Map));
      } catch (e) {
        _logger.warning('Could not parse code: $e');
      }
    }
  }
  return codes;
}
