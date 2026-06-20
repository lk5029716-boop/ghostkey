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
  final contents = await File(path).readAsString();
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parsePlainTextCodes(contents, onProgress),
    );
  } catch (e, s) {
    _logger.severe('Plain text import failed', e, s);
    if (!context.mounted) return;
    await showGhostKeyError(
      context,
      'Import failed',
      'Could not import the file.\nError: $e',
    );
  }
}

List<Code> _parsePlainTextCodes(
  String contents,
  void Function(int current, int total) onProgress,
) {
  final codes = <Code>[];

  if (contents.trim().startsWith('otpauth://')) {
    var split = contents.split(',');
    if (split.length == 1) {
      split = const LineSplitter().convert(contents);
    }
    final total = split.length;
    for (var i = 0; i < split.length; i++) {
      final c = split[i];
      final trimmed = c.trim();
      if (trimmed.isEmpty) continue;
      try {
        codes.add(Code.fromOTPAuthUrl(trimmed));
      } catch (e) {
        _logger.warning('Could not parse code: $e');
      }
      onProgress(i + 1, total);
    }
  } else {
    final decoded = jsonDecode(contents);
    final items = (decoded as Map)['items'] as List? ?? [];
    final total = items.length;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        codes.add(Code.fromExportJson(item as Map));
      } catch (e) {
        _logger.warning('Could not parse code: $e');
      }
      onProgress(i + 1, total);
    }
  }
  return codes;
}
