import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../events/vault_items_updated_event.dart';
import '../vault_data.dart';
import '../services/seed_phrase_storage.dart';

/// Encrypted local storage for vault items (passwords, seeds, API keys, codes).
///
/// Architecture (local-first, no server):
///   - Each item encrypted with a unique per-item vaultKey (AES-256-GCM)
///   - vaultKey encrypted with masterKey, stored alongside the item
///   - masterKey stored in flutter_secure_storage, wrapped by KEK from PIN
///   - Database is just ciphertext + metadata — nothing useful without the keys
///
/// Database: ghostkey.vault.db
/// Table: vault_items
///   - id: TEXT PRIMARY KEY (UUID v4)
///   - category: TEXT NOT NULL (password, seeds, apiKeys, codes)
///   - title TEXT NOT NULL
///   - subtitle TEXT
///   - icon_name INTEGER (code point)
///   - icon_color INTEGER (ARGB)
///   - icon_bg_color INTEGER (ARGB)
///   - encrypted_data TEXT NOT NULL (AES-256-GCM ciphertext, base64)
///   - encrypted_key TEXT NOT NULL (vaultKey encrypted with masterKey, base64)
///   - iv TEXT NOT NULL (12-byte nonce, base64)
///   - created_at INTEGER NOT NULL (epoch ms)
///   - updated_at INTEGER NOT NULL (epoch ms)
class VaultStore {
  static const _databaseName = 'ghostkey.vault.db';
  static const _databaseVersion = 1;
  static const _table = 'vault_items';

  static final VaultStore instance = VaultStore._();
  VaultStore._();

  final _eventBus = EventBus();

  static Future<Database>? _dbFuture;
  static const _uuid = Uuid();

  // In-memory master key (unlocked after PIN entry)
  Uint8List? _masterKey;

  /// Set the master key in memory (called after PIN unlock).
  /// Key is held in memory only while vault is unlocked.
  void setMasterKey(Uint8List? key) {
    // Zero old key if present
    if (_masterKey != null) {
      _masterKey!.fillRange(0, _masterKey!.length, 0);
    }
    _masterKey = key;
  }

