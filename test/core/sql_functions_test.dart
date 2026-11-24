
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/db/sql_functions.dart';
import 'package:dreampos/core/widgets/pickers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('likeToRegExp handles wildcards and escape', () {
    expect(likeToRegExp('%мол_ко%').hasMatch('Свежее МОЛОКО 1л'), isTrue);
    expect(likeToRegExp('a\\%b', escape: '\\').hasMatch('a%b'), isTrue);
    expect(likeToRegExp('a\\%b', escape: '\\').hasMatch('axxb'), isFalse);
    expect(likeToRegExp('ab').hasMatch('xab'), isFalse);
  });

  test('Cyrillic LIKE / lower / upper are case-insensitive in SQL', () async {
    final db = memoryDb();
    addTearDown(db.close);
    await db.into(db.products).insert(
        ProductsCompanion.insert(id: newId(), name: 'Молоко 2.5% 1л', price: 1000));
    await db.into(db.products).insert(
        ProductsCompanion.insert(id: newId(), name: "O'zbek choyi", price: 1000));
    expect((await searchProducts(db, 'молоко')).single.name, 'Молоко 2.5% 1л');
    expect((await searchProducts(db, 'МОЛОКО')).length, 1);
    expect((await searchProducts(db, "o'ZBEK")).length, 1);
    final row = await db.customSelect("SELECT lower('ЁЖИК') AS l, upper('ёжик') AS u").getSingle();
    expect(row.read<String>('l'), 'ёжик');
    expect(row.read<String>('u'), 'ЁЖИК');
    final nulls = await db.customSelect("SELECT NULL LIKE 'a' AS x", readsFrom: {}).getSingle();
    expect(nulls.data['x'], isNull);
  });
}
