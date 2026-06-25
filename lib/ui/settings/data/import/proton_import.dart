import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart';

import '../../../../models/code.dart';
import 'import_file_cleanup.dart';
import 'import_helpers.dart';
import 'import_progress.dart';

const _protonExportVersion = 1;
const _protonExportNonceLength = 12;
const _protonExportMacSizeBits = 128;
const _protonExportSaltLength = 16;
const _protonExportPasswordKeyLength = 32;
const _protonExportAad = 'proton.authenticator.export.v1';

final _logger = Logger('ProtonImport');

class IncorrectProtonExportPasswordException implements Exception {
  const IncorrectProtonExportPasswordException();
  @override
  String toString() => 'Incorrect password';
}

Map<String, dynamic> decodeProtonExportJson(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is! Map) throw const FormatException('Invalid Proton export');
  final exportJson = Map<String, dynamic>.from(decoded);
  _validateVersion(exportJson);
  return exportJson;
}

bool isEncryptedProtonExport(Map<String, dynamic> decoded) {
  return decoded['salt'] != null &&
      decoded['content'] != null &&
      decoded['entries'] == null;
}

List<Code> parseProtonExport(Map<String, dynamic> decoded) {
  if (isEncryptedProtonExport(decoded)) {
    throw const FormatException('Password protected Proton export');
  }
  final entries = decoded['entries'];
  if (entries is! List) throw const FormatException('Invalid Proton export');

  final codes = <Code>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    try {
      final entryMap = Map<String, dynamic>.from(entry);
      final content = entryMap['content'];
      if (content is! Map) continue;
      final contentMap = Map<String, dynamic>.from(content);
      final type = contentMap['entry_type'] as String?;

      final Code code;
      switch (type) {
        case 'Steam':
          final steamUri = contentMap['uri'] as String?;
          if (steamUri == null || !steamUri.startsWith('steam://')) continue;
          final name = (contentMap['name'] as String?)?.trim();
          code = Code.fromAccountAndSecret(
            Type.steam,
            '',
            (name == null || name.isEmpty) ? 'Steam' : name,
            steamUri.substring('steam://'.length),
            null,
            Code.steamDigits,
          );
          break;
        case 'Totp':
          final otpUri = contentMap['uri'] as String?;
          if (otpUri == null || !otpUri.startsWith('otpauth://')) continue;
          final parsed = Code.fromOTPAuthUrl(otpUri);
          final encI = Uri.encodeComponent(parsed.issuer);
          final encA = Uri.encodeComponent(parsed.account);
          final url =
              'otpauth://totp/$encI:$encA?secret=${parsed.secret}&issuer=$encI&algorithm=${parsed.algorithm.name.toUpperCase()}&digits=${parsed.digits}&period=${parsed.period}';
          code = Code.fromOTPAuthUrl(url);
          break;
        default:
          _logger.warning('Unsupported Proton entry type: $type');
          continue;
      }

      final note = entryMap['note'] as String?;
      final finalCode = (note != null && note.isNotEmpty)
          ? code.copyWith(display: code.display.copyWith(note: note))
          : code;
      codes.add(finalCode);
    } catch (e, s) {
      _logger.warning('Failed to parse Proton entry', e, s);
    }
  }
  return codes;
}

Future<List<Code>> _parseProtonEntries(
  Map<String, dynamic> decoded,
  String? password,
  void Function(int current, int total) onProgress,
) async {
  if (isEncryptedProtonExport(decoded)) {
    if (password == null) {
      throw Exception('Password required for encrypted Proton export');
    }
    onProgress(0, 1);
    final result = await compute(
      _decryptProtonInIsolate,
      _ProtonDecryptParams(jsonEncode(decoded), password),
    );
    if (result['status'] == 'incorrect_password') {
      throw const IncorrectProtonExportPasswordException();
    }
    decoded = decodeProtonExportJson(result['jsonString']!);
  }
  final entries = decoded['entries'];
  if (entries is! List) throw const FormatException('Invalid Proton export');

  final total = entries.length;
  final codes = <Code>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    if (entry is! Map) continue;
    try {
      final entryMap = Map<String, dynamic>.from(entry);
      final content = entryMap['content'];
      if (content is! Map) continue;
      final contentMap = Map<String, dynamic>.from(content);
      final type = contentMap['entry_type'] as String?;

      final Code code;
      switch (type) {
        case 'Steam':
          final steamUri = contentMap['uri'] as String?;
          if (steamUri == null || !steamUri.startsWith('steam://')) continue;
          final name = (contentMap['name'] as String?)?.trim();
          code = Code.fromAccountAndSecret(
            Type.steam,
            '',
            (name == null || name.isEmpty) ? 'Steam' : name,
            steamUri.substring('steam://'.length),
            null,
            Code.steamDigits,
          );
          break;
        case 'Totp':
          final otpUri = contentMap['uri'] as String?;
          if (otpUri == null || !otpUri.startsWith('otpauth://')) continue;
          final parsed = Code.fromOTPAuthUrl(otpUri);
          final encI = Uri.encodeComponent(parsed.issuer);
          final encA = Uri.encodeComponent(parsed.account);
          final url =
              'otpauth://totp/$encI:$encA?secret=${parsed.secret}&issuer=$encI&algorithm=${parsed.algorithm.name.toUpperCase()}&digits=${parsed.digits}&period=${parsed.period}';
          code = Code.fromOTPAuthUrl(url);
          break;
        default:
          _logger.warning('Unsupported Proton entry type: $type');
          continue;
      }

      final note = entryMap['note'] as String?;
      final finalCode = (note != null && note.isNotEmpty)
          ? code.copyWith(display: code.display.copyWith(note: note))
          : code;
      codes.add(finalCode);
    } catch (e, s) {
      _logger.warning('Failed to parse Proton entry', e, s);
    }
    onProgress(i + 1, total);
  }
  return codes;
}

