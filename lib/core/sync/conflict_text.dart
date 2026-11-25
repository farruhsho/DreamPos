// Text of sync conflicts (`sync_conflicts`, D-025 spec §6, §11).
//
// `sync_conflicts.details` holds a language-neutral payload written by the
// engine: JSON `{"m": "<message id>", "a": {...raw args...}}` — amounts in
// minor units, quantities with their unit code, document numbers as
// (number, register code), names / codes as data. [ConflictText] formats it
// with the CURRENT AppLocalizations, so a conflict recorded under ru reads in
// uz / ky / en after the language is switched. Rows written before this
// format (finished text in the language of the moment) and the technical
// `normalize` rows are plain text and are shown as they are.
import 'dart:convert';

import '../../l10n/l10n.dart';
import '../db/database.dart';
import '../doc_number.dart';
import '../money.dart';
import 'sync_service.dart' show SyncConflictKind;

/// Language-neutral description of one conflict ([message] = a
/// [SyncConflictKind] value, [args] = raw data).
class SyncConflictPayload {
  const SyncConflictPayload(this.message, this.args);

  final String message;
  final Map<String, Object?> args;

  // ---------------------------------------------------------- constructors

  factory SyncConflictPayload.identity({required String? oldCode, required String newCode}) =>
      SyncConflictPayload(SyncConflictKind.identity, {'old': oldCode, 'new': newCode});

  factory SyncConflictPayload.uniqueBarcode({required String code, required String winner, required String loser}) =>
      SyncConflictPayload(SyncConflictKind.uniqueBarcode, {'code': code, 'winner': winner, 'loser': loser});

  factory SyncConflictPayload.uniqueCard({required String code, required String winner, required String loser}) =>
      SyncConflictPayload(SyncConflictKind.uniqueCard, {'code': code, 'winner': winner, 'loser': loser});

  factory SyncConflictPayload.uniqueGiftCode({required String code, required String newCode}) =>
      SyncConflictPayload(SyncConflictKind.uniqueGiftCode, {'code': code, 'newCode': newCode});

  /// Document `docNo(number, code)` collided; the newer one got [newCode].
  factory SyncConflictPayload.uniqueNumber({required int number, required String? code, required String newCode}) =>
      SyncConflictPayload(SyncConflictKind.uniqueNumber, {'number': number, 'code': code, 'newCode': newCode});

  factory SyncConflictPayload.voidReturn({required int number, required String? code, required int refunded}) =>
      SyncConflictPayload(SyncConflictKind.voidReturn, {'number': number, 'code': code, 'refunded': refunded});

  factory SyncConflictPayload.overReturn(
          {required int number, required String? code, required int refunded, required int total}) =>
      SyncConflictPayload(
          SyncConflictKind.overReturn, {'number': number, 'code': code, 'refunded': refunded, 'total': total});

  factory SyncConflictPayload.negativeStock({required String name, required double qty, required String? unit}) =>
      SyncConflictPayload(SyncConflictKind.negativeStock, {'name': name, 'qty': qty, 'unit': unit});

  factory SyncConflictPayload.negativeGiftBalance({required String code, required int balance}) =>
      SyncConflictPayload(SyncConflictKind.negativeGiftBalance, {'code': code, 'balance': balance});

  factory SyncConflictPayload.negativeBonus({required String name, required int balance}) =>
      SyncConflictPayload(SyncConflictKind.negativeBonus, {'name': name, 'balance': balance});

  /// Gift card sale `docNo(number, code)` voided twice; the lost void was in
  /// shift `docNo(shiftNumber, shiftCode)` (null: shift unknown).
  factory SyncConflictPayload.doubleVoid({
    required String giftCode,
    required int number,
    required String? code,
    required int amount,
    required int? shiftNumber,
    required String? shiftCode,
  }) =>
      SyncConflictPayload(SyncConflictKind.doubleVoid, {
        'giftCode': giftCode,
        'number': number,
        'code': code,
        'amount': amount,
        'shiftNumber': shiftNumber,
        'shiftCode': shiftCode,
      });

