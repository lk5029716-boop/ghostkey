import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart';

import 'package:flutter/scheduler.dart';

import '../../../../models/code.dart';
import '../../../../models/export/ente.dart';
import 'import_helpers.dart';
import 'import_progress.dart';
import 'secret_box.dart';

final _logger = Logger('EncryptedEnteImport');

Future<void> showEncryptedEnteImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import encrypted Ente Auth export',
    body:
        'Select an Ente Auth encrypted JSON backup. You will be asked for the password used when exporting.',
    formatHint: 'ente-auth-export-*.json',
  );
  if (!proceed) return;
  await _pickEnteFile(context);
}

Future<void> _pickEnteFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Ente export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  if (!context.mounted) return;
  final jsonString = await File(path).readAsString();

  EnteAuthExport export;
  try {
    export = EnteAuthExport.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  } catch (e) {
    await showGhostKeyError(
      context,
      'Not an Ente export',
      'The selected file is not a valid Ente Auth encrypted export.\nError: $e',
    );
    return;
  }

  final password = await showGhostKeyPasswordPrompt(
    context,
    title: 'Enter export password',
  );
  if (password == null || password.isEmpty) return;

  if (!context.mounted) return;
  // Wait for the frame to finish processing before pushing a new dialog.
  // This guarantees the password dialog's route removal is fully processed.
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _decryptAndParseEnte(
        export, password, onProgress,
      ),
    );
  } catch (e, s) {
    _logger.severe('Ente import failed', e, s);
    if (!context.mounted) return;
    final msg = e.toString();
    final isPwd = msg.contains('MAC verification failed') || msg.contains('decrypt') || msg.contains('password');
    await showGhostKeyError(
      context,
      'Import failed',
      isPwd
          ? 'Could not decrypt the backup. Please check your password and try again.\n\nDetails: $msg'
          : 'Could not import Ente export.\nError: $msg',
    );
  }
}

/// Decrypts the Ente export in an isolate, then parses the lines.
/// The [onProgress] callback updates the single dialog throughout.
Future<List<Code>> _decryptAndParseEnte(
  EnteAuthExport export,
  String password,
  void Function(int current, int total) onProgress,
) async {
  onProgress(0, 1); // Show progress bar immediately, matching other importers
  final result = await compute(
    _decryptEnteInIsolate,
    _EnteDecryptParams(
      memLimit: export.kdfParams.memLimit,
      opsLimit: export.kdfParams.opsLimit,
      salt: export.kdfParams.salt,
      encryptedDataB64: export.encryptedData,
      encryptionNonceB64: export.encryptionNonce,
      password: password,
    ),
  );

  if (result['status'] == 'error') {
    throw Exception(result['message'] ?? 'Decryption failed');
  }

  final decrypted = result['data']!;
  final lines = decrypted.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final total = lines.length;
  final codes = <Code>[];
  for (var i = 0; i < lines.length; i++) {
    try {
      codes.add(Code.fromOTPAuthUrl(lines[i].trim()));
    } catch (e) {
      _logger.warning('Could not parse code: $e');
    }
    onProgress(i + 1, total);
  }
  return codes;
}

class _EnteDecryptParams {
  final int memLimit;
  final int opsLimit;
  final String salt;
  final String encryptedDataB64;
  final String encryptionNonceB64;
  final String password;
  _EnteDecryptParams({
    required this.memLimit,
    required this.opsLimit,
    required this.salt,
    required this.encryptedDataB64,
    required this.encryptionNonceB64,
    required this.password,
  });
}

Map<String, String> _decryptEnteInIsolate(_EnteDecryptParams params) {
  try {
    // 1. Derive 32-byte key from password via Argon2id.
    final salt = base64Decode(params.salt);
    // Ente's export stores memLimit in bytes (libsodium convention), but
    // pointycastle's Argon2Parameters.memory expects 1024-byte blocks.
    final memoryBlocks = params.memLimit ~/ 1024;
    final generator = Argon2BytesGenerator()
      ..init(
        Argon2Parameters(
          Argon2Parameters.ARGON2_id,
          Uint8List.fromList(salt),
          desiredKeyLength: 32,
          iterations: params.opsLimit,
          memory: memoryBlocks,
          lanes: 1,
          version: Argon2Parameters.ARGON2_VERSION_13,
        ),
      );
    final derivedKey = generator.process(
      Uint8List.fromList(utf8.encode(params.password)),
    );

    // 2. Decrypt via XChaCha20-Poly1305 secretbox.
    final ciphertext = base64Decode(params.encryptedDataB64);
    final nonce = base64Decode(params.encryptionNonceB64);
    final plaintext = secretBoxOpenEasy(
      ciphertextWithTag: Uint8List.fromList(ciphertext),
      nonce: Uint8List.fromList(nonce),
      key: derivedKey,
    );
    return {'status': 'ok', 'data': utf8.decode(plaintext)};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}
