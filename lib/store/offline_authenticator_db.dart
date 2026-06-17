import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/authenticator/auth_entity.dart';
import '../models/authenticator/local_auth_entity.dart';
import '../utils/directory_utils.dart';

class OfflineAuthenticatorDB {
  static const _databaseName = "ente.offline_authenticator.db";
  static const _databaseVersion = 2;

  static const entityTable = 'entities';

  OfflineAuthenticatorDB._privateConstructor();
  static final OfflineAuthenticatorDB instance =
      OfflineAuthenticatorDB._privateConstructor();

  static Future<Database>? _dbFuture;

  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      var databaseFactory = databaseFactoryFfi;
      return await databaseFactory.openDatabase(
        await DirectoryUtils.getDatabasePath(_databaseName),
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
    final Directory documentsDirectory = Platform.isMacOS
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    debugPrint(path);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
                CREATE TABLE $entityTable (
                  _generatedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                  id TEXT,
                  encryptedData TEXT NOT NULL,
                  header TEXT NOT NULL,
                  createdAt INTEGER NOT NULL,
                  updatedAt INTEGER NOT NULL,
                  shouldSync INTEGER DEFAULT 0,
                  manual_order INTEGER DEFAULT 0,
                  UNIQUE(id)
                );
      ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: add manual_order for drag-to-reorder
      await db
          .execute('ALTER TABLE $entityTable ADD COLUMN manual_order INTEGER DEFAULT 0');
    }
  }

  Future<int> insert(String encData, String header) async {
    final db = await instance.database;
    final int timeInMicroSeconds = DateTime.now().microsecondsSinceEpoch;
    final insertedID = await db.insert(entityTable, {
      "encryptedData": encData,
      "header": header,
      "shouldSync": 1,
      "createdAt": timeInMicroSeconds,
      "updatedAt": timeInMicroSeconds,
    });
    return insertedID;
  }

  Future<int> updateEntry(
    int generatedID,
    String encData,
    String header,
  ) async {
    final db = await instance.database;
    final int timeInMicroSeconds = DateTime.now().microsecondsSinceEpoch;
    int affectedRows = await db.update(
      entityTable,
      {
        "encryptedData": encData,
        "header": header,
        "shouldSync": 1,
        "updatedAt": timeInMicroSeconds,
      },
      where: '_generatedID = ?',
      whereArgs: [generatedID],
    );
    return affectedRows;
  }

  Future<void> insertOrReplace(List<AuthEntity> authEntities) async {
    final db = await instance.database;
    final batch = db.batch();
    for (AuthEntity authEntity in authEntities) {
      final insertRow = authEntity.toMap();
      insertRow.remove('isDeleted');
      insertRow.putIfAbsent('shouldSync', () => 0);
      batch.insert(
        entityTable,
        insertRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateLocalEntity(LocalAuthEntity localAuthEntity) async {
    final db = await instance.database;
    await db.update(
      entityTable,
      localAuthEntity.toMap(),
      where: '_generatedID = ?',
      whereArgs: [localAuthEntity.generatedID],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalAuthEntity?> getEntryByID(int genID) async {
    final db = await instance.database;
    final rows = await db.query(
      entityTable,
      where: '_generatedID = ?',
      whereArgs: [genID],
    );
    final listOfAuthEntities = _convertRows(rows);
    if (listOfAuthEntities.isEmpty) {
      return null;
    } else {
      return listOfAuthEntities.first;
    }
  }

  Future<List<LocalAuthEntity>> getAll() async {
    final db = await instance.database;
    final rows = await db.rawQuery("SELECT * from $entityTable");
    return _convertRows(rows);
  }

  // deleteByID will prefer generated id if both ids are passed during deletion
  Future<void> deleteByIDs({List<int>? generatedIDs, List<String>? ids}) async {
    final db = await instance.database;
    final batch = db.batch();
    const whereGenID = '_generatedID = ?';
    const whereID = 'id = ?';
    if (generatedIDs != null) {
      for (int genId in generatedIDs) {
        batch.delete(entityTable, where: whereGenID, whereArgs: [genId]);
      }
    }
    if (ids != null) {
      for (String id in ids) {
        batch.delete(entityTable, where: whereID, whereArgs: [id]);
      }
    }
    final _ = await batch.commit();
    debugPrint("Done");
  }

  Future<void> clearTable() async {
    final db = await instance.database;
    await db.delete(entityTable);
  }

  List<LocalAuthEntity> _convertRows(List<Map<String, dynamic>> rows) {
    final keys = <LocalAuthEntity>[];
    for (final row in rows) {
      keys.add(LocalAuthEntity.fromMap(row));
    }
    return keys;
  }
}