/// Decrypts an encrypted Proton export. Returns the inner JSON string.
String decryptProtonExport(
  Map<String, dynamic> decoded, {
  required String password,
}) {
  _validateVersion(decoded);
  if (!isEncryptedProtonExport(decoded)) {
    throw const FormatException('Invalid Proton export');
  }
  final saltB64 = decoded['salt'] as String;
  final contentB64 = decoded['content'] as String;
  final salt = base64Decode(saltB64);
  if (salt.length != _protonExportSaltLength) {
    throw const FormatException('Invalid Proton export salt');
  }
  final encryptedBytes = base64Decode(contentB64);
  if (encryptedBytes.length <= _protonExportNonceLength) {
    throw const FormatException('Invalid Proton export content');
  }

  final key = _deriveProtonPasswordKey(password, Uint8List.fromList(salt));
  final nonce = encryptedBytes.sublist(0, _protonExportNonceLength);
  final ct = encryptedBytes.sublist(_protonExportNonceLength);

  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(
        KeyParameter(key),
        _protonExportMacSizeBits,
        nonce,
        Uint8List.fromList(utf8.encode(_protonExportAad)),
      ),
    );
  try {
    return utf8.decode(cipher.process(ct));
  } on InvalidCipherTextException {
    throw const IncorrectProtonExportPasswordException();
  }
}

Uint8List _deriveProtonPasswordKey(String password, Uint8List salt) {
  final generator = Argon2BytesGenerator()
    ..init(
      Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        desiredKeyLength: _protonExportPasswordKeyLength,
        iterations: 2,
        memory: 19 * 1024,
        lanes: 1,
        version: Argon2Parameters.ARGON2_VERSION_13,
      ),
    );
  return generator.process(Uint8List.fromList(utf8.encode(password)));
}

void _validateVersion(Map<String, dynamic> decoded) {
  if (decoded['version'] != _protonExportVersion) {
    throw const FormatException('Invalid Proton export version');
  }
}

class _ProtonDecryptParams {
  final String jsonString;
  final String password;
  _ProtonDecryptParams(this.jsonString, this.password);
}

Map<String, String> _decryptProtonInIsolate(_ProtonDecryptParams params) {
  final decoded = decodeProtonExportJson(params.jsonString);
  try {
    return {
      'status': 'ok',
      'jsonString': decryptProtonExport(decoded, password: params.password),
    };
  } on IncorrectProtonExportPasswordException {
    return {'status': 'incorrect_password'};
  }
}

Future<void> showProtonImportInstruction(BuildContext context) async {
  final proceed = await showImportInstructionDialog(
    context: context,
    title: 'Import from Proton Authenticator',
    body:
        'In Proton Authenticator: ⋯ menu → Export → choose JSON. If the export is password-protected, enter that password when prompted.',
    formatHint: 'proton-authenticator-export-*.json',
  );
  if (!proceed) return;
  await _pickProtonFile(context);
}

Future<void> _pickProtonFile(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select Proton export',
  );
  if (result == null) return;
  final path = result.files.single.path!;

  final jsonString = await readPickedImportFileAsString(path);

  if (!context.mounted) return;
  var decoded = decodeProtonExportJson(jsonString);

  String? password;
  if (isEncryptedProtonExport(decoded)) {
    if (!context.mounted) return;
    password = await showGhostKeyPasswordPrompt(
      context,
      title: 'Enter Proton export password',
    );
    if (password == null) return;
  }

  if (!context.mounted) return;
  await SchedulerBinding.instance.endOfFrame;
  if (!context.mounted) return;
  try {
    await showImportProgressWithParsing(
      context: context,
      parser: (onProgress) => _parseProtonEntries(decoded, password, onProgress),
    );
  } catch (e, s) {
    _logger.severe('Proton import failed', e, s);
    if (!context.mounted) return;
    final msg = e.toString();
    final isPwd = password != null && (msg.contains('decrypt') || msg.contains('password') || msg.contains('cipher'));
    await showGhostKeyError(
      context,
      'Import failed',
      isPwd
          ? 'Could not decrypt the backup. Please check your password.\n\nDetails: $msg'
          : 'Could not import Proton export.\nError: $msg',
    );
  }
}
