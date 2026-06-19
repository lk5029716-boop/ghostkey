import 'dart:async';
import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../events/vault_items_updated_event.dart';
import '../vault_data.dart';

/// Local storage for vault items (passwords, seeds, API keys, codes).
/// Simple unencrypted SQLite storage for now — encryption layer can be added later.
///
/// Database: ghostkey.vault.db
/// Table: vault_items
class VaultStore {
  static const _databaseName = 'ghostkey.vault.db';
  static const _databaseVersion = 1;
  static const _table = 'vault_items';

  static final VaultStore instance = VaultStore._();
  VaultStore._();

  final _eventBus = EventBus();

  static Future<Database>? _dbFuture;
  static const _uuid = Uuid();

  // No master key needed for unencrypted storage
  bool get isUnlocked => true;

  void setMasterKey(dynamic key) {
    // No-op for unencrypted storage
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
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_vault_category ON $_table (category)');
        await db.execute('CREATE INDEX idx_vault_title ON $_table (title)');
      },
    );
  }

  // ─── CRUD ──────────────────────────────────────────────────────

  /// Add a new vault item.
  Future<String> addItem(VaultItem item) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = item.id.isEmpty ? _uuid.v4() : item.id;

    await db.insert(_table, {
      'id': id,
      'category': item.category.name,
      'title': item.title,
      'subtitle': item.subtitle,
      'icon_name': item.icon.codePoint,
      'icon_color': item.iconColor.value,
      'icon_bg_color': item.iconBgColor.value,
      'data': jsonEncode(item.fields),
      'created_at': now,
      'updated_at': now,
    });

    _eventBus.fire(VaultItemsUpdatedEvent());
    return id;
  }

  /// Update an existing vault item.
  Future<void> updateItem(VaultItem item) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      _table,
      {
        'title': item.title,
        'subtitle': item.subtitle,
        'icon_name': item.icon.codePoint,
        'icon_color': item.iconColor.value,
        'icon_bg_color': item.iconBgColor.value,
        'data': jsonEncode(item.fields),
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

  /// Get all vault items. Optionally filter by category.
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
        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        final fields = data.map((k, v) => MapEntry(k, v.toString()));

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
          fields: fields,
        ));
      } catch (e) {
        debugPrint('Failed to parse vault item ${row['id']}: $e');
      }
    }
    return items;
  }

  /// Search vault items by title (case-insensitive).
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
        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        final fields = data.map((k, v) => MapEntry(k, v.toString()));

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
          fields: fields,
        ));
      } catch (e) {
        debugPrint('Failed to parse search result ${row['id']}: $e');
      }
    }
    return items;
  }

  /// Get count per category.
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
