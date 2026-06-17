import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:logging/logging.dart';

import '../../../../models/code.dart';
import '../../../../models/protos/googleauth.pb.dart';

const kGoogleAuthExportPrefix = 'otpauth-migration://offline?data=';

bool isGoogleAuthExportQr(String qrCodeData) {
  return qrCodeData.startsWith(kGoogleAuthExportPrefix);
}

List<Code> parseGoogleAuth(String qrCodeData) {
  try {
    final codes = <Code>[];
    final payload = qrCodeData.substring(kGoogleAuthExportPrefix.length);
    final base64Decoded = base64Decode(Uri.decodeComponent(payload));
    final mPayload = MigrationPayload.fromBuffer(base64Decoded);

    for (final otpParameter in mPayload.otpParameters) {
      final issuer = otpParameter.issuer;
      final account = otpParameter.name;
      final counter = otpParameter.counter;
      final bytes = Uint8List.fromList(otpParameter.secret);
      final secret = base32.encode(bytes);

      int digits = 6;
      int timer = 30; // Google Auth default
      Algorithm algorithm = Algorithm.sha1;

      switch (otpParameter.algorithm) {
        case MigrationPayload_Algorithm.ALGORITHM_MD5:
          throw Exception('MD5 is not supported');
        case MigrationPayload_Algorithm.ALGORITHM_SHA1:
          algorithm = Algorithm.sha1;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_SHA256:
          algorithm = Algorithm.sha256;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_SHA512:
          algorithm = Algorithm.sha512;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_UNSPECIFIED:
          algorithm = Algorithm.sha1;
          break;
      }

      switch (otpParameter.digits) {
        case MigrationPayload_DigitCount.DIGIT_COUNT_EIGHT:
          digits = 8;
          break;
        case MigrationPayload_DigitCount.DIGIT_COUNT_SIX:
          digits = 6;
          break;
        case MigrationPayload_DigitCount.DIGIT_COUNT_UNSPECIFIED:
          digits = 6;
      }

      final String otpUrl;
      if (otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_TOTP ||
          otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_UNSPECIFIED) {
        otpUrl =
            'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=${algorithm.name}&digits=$digits&period=$timer';
      } else if (otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_HOTP) {
        otpUrl =
            'otpauth://hotp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=${algorithm.name}&digits=$digits&counter=$counter';
      } else {
        throw Exception('Invalid OTP type');
      }
      codes.add(Code.fromOTPAuthUrl(otpUrl));
    }
    return codes;
  } catch (e, s) {
    Logger('GoogleAuthImport')
        .severe('Error parsing Google Auth QR', e, s);
    throw Exception('Failed to parse Google Auth QR code');
  }
}