  factory SyncConflictPayload.voidRedeem({required String code, required int amount}) =>
      SyncConflictPayload(SyncConflictKind.voidRedeem, {'code': code, 'amount': amount});

  /// Users of this database deactivated when it joined a store.
  factory SyncConflictPayload.joinUsers({required List<String> names}) =>
      SyncConflictPayload(SyncConflictKind.joinUsers, {'names': names});

  // --------------------------------------------------------------- codec

  /// The value stored in `sync_conflicts.details`.
  String encode() => jsonEncode({'m': message, 'a': args});

  /// Parses a stored payload; null for plain text (legacy rows, `normalize`)
  /// or anything that is not a payload.
  static SyncConflictPayload? decode(String? details) {
    final s = details?.trim() ?? '';
    if (!s.startsWith('{')) return null;
    try {
      final j = jsonDecode(s);
      if (j is! Map) return null;
      final m = j['m'];
      final a = j['a'];
      if (m is! String || (a != null && a is! Map)) return null;
      return SyncConflictPayload(m, a == null ? const {} : Map<String, Object?>.from(a as Map));
    } on FormatException {
      return null;
    }
  }
}

/// Renders conflicts in a given language.
abstract final class ConflictText {
  /// Short name of a conflict kind (list title).
  static String kindLabel(AppLocalizations l, String kind) => switch (kind) {
        SyncConflictKind.uniqueBarcode => l.syncConflictKindBarcode,
        SyncConflictKind.uniqueCard => l.syncConflictKindCard,
        SyncConflictKind.uniqueGiftCode => l.syncConflictKindGiftCode,
        SyncConflictKind.negativeStock => l.syncConflictKindStock,
        SyncConflictKind.negativeGiftBalance => l.syncConflictKindGiftBalance,
        SyncConflictKind.negativeBonus => l.syncConflictKindBonus,
        SyncConflictKind.uniqueNumber => l.syncConflictKindNumber,
        SyncConflictKind.voidReturn => l.syncConflictKindVoidReturn,
        SyncConflictKind.overReturn => l.syncConflictKindOverReturn,
        SyncConflictKind.identity => l.syncConflictKindIdentity,
        SyncConflictKind.doubleVoid => l.syncConflictKindDoubleVoid,
        SyncConflictKind.voidRedeem => l.syncConflictKindVoidRedeem,
        SyncConflictKind.joinUsers => l.syncConflictKindJoinUsers,
        'normalize' => l.syncConflictKindNormalize,
        _ => l.syncConflictKindOther,
      };

  /// Title of the conflict («Конфликт синхронизации: штрихкод …»); the kind
  /// label for plain-text rows.
  static String title(AppLocalizations l, SyncConflict c) => titleOf(l, c.kind, c.details);

  /// Body of the conflict; the stored text for plain-text rows, null when
  /// there is nothing to show.
  static String? body(AppLocalizations l, SyncConflict c) => bodyOf(l, c.details);

  /// [title] from the raw columns.
  static String titleOf(AppLocalizations l, String kind, String? details) {
    final p = SyncConflictPayload.decode(details);
    final subject = p == null ? null : _guard(() => _subject(l, p));
    return subject == null ? kindLabel(l, kind) : l.syncConflictTitle(subject);
  }

  /// [body] from the raw column.
  static String? bodyOf(AppLocalizations l, String? details) {
    if (details == null || details.trim().isEmpty) return null;
    final p = SyncConflictPayload.decode(details);
    if (p == null) return details;
    return _guard(() => _body(l, p));
  }

  /// A payload with missing / mistyped args (or one written by a newer
  /// version) never breaks the screen: it just has no text.
  static String? _guard(String? Function() f) {
    try {
      return f();
    } on TypeError {
      return null;
    }
  }

