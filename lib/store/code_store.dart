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
  /// trust the local DB.
  Future<List<Code>> getAllCodes() async {
    final db = await OfflineAuthenticatorDB.instance.database;
    final rows = await db.query(OfflineAuthenticatorDB.entityTable);
    final codes = <Code>[];
    for (final row in rows) {
      final entity = LocalAuthEntity.fromMap(row);
      if (entity.encryptedData.isEmpty) {
        continue;
      }
      try {
        final raw = entity.encryptedData;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        codes.add(CodeFromMap.fromMap(json));
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
