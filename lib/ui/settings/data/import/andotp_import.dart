import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart';

import '../../../../models/code.dart';
import '../../../../models/code_display.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

final _logger = Logger('AndOTPImport');

Future<void> showAndOTPImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from andOTP',
    body:
        'In andOTP: Settings → Backup → Export to file. Choose "Plain" (JSON) or "Encrypted" (AES). For encrypted backups, you will be asked for the password.',
    formatHint: 'andOTP.json  /  andOTP.json.aes',
  );
  if (!proceed) return;
  await _pickAndOTPFile(context);
}

Future<void> _pickAndOTPFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select andOTP backup',
    type: FileType.custom,
    allowedExtensions: ['json', 'aes'],
  );
  if (result == null) return;
  final path = result.files.single.path!;

  final bytes = await readPickedImportFileAsBytes(path);
  final isPlain = _looksLikeJson(bytes);

  String? password;
  if (!isPlain) {
    if (!context.mounted) return;
    password = await showGhostKeyPasswordPrompt(
      context,
      title: 'Enter andOTP backup password',
    );
    if (password == null) return;
  }

  if (!context.mounted) return;
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parseAndOTPCodes(bytes, password, onProgress),
    );
  } catch (e, s) {
    _logger.severe('andOTP import failed', e, s);
    if (!context.mounted) return;
    final msg = e.toString();
    await showGhostKeyError(
      context,
      'Import failed',
      !isPlain && (msg.contains('decrypt') || msg.contains('cipher'))
          ? 'Could not decrypt the backup. Please check your password.\n\nDetails: $msg'
          : 'Could not import andOTP backup.\nError: $msg',
    );
  }
}

bool _looksLikeJson(Uint8List bytes) {
  for (final b in bytes) {
    final c = b & 0xFF;
    if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) continue;
    return c == 0x7B /* { */ || c == 0x5B /* [ */;
  }
  return false;
}

Future<List<Code>> _parseAndOTPCodes(
  Uint8List bytes,
  String? password,
  void Function(int current, int total) onProgress,
) async {
  final isPlain = _looksLikeJson(bytes);

  late List<dynamic> entries;
  if (isPlain) {
    final jsonString = utf8.decode(bytes);
    entries = jsonDecode(jsonString) as List<dynamic>;
  } else {
    if (password == null) {
      throw Exception('Password required for encrypted andOTP backup');
    }
    final jsonString = _decryptAndOTPBackup(bytes, password);
    entries = jsonDecode(jsonString) as List<dynamic>;
  }

  final total = entries.length;
  final codes = <Code>[];
  for (var i = 0; i < entries.length; i++) {
    final item = entries[i];
    try {
      final type = (item['type'] as String).toUpperCase();
      if (type != 'TOTP' && type != 'HOTP' && type != 'STEAM') {
        _logger.warning('Skipping unsupported OTP type: $type');
        continue;
      }
      final issuer = (item['issuer'] as String?) ?? '';
      final label = (item['label'] as String?) ?? '';
      final secret = item['secret'] as String;
      final algorithm = (item['algorithm'] as String?) ?? 'SHA1';
      final digits = (item['digits'] as int?) ?? 6;
      final period = (item['period'] as int?) ?? 30;
      final counter = (item['counter'] as int?) ?? 0;
      final tags = ((item['tags'] as List?)?.map((e) => e.toString()) ?? [])
          .toList();

      final encIssuer = Uri.encodeComponent(issuer);
      final encLabel = Uri.encodeComponent(label);

      final String otpUrl;
      if (type == 'TOTP' || type == 'STEAM') {
        final otpType = type.toLowerCase();
        otpUrl =
            'otpauth://$otpType/$encIssuer:$encLabel?secret=$secret&issuer=$encIssuer&algorithm=$algorithm&digits=$digits&period=$period';
      } else {
        otpUrl =
            'otpauth://hotp/$encIssuer:$encLabel?secret=$secret&issuer=$encIssuer&algorithm=$algorithm&digits=$digits&counter=$counter';
      }

      var code = Code.fromOTPAuthUrl(otpUrl);
      if (tags.isNotEmpty) {
        code = code.copyWith(display: CodeDisplay(tags: tags));
      }
      codes.add(code);
    } catch (e, s) {
      _logger.warning('Failed to parse andOTP entry', e, s);
    }
    onProgress(i + 1, total);
  }
  return codes;
}

/// andOTP encrypted file structure:
///   [iterations: 4 bytes BE][salt: 12 bytes][iv: 12 bytes][ciphertext+tag: N bytes]
/// Key derived via PBKDF2-HMAC-SHA1.
String _decryptAndOTPBackup(Uint8List fileBytes, String password) {
  const int intLength = 4;
  const int saltLength = 12;
  const int ivLength = 12;
  const int keyLength = 32;

  if (fileBytes.length < intLength + saltLength + ivLength) {
    throw Exception('Invalid andOTP encrypted file: file too small');
  }
  final byteData = ByteData.sublistView(fileBytes, 0, intLength);
  final iterations = byteData.getInt32(0, Endian.big);
  final salt = Uint8List.sublistView(fileBytes, intLength, intLength + saltLength);
  final iv = Uint8List.sublistView(
    fileBytes,
    intLength + saltLength,
    intLength + saltLength + ivLength,
  );
  final ct = Uint8List.sublistView(fileBytes, intLength + saltLength + ivLength);

  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA1Digest(), 64));
  pbkdf2.init(Pbkdf2Parameters(salt, iterations, keyLength));
  final key = Uint8List(keyLength);
  pbkdf2.deriveKey(Uint8List.fromList(utf8.encode(password)), 0, key, 0);

  final cipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  final decrypted = cipher.process(ct);
  return utf8.decode(decrypted);
}