  static String? _subject(AppLocalizations l, SyncConflictPayload p) {
    final a = p.args;
    return switch (p.message) {
      SyncConflictKind.identity => l.syncConflictSubjectDevice,
      SyncConflictKind.uniqueBarcode => l.syncConflictSubjectBarcode(_s(a['code'])),
      SyncConflictKind.uniqueCard => l.syncConflictSubjectCard(_s(a['code'])),
      SyncConflictKind.uniqueGiftCode ||
      SyncConflictKind.negativeGiftBalance ||
      SyncConflictKind.voidRedeem =>
        l.syncConflictSubjectGiftCard(_s(a['code'])),
      SyncConflictKind.doubleVoid => l.syncConflictSubjectGiftCard(_s(a['giftCode'])),
      SyncConflictKind.uniqueNumber => l.syncConflictSubjectDocNumber(_no(a)),
      SyncConflictKind.voidReturn || SyncConflictKind.overReturn => l.syncConflictSubjectSale(_no(a)),
      SyncConflictKind.negativeStock => l.syncConflictSubjectStock(_s(a['name'])),
      SyncConflictKind.negativeBonus => l.syncConflictSubjectBonus(_s(a['name'])),
      SyncConflictKind.joinUsers => l.syncConflictSubjectJoinUsers,
      _ => null,
    };
  }

  static String? _body(AppLocalizations l, SyncConflictPayload p) {
    final a = p.args;
    return switch (p.message) {
      SyncConflictKind.identity => l.syncConflictIdentityBody(_s(a['old'], '—'), _s(a['new'])),
      SyncConflictKind.uniqueBarcode =>
        l.syncConflictBarcodeBody(_s(a['code']), _s(a['winner']), _s(a['loser'])),
      SyncConflictKind.uniqueCard => l.syncConflictCardBody(_s(a['code']), _s(a['winner']), _s(a['loser'])),
      SyncConflictKind.uniqueGiftCode => l.syncConflictGiftCodeBody(_s(a['code']), _s(a['newCode'])),
      SyncConflictKind.uniqueNumber =>
        l.syncConflictNumberBody(_no(a), docNo(_int(a['number']), a['newCode'] as String?)),
      SyncConflictKind.voidReturn => l.syncConflictVoidReturnBody(_no(a), _money(a['refunded'])),
      SyncConflictKind.overReturn =>
        l.syncConflictOverReturnBody(_no(a), _money(a['refunded']), _money(a['total'])),
      SyncConflictKind.negativeStock => l.syncConflictStockBody(
          _s(a['name']), Qty.format((a['qty']! as num).toDouble(), a['unit'] as String?, l)),
      SyncConflictKind.negativeGiftBalance => l.syncConflictGiftBalanceBody(_s(a['code']), _money(a['balance'])),
      SyncConflictKind.negativeBonus => l.syncConflictBonusBody(_s(a['name']), _money(a['balance'])),
      SyncConflictKind.doubleVoid => l.syncConflictDoubleVoidBody(
          _s(a['giftCode']),
          _no(a),
          _money(a['amount']),
          a['shiftNumber'] == null ? '—' : docNo(_int(a['shiftNumber']), a['shiftCode'] as String?),
        ),
      SyncConflictKind.voidRedeem => l.syncConflictVoidRedeemBody(_s(a['code']), _money(a['amount'])),
      SyncConflictKind.joinUsers =>
        l.syncConflictJoinUsersBody([for (final n in a['names']! as List) '$n'].join(', ')),
      _ => null,
    };
  }

  static String _s(Object? v, [String empty = '']) => v == null ? empty : '$v';
  static int _int(Object? v) => (v! as num).toInt();
  static String _money(Object? v) => Money.format(_int(v));
  static String _no(Map<String, Object?> a) => docNo(_int(a['number']), a['code'] as String?);
}
