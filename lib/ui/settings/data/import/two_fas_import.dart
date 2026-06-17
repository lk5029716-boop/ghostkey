import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart';

import '../../../../models/code.dart';
import '../../../../models/code_display.dart';
import '../../../../store/code_store.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';

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
  await showGhostKeyProgress(context, 'Importing…');

  try {
    final count = await compute(
      _process2FasInIsolate,
      _TwoFasParams(path: path, password: password),
    );
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    if (count != null) await showGhostKeySuccess(context, count);
  } catch (e, s) {
    _logger.severe('2FAS import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
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

class _TwoFasParams {
  final String path;
  final String? password;
  _TwoFasParams({required this.path, this.password});
}

Future<int?> _process2FasInIsolate(_TwoFasParams params) async {
  final jsonString = await readPickedImportFileAsString(params.path);
  final decoded = jsonDecode(jsonString);
  final isEncrypted = decoded['reference'] != null;

  late List<dynamic> services;
  if (isEncrypted) {
    if (params.password == null) {
      throw Exception('Password required for encrypted 2FAS backup');
    }
    final decryptedJson = decrypt2FasVault(decoded, password: params.password!);
    services = jsonDecode(decryptedJson) as List<dynamic>;
  } else {
    services = (decoded['services'] as List<dynamic>?) ?? [];
  }

  final groupIdToName = <String, String>{};
  for (final g in (decoded['groups'] as List? ?? [])) {
    groupIdToName[g['id']] = g['name'];
  }

  final codes = <Code>[];
  for (final item in services) {
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
  }

  for (final code in codes) {
    await CodeStore.instance.addCode(code);
  }
  return codes.length;
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
