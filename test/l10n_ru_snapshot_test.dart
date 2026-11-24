// Pins the Russian text of the UI strings that the UX tests find widgets by.
// The UX tests look widgets up through ARB keys (for SCREENSHOTS_LOCALE), so
// they no longer fail when an ru value drifts; this test does. The ru value
// must stay byte-identical to the original literal (docs/specs/localization.md).
import 'package:dreampos/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ru values used as UX-test finders are unchanged', () {
    final l = L.of('ru');
    final pinned = <String, (String, String)>{
    'commonActions': (l.commonActions, 'Действия'), // l10n-ignore
    'commonAdd': (l.commonAdd, 'Добавить'), // l10n-ignore
    'commonAll': (l.commonAll, 'Все'), // l10n-ignore
    'commonApply': (l.commonApply, 'Применить'), // l10n-ignore
    'commonCancel': (l.commonCancel, 'Отмена'), // l10n-ignore
    'commonCategory': (l.commonCategory, 'Категория'), // l10n-ignore
    'commonClose': (l.commonClose, 'Закрыть'), // l10n-ignore
    'commonCreate': (l.commonCreate, 'Создать'), // l10n-ignore
    'commonDone': (l.commonDone, 'Готово'), // l10n-ignore
    'commonEdit': (l.commonEdit, 'Изменить'), // l10n-ignore
    'commonMore': (l.commonMore, 'Ещё'), // l10n-ignore
    'commonReturn': (l.commonReturn, 'Возврат'), // l10n-ignore
    'custAcceptDebtPayment': (l.custAcceptDebtPayment, 'Принять оплату долга'), // l10n-ignore
    'custCardTitle': (l.custCardTitle, 'Карточка клиента'), // l10n-ignore
    'custEditTitle': (l.custEditTitle, 'Редактирование клиента'), // l10n-ignore
    'custNew': (l.custNew, 'Новый клиент'), // l10n-ignore
    'custNewTooltip': (l.custNewTooltip, 'Новый клиент (Ctrl+N)'), // l10n-ignore
    'custSegDebtors': (l.custSegDebtors, 'Должники'), // l10n-ignore
    'custTabFav': (l.custTabFav, 'Любимые товары'), // l10n-ignore
    'custTabFavShort': (l.custTabFavShort, 'Любимое'), // l10n-ignore
    'custTabLedger': (l.custTabLedger, 'Долги и бонусы'), // l10n-ignore
    'custTabLedgerShort': (l.custTabLedgerShort, 'Операции'), // l10n-ignore
    'invAdjustment': (l.invAdjustment, 'Корректировка'), // l10n-ignore
    'invAllProducts': (l.invAllProducts, 'Все товары'), // l10n-ignore
    'invCount': (l.invCount, 'Инвентаризация'), // l10n-ignore
    'invDiscrepancies': (l.invDiscrepancies, 'Расхождения'), // l10n-ignore
    'invDocuments': (l.invDocuments, 'Документы'), // l10n-ignore
    'invMovements': (l.invMovements, 'Движения'), // l10n-ignore
    'invNewCount': (l.invNewCount, 'Новая инвентаризация'), // l10n-ignore
    'invNewReceipt': (l.invNewReceipt, 'Новый приход'), // l10n-ignore
    'invReceipt': (l.invReceipt, 'Приход'), // l10n-ignore
    'invReceiptReversed': (l.invReceiptReversed, 'Сторнирован'), // l10n-ignore
    'invReverse': (l.invReverse, 'Сторнировать'), // l10n-ignore
    'invScanPlusOne': (l.invScanPlusOne, 'Скан: +1 к факту'), // l10n-ignore
    'invWriteoff': (l.invWriteoff, 'Списание'), // l10n-ignore
    'mktCheckBalance': (l.mktCheckBalance, 'Проверить баланс'), // l10n-ignore
    'mktGiftBalanceTitle': (l.mktGiftBalanceTitle, 'Баланс сертификата'), // l10n-ignore
    'mktGiftSalesSegment': (l.mktGiftSalesSegment, 'Продажи'), // l10n-ignore
    'mktIssue': (l.mktIssue, 'Выпустить'), // l10n-ignore
    'mktNewPromo': (l.mktNewPromo, 'Новая акция'), // l10n-ignore
    'mktPayMixed': (l.mktPayMixed, 'Смешанная'), // l10n-ignore
    'mktPromoEnabled': (l.mktPromoEnabled, 'Акция включена'), // l10n-ignore
    'mktSaleDocument': (l.mktSaleDocument, 'Документ продажи'), // l10n-ignore
    'mktSaleVoidedStatus': (l.mktSaleVoidedStatus, 'Аннулирована'), // l10n-ignore
    'mktSimAddProduct': (l.mktSimAddProduct, 'Добавить товар'), // l10n-ignore
    'mktSimQtyShort': (l.mktSimQtyShort, 'Кол-во'), // l10n-ignore
    'mktSimTitle': (l.mktSimTitle, 'Проверка акций на чеке'), // l10n-ignore
    'mktTabGiftCards': (l.mktTabGiftCards, 'Сертификаты'), // l10n-ignore
    'mktTabLoyalty': (l.mktTabLoyalty, 'Лояльность'), // l10n-ignore
    'mktTabMailing': (l.mktTabMailing, 'Рассылки'), // l10n-ignore
    'mktTestOnReceipt': (l.mktTestOnReceipt, 'Проверить на чеке'), // l10n-ignore
    'payCard': (l.payCard, 'Карта'), // l10n-ignore
    'payDebt': (l.payDebt, 'В долг'), // l10n-ignore
    'posCartActions': (l.posCartActions, 'Действия с чеком'), // l10n-ignore
    'posCloseEsc': (l.posCloseEsc, 'Закрыть (Esc)'), // l10n-ignore
    'posLineDiscount': (l.posLineDiscount, 'Скидка на позицию'), // l10n-ignore
    'posMixed': (l.posMixed, 'Смешанная оплата'), // l10n-ignore
    'posParkedReceipts': (l.posParkedReceipts, 'Отложенные чеки'), // l10n-ignore
    'posParkedTooltip': (l.posParkedTooltip, 'Отложенные чеки (F9)'), // l10n-ignore
    'posSellGiftCard': (l.posSellGiftCard, 'Продать сертификат'), // l10n-ignore
    'prodCancelSelection': (l.prodCancelSelection, 'Отменить выбор (Esc)'), // l10n-ignore
    'prodCategories': (l.prodCategories, 'Категории'), // l10n-ignore
    'prodCloseUnsavedQ': (l.prodCloseUnsavedQ, 'Закрыть без сохранения?'), // l10n-ignore
    'prodImportFromCsv': (l.prodImportFromCsv, 'Импорт из CSV'), // l10n-ignore
    'prodMovements': (l.prodMovements, 'Движение товара'), // l10n-ignore
    'prodNewCategory': (l.prodNewCategory, 'Новая категория'), // l10n-ignore
    'prodNewProduct': (l.prodNewProduct, 'Новый товар'), // l10n-ignore
    'prodPriceLabels': (l.prodPriceLabels, 'Ценники'), // l10n-ignore
    'prodSelect': (l.prodSelect, 'Выбрать'), // l10n-ignore
    'salesReceiptText': (l.salesReceiptText, 'Текст чека'), // l10n-ignore
    'salesReturnAll': (l.salesReturnAll, 'Вернуть всё'), // l10n-ignore
    'salesTabReturns': (l.salesTabReturns, 'Возвраты'), // l10n-ignore
    'salesTitle': (l.salesTitle, 'Чеки'), // l10n-ignore
    'salesWhatToReturn': (l.salesWhatToReturn, 'Что возвращаем'), // l10n-ignore
    'settingsBackupCreateNow': (l.settingsBackupCreateNow, 'Создать копию сейчас'), // l10n-ignore
    'settingsCancelVerb': (l.settingsCancelVerb, 'Отменить'), // l10n-ignore
    'shiftTabCurrent': (l.shiftTabCurrent, 'Текущая смена'), // l10n-ignore
    'shiftTabHistory': (l.shiftTabHistory, 'История смен'), // l10n-ignore
    'staffTabAudit': (l.staffTabAudit, 'Журнал действий'), // l10n-ignore
    'staffTabMotivation': (l.staffTabMotivation, 'Мотивация'), // l10n-ignore
    'staffTabRoles': (l.staffTabRoles, 'Роли и права'), // l10n-ignore
    'staffTabTime': (l.staffTabTime, 'Рабочее время'), // l10n-ignore
    'warrantyClaimFab': (l.warrantyClaimFab, 'Заявка'), // l10n-ignore
    'warrantyFind': (l.warrantyFind, 'Найти'), // l10n-ignore
    'warrantyNewClaim': (l.warrantyNewClaim, 'Новая заявка'), // l10n-ignore
    'warrantySubmit': (l.warrantySubmit, 'Принять заявку'), // l10n-ignore
    'warrantyWithoutReceipt': (l.warrantyWithoutReceipt, 'Без чека'), // l10n-ignore
    };
    for (final MapEntry(key: k, value: (actual, expected)) in pinned.entries) {
      expect(actual, expected, reason: 'app_ru.arb "$k" changed');
    }
  });
}
