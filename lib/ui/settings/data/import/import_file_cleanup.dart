import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _logger = Logger('GhostKeyImportFileCleanup');

/// Read a file as UTF-8 string. Caller is responsible for cleanup.
Future<String> readPickedImportFileAsString(String path) async {
  return await File(path).readAsString();
}

/// Read a file as raw bytes (for encrypted imports). Caller is responsible for cleanup.
Future<Uint8List> readPickedImportFileAsBytes(String path) async {
  return await File(path).readAsBytes();
}

/// Delete the picked import file if GhostKey owns the directory
/// (file_picker's cache or tmp dir on iOS/Android).
Future<void> deletePickedImportFileIfAppOwned(String path) async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  if (!await isAppOwnedPickedImportFile(path)) return;

  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (e, s) {
    _logger.warning('Failed to delete picked import file copy', e, s);
  }
}

Future<bool> isAppOwnedPickedImportFile(String path) async {
  if (!Platform.isIOS && !Platform.isAndroid) return false;

  final candidatePath = await _canonicalFilePath(path);
  final roots = await _appOwnedPickedFileRoots();

  for (final root in roots) {
    final rootPath = await _canonicalDirectoryPath(root);
    if (p.isWithin(rootPath, candidatePath)) return true;
  }
  return false;
}

Future<List<String>> _appOwnedPickedFileRoots() async {
  final roots = <String>[];
  if (Platform.isIOS) {
    roots.add(Directory.systemTemp.path);
    await _addRoot(roots, getApplicationCacheDirectory);
  } else if (Platform.isAndroid) {
    await _addRoot(roots, getApplicationCacheDirectory, child: 'file_picker');
    await _addRoot(roots, getTemporaryDirectory, child: 'file_picker');
  }
  return roots.toSet().toList();
}

Future<void> _addRoot(
  List<String> roots,
  Future<Directory> Function() provider, {
  String? child,
}) async {
  try {
    final dir = await provider();
    roots.add(child == null ? dir.path : p.join(dir.path, child));
  } catch (e, s) {
    _logger.fine('Failed to resolve import cleanup root', e, s);
  }
}

Future<String> _canonicalFilePath(String path) async {
  try {
    return await File(path).resolveSymbolicLinks();
  } catch (_) {
    return p.normalize(p.absolute(path));
  }
}

Future<String> _canonicalDirectoryPath(String path) async {
  try {
    return await Directory(path).resolveSymbolicLinks();
  } catch (_) {
    return p.normalize(p.absolute(path));
  }
}
