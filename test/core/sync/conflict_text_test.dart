// Sync conflict text (D-025 spec §6, §11): `sync_conflicts.details` holds a
// language-neutral payload; ConflictText renders it in the CURRENT language.
// Legacy rows (finished text) are shown as they are.
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/core/doc_number.dart';
import 'package:dreampos/core/money.dart';
import 'package:dreampos/core/sync/conflict_text.dart';
import 'package:dreampos/core/sync/sync_service.dart';
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sync_server.dart';
import 'sync_harness.dart';

SyncConflict _row(String kind, String? details) =>
    SyncConflict(id: 1, kind: kind, details: details, at: DateTime(2026, 1, 1), resolved: false);

/// One payload of every kind the engine writes.
final _all = <SyncConflictPayload>[
  SyncConflictPayload.identity(oldCode: 'A', newCode: 'C'),
  SyncConflictPayload.identity(oldCode: null, newCode: 'C'),
  SyncConflictPayload.uniqueBarcode(code: '4600000000017', winner: 'Товар B', loser: 'Товар A'),
  SyncConflictPayload.uniqueCard(code: 'C-100', winner: 'Анна', loser: 'Борис'),
  SyncConflictPayload.uniqueGiftCode(code: 'GIFT1', newCode: 'GIFT1~abcdef12'),
  SyncConflictPayload.uniqueNumber(number: 15, code: 'A', newCode: 'A~1F2E'),
  SyncConflictPayload.uniqueNumber(number: 15, code: null, newCode: '~1F2E'),
  SyncConflictPayload.voidReturn(number: 7, code: 'B', refunded: 150000),
  SyncConflictPayload.overReturn(number: 7, code: 'B', refunded: 250000, total: 200000),
  SyncConflictPayload.negativeStock(name: 'Сыр', qty: -1.25, unit: 'kg'),
  SyncConflictPayload.negativeStock(name: 'Чай', qty: -2, unit: 'pcs'),
  SyncConflictPayload.negativeGiftBalance(code: 'GIFT0001', balance: -5000),
  SyncConflictPayload.negativeBonus(name: 'Иван', balance: -1500),
  SyncConflictPayload.doubleVoid(
      giftCode: 'GIFT2', number: 3, code: 'A', amount: 50000, shiftNumber: 4, shiftCode: 'B'),
  SyncConflictPayload.doubleVoid(
      giftCode: 'GIFT2', number: 3, code: null, amount: 50000, shiftNumber: null, shiftCode: null),
  SyncConflictPayload.voidRedeem(code: 'GIFT3', amount: 20000),
  SyncConflictPayload.joinUsers(names: ['Local owner', 'Кассир']),
];