  /// Check if vault is unlocked (master key is in memory).
  bool get isUnlocked => _masterKey != null;

  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // Desktop: use sqflite_common_ffi
      // (same pattern as OfflineAuthenticatorDB)
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY NOT NULL,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT,
            icon_name INTEGER,
            icon_color INTEGER,
            icon_bg_color INTEGER,
            encrypted_data TEXT NOT NULL,
            encrypted_key TEXT NOT NULL,
            iv TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        // Index on category for fast filtering
        await db.execute(
            'CREATE INDEX idx_vault_category ON $_table (category)');
        // Index on title for search
        await db.execute(
            'CREATE INDEX idx_vault_title ON $_table (title)');
      },
    );
  }

  // ─── Encryption helpers ────────────────────────────────────────

  /// Generate a random 256-bit key for per-item encryption.
  Uint8List _generateVaultKey() {
    final rng = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) key[i] = rng.nextInt(256);
    return key;
  }

  /// Generate a 12-byte nonce for AES-GCM.
  Uint8List _generateIv() {
    final rng = Random.secure();
    final iv = Uint8List(12);
    for (int i = 0; i < 12; i++) iv[i] = rng.nextInt(256);
    return iv;
  }

  /// Encrypt [plaintext] with AES-256-GCM using [key] and [iv].
  Uint8List _encrypt(Uint8List plaintext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(plaintext);
  }

  /// Decrypt [ciphertext] with AES-256-GCM using [key] and [iv].
  Uint8List _decrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(ciphertext);
  }

  /// Wrap (encrypt) the per-item vaultKey with the masterKey.
  Uint8List _wrapKey(Uint8List vaultKey, Uint8List masterKey, Uint8List iv) {
    return _encrypt(vaultKey, masterKey, iv);
  }

  /// Unwrap (decrypt) the per-item vaultKey using the masterKey.
  Uint8List _unwrapKey(Uint8List wrappedKey, Uint8List masterKey, Uint8List iv) {
    return _decrypt(wrappedKey, masterKey, iv);
  }

  // ─── CRUD ──────────────────────────────────────────────────────

  /// Add a new vault item. Encrypts data before storing.
  /// Returns the item's UUID.
  Future<String> addItem(VaultItem item) async {
    final mk = _masterKey;
    if (mk == null) throw StateError('Vault is locked. Unlock first.');

    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Serialize item fields to JSON
    final payload = jsonEncode(item.fields);
    final plaintext = utf8.encode(payload);

    // Per-item encryption: random vaultKey + random IV
    final vaultKey = _generateVaultKey();
    final dataIv = _generateIv();
    final ciphertext = _encrypt(plaintext, vaultKey, dataIv);

    // Wrap vaultKey with masterKey
    final keyIv = _generateIv();
    final wrappedKey = _wrapKey(vaultKey, mk, keyIv);

    final id = item.id.isEmpty ? _uuid.v4() : item.id;

    await db.insert(_table, {
      'id': id,
      'category': item.category.name,
      'title': item.title,
      'subtitle': item.subtitle,
      'icon_name': item.icon.codePoint,
      'icon_color': item.iconColor.value,
      'icon_bg_color': item.iconBgColor.value,
      'encrypted_data': base64Encode(ciphertext),
      'encrypted_key': base64Encode(wrappedKey),
      'iv': base64Encode(dataIv),
      'created_at': now,
      'updated_at': now,
    });

    _eventBus.fire(VaultItemsUpdatedEvent());
    return id;
  }

  /// Update an existing vault item.
  Future<void> updateItem(VaultItem item) async {
    final mk = _masterKey;
    if (mk == null) throw StateError('Vault is locked. Unlock first.');

    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final payload = jsonEncode(item.fields);
    final plaintext = utf8.encode(payload);

    final vaultKey = _generateVaultKey();
    final dataIv = _generateIv();
    final ciphertext = _encrypt(plaintext, vaultKey, dataIv);

    final keyIv = _generateIv();
    final wrappedKey = _wrapKey(vaultKey, mk, keyIv);

    await db.update(
      _table,
      {
        'title': item.title,
        'subtitle': item.subtitle,
        'icon_name': item.icon.codePoint,
        'icon_color': item.iconColor.value,
        'icon_bg_color': item.iconBgColor.value,
        'encrypted_data': base64Encode(ciphertext),
        'encrypted_key': base64Encode(wrappedKey),
        'iv': base64Encode(dataIv),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );

    _eventBus.fire(VaultItemsUpdatedEvent());
  }

  /// Delete a vault item by ID.
  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _eventBus.fire(VaultItemsUpdatedEvent());
  }

  /// Listen for vault item changes.
  Stream<VaultItemsUpdatedEvent> onVaultItemsUpdated() =>
      _eventBus.on<VaultItemsUpdatedEvent>();

  /// Get all vault items, decrypted. Optionally filter by category.
  /// Returns empty list if vault is locked.
  Future<List<VaultItem>> getAllItems({VaultCategory? category}) async {
    final mk = _masterKey;
    if (mk == null) return []; // vault locked

    final db = await database;
    final List<Map<String, dynamic>> rows;

    if (category != null) {
      rows = await db.query(
        _table,
        where: 'category = ?',
        whereArgs: [category.name],
        orderBy: 'created_at DESC',
      );
    } else {
      rows = await db.query(_table, orderBy: 'created_at DESC');
    }

    final items = <VaultItem>[];
    for (final row in rows) {
      try {
        // Unwrap the vaultKey
        final wrappedKey = base64Decode(row['encrypted_key'] as String);
        final dataIv = base64Decode(row['iv'] as String);
        final vaultKey = _unwrapKey(wrappedKey, mk, dataIv);

        // Decrypt the data
        final ciphertext = base64Decode(row['encrypted_data'] as String);
        final plaintext = _decrypt(ciphertext, vaultKey, dataIv);
        final json = jsonDecode(utf8.decode(plaintext)) as Map<String, String>;

        items.add(VaultItem(
          id: row['id'] as String,
          title: row['title'] as String,
          subtitle: (row['subtitle'] as String?) ?? '',
          category: VaultCategory.values.byName(row['category'] as String),
          icon: IconData(
            row['icon_name'] as int? ?? 0xe0e1,
            fontFamily: 'MaterialIcons',
          ),
          iconColor: Color(row['icon_color'] as int? ?? 0xFF0D631B),
          iconBgColor: Color(row['icon_bg_color'] as int? ?? 0xFFC8E6C9),
          date: _formatDate(row['created_at'] as int),
          fields: json,
        ));
      } catch (e) {
        debugPrint('Failed to decrypt vault item ${row['id']}: $e');
        // Skip corrupted items rather than crashing
      }
    }
    return items;
  }

  /// Search vault items by title (case-insensitive).
  Future<List<VaultItem>> search(String query) async {
    final mk = _masterKey;
    if (mk == null) return [];

    // Note: title is stored unencrypted for searchability.
    // This is a trade-off: titles are visible without decryption,
    // but content (fields) remains encrypted.
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'title LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'created_at DESC',
    );

    final items = <VaultItem>[];
    for (final row in rows) {
      try {
        final wrappedKey = base64Decode(row['encrypted_key'] as String);
        final dataIv = base64Decode(row['iv'] as String);
        final vaultKey = _unwrapKey(wrappedKey, mk, dataIv);
        final ciphertext = base64Decode(row['encrypted_data'] as String);
        final plaintext = _decrypt(ciphertext, vaultKey, dataIv);
        final json = jsonDecode(utf8.decode(plaintext)) as Map<String, String>;

        items.add(VaultItem(
          id: row['id'] as String,
          title: row['title'] as String,
          subtitle: (row['subtitle'] as String?) ?? '',
          category: VaultCategory.values.byName(row['category'] as String),
          icon: IconData(
            row['icon_name'] as int? ?? 0xe0e1,
            fontFamily: 'MaterialIcons',
          ),
          iconColor: Color(row['icon_color'] as int? ?? 0xFF0D631B),
          iconBgColor: Color(row['icon_bg_color'] as int? ?? 0xFFC8E6C9),
          date: _formatDate(row['created_at'] as int),
          fields: json,
        ));
      } catch (e) {
        debugPrint('Failed to decrypt search result ${row['id']}: $e');
      }
    }
    return items;
  }

  /// Get count per category (for filter chip badges).
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT category, COUNT(*) as cnt FROM $_table GROUP BY category',
    );
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row['category'] as String] = row['cnt'] as int;
    }
    return counts;
  }

  /// Count items matching a specific category.
  Future<int> countByCategory(VaultCategory category) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE category = ?',
      [category.name],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Total item count.
  Future<int> get totalCount async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Delete all vault items (for wipe/reset).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }

  // ─── Helpers ───────────────────────────────────────────────────

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
