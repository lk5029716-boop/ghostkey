import 'package:flutter/cupertino.dart';

import 'aegis_import.dart';
import 'andotp_import.dart';
import 'bitwarden_import.dart';
import 'encrypted_ente_import.dart';
import 'google_auth_import.dart';
import 'lastpass_import.dart';
import 'plain_text_import.dart';
import 'proton_import.dart';
import 'raivo_plain_text_import.dart';
import 'two_fas_import.dart';

/// All import sources GhostKey supports.
enum ImportType {
  plainText,
  encrypted,
  raivo,
  googleAuthenticator,
  aegis,
  twoFas,
  bitwarden,
  lastpass,
  proton,
  andOTP,
}

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  Future<void> initiateImport(BuildContext context, ImportType type) async {
    switch (type) {
      case ImportType.plainText:
        await showPlainTextImportInstruction(context);
        break;
      case ImportType.encrypted:
        await showEncryptedEnteImportInstruction(context);
        break;
      case ImportType.raivo:
        await showRaivoImportInstruction(context);
        break;
      case ImportType.googleAuthenticator:
        await showGoogleAuthInstruction(context);
        break;
      case ImportType.aegis:
        await showAegisImportInstruction(context);
        break;
      case ImportType.twoFas:
        await show2FasImportInstruction(context);
        break;
      case ImportType.bitwarden:
        await showBitwardenImportInstruction(context);
        break;
      case ImportType.lastpass:
        await showLastpassImportInstruction(context);
        break;
      case ImportType.proton:
        await showProtonImportInstruction(context);
        break;
      case ImportType.andOTP:
        await showAndOTPImportInstruction(context);
        break;
    }
  }
}
