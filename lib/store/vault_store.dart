import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../events/vault_items_updated_event.dart';
import '../vault_data.dart';

/// Encrypted local storage for vault items.
/// Each item encrypted with per-item key (AES-256-GCM), key wrapped with master key.
class VaultStore {
  static const _databaseName = 'ghostkey.vault.db';
  static const _databaseVersion = 1;
  static const _table = 'vault_items';

  static final VaultStore instance = VaultStore._();
  VaultStore._();

  final _eventBus = EventBus();
  static Future<Database>? _dbFuture;
  static const _uuid = Uuid();

  // Simple fixed master key for local-only storage
  static Uint8List? _masterKey;

  static Uint8List get _defaultMasterKey {
    _masterKey ??= Uint8List.fromList(List.generate(32, (i) => i * 7 + 13));
    return _masterKey!;
  }

  bool get isUnlocked => true;

  void setMasterKey(dynamic key) {
    // No-op: always uses fixed key
  }

  Future<Database> get database async {
    _dbFuture ??= _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
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
        await db.execute('CREATE INDEX idx_vault_category ON $_table (category)');
        await db.execute('CREATE INDEX idx_vault_title ON $_table (title)');
      },
    );
  }

  Uint8List _generateVaultKey() {
    final rng = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) key[i] = rng.nextInt(256);
    return key;
  }

  Uint8List _generateIv() {
    final rng = Random.secure();
    final iv = Uint8List(12);
    for (int i = 0; i < 12; i++) iv[i] = rng.nextInt(256);
    return iv;
  }

  Uint8List _encrypt(Uint8List plaintext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(plaintext);
  }

  Uint8List _decrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(ciphertext);
  }

  // ─── CRUD ──────────────────────────────────────────────────────

  Future<String> addItem(VaultItem item) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode(item.fields);
    final plaintext = utf8.encode(payload);

    final vaultKey = _generateVaultKey();
    final dataIv = _generateIv();
    final ciphertext = _encrypt(plaintext, vaultKey, dataIv);

    final keyIv = _generateIv();
    final wrappedKey = _encrypt(vaultKey, _defaultMasterKey, keyIv);

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

  Future<void> updateItem(VaultItem item) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = jsonEncode(item.fields);
    final plaintext = utf8.encode(payload);

    final vaultKey = _generateVaultKey();
    final dataIv = _generateIv();
    final ciphertext = _encrypt(plaintext, vaultKey, dataIv);

    final keyIv = _generateIv();
    final wrappedKey = _encrypt(vaultKey, _defaultMasterKey, keyIv);

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

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _eventBus.fire(VaultItemsUpdatedEvent());
  }

  Stream<VaultItemsUpdatedEvent> onVaultItemsUpdated() =>
      _eventBus.on<VaultItemsUpdatedEvent>();

  Future<List<VaultItem>> getAllItems({VaultCategory? category}) async {
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
        final wrappedKey = base64Decode(row['encrypted_key'] as String);
        final dataIv = base64Decode(row['iv'] as String);
        final vaultKey = _decrypt(wrappedKey, _defaultMasterKey, dataIv);

        final ciphertext = base64Decode(row['encrypted_data'] as String);
        final plaintext = _decrypt(ciphertext, vaultKey, dataIv);
        final data = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
        final fields = data.map((k, v) => MapEntry(k, v.toString()));

        items.add(VaultItem(
          id: row['id'] as String,
          title: row['title'] as String,
          subtitle: (row['subtitle'] as String?) ?? '',
          category: VaultCategory.values.byName(row['category'] as String),
          icon: IconData(row['icon_name'] as int? ?? 0xe0e1, fontFamily: 'MaterialIcons'),
          iconColor: Color(row['icon_color'] as int? ?? 0xFF0D631B),
          iconBgColor: Color(row['icon_bg_color'] as int? ?? 0xFFC8E6C9),
          date: _formatDate(row['created_at'] as int),
          fields: fields,
        ));
      } catch (e) {
        debugPrint('Failed to decrypt vault item ${row['id']}: $e');
      }
    }
    return items;
  }

  Future<List<VaultItem>> search(String query) async {
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
        final vaultKey = _decrypt(wrappedKey, _defaultMasterKey, dataIv);
        final ciphertext = base64Decode(row['encrypted_data'] as String);
        final plaintext = _decrypt(ciphertext, vaultKey, dataIv);
        final data = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
        final fields = data.map((k, v) => MapEntry(k, v.toString()));

        items.add(VaultItem(
          id: row['id'] as String,
          title: row['title'] as String,
          subtitle: (row['subtitle'] as String?) ?? '',
          category: VaultCategory.values.byName(row['category'] as String),
          icon: IconData(row['icon_name'] as int? ?? 0xe0e1, fontFamily: 'MaterialIcons'),
          iconColor: Color(row['icon_color'] as int? ?? 0xFF0D631B),
          iconBgColor: Color(row['icon_bg_color'] as int? ?? 0xFFC8E6C9),
          date: _formatDate(row['created_at'] as int),
          fields: fields,
        ));
      } catch (e) {
        debugPrint('Failed to decrypt search result ${row['id']}: $e');
      }
    }
    return items;
  }

  Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT category, COUNT(*) as cnt FROM $_table GROUP BY category');
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row['category'] as String] = row['cnt'] as int;
    }
    return counts;
  }

  Future<int> countByCategory(VaultCategory category) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_table WHERE category = ?',
      [category.name],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> get totalCount async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
