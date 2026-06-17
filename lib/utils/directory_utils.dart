import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DirectoryUtils {
  static Future<String> getDatabasePath(String databaseName) async {
    final dir = await getApplicationSupportDirectory();
    return p.joinAll([dir.path, ".$databaseName"]);
  }

  static Future<Directory> getDirectoryForInit() async {
    final dir = await getApplicationCacheDirectory();
    return Directory(p.join(dir.path, "ghostkeyinit"));
  }

  static Future<Directory> getTempsDir() async {
    return await getTemporaryDirectory();
  }

  /// Ente's upstream renames the DB file on first run after the v1
  /// release. GhostKey is a fresh install, so this is a no-op on mobile
  /// (and the desktop migration paths are out of scope for the demo).
  static Future<void> migrateNamingChanges() async {
    // No-op for new GhostKey installs.
  }
}
