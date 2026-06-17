import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/code.dart';
import 'dialog_util.dart';

const _pickedImagesDirectoryName = 'picked_images';

/// Result of attempting to import a TOTP code from a QR (scanned live or
/// picked from the gallery). Replaces ente's `GalleryImportResult` with
/// the same shape so call sites stay compatible.
class GalleryImportResult {
  final Code? code;
  final List<Code>? googleAuthCodes;

  const GalleryImportResult.code(Code this.code) : googleAuthCodes = null;

  const GalleryImportResult.googleAuthCodes(List<Code> this.googleAuthCodes)
      : code = null;
}

Future<Directory> _getPickedImagesDirectory({
  Future<Directory> Function()? documentsDirectoryProvider,
}) async {
  final documentsDirectory =
      await (documentsDirectoryProvider ?? getApplicationDocumentsDirectory)();
  return Directory(p.join(documentsDirectory.path, _pickedImagesDirectoryName));
}

Future<File?> _getManagedPickedGalleryImage(
  String imagePath, {
  Future<Directory> Function()? documentsDirectoryProvider,
}) async {
  if (!Platform.isIOS) {
    return null;
  }

  final pickedImagesDirectory = await _getPickedImagesDirectory(
    documentsDirectoryProvider: documentsDirectoryProvider,
  );
  if (!p.isWithin(
    p.normalize(pickedImagesDirectory.path),
    p.normalize(imagePath),
  )) {
    return null;
  }
  return File(imagePath);
}

Future<void> _clearPickedImagesDirectoryContents(
  Directory pickedImagesDirectory, {
  Logger? logger,
}) async {
  try {
    await for (final entity in pickedImagesDirectory.list()) {
      await entity.delete(recursive: true);
    }
  } catch (e, stackTrace) {
    logger?.warning(
      'Failed to clear stale picked_images contents',
      e,
      stackTrace,
    );
  }
}

Future<void> _cleanupPickedGalleryImageIfNeeded(
  File imageFile, {
  Logger? logger,
}) async {
  if (!await imageFile.exists()) {
    return;
  }

  try {
    await imageFile.delete();
  } catch (e, stackTrace) {
    logger?.warning('Failed to delete picked gallery image', e, stackTrace);
  }
}

Future<void> cleanupPickedImagesOnStartup({Logger? logger}) async {
  if (!Platform.isIOS) {
    return;
  }

  final pickedImagesDirectory = await _getPickedImagesDirectory();
  if (!await pickedImagesDirectory.exists()) {
    return;
  }

  await _clearPickedImagesDirectoryContents(
    pickedImagesDirectory,
    logger: logger,
  );
}

/// Parse a QR payload (scanned live or pulled from a gallery image) and
/// return either a single TOTP/HOTP `Code` or a batch of codes if the
/// payload is a Google Authenticator export.
///
/// Stub: GhostKey supports single `otpauth://` URIs for now. Google Auth
/// export (the `otpauth-migration://` scheme) is wired in a later pass
/// using `models/protos/googleauth.pb.dart`.
GalleryImportResult parseQrImportPayload(String qrCodeData) {
  if (qrCodeData.startsWith('otpauth-migration://')) {
    throw const FormatException(
      'Google Authenticator bulk import not yet implemented in GhostKey',
    );
  }
  return GalleryImportResult.code(Code.fromOTPAuthUrl(qrCodeData));
}

/// Prompt the user to pick an image from their gallery and try to extract
/// a TOTP code. Currently returns null — live QR scanning is the
/// supported path; gallery import is reserved for a later release.
Future<GalleryImportResult?> pickCodeFromGallery(
  BuildContext context, {
  Logger? logger,
}) async {
  // The full gallery → ml-kit → Code flow is not wired yet. We still
  // expose the FilePicker hook so the UI can call it without crashing.
  try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) {
      return null;
    }
    logger?.info(
      'Gallery image picked: ${result.files.single.path} — '
      'image-QR decoding not implemented in demo build',
    );
    await showErrorDialog(
      context,
      'Coming soon',
      'Image QR scanning will land in a future build. Use the live scanner for now.',
    );
    return null;
  } catch (e, st) {
    logger?.severe('Failed to import from gallery', e, st);
    return null;
  }
}
