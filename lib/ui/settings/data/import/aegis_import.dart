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

final _logger = Logger('AegisImport');

Future<void> showAegisImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from Aegis Authenticator',
    body:
        'In Aegis: Settings → Export vault → choose JSON. If you have a password-protected vault, you will be asked for the password.',
    formatHint: 'aegis-export.json  (or  aegis-export.json.aes)',
  );
  if (!proceed) return;
  await _pickAegisFile(context);
}

Future<void> _pickAegisFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Aegis export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  final jsonString = await readPickedImportFileAsString(path);
  final decoded = jsonDecode(jsonString);
  final isEncrypted = decoded['header']?['slots'] != null;

  String? password;
  if (isEncrypted) {
    if (!context.mounted) return;
    password = await showGhostKeyPasswordPrompt(
      context,
      title: 'Enter Aegis vault password',
    );
    if (password == null) return;
  }

  if (!context.mounted) return;
  await showGhostKeyProgress(context, 'Importing…');

  try {
    final count = await compute(
      _processAegisInIsolate,
      _AegisParams(path: path, password: password),
    );
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    if (count != null) await showGhostKeySuccess(context, count);
  } catch (e, s) {
    _logger.severe('Aegis import failed', e, s);
    if (!context.mounted) return;
    await hideGhostKeyProgress(context);
    final msg = e.toString();
    await showGhostKeyError(
      context,
      'Import failed',
      isEncrypted && msg.contains('decrypt')
          ? 'Could not decrypt the vault. Please check your password and try again.\n\nDetails: $msg'
          : 'Could not import Aegis vault.\nError: $msg',
    );
  }
}

class _AegisParams {
  final String path;
  final String? password;
  _AegisParams({required this.path, this.password});
}

Future<int?> _processAegisInIsolate(_AegisParams params) async {
  final jsonString = await readPickedImportFileAsString(params.path);
  final decoded = jsonDecode(jsonString);
  final isEncrypted = decoded['header']?['slots'] != null;

  Map? aegisDb;
  if (isEncrypted) {
    if (params.password == null) {
      throw Exception('Password required for encrypted Aegis vault');
    }
    final inner = decryptAegisVault(decoded, password: params.password!);
    aegisDb = jsonDecode(inner) as Map;
  } else {
    aegisDb = decoded['db'];
  }

  final groupIdToName = <String, String>{};
  if (aegisDb?['groups'] != null) {
    for (final g in aegisDb!['groups']) {
      groupIdToName[g['uuid']] = g['name'];
    }
  }

  final codes = <Code>[];
  for (final item in aegisDb?['entries'] ?? []) {
    try {
      final kind = (item['type'] as String).toLowerCase();
      final account = Uri.encodeComponent(item['name'] ?? '');
      final issuer = Uri.encodeComponent(item['issuer'] ?? '');
      final algorithm = item['info']['algo'];
      final secret = item['info']['secret'];
      final timer = item['info']['period'];
      final digits = item['info']['digits'];
      final counter = item['info']['counter'];
      final isFavorite = item['favorite'] ?? false;

      final tags = <String>[];
      if (item['groups'] != null) {
        for (final g in item['groups']) {
          if (groupIdToName.containsKey(g)) {
            tags.add(groupIdToName[g]!);
          }
        }
      }

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
      code = code.copyWith(
        display: CodeDisplay(pinned: isFavorite, tags: tags),
      );
      codes.add(code);
    } catch (e, s) {
      _logger.warning('Failed to parse Aegis entry', e, s);
    }
  }

  for (final code in codes) {
    await CodeStore.instance.addCode(code);
  }
  return codes.length;
}

/// Aegis vault format: header.slots is a list of password slots.
/// Each slot runs scrypt on the password + salt to produce a 32-byte key,
/// then AES-GCM-decrypts slot.key (||slot.key_params.tag) using that key.
/// The resulting bytes are the master key.
/// The master key then AES-GCM-decrypts header.params-encrypted `db`.
String decryptAegisVault(dynamic data, {required String password}) {
  final header = data['header'];
  final slots = (header['slots'] as List)
      .where((s) => s['type'] == 1)
      .toList();

  Uint8List? masterKey;
  for (final slot in slots) {
    try {
      final salt = _hexDecode(slot['salt'] as String);
      final iterations = slot['n'] as int;
      final r = slot['r'] as int;
      final p = slot['p'] as int;

      final scrypt = Scrypt()
        ..init(ScryptParameters(iterations, r, p, 32, salt));
      final key = scrypt.process(Uint8List.fromList(utf8.encode(password)));

      final params = slot['key_params'];
      final nonce = _hexDecode(params['nonce'] as String);
      final ct = Uint8List.fromList(
        _hexDecode(slot['key'] as String) + _hexDecode(params['tag'] as String),
      );

      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

      masterKey = cipher.process(ct);
      break;
    } catch (_) {
      // Try next slot.
    }
  }
  if (masterKey == null) {
    throw Exception('Unable to decrypt master key with the given password');
  }

  final content = base64.decode(data['db'] as String);
  final params = header['params'];
  final nonce = _hexDecode(params['nonce'] as String);
  final tag = _hexDecode(params['tag'] as String);
  final ct = Uint8List.fromList(content + tag);

  final cipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(masterKey), 128, nonce, Uint8List(0)));
  return utf8.decode(cipher.process(ct));
}

Uint8List _hexDecode(String hex) {
  final clean = hex.replaceAll(RegExp(r'\s'), '');
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}
