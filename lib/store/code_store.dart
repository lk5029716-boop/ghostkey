import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:event_bus/event_bus.dart' as eb;
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import '../events/codes_updated_event.dart';
import '../models/authenticator/entity_result.dart';
import '../models/authenticator/local_auth_entity.dart';
import '../models/code.dart';
import '../models/code_parse_error.dart';
import 'offline_authenticator_db.dart';

/// Local-first store for GhostKey TOTP/HOTP codes.
///
/// Replaces ente's CodeStore (which depends on AuthenticatorService and
/// server-side sync). GhostKey is local-only for the demo phase, so this
/// implementation only wraps [OfflineAuthenticatorDB] with the higher-level
/// API the UI expects: [addCode], [getAllCodes], [removeCode], and cache
/// management via [CodesUpdatedEvent].
///
/// Encryption can be layered on top later by wrapping the
/// [LocalAuthEntity.encryptedData] field in real ciphertext.
class CodeStore {
  static final CodeStore instance = CodeStore._privateConstructor();

  CodeStore._privateConstructor();

  final _logger = Logger('CodeStore');
  final Map<int, Code> _cacheCodes = {};
  final _eventBus = eb.EventBus();

  Future<void> init() async {
    await OfflineAuthenticatorDB.instance.database;
  }

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------

  List<Code> get currentCodes => _cacheCodes.values.toList();

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Persist [code] to the local SQLite store and broadcast a
  /// [CodesUpdatedEvent] so the UI can refresh.
  Future<void> addCode(Code code) async {
    final db = await OfflineAuthenticatorDB.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final local = LocalAuthEntity(
      0, // generatedID: auto-increment handled by SQLite
      code.hashCode.toString(), // id: stable string key
      jsonEncode(code.toMap()), // encryptedData: JSON payload
      '', // header: empty for now
      now, // createdAt
      now, // updatedAt
      false, // shouldSync: local-only, no server
    );
    await db.insert(
      OfflineAuthenticatorDB.entityTable,
      local.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _eventBus.fire(CodesUpdatedEvent());
  }

  /// Read all codes from the store. Decodes the JSON payload stored in
  /// [LocalAuthEntity.encryptedData] — for the demo we skip decryption and
  /// trust the local DB. Also populates each Code's `generatedID` and
  /// `manualOrder` from the row.
  Future<List<Code>> getAllCodes() async {
    final db = await OfflineAuthenticatorDB.instance.database;
    final rows = await db.query(
      OfflineAuthenticatorDB.entityTable,
      orderBy: 'manual_order ASC, createdAt ASC',
    );
    final codes = <Code>[];
    for (final row in rows) {
      final entity = LocalAuthEntity.fromMap(row);
      if (entity.encryptedData.isEmpty) continue;
      try {
        final json = jsonDecode(entity.encryptedData) as Map<String, dynamic>;
        var code = CodeFromMap.fromMap(json);
        code = code.copyWith(generatedID: entity.generatedID);
        codes.add(code);
      } on CodeParseError catch (e) {
        _logger.warning('Skipping unparseable code: ${e.message}');
      } catch (e, st) {
        _logger.severe('Failed to decode code', e, st);
      }
    }
    _cacheCodes
      ..clear()
      ..addAll({for (final c in codes) c.hashCode: c});
    return codes;
  }

  /// Remove [code] from the store.
  Future<void> removeCode(Code code) async {
    final db = await OfflineAuthenticatorDB.instance.database;
    await db.delete(
      OfflineAuthenticatorDB.entityTable,
      where: 'id = ?',
      whereArgs: [code.hashCode.toString()],
    );
    _cacheCodes.remove(code.hashCode);
    _eventBus.fire(CodesUpdatedEvent());
  }

  /// Replace every stored code with [codes] (used by import flows).
  Future<int> saveUpadedIndexes(List<Code> codes) async {
    int changedCount = 0;
    final existing = await getAllCodes();
    final existingById = {for (final c in existing) c.hashCode: c};
    final newById = {for (final c in codes) c.hashCode: c};

    // Insert or update.
    for (final code in codes) {
      final prev = existingById[code.hashCode];
      if (prev == null) {
        await addCode(code);
        changedCount++;
      } else if (!_codeEquals(prev, code)) {
        await addCode(code);
        changedCount++;
      }
    }
    // Delete removals.
    for (final prev in existing) {
      if (!newById.containsKey(prev.hashCode)) {
        await removeCode(prev);
        changedCount++;
      }
    }
    return changedCount;
  }

  /// Save the new manual order of codes (from drag-to-reorder).
  /// Updates [LocalAuthEntity.manualOrder] in the DB using a single batch.
  Future<bool> saveUpdatedIndexes(List<Code> codes) async {
    final db = await OfflineAuthenticatorDB.instance.database;
    // Load all existing rows once
    final rows = await db.query(OfflineAuthenticatorDB.entityTable);
    final idToGenId = <String, int>{};
    final idToOrder = <String, int>{};
    for (final row in rows) {
      final id = row['id'] as String?;
      final genId = row['_generatedID'] as int?;
      final order = (row['manual_order'] as int?) ?? 0;
      if (id != null && genId != null) {
        idToGenId[id] = genId;
        idToOrder[id] = order;
      }
    }
    final batch = db.batch();
    var changed = false;
    for (var i = 0; i < codes.length; i++) {
      final id = codes[i].hashCode.toString();
      final genId = idToGenId[id];
      if (genId == null) continue;
      final currentOrder = idToOrder[id] ?? 0;
      if (currentOrder != i) {
        batch.update(
          OfflineAuthenticatorDB.entityTable,
          {'manual_order': i},
          where: '_generatedID = ?',
          whereArgs: [genId],
        );
        changed = true;
      }
    }
    if (changed) {
      await batch.commit(noResult: true);
      _eventBus.fire(CodesUpdatedEvent());
    }
    return changed;
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Listen for store mutations.
  Stream<CodesUpdatedEvent> onCodesUpdated() =>
      _eventBus.on<CodesUpdatedEvent>();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _codeEquals(Code a, Code b) {
    return const DeepCollectionEquality().equals(a.toMap(), b.toMap());
  }
}

/// Stub to mirror the ente API surface without pulling in
/// `AuthenticatorService` / `AuthenticatorGateway`.
extension CodeStoreResult on CodeStore {
  Future<List<EntityResult>> getEntityResults() async {
    final db = await OfflineAuthenticatorDB.instance.database;
    final rows = await db.query(OfflineAuthenticatorDB.entityTable);
    return rows
        .map((row) => EntityResult(
              row['id'] as int? ?? 0,
              row['encryptedData']?.toString() ?? '',
              true,
            ))
        .toList();
  }
}
