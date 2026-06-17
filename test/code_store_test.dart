import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ghostkey/models/code.dart';
import 'package:ghostkey/store/code_store.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('Adding two different codes persists both rows', () async {
    final store = CodeStore.instance;
    await store.init();

    final codeA = Code.fromAccountAndSecret(
      Type.totp,
      'alice@example.com',
      'GitHub',
      'JBSWY3DPEHPK3PXP',
      null,
      6,
      algorithm: Algorithm.sha1,
      period: 30,
    );
    final codeB = Code.fromAccountAndSecret(
      Type.totp,
      'bob@example.com',
      'Google',
      'KRSXG5BAONSWG4TFOQ',
      null,
      6,
      algorithm: Algorithm.sha1,
      period: 30,
    );

    await store.addCode(codeA);
    await store.addCode(codeB);
    final all = await store.getAllCodes();
    expect(all.length, 2,
        reason: 'Two different codes must both persist. Got ${all.length}');
    print('PASS: 2 codes in DB after adding 2 different ones');
  });

  test('Adding the same code twice creates two rows', () async {
    final store = CodeStore.instance;
    final code = Code.fromAccountAndSecret(
      Type.totp,
      'a@b.com',
      'Svc',
      'JBSWY3DPEHPK3PXP',
      null,
      6,
      algorithm: Algorithm.sha1,
      period: 30,
    );
    final before = (await store.getAllCodes()).length;
    await store.addCode(code);
    await store.addCode(code);
    final after = (await store.getAllCodes()).length;
    expect(after, before + 2,
        reason: 'Adding same code twice should add 2 new rows');
    print('PASS: +2 rows for same code added twice');
  });

  test('addOrUpdateCode updates in place (preserves generatedID)', () async {
    final store = CodeStore.instance;
    final code = Code.fromAccountAndSecret(
      Type.totp,
      'a@b.com',
      'Svc',
      'JBSWY3DPEHPK3PXP',
      null,
      6,
      algorithm: Algorithm.sha1,
      period: 30,
    );
    await store.addCode(code);
    final all = await store.getAllCodes();
    final before = all.length;
    final first = all.first;
    final pinned = first.copyWith(
      display: first.display.copyWith(pinned: true),
    );
    await store.addOrUpdateCode(pinned);
    final after = (await store.getAllCodes()).length;
    expect(after, before,
        reason: 'addOrUpdateCode must update in place, not add a new row');
    print('PASS: addOrUpdateCode preserved row count ($before -> $after)');
  });
}
