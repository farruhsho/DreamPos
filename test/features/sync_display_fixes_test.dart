// Display fixes of the sync review (D-025): the shell shift chip shows the
// register code and still fits a phone top bar; ky texts name a purchase
// order «Буйрутма» like the rest of the ky app.
import 'package:dreampos/app/shell.dart' show shiftChipLabel;
import 'package:dreampos/core/db/database.dart';
import 'package:dreampos/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Shift _shift(String? code) => Shift(
      id: 's',
      createdAt: DateTime(2026, 11, 25, 9),
      updatedAt: DateTime(2026, 11, 25, 9),
      number: 3,
      deviceCode: code,
      openedBy: 'u',
      openedAt: DateTime(2026, 11, 25, 9),
      openingCash: 0,
      status: 'open',
    );

void main() {
  Future<List<String>> labels(WidgetTester tester, String? code, List<double> widths, {Locale locale = const Locale('ru')}) async {
    late List<String> out;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        out = [for (final w in widths) shiftChipLabel(context, _shift(code), w)];
        return const SizedBox();
      }),
    ));
    return out;
  }

  testWidgets('shift chip: full text, then shorter, always with the register code', (tester) async {
    final l = await labels(tester, 'A', [1000, 140, 50]); // test font: 12 px per glyph
    expect(l[0], startsWith('Смена №A-3 · с '));
    expect(l[1], 'Смена №A-3');
    expect(l[2], '№A-3');
  });

  testWidgets('shift chip without sync is unchanged', (tester) async {
    final l = await labels(tester, null, [1000]);
    expect(l.single, startsWith('Смена №3 · с '));
  });

  test('ky: a purchase order is «Буйрутма» in the sync texts too', () {
    final ky = lookupAppLocalizations(const Locale('ky'));
    expect(ky.syncSubjectOrder('5'), 'Буйрутма №5');
    expect(ky.syncCachePoPaid, startsWith('Буйрутма'));
    expect(ky.syncCachePoReceived, startsWith('Буйрутма'));
    expect(ky.errOrderClosed('5'), startsWith('Буйрутма'));
  });
}
