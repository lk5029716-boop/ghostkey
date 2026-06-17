import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Pure-SQL test of the unique-id + insert logic. Reproduces exactly
/// what CodeStore.addCode does, against a real SQLite database, to
/// prove that two adds never collide on UNIQUE(id).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Two inserts with UUIDv4 ids both persist (no replace)', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE entities (
              _generatedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              id TEXT,
              encryptedData TEXT NOT NULL,
              header TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL,
              shouldSync INTEGER DEFAULT 0,
              manual_order INTEGER DEFAULT 0,
              UNIQUE(id)
            )
          ''');
        },
      ),
    );

    const uuid = Uuid();
    // Mimic CodeStore.addCode exactly.
    Future<void> add(String issuer, String account, String secret) async {
      final id = uuid.v4();
      await db.insert('entities', {
        '_generatedID': 0,
        'id': id,
        'encryptedData': '{"issuer":"$issuer","account":"$account","secret":"$secret"}',
        'header': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'shouldSync': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await add('GitHub', 'alice', 'JBSWY3DPEHPK3PXP');
    await add('Google', 'bob', 'KRSXG5BAONSWG4TFOQ');

    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM entities')) ??
        0;
    expect(count, 2,
        reason: 'Two different codes must produce 2 rows. Got $count');
    print('PASS: 2 rows after 2 different adds (UUIDv4 uniqueId)');
  });

  test('Adding the same code twice creates two rows', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE entities (
              _generatedID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              id TEXT,
              encryptedData TEXT NOT NULL,
              header TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL,
              shouldSync INTEGER DEFAULT 0,
              manual_order INTEGER DEFAULT 0,
              UNIQUE(id)
            )
          ''');
        },
      ),
    );

    const uuid = Uuid();
    for (int i = 0; i < 2; i++) {
      await db.insert('entities', {
        '_generatedID': 0,
        'id': uuid.v4(),
        'encryptedData': '{"issuer":"X","secret":"Y"}',
        'header': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'shouldSync': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM entities')) ??
        0;
    expect(count, 2,
        reason: 'Adding same data twice should create 2 rows. Got $count');
    print('PASS: 2 rows after 2 same-data adds (UUIDv4)');
  });

  test('UUIDv4 collisions in 1000 generates', () async {
    const uuid = Uuid();
    final set = <String>{};
    for (int i = 0; i < 1000; i++) {
      set.add(uuid.v4());
    }
    expect(set.length, 1000,
        reason: 'UUIDv4 collisions in 1000 generates is essentially impossible');
    print('PASS: 1000/1000 unique UUIDv4 ids');
  });
}
