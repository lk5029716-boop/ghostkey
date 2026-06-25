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

final _logger = Logger('2FASImport');

Future<void> show2FasImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from 2FAS Authenticator',
    body:
        'In 2FAS: Settings → Backup → Export to file. Choose JSON format. For password-protected backups, you will be asked for the password.',
    formatHint: '2fas-backup-*.json',
  );
  if (!proceed) return;
  await _pick2FasFile(context);
}

Future<void> _pick2FasFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select 2FAS export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  final jsonString = await readPickedImportFileAsString(path);
  final decoded = jsonDecode(jsonString);
  final version = (decoded['schemaVersion'] ?? 0) as int;
  if (version != 3 && version != 4) {
    if (!context.mounted) return;
    await showGhostKeyError(
      context,
      'Unsupported format',
      'Sorry, this version of 2FAS export is not supported (got v$version).',
    );
    return;
  }

  final isEncrypted = decoded['reference'] != null;
  String? password;
  if (isEncrypted) {
    if (!context.mounted) return;
    password = await showGhostKeyPasswordPrompt(
      context,
      title: 'Enter 2FAS backup password',
    );
    if (password == null) return;
  }

  if (!context.mounted) return;
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parse2FasCodes(decoded, password, onProgress),
    );
  } catch (e, s) {
    _logger.severe('2FAS import failed', e, s);
    if (!context.mounted) return;
    final msg = e.toString();
    await showGhostKeyError(
      context,
      'Import failed',
      isEncrypted && (msg.contains('decrypt') || msg.contains('cipher'))
          ? 'Could not decrypt the backup. Please check your password.\n\nDetails: $msg'
          : 'Could not import 2FAS export.\nError: $msg',
    );
  }
}

/// Parse 2FAS JSON and return a list of Code objects (not yet saved).
Future<List<Code>> _parse2FasCodes(
  dynamic decoded,
  String? password,
  void Function(int current, int total) onProgress,
) async {
  final isEncrypted = decoded['reference'] != null;

  late List<dynamic> services;
  if (isEncrypted) {
    if (password == null) {
      throw Exception('Password required for encrypted 2FAS backup');
    }
    final decryptedJson = decrypt2FasVault(decoded, password: password);
    services = jsonDecode(decryptedJson) as List<dynamic>;
  } else {
    services = (decoded['services'] as List<dynamic>?) ?? [];
  }

  final groupIdToName = <String, String>{};
  for (final g in (decoded['groups'] as List? ?? [])) {
    groupIdToName[g['id']] = g['name'];
  }

  final total = services.length;
  final codes = <Code>[];
  for (var i = 0; i < services.length; i++) {
    final item = services[i];
    try {
      final kind = (item['otp']['tokenType'] as String).toLowerCase();
      var issuer = item['otp']['issuer']?.toString() ?? '';
      if (issuer.isEmpty) {
        issuer = item['name']?.toString() ?? '';
      }
      final account = item['otp']['account']?.toString() ?? '';
      final algorithm = item['otp']['algorithm']?.toString() ?? 'SHA1';
      final secret = item['secret']?.toString() ?? '';
      final timer = item['otp']['period'] ?? 30;
      final digits = item['otp']['digits'] ?? 6;
      final counter = item['otp']['counter'] ?? 0;
      final groupId = item['groupId']?.toString();

      final String otpUrl;
      if (kind == 'totp' || kind == 'steam') {
        otpUrl =
            'otpauth://$kind/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&period=$timer';
      } else if (kind == 'hotp') {
        otpUrl =
            'otpauth://$kind/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&counter=$counter';
      } else {
        throw Exception('Invalid OTP type: $kind');
      }

      var code = Code.fromOTPAuthUrl(otpUrl);
      if (groupId != null && groupIdToName.containsKey(groupId)) {
        code = code.copyWith(
          display: CodeDisplay(tags: [groupIdToName[groupId]!]),
        );
      }
      codes.add(code);
    } catch (e, s) {
      _logger.warning('Failed to parse 2FAS entry', e, s);
    }
    onProgress(i + 1, total);
  }
  return codes;
}

/// 2FAS encrypted backup layout:
/// `servicesEncrypted = "base64(ciphertext):base64(salt):base64(iv)"`
/// Key derived via PBKDF2-HMAC-SHA256, 10000 iterations, 256 bits.
String decrypt2FasVault(dynamic data, {required String password}) {
  const int iterationCount = 10000;
  const int keySize = 256;
  final String encryptedServices = data['servicesEncrypted'] as String;
  final split = encryptedServices.split(':');
  if (split.length < 3) {
    throw Exception('Malformed servicesEncrypted string');
  }
  final encryptedData = base64.decode(split[0]);
  final salt = base64.decode(split[1]);
  final iv = base64.decode(split[2]);

  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  pbkdf2.init(Pbkdf2Parameters(salt, iterationCount, keySize ~/ 8));
  final key = Uint8List(keySize ~/ 8);
  pbkdf2.deriveKey(Uint8List.fromList(utf8.encode(password)), 0, key, 0);

  final cipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  final decrypted = cipher.process(encryptedData);
  return utf8.decode(decrypted);
}
