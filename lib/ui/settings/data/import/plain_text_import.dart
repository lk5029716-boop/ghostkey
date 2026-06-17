import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import '../../../../store/code_store.dart';
import 'import_helpers.dart';

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
  await showGhostKeyProgress(context, 'Importing…');

  try {
    final count = await compute(_processPlainTextInIsolate, path);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    if (count != null) await showGhostKeySuccess(context, count);
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

Future<int?> _processPlainTextInIsolate(String path) async {
  final contents = await File(path).readAsString();
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

  for (final code in codes) {
    await CodeStore.instance.addCode(code);
  }
  return codes.length;
}