void main() {
  tearDown(L.reset);

  test('every conflict kind renders in all 4 languages', () {
    final kinds = {for (final p in _all) p.message};
    expect(kinds, hasLength(13), reason: 'one payload per engine kind');
    for (final p in _all) {
      final row = _row(p.message, p.encode());
      for (final lc in supportedLanguageCodes) {
        final l = L.of(lc);
        final title = ConflictText.title(l, row);
        final body = ConflictText.body(l, row);
        expect(title, startsWith(l.syncConflictTitle('')), reason: '${p.message}/$lc: $title');
        expect(title.length, greaterThan(l.syncConflictTitle('').length), reason: '${p.message}/$lc');
        expect(body, isNotNull, reason: '${p.message}/$lc');
        expect(body, isNot(contains('{')), reason: '${p.message}/$lc: $body');
        expect(body, isNot(contains('null')), reason: '${p.message}/$lc: $body');
        expect(ConflictText.kindLabel(l, p.message), isNot(l.syncConflictKindOther), reason: p.message);
      }
    }
  });

  test('raw args are formatted with the given language (money, qty + unit, doc numbers)', () {
    for (final lc in supportedLanguageCodes) {
      final l = L.of(lc);
      String body(SyncConflictPayload p) => ConflictText.body(l, _row(p.message, p.encode()))!;
      expect(body(SyncConflictPayload.negativeStock(name: 'Сыр', qty: -1.25, unit: 'kg')),
          l.syncConflictStockBody('Сыр', Qty.format(-1.25, 'kg', l)));
      expect(body(SyncConflictPayload.overReturn(number: 7, code: 'B', refunded: 250000, total: 200000)),
          l.syncConflictOverReturnBody('B-7', Money.format(250000), Money.format(200000)));
      expect(body(SyncConflictPayload.uniqueNumber(number: 15, code: 'A', newCode: 'A~1F2E')),
          l.syncConflictNumberBody('A-15', 'A~1F2E-15'));
      expect(
          body(SyncConflictPayload.doubleVoid(
              giftCode: 'G', number: 3, code: null, amount: 100, shiftNumber: null, shiftCode: null)),
          l.syncConflictDoubleVoidBody('G', '3', Money.format(100), '—'));
      expect(body(SyncConflictPayload.identity(oldCode: null, newCode: 'C')), l.syncConflictIdentityBody('—', 'C'));
    }
    // ru unit label differs from uz/en: the unit is data, its label is not.
    expect(Qty.format(-2, 'pcs', L.of('ru')), isNot(Qty.format(-2, 'pcs', L.of('en'))));
  });

  test('legacy plain-text rows render as they are; broken payloads never throw', () {
    const legacy = 'Остаток товара «Чай» стал отрицательным (-2) после продаж на разных кассах.';
    for (final lc in supportedLanguageCodes) {
      final l = L.of(lc);
      final row = _row(SyncConflictKind.negativeStock, legacy);
      expect(ConflictText.body(l, row), legacy);
      expect(ConflictText.title(l, row), l.syncConflictKindStock);
      // normalize rows (technical text written by the aggregates check)
      expect(ConflictText.body(l, _row('normalize', 'balance: cached=5; derived=0')), 'balance: cached=5; derived=0');
      expect(ConflictText.body(l, _row(SyncConflictKind.uniqueBarcode, null)), isNull);
      expect(ConflictText.body(l, _row(SyncConflictKind.uniqueBarcode, '')), isNull);
      // not JSON / not a payload: shown as is
      expect(ConflictText.body(l, _row('x', '{broken')), '{broken');
      expect(ConflictText.body(l, _row('x', '{"a":1}')), '{"a":1}');
      // unknown message (newer version) or missing args: kind label, no body
      final unknown = _row('future_kind', const SyncConflictPayload('future_kind', {'x': 1}).encode());
      expect(ConflictText.title(l, unknown), l.syncConflictKindOther);
      expect(ConflictText.body(l, unknown), isNull);
      final missing = _row(SyncConflictKind.voidReturn, const SyncConflictPayload(SyncConflictKind.voidReturn, {}).encode());
      expect(ConflictText.title(l, missing), l.syncConflictKindVoidReturn);
      expect(ConflictText.body(l, missing), isNull);
    }
  });

  test('a conflict recorded under ru renders in uz / ky / en after switching the language', () async {
    final server = FakeSyncServer()..addUser(testEmail, testPassword);
    final ds = await cluster(2, server: server);
    try {
      final a = ds[0], b = ds[1];
      L.setCurrent('ru');
      final pa = await a.product('Товар A', barcode: '4600000000017');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final pb = await b.product('Товар B', barcode: '4600000000017');
      await a.syncNow();
      await b.syncNow();
      await a.syncNow();
      final row = (await a.db.select(a.db.syncConflicts).get())
          .singleWhere((c) => c.kind == SyncConflictKind.uniqueBarcode && c.entityId == pa.id);
      expect(row.details, isNot(contains('Штрихкод')), reason: 'stored language-neutral: ${row.details}');
      final p = SyncConflictPayload.decode(row.details)!;
      expect(p.args, {'code': '4600000000017', 'winner': 'Товар B', 'loser': 'Товар A'});
      expect(pb.barcode, '4600000000017');
      // The notification keeps the language of the moment (ru).
      final note = (await a.db.select(a.db.notifications).get()).singleWhere((n) => n.refType == 'sync_conflict');
      expect(note.title, 'Конфликт синхронизации: штрихкод 4600000000017');
      expect(note.body, L.of('ru').syncConflictBarcodeBody('4600000000017', 'Товар B', 'Товар A'));

      final ru = ConflictText.body(L.of('ru'), row);
      for (final lc in ['uz', 'ky', 'en']) {
        L.setCurrent(lc);
        final l = L.current;
        final body = ConflictText.body(l, row);
        expect(body, l.syncConflictBarcodeBody('4600000000017', 'Товар B', 'Товар A'), reason: lc);
        expect(body, isNot(ru), reason: lc);
        expect(ConflictText.title(l, row), l.syncConflictTitle(l.syncConflictSubjectBarcode('4600000000017')));
      }
    } finally {
      for (final d in ds) {
        await d.close();
      }
    }
  });

  test('document numbers keep the register code as data', () {
    final p = SyncConflictPayload.uniqueNumber(number: 9, code: 'B', newCode: 'B~AAAA');
    final back = SyncConflictPayload.decode(p.encode())!;
    expect(back.args, {'number': 9, 'code': 'B', 'newCode': 'B~AAAA'});
    expect(docNo(9, back.args['code'] as String?), 'B-9');
  });
}
