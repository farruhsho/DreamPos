// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonSearch => 'Поиск';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonCreate => 'Создать';

  @override
  String get commonConfirm => 'Подтвердить';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Да';

  @override
  String get commonNo => 'Нет';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonEmpty => 'Нет данных';

  @override
  String get commonNothingFound => 'Ничего не найдено';

  @override
  String get commonPrint => 'Печать';

  @override
  String get commonExport => 'Экспорт';

  @override
  String get commonImport => 'Импорт';

  @override
  String get commonTotal => 'Итого';

  @override
  String get commonDate => 'Дата';

  @override
  String get commonTime => 'Время';

  @override
  String get commonAmount => 'Сумма';

  @override
  String get commonQty => 'Количество';

  @override
  String get commonPrice => 'Цена';

  @override
  String get commonCost => 'Себестоимость';

  @override
  String get commonStatus => 'Статус';

  @override
  String get commonReason => 'Причина';

  @override
  String get commonComment => 'Комментарий';

  @override
  String get commonNote => 'Примечание';

  @override
  String get commonName => 'Название';

  @override
  String get commonPersonName => 'Имя';

  @override
  String get commonPhone => 'Телефон';

  @override
  String get commonAddress => 'Адрес';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonNext => 'Далее';

  @override
  String get commonDone => 'Готово';

  @override
  String get commonApply => 'Применить';

  @override
  String get commonReset => 'Сбросить';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonAll => 'Все';

  @override
  String get commonFilter => 'Фильтр';

  @override
  String get commonSort => 'Сортировка';

  @override
  String get commonPeriod => 'Период';

  @override
  String get commonToday => 'Сегодня';

  @override
  String get commonYesterday => 'Вчера';

  @override
  String get commonWeek => 'Неделя';

  @override
  String get commonMonth => 'Месяц';

  @override
  String get commonYear => 'Год';

  @override
  String get commonActions => 'Действия';

  @override
  String get commonDetails => 'Подробнее';

  @override
  String get commonMore => 'Ещё';

  @override
  String get commonShowAll => 'Показать все';

  @override
  String get commonRequired => 'Обязательное поле';

  @override
  String get commonInvalidAmount => 'Неверная сумма';

  @override
  String get commonEnterNumber => 'Введите число';

  @override
  String get commonMustBePositive => 'Должно быть больше нуля';

  @override
  String get commonAmountMustBePositive => 'Должна быть больше нуля';

  @override
  String get commonCannotBeNegative => 'Не может быть отрицательной';

  @override
  String get commonIntegerOnly => 'Только целое число';

  @override
  String get commonEnterName => 'Введите имя';

  @override
  String get commonSomethingWentWrong => 'Что-то пошло не так';

  @override
  String get commonProduct => 'Товар';

  @override
  String get commonProducts => 'Товары';

  @override
  String get commonCustomer => 'Клиент';

  @override
  String get commonCustomers => 'Клиенты';

  @override
  String get commonSupplier => 'Поставщик';

  @override
  String get commonCashier => 'Кассир';

  @override
  String get commonEmployee => 'Сотрудник';

  @override
  String get commonShift => 'Смена';

  @override
  String get commonReceipt => 'Чек';

  @override
  String get commonSale => 'Продажа';

  @override
  String get commonReturn => 'Возврат';

  @override
  String get commonPayment => 'Оплата';

  @override
  String get commonPaymentMethod => 'Способ оплаты';

  @override
  String get commonDiscount => 'Скидка';

  @override
  String get commonChange => 'Сдача';

  @override
  String get commonDebt => 'Долг';

  @override
  String get commonBonuses => 'Бонусы';

  @override
  String get commonBalance => 'Баланс';

  @override
  String get commonGiftCard => 'Сертификат';

  @override
  String get commonCategory => 'Категория';

  @override
  String get commonBarcode => 'Штрихкод';

  @override
  String get commonSku => 'Артикул';

  @override
  String get commonStock => 'Остаток';

  @override
  String get commonUnit => 'Ед. изм.';

  @override
  String get commonVat => 'НДС';

  @override
  String get commonDocument => 'Документ';

  @override
  String get commonVoided => 'Аннулирован';

  @override
  String get commonEnabled => 'Включено';

  @override
  String get commonDisabled => 'Выключено';

  @override
  String get commonNew => 'Новый';

  @override
  String get commonOpen => 'Открыть';

  @override
  String get commonCustomerNotFound => 'Клиент не найден';

  @override
  String commonPositionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count позиции',
      many: '$count позиций',
      few: '$count позиции',
      one: '$count позиция',
    );
    return '$_temp0';
  }

  @override
  String commonDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count документа',
      many: '$count документов',
      few: '$count документа',
      one: '$count документ',
    );
    return '$_temp0';
  }

  @override
  String commonReceiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чека',
      many: '$count чеков',
      few: '$count чека',
      one: '$count чек',
    );
    return '$_temp0';
  }

  @override
  String commonReturnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count возврата',
      many: '$count возвратов',
      few: '$count возврата',
      one: '$count возврат',
    );
    return '$_temp0';
  }

  @override
  String commonMarksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отметки',
      many: '$count отметок',
      few: '$count отметки',
      one: '$count отметка',
    );
    return '$_temp0';
  }

  @override
  String commonProductsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товара',
      many: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String commonCustomersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count клиента',
      many: '$count клиентов',
      few: '$count клиента',
      one: '$count клиент',
    );
    return '$_temp0';
  }

  @override
  String commonDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get payCash => 'Наличные';

  @override
  String get payCard => 'Карта';

  @override
  String get payTransfer => 'Перевод';

  @override
  String get payBonus => 'Бонусы';

  @override
  String get payDebt => 'В долг';

  @override
  String get payGiftCard => 'Сертификат';

  @override
  String get unitPcs => 'шт';

  @override
  String get unitKg => 'кг';

  @override
  String get unitG => 'г';

  @override
  String get unitL => 'л';

  @override
  String get unitM => 'м';

  @override
  String get unitPack => 'уп';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleManager => 'Менеджер';

  @override
  String get roleCashier => 'Кассир';

  @override
  String get roleStorekeeper => 'Кладовщик';

  @override
  String get coreLanguage => 'Язык';

  @override
  String get coreUiLanguage => 'Язык интерфейса';

  @override
  String get coreReceiptLanguage => 'Язык чека';

  @override
  String get coreDuplicateBarcode => 'Товар с таким штрихкодом уже существует';

  @override
  String get coreDuplicateCard => 'Карта с таким номером уже есть';

  @override
  String get coreDuplicateCode => 'Такой код уже существует';

  @override
  String get coreDuplicateRecord => 'Такая запись уже существует';

  @override
  String get coreErase => 'Стереть';

  @override
  String get corePickProductTitle => 'Выбор товара';

  @override
  String get corePickProductHint => 'Название, артикул или штрихкод';

  @override
  String coreSkuShort(String sku) {
    return 'арт. $sku';
  }

  @override
  String coreStockShort(String qty) {
    return 'остаток $qty';
  }

  @override
  String get coreNewCustomer => 'Новый клиент';

  @override
  String get coreNameRequiredLabel => 'Имя *';

  @override
  String get coreCustomerSearchHint => 'Имя, телефон или номер карты';

  @override
  String get coreCreateCustomer => 'Создать клиента';

  @override
  String coreCardShort(String number) {
    return 'карта $number';
  }

  @override
  String coreDiscountShort(String percent) {
    return 'скидка $percent%';
  }

  @override
  String coreDebtShort(String amount) {
    return 'долг $amount';
  }

  @override
  String coreBonusShort(String amount) {
    return 'бонусы $amount';
  }

  @override
  String get corePinFormat => 'PIN — от 4 до 8 цифр';

  @override
  String get corePinTooSimple => 'Слишком простой PIN';

  @override
  String corePrintPhone(String phone) {
    return 'Тел: $phone';
  }

  @override
  String corePrintTaxId(String taxId) {
    return 'ИНН: $taxId';
  }

  @override
  String coreReceiptTitle(String number) {
    return 'ЧЕК №$number';
  }

  @override
  String coreReceiptCopyTitle(String number) {
    return 'КОПИЯ ЧЕК №$number';
  }

  @override
  String corePrintCashier(String name) {
    return 'Кассир: $name';
  }

  @override
  String corePrintCustomer(String name) {
    return 'Клиент: $name';
  }

  @override
  String corePrintWarrantyUntil(String date) {
    return 'Гарантия до $date';
  }

  @override
  String get corePrintTotal => 'ИТОГО';

  @override
  String get corePrintVatIncluded => 'в т.ч. НДС';

  @override
  String get corePrintBonusEarned => 'Начислено бонусов';

  @override
  String get corePrintCustomerDebt => 'Долг клиента';

  @override
  String get corePrintVoided => '*** АННУЛИРОВАН ***';

  @override
  String corePrintReason(String reason) {
    return 'Причина: $reason';
  }

  @override
  String corePrintJobReceipt(String number) {
    return 'Чек $number';
  }

  @override
  String corePrintJobGift(String number) {
    return 'Сертификат $number';
  }

  @override
  String coreGiftSlipTitle(String number) {
    return 'Продажа сертификата №$number';
  }

  @override
  String coreGiftSlipCopyTitle(String number) {
    return 'КОПИЯ Продажа сертификата №$number';
  }

  @override
  String get coreGiftSlipNote =>
      'Сертификат не является фискальным чеком на товар';

  @override
  String get coreGiftCode => 'Код сертификата';

  @override
  String get coreGiftFaceValue => 'Номинал';

  @override
  String get coreGiftValidity => 'Срок действия';

  @override
  String get coreGiftNoExpiry => 'без срока';

  @override
  String coreGiftUntil(String date) {
    return 'до $date';
  }

  @override
  String get navDashboard => 'Обзор';

  @override
  String get navPos => 'Касса';

  @override
  String get navSales => 'Чеки';

  @override
  String get navShifts => 'Смена';

  @override
  String get navProducts => 'Товары';

  @override
  String get navInventory => 'Склад';

  @override
  String get navPurchasing => 'Закупки';

  @override
  String get navCustomers => 'Клиенты';

  @override
  String get navMarketing => 'Маркетинг';

  @override
  String get navWarranty => 'Гарантия';

  @override
  String get navReports => 'Отчёты';

  @override
  String get navStaff => 'Сотрудники';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navNotifications => 'Уведомления';

  @override
  String get appMenu => 'Меню';

  @override
  String get appShiftClosed => 'Смена закрыта';

  @override
  String appShiftChip(String number, String time) {
    return 'Смена №$number · с $time';
  }

  @override
  String appShiftChipShort(String number) {
    return 'Смена №$number';
  }

  @override
  String appShiftChipNumber(String number) {
    return '№$number';
  }

  @override
  String get appProfile => 'Профиль';

  @override
  String get appLockSwitch => 'Заблокировать / сменить кассира';

  @override
  String get domCustomerDiscount => 'Скидка клиента';

  @override
  String get errPinInUse => 'Этот PIN уже используется другим сотрудником';

  @override
  String errTooManyAttempts(String minutes) {
    return 'Слишком много неверных попыток. Подождите $minutes минут';
  }

  @override
  String get errAccountLockedTryLater =>
      'Учётная запись временно заблокирована. Попробуйте позже';

  @override
  String get errAccountLocked => 'Учётная запись временно заблокирована';

  @override
  String get errWrongPin => 'Неверный PIN';

  @override
  String get errAmountMustBePositive => 'Сумма должна быть больше нуля';

  @override
  String get errNoDebt => 'У клиента нет долга';

  @override
  String get errAmountExceedsDebt => 'Сумма больше долга клиента';

  @override
  String get errOpenShiftForCash => 'Для приёма наличных откройте смену';

  @override
  String get errBonusNegative => 'Баланс бонусов не может быть отрицательным';

  @override
  String get errGiftCodeTooShort => 'Код сертификата — минимум 6 символов';

  @override
  String get errGiftCodeTooLong => 'Код сертификата слишком длинный';

  @override
  String get errGiftCodeChars => 'Код: только латинские буквы и цифры';

  @override
  String get errFaceValuePositive => 'Номинал должен быть больше нуля';

  @override
  String get errExpiryPassed => 'Срок действия уже истёк';

  @override
  String get errOpenShiftToSellGift =>
      'Откройте смену, чтобы продать сертификат';

  @override
  String get errChoosePaymentMethod => 'Выберите способ оплаты';

  @override
  String get errGiftPaymentMethods =>
      'Сертификат можно оплатить только наличными, картой или переводом';

  @override
  String get errPaymentMustBePositive => 'Сумма оплаты должна быть больше нуля';

  @override
  String get errGiftPaymentsMismatch =>
      'Сумма оплат не совпадает с номиналом сертификата';

  @override
  String get errCashNotInPayment => 'Наличные не входят в оплату';

  @override
  String get errCashTenderedLess => 'Получено наличных меньше суммы к оплате';

  @override
  String errGiftCodeExists(String code) {
    return 'Сертификат с кодом $code уже существует';
  }

  @override
  String get errDocumentNotFound => 'Документ не найден';

  @override
  String get errGiftSaleAlreadyVoided => 'Продажа уже аннулирована';

  @override
  String get errGiftNotFound => 'Сертификат не найден';

  @override
  String get errGiftUsedCannotVoid =>
      'Сертификат уже использован — аннулирование невозможно';

  @override
  String get errVoidReasonRequired => 'Укажите причину аннулирования';

  @override
  String get errOpenShiftToVoid => 'Откройте смену, чтобы аннулировать продажу';

  @override
  String errGiftSaleNumberVoided(String number) {
    return 'Продажа сертификата №$number уже аннулирована';
  }

  @override
  String get errAddLine => 'Добавьте хотя бы одну позицию';

  @override
  String get errPurchasePriceNegative =>
      'Цена закупки не может быть отрицательной';

  @override
  String get errRetailPricePositive => 'Розничная цена должна быть больше нуля';

  @override
  String get errProductNotFound => 'Товар не найден';

  @override
  String errProductDeleted(String name) {
    return 'Товар «$name» удалён';
  }

  @override
  String errLinePurchasePriceNegative(String name) {
    return '$name: цена закупки отрицательная';
  }

  @override
  String errProductRepeated(String name) {
    return 'Товар «$name» повторяется в документе — объедините строки';
  }

  @override
  String get errSupplierNotFound => 'Поставщик не найден';

  @override
  String get errOrderNotFound => 'Заказ не найден';

  @override
  String get errOrderOtherSupplier => 'Заказ не относится к этому поставщику';

  @override
  String errOrderClosed(String number) {
    return 'Заказ №$number уже закрыт';
  }

  @override
  String get errOrderLineNotFound => 'Позиция не найдена в заказе';

  @override
  String get errOrderLineWithoutOrder => 'Позиция заказа указана без заказа';

  @override
  String get errReversalReasonRequired => 'Укажите причину сторно';

  @override
  String get errReceiptNotFound => 'Приход не найден';

  @override
  String errReceiptAlreadyReversed(String number) {
    return 'Приход №$number уже сторнирован';
  }

  @override
  String errSupplierDeletedNoReversal(String name, String number) {
    return 'Поставщик «$name» удалён — сторно прихода №$number невозможно';
  }

  @override
  String get errQtyMustBePositive => 'Количество должно быть больше нуля';

  @override
  String errQtyIntegerOnly(String unit) {
    return 'Для «$unit» допускается только целое число';
  }

  @override
  String get errQtyTooLarge => 'Слишком большое количество';

  @override
  String get errCartEmpty => 'Чек пуст';

  @override
  String get errPriceNegative => 'Цена не может быть отрицательной';

  @override
  String get errPaymentNegative => 'Сумма оплаты не может быть отрицательной';

  @override
  String errUnknownPaymentMethodNamed(String method) {
    return 'Неизвестный способ оплаты: $method';
  }

  @override
  String get errUnknownPaymentMethod => 'Неизвестный способ оплаты';

  @override
  String get errOpenShiftToSell => 'Откройте смену, чтобы продавать';

  @override
  String get errShiftClosedOpenNew => 'Смена закрыта. Откройте новую смену';

  @override
  String get errProductNotFoundOrDeleted => 'Товар не найден или удалён';

  @override
  String get errPromoInvalid => 'Промокод недействителен';

  @override
  String errManualDiscountLimit(String percent, String limit) {
    return 'Ручная скидка $percent% превышает допустимую ($limit%). Нужно подтверждение менеджера';
  }

  @override
  String get errNonCashExceedsTotal =>
      'Безналичная оплата превышает сумму чека';

  @override
  String errInsufficientPayment(String amount) {
    return 'Недостаточно оплаты: не хватает $amount';
  }

  @override
  String get errBonusNeedsCustomer => 'Для оплаты бонусами выберите клиента';

  @override
  String get errLoyaltyDisabled => 'Бонусная программа выключена';

  @override
  String errInsufficientBonus(String amount) {
    return 'Недостаточно бонусов: доступно $amount';
  }

  @override
  String errBonusMaxRedeem(String amount) {
    return 'Бонусами можно оплатить не более $amount';
  }

  @override
  String get errDebtNeedsCustomer => 'Для продажи в долг выберите клиента';

  @override
  String errCreditLimitExceeded(String limit, String debt) {
    return 'Превышен кредитный лимит клиента ($limit). Текущий долг: $debt';
  }

  @override
  String get errNoCredit => 'Клиенту не открыт кредит';

  @override
  String errGiftCardNotFound(String code) {
    return 'Сертификат $code не найден';
  }

  @override
  String errGiftCardInactive(String code) {
    return 'Сертификат $code не активен';
  }

  @override
  String errGiftCardExpired(String code) {
    return 'Срок действия сертификата $code истёк';
  }

  @override
  String errGiftCardInsufficient(String code, String amount) {
    return 'На сертификате $code только $amount';
  }

  @override
  String get errSelectReturnItems => 'Выберите товары для возврата';

  @override
  String get errSaleNotFound => 'Чек не найден';

  @override
  String get errFullyReturned => 'По этому чеку уже оформлен полный возврат';

  @override
  String errReturnPeriodExpired(String days) {
    return 'Срок возврата ($days дн.) истёк';
  }

  @override
  String get errLineNotInSale => 'Позиция не из этого чека';

  @override
  String errReturnQtyExceeded(String name, String qty) {
    return '«$name»: можно вернуть не более $qty';
  }

  @override
  String get errSaleNoCustomer => 'В чеке нет клиента';

  @override
  String get errOpenShiftForCashRefund =>
      'Для возврата наличными откройте смену';

  @override
  String get errVoidOnlyWithoutReturns =>
      'Аннулировать можно только чек без возвратов';

  @override
  String get errSaleOtherShift => 'Чек из другой смены — оформите возврат';

  @override
  String get errAmountNegative => 'Сумма не может быть отрицательной';

  @override
  String errShiftAlreadyOpen(String number) {
    return 'Смена №$number уже открыта';
  }

  @override
  String get errUnknownOperation => 'Неизвестная операция';

  @override
  String get errShiftClosed => 'Смена закрыта';

  @override
  String get errNotEnoughCash => 'В кассе недостаточно наличных';

  @override
  String get errShiftAlreadyClosed => 'Смена уже закрыта';

  @override
  String errInsufficientStock(String name, String qty) {
    return 'Недостаточно товара «$name»: в наличии $qty';
  }

  @override
  String get errCountClosed => 'Инвентаризация уже закрыта';

  @override
  String errSupplierDeleted(String name) {
    return 'Поставщик «$name» удалён — операция невозможна';
  }

  @override
  String get errOpenShiftForCashPayout =>
      'Для оплаты наличными из кассы откройте смену';

  @override
  String errOverpaySupplier(String amount) {
    return 'Сумма больше долга поставщику ($amount). Подтвердите переплату.';
  }

  @override
  String errOrderCancelled(String number) {
    return 'Заказ №$number отменён';
  }

  @override
  String get errShiftClosedOpenShift => 'Смена закрыта — откройте смену';

  @override
  String get errCancelReasonRequired => 'Укажите причину отмены оплаты';

  @override
  String get errPaymentNotFound => 'Оплата не найдена';

  @override
  String get errPaymentAlreadyCancelled => 'Оплата уже отменена';

  @override
  String get errPaymentShiftClosed =>
      'Смена оплаты закрыта — отмена невозможна';

  @override
  String get errAdjustmentZero => 'Сумма корректировки не может быть нулевой';

  @override
  String get errAdjustmentReasonRequired => 'Укажите причину корректировки';

  @override
  String get errPinAmbiguous =>
      'Этот PIN-код есть у нескольких сотрудников (после синхронизации касс). Войдите другим сотрудником и смените PIN одному из них.';

  @override
  String get errPaymentOtherRegisterShift =>
      'Оплата наличными внесена в смене другой кассы — отменить её можно только на той кассе';

  @override
  String errReceiptOpeningNoReversal(String number) {
    return 'Приход №$number — начальный остаток синхронизации, его нельзя сторнировать';
  }

  @override
  String get errEffectDoneElsewhere =>
      'Этот документ уже проведён на другой кассе, но его изменения ещё не все пришли. Синхронизируйте кассу и откройте документ снова.';

  @override
  String get authEnterPin => 'Введите PIN-код';

  @override
  String get authDemoMode => 'Демо-режим';

  @override
  String get setupDefaultReceiptFooter => 'Спасибо за покупку!';

  @override
  String get setupWelcome => 'Добро пожаловать в DreamPOS';

  @override
  String get setupIntro =>
      'Настройка займёт меньше минуты. Всё можно изменить позже в «Настройках».';

  @override
  String get setupStart => 'Начать работу';

  @override
  String get setupStoreName => 'Название магазина *';

  @override
  String get setupEnterStoreName => 'Введите название';

  @override
  String get setupTaxId => 'ИНН / STIR';

  @override
  String get setupCurrency => 'Валюта учёта';

  @override
  String setupCurrencyExample(String amount) {
    return 'Пример: $amount';
  }

  @override
  String get setupCurrencyWarning =>
      'Валюту нельзя менять после первой продажи — от неё зависят все суммы в базе.';

  @override
  String get setupOwnerName => 'Ваше имя (владелец) *';

  @override
  String get setupPin => 'PIN-код (4–8 цифр) *';

  @override
  String get setupPinRepeat => 'Повторите PIN *';

  @override
  String get setupPinMismatch => 'PIN не совпадает';

  @override
  String get setupDemo => 'Заполнить демо-данными';

  @override
  String get setupDemoHint =>
      'Товары, клиенты и акции для знакомства с системой. Не включайте для реального магазина.';

  @override
  String get setupStepStore => 'Магазин';

  @override
  String get setupStepCurrency => 'Валюта';

  @override
  String get setupStepOwner => 'Владелец';

  @override
  String get setupOr => 'или';

  @override
  String get setupJoinStore => 'Подключиться к существующему магазину';

  @override
  String get setupJoinStoreHint =>
      'Если магазин уже работает в облаке на другой кассе: товары, клиенты и пользователи загрузятся оттуда.';

  @override
  String get setupJoinTitle => 'Подключение к магазину';

  @override
  String get setupJoinIntro =>
      'Войдите в аккаунт облака и выберите магазин. Его данные и пользователи загрузятся на эту кассу, затем войдите по PIN-коду.';

  @override
  String get setupJoinNewStore => 'Создать новый магазин';

  @override
  String get setupJoinDone => 'Данные магазина загружены. Войдите по PIN-коду.';

  @override
  String get setupJoinPartial =>
      'Касса подключена, но загрузка данных не завершилась. Проверьте связь и повторите.';

  @override
  String get setupJoinRetry => 'Повторить загрузку';

  @override
  String get setupJoinSignUpIntro =>
      'Создайте аккаунт владельца в вашем проекте Firebase. Затем создайте на этой кассе новый магазин, а чтобы перенести его в облако, выберите в разделе Настройки › Синхронизация «Создать магазин в облаке».';

  @override
  String get custCreated => 'Клиент создан';

  @override
  String get custNoneToExport => 'Нет клиентов для экспорта';

  @override
  String custCsvCopied(String count) {
    return 'Скопировано $count клиентов в формате CSV — вставьте в Excel';
  }

  @override
  String custTotalCount(String count) {
    return 'Всего: $count';
  }

  @override
  String get custExportTooltip =>
      'Скопировать текущий список в CSV (для Excel)';

  @override
  String get custNewTooltip => 'Новый клиент (Ctrl+N)';

  @override
  String get custNew => 'Новый клиент';

  @override
  String get custSelectTitle => 'Выберите клиента';

  @override
  String get custSelectMessage =>
      'Здесь появятся покупки, долги, бонусы и любимые товары клиента.';

  @override
  String get custStatCustomers => 'Клиентов';

  @override
  String get custStatReceivable => 'Дебиторка';

  @override
  String custOverdueLower(String amount) {
    return 'просрочено $amount';
  }

  @override
  String custOverdue(String amount) {
    return 'Просрочено $amount';
  }

  @override
  String get custStatBonusLiability => 'Бонусные обязательства';

  @override
  String get custSearchHintWide => 'Имя, телефон или карта (Ctrl+F)';

  @override
  String get custSearchHint => 'Имя, телефон, карта';

  @override
  String custSortTooltip(String sort) {
    return 'Сортировка: $sort';
  }

  @override
  String get custTagFilter => 'Фильтр по тегу';

  @override
  String custTagTooltip(String tag) {
    return 'Тег: $tag';
  }

  @override
  String get custAllTags => 'Все теги';

  @override
  String get custEmptyTitle => 'Клиентов пока нет';

  @override
  String get custEmptyMessage =>
      'Добавьте клиентов, чтобы давать скидки, начислять бонусы и продавать в долг.';

  @override
  String get custAdd => 'Добавить клиента';

  @override
  String get custNotFoundTitle => 'Никого не найдено';

  @override
  String get custNotFoundMessage => 'Измените запрос или сбросьте фильтры';

  @override
  String get custResetFilters => 'Сбросить фильтры';

  @override
  String custTileCard(String card) {
    return 'карта $card';
  }

  @override
  String custDiscountLower(String value) {
    return 'скидка $value';
  }

  @override
  String custTilePurchases(String amount) {
    return 'покупки $amount';
  }

  @override
  String custTileVisits(String count) {
    return '$count виз.';
  }

  @override
  String get custTileNeverBought => 'не покупал';

  @override
  String custTileLastVisit(String date) {
    return 'был $date';
  }

  @override
  String get custBirthdayToday => 'День рождения сегодня';

  @override
  String custBirthdayIn(String days) {
    return 'День рождения через $days дн.';
  }

  @override
  String custTileDebt(String amount) {
    return 'долг $amount';
  }

  @override
  String get custTileOverdueChip => 'просрочен';

  @override
  String custTileBonus(String amount) {
    return 'бонусы $amount';
  }

  @override
  String get custCardTitle => 'Карточка клиента';

  @override
  String custDeleteDebt(String amount) {
    return 'Нельзя удалить клиента с долгом $amount. Сначала примите оплату.';
  }

  @override
  String get custDeleteOverpaid => 'Нельзя удалить клиента с переплатой.';

  @override
  String get custDeleteTitle => 'Удалить клиента?';

  @override
  String custDeleteMessage(String name) {
    return '«$name» будет скрыт из списка. История продаж сохранится.';
  }

  @override
  String custDeleteBonusLost(String amount) {
    return 'Бонусы $amount будут недоступны.';
  }

  @override
  String get custDeleted => 'Клиент удалён';

  @override
  String get custNotFoundOrDeleted => 'Клиент не найден или удалён';

  @override
  String get custKpiSpent => 'Сумма покупок';

  @override
  String get custKpiVisits => 'Визитов';

  @override
  String get custKpiAvg => 'Средний чек';

  @override
  String get custKpiLastVisit => 'Последний визит';

  @override
  String get custNoPurchasesYet => 'Покупок ещё не было';

  @override
  String get custNoPurchasesLower => 'покупок не было';

  @override
  String custLimit(String amount) {
    return 'Лимит $amount';
  }

  @override
  String custLimitLower(String amount) {
    return 'лимит $amount';
  }

  @override
  String get custNoCredit => 'Кредит не открыт';

  @override
  String get custNoCreditLower => 'кредит не открыт';

  @override
  String get custBdayToday => 'сегодня!';

  @override
  String custBdayIn(String days) {
    return 'через $days дн.';
  }

  @override
  String custDiscountChip(String percent) {
    return 'Скидка $percent%';
  }

  @override
  String get custDelete => 'Удалить клиента';

  @override
  String get custNoPayPerm => 'Нет права принимать оплату';

  @override
  String get custAcceptDebtPayment => 'Принять оплату долга';

  @override
  String get custNoEditPerm => 'Нет права редактировать клиентов';

  @override
  String get custRemind => 'Напомнить';

  @override
  String get custNeedPromoPerm => 'Нужно право «Акции и бонусы»';

  @override
  String get custReminder => 'Напоминание';

  @override
  String get custTabSales => 'Покупки';

  @override
  String get custTabSalesShort => 'Покупки';

  @override
  String get custTabLedgerShort => 'Операции';

  @override
  String get custTabLedger => 'Долги и бонусы';

  @override
  String get custTabFavShort => 'Любимое';

  @override
  String get custTabFav => 'Любимые товары';

  @override
  String get custAgoToday => 'сегодня';

  @override
  String get custAgoYesterday => 'вчера';

  @override
  String custAgoDays(String days) {
    return '$days дн. назад';
  }

  @override
  String get custCopy => 'Скопировать';

  @override
  String custCopied(String text) {
    return 'Скопировано: $text';
  }

  @override
  String get custSalesEmptyTitle => 'Покупок пока нет';

  @override
  String get custSalesEmptyMessage =>
      'Выберите клиента на кассе, чтобы копить историю и бонусы.';

  @override
  String custReceiptNo(String number) {
    return 'Чек №$number';
  }

  @override
  String custReturnLower(String amount) {
    return 'возврат $amount';
  }

  @override
  String custReturnedQty(String qty) {
    return 'возвращено $qty';
  }

  @override
  String custBonusEarned(String amount) {
    return 'Начислено бонусов: $amount';
  }

  @override
  String get custLedgerEmpty => 'Операций по долгу и бонусам нет';

  @override
  String custDueUntil(String date) {
    return 'срок до $date';
  }

  @override
  String custBalanceAfter(String amount) {
    return 'остаток $amount';
  }

  @override
  String get custDuePassed => 'срок прошёл';

  @override
  String get custFavEmpty => 'Пока нет данных о покупках';

  @override
  String custBought(String qty) {
    return 'куплено $qty';
  }

  @override
  String get custSegDebtors => 'Должники';

  @override
  String get custSegOverdue => 'Просрочка';

  @override
  String get custSegVip => 'VIP';

  @override
  String get custSegSleeping => 'Спящие';

  @override
  String get custSegBirthdays => 'Именинники';

  @override
  String get custSegAllHint => 'Все клиенты';

  @override
  String get custSegDebtorsHint => 'Клиенты с непогашенным долгом';

  @override
  String get custSegOverdueHint => 'Срок оплаты долга прошёл';

  @override
  String get custSegVipHint => 'Топ-10% клиентов по сумме покупок';

  @override
  String custSegSleepingHint(String days) {
    return 'Не покупали больше $days дней';
  }

  @override
  String custSegBirthdaysHint(String days) {
    return 'День рождения в ближайшие $days дней';
  }

  @override
  String get custSortName => 'По имени';

  @override
  String get custSortLastVisit => 'По последнему визиту';

  @override
  String get custSortSpent => 'По сумме покупок';

  @override
  String get custSortDebt => 'По долгу';

  @override
  String get custSortBonus => 'По бонусам';

  @override
  String get custSortCreated => 'Сначала новые';

  @override
  String get custLedgerDebtSale => 'Продажа в долг';

  @override
  String get custLedgerDebtPayment => 'Погашение долга';

  @override
  String get custLedgerDebtAdjust => 'Корректировка долга';

  @override
  String get custLedgerBonusEarn => 'Начисление бонусов';

  @override
  String get custLedgerBonusSpend => 'Списание бонусов';

  @override
  String get custLedgerBonusAdjust => 'Корректировка бонусов';

  @override
  String get custStatusCompleted => 'Оплачен';

  @override
  String get custStatusPartReturned => 'Частичный возврат';

  @override
  String get custStatusReturned => 'Возвращён';

  @override
  String get custStatusHeld => 'Отложен';

  @override
  String custReminderGreeting(String name, String store, String debt) {
    return 'Здравствуйте, $name! Ваш долг в $store составляет $debt.';
  }

  @override
  String custReminderOverdue(String amount) {
    return 'Из них просрочено: $amount.';
  }

  @override
  String custReminderDue(String date) {
    return 'Срок оплаты — до $date.';
  }

  @override
  String get custReminderAsk =>
      'Просим погасить задолженность при ближайшем посещении магазина.';

  @override
  String custReminderPhone(String phone) {
    return 'Телефон для связи: $phone.';
  }

  @override
  String get custThanks => 'Спасибо!';

  @override
  String get custCsvCard => 'Карта';

  @override
  String get custCsvDiscount => 'Скидка %';

  @override
  String custPaymentAccepted(String amount) {
    return 'Оплата $amount принята';
  }

  @override
  String get custCurrentDebt => 'Текущий долг:';

  @override
  String get custPayAmount => 'Сумма оплаты *';

  @override
  String custNotMoreThanDebt(String amount) {
    return 'Не больше долга ($amount)';
  }

  @override
  String custFullAmountValue(String amount) {
    return 'Вся сумма: $amount';
  }

  @override
  String get custFullAmount => 'Вся сумма';

  @override
  String get custShiftClosedCash =>
      'Смена закрыта: для приёма наличных откройте смену или выберите другой способ.';

  @override
  String custCashToShift(String number) {
    return 'Наличные будут учтены в кассе смены №$number';
  }

  @override
  String get custPrintSlip => 'Распечатать квитанцию';

  @override
  String get custAcceptPayment => 'Принять оплату';

  @override
  String get custPdfSlipTitle => 'КВИТАНЦИЯ';

  @override
  String get custPdfSlipSubtitle => 'об оплате долга';

  @override
  String get custPdfDebtBefore => 'Долг до оплаты';

  @override
  String custPdfPaid(String method) {
    return 'Оплачено ($method)';
  }

  @override
  String get custPdfDebtAfter => 'Остаток долга';

  @override
  String get custPdfSignature => 'Подпись клиента: ____________';

  @override
  String custPdfJobName(String name) {
    return 'Квитанция $name';
  }

  @override
  String custBonusAdded(String amount) {
    return 'Начислено $amount';
  }

  @override
  String custBonusRemoved(String amount) {
    return 'Списано $amount';
  }

  @override
  String custBonusHeader(String name, String amount) {
    return '$name · баланс $amount';
  }

  @override
  String get custBonusAdd => 'Начислить';

  @override
  String get custBonusRemove => 'Списать';

  @override
  String get custBonusAmount => 'Сумма бонусов *';

  @override
  String custBonusOnlyOnBalance(String amount) {
    return 'На балансе только $amount';
  }

  @override
  String get custReasonRequired => 'Причина *';

  @override
  String get custReasonHint => 'Например: компенсация за задержку заказа';

  @override
  String get custReasonError => 'Укажите причину корректировки';

  @override
  String get custOurStore => 'наш магазин';

  @override
  String get custReminderTitle => 'Напоминание о долге';

  @override
  String get custPhoneCopied => 'Телефон скопирован';

  @override
  String get custReminderEmpty => 'Текст напоминания пуст';

  @override
  String get custReminderCopied => 'Текст напоминания скопирован';

  @override
  String custPhoneValue(String phone) {
    return 'Телефон: $phone';
  }

  @override
  String get custReminderSendHint =>
      'Отправьте текст в мессенджере или SMS со своего телефона.';

  @override
  String get custCopyPhone => 'Копировать телефон';

  @override
  String get custCopyText => 'Копировать текст';

  @override
  String get custEditTitle => 'Редактирование клиента';

  @override
  String get custBirthday => 'День рождения';

  @override
  String get custCardTaken => 'Эта карта уже привязана к другому клиенту';

  @override
  String get custPhoneUsedTitle => 'Телефон уже используется';

  @override
  String custPhoneUsedMessage(String phone, String name) {
    return 'Номер $phone уже есть у клиента «$name». Сохранить ещё одного клиента с этим номером?';
  }

  @override
  String get custNameField => 'Имя *';

  @override
  String get custEnterName => 'Введите имя клиента';

  @override
  String custPhoneExists(String names) {
    return 'Уже есть: $names';
  }

  @override
  String get custPhoneTooShort => 'Слишком короткий номер';

  @override
  String get custPhoneTooLong => 'Слишком длинный номер';

  @override
  String get custEmailInvalidFormat => 'Неверный формат email';

  @override
  String get custCardNumber => 'Номер карты';

  @override
  String get custGenerateCard => 'Сгенерировать номер карты';

  @override
  String get custNotSet => 'Не указан';

  @override
  String get custNoDiscountPerm => 'Нет права изменять скидку';

  @override
  String get custPersonalDiscount => 'Персональная скидка';

  @override
  String get custDiscountHelper => 'Не суммируется с акциями: берётся лучшая';

  @override
  String get custPercentRange => 'От 0 до 100%';

  @override
  String get custNoDebtPerm => 'Нет права управлять долгами';

  @override
  String get custDebtLimit => 'Лимит долга';

  @override
  String get custDebtLimitHelper => '0 — продажа в долг запрещена';

  @override
  String get custManagerOnly => 'Только для менеджера';

  @override
  String get custTags => 'Теги';

  @override
  String get custTagsHelper => 'Через запятую, например: опт, постоянный';

  @override
  String get custNote => 'Заметка';

  @override
  String get custCardGenFailed =>
      'Не удалось сгенерировать номер карты, попробуйте ещё раз';

  @override
  String get custNameTooLong => 'Имя слишком длинное';

  @override
  String get custDiscountRange => 'Скидка должна быть от 0 до 100%';

  @override
  String get custDebtLimitNegative => 'Лимит долга не может быть отрицательным';

  @override
  String get custEmailInvalid => 'Неверный email';

  @override
  String custCardTakenBy(String card) {
    return 'Карта $card уже привязана к другому клиенту';
  }

  @override
  String get custNoAssignDiscountPerm => 'Нет права назначать скидку клиенту';

  @override
  String get custNoOpenCreditPerm => 'Нет права открывать кредит клиенту';

  @override
  String get custNoChangeDiscountPerm => 'Нет права изменять скидку клиента';

  @override
  String get custNoChangeDebtLimitPerm => 'Нет права изменять лимит долга';

  @override
  String get custDeleteDebtRepo =>
      'Нельзя удалить клиента с долгом. Сначала примите оплату долга.';

  @override
  String get dash7Days => '7 дн.';

  @override
  String get dashAllReceipts => 'Все чеки';

  @override
  String get dashAvgCheck => 'Средний чек';

  @override
  String dashBarTooltip(String revenue, String receipts) {
    return 'Выручка: $revenue\nЧеков: $receipts';
  }

  @override
  String get dashDebtAllPaid => 'Все клиенты рассчитались';

  @override
  String get dashDebtLoading => 'Долги…';

  @override
  String get dashDebtNone => 'Долгов нет';

  @override
  String dashDebtTotal(String amount) {
    return 'Долг клиентов: $amount';
  }

  @override
  String dashDebtors(String count) {
    return 'Должников: $count';
  }

  @override
  String dashDuration(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get dashGrossProfit => 'Валовая прибыль';

  @override
  String dashMargin(String pct) {
    return 'маржа $pct%';
  }

  @override
  String get dashNoAccess => 'Нет доступа к разделу';

  @override
  String get dashNoPaymentsToday => 'Оплат сегодня ещё не было';

  @override
  String get dashNoReceipts => 'Чеков пока нет';

  @override
  String get dashNoSales => 'Продаж пока нет';

  @override
  String get dashOnbProductsButton => 'К товарам';

  @override
  String dashOnbProductsDone(String count) {
    return 'В каталоге $count тов. Можно добавить ещё или загрузить остатки.';
  }

  @override
  String get dashOnbProductsText =>
      'Заведите товары с ценами и остатками — вручную или сканером штрихкодов.';

  @override
  String get dashOnbProductsTitle => 'Добавьте товары';

  @override
  String get dashOnbSaleButton => 'Перейти в кассу';

  @override
  String get dashOnbSaleText =>
      'Отсканируйте товар или выберите его в кассе и примите оплату.';

  @override
  String get dashOnbSaleTitle => 'Сделайте первую продажу';

  @override
  String get dashOnbShiftButton => 'Открыть смену';

  @override
  String dashOnbShiftDone(String number) {
    return 'Смена №$number открыта — можно продавать.';
  }

  @override
  String get dashOnbShiftText =>
      'Укажите сумму размена в кассе, чтобы вечером сверить наличные.';

  @override
  String get dashOnbShiftTitle => 'Откройте смену';

  @override
  String get dashPaymentsToday => 'Оплаты сегодня';

  @override
  String dashPcs(String count) {
    return '$count шт.';
  }

  @override
  String get dashPos => 'Касса';

  @override
  String dashReceiptNumber(String number) {
    return 'Чек №$number';
  }

  @override
  String get dashReceipts => 'Чеков';

  @override
  String get dashRecentReceipts => 'Последние чеки';

  @override
  String get dashReports => 'Отчёты';

  @override
  String get dashReturns => 'Возвраты';

  @override
  String get dashRevenue14 => 'Выручка за 14 дней';

  @override
  String dashRevenueSummary(String total, String avg) {
    return 'Итого $total · в среднем $avg в торговый день';
  }

  @override
  String get dashRevenueToday => 'Выручка сегодня';

  @override
  String get dashRevenueTooltip =>
      'Продажи минус возвраты (аннулированные чеки не учитываются)';

  @override
  String get dashShiftClosed => 'Смена закрыта';

  @override
  String get dashShiftClosedText => 'Продажи невозможны, пока смена не открыта';

  @override
  String get dashShiftLong => 'Долго открыта';

  @override
  String get dashShiftLongText =>
      'Смена открыта больше 16 часов — закройте её и сверьте кассу.';

  @override
  String dashShiftOpen(String number) {
    return 'Смена №$number открыта';
  }

  @override
  String get dashShiftRunning => 'Идёт';

  @override
  String dashShiftSince(String time) {
    return 'С $time';
  }

  @override
  String dashShiftTotals(String receipts, String revenue) {
    return 'Чеков: $receipts · выручка $revenue';
  }

  @override
  String get dashStatusPartReturned => 'частичный возврат';

  @override
  String get dashStatusReturned => 'возврат';

  @override
  String get dashStatusVoided => 'аннулирован';

  @override
  String dashStepsDone(String done, String total) {
    return 'Выполнено $done из $total';
  }

  @override
  String get dashStockLoading => 'Остатки…';

  @override
  String dashStockLow(String low, String out) {
    return 'Заканчиваются: $low · нет в наличии: $out';
  }

  @override
  String get dashStockOk => 'Остатков достаточно';

  @override
  String get dashStockSubtitle => 'Товары с остатком ниже минимального';

  @override
  String get dashTitle => 'Обзор';

  @override
  String dashTodayDate(String date) {
    return 'Сегодня, $date';
  }

  @override
  String get dashTop5 => 'Топ-5 товаров';

  @override
  String dashVoidedSuffix(String count) {
    return ' · аннулировано чеков: $count';
  }

  @override
  String get dashWelcome => 'Добро пожаловать в DreamPOS!';

  @override
  String get dashWelcomeText =>
      'Три шага — и здесь появятся выручка, прибыль, лучшие товары и подсказки.';

  @override
  String dashYesterdaySoFar(String value) {
    return 'вчера к этому часу: $value';
  }

  @override
  String get invReceipt => 'Приход';

  @override
  String get invMoveReceiptReversal => 'Сторно прихода';

  @override
  String get invWriteoff => 'Списание';

  @override
  String get invAdjustment => 'Корректировка';

  @override
  String get invCount => 'Инвентаризация';

  @override
  String get invMoveTransfer => 'Перемещение';

  @override
  String get invMovements => 'Движения';

  @override
  String get invStockTab => 'Остатки';

  @override
  String get invReasonDefect => 'Брак';

  @override
  String get invReasonExpired => 'Просрочка';

  @override
  String get invReasonSpoiled => 'Порча';

  @override
  String get invReasonShortage => 'Недостача';

  @override
  String get invReasonPersonalUse => 'Личное потребление';

  @override
  String get invReasonOther => 'Другое';

  @override
  String get invReceiptPosted => 'Проведён';

  @override
  String get invReceiptReversed => 'Сторнирован';

  @override
  String get invCountDraft => 'Черновик';

  @override
  String get invCountCompleted => 'Проведена';

  @override
  String get invCountCancelled => 'Отменена';

  @override
  String get invDeletedProduct => 'Удалённый товар';

  @override
  String invReceiptRef(String number) {
    return 'Приход №$number';
  }

  @override
  String get invFilterLow => 'Мало';

  @override
  String get invFilterOut => 'Нет в наличии';

  @override
  String get invFilterNegative => 'Минус';

  @override
  String get invQtyRequired => 'Введите количество';

  @override
  String get invQtyNegative => 'Количество не может быть отрицательным';

  @override
  String get invQtyPositive => 'Количество должно быть больше нуля';

  @override
  String invQtyIntegerOnly(String unit) {
    return 'Для «$unit» допускается только целое число';
  }

  @override
  String get invQtyTooLarge => 'Слишком большое количество';

  @override
  String get invAddAtLeastOneLine => 'Добавьте хотя бы одну позицию';

  @override
  String invCostNegative(String name) {
    return '$name: цена закупки отрицательная';
  }

  @override
  String invRetailMustBePositive(String name) {
    return '$name: розничная цена должна быть больше нуля';
  }

  @override
  String get invSelectCategory => 'Выберите категорию';

  @override
  String get invSelectProducts => 'Выберите товары';

  @override
  String get invNoProductsToCount => 'Нет товаров для инвентаризации';

  @override
  String get invCountClosed => 'Инвентаризация уже закрыта';

  @override
  String get invNoCountedQty => 'Не введено ни одного фактического количества';

  @override
  String get invNoAccess => 'Нет доступа';

  @override
  String get invNoAccessMessage =>
      'Складские операции доступны кладовщику, менеджеру и владельцу';

  @override
  String get invNoProductsTitle => 'Товаров пока нет';

  @override
  String get invNoProductsMessage =>
      'Добавьте товары в разделе «Товары», затем оформите приход.';

  @override
  String get invChangeFiltersOrQuery => 'Измените фильтры или запрос';

  @override
  String get invStockValue => 'Сумма запаса';

  @override
  String get invPositionsTracked => 'Позиций на учёте';

  @override
  String get invStockAtCost => 'Запас по себестоимости';

  @override
  String get invStockAtRetail => 'Запас в розничных ценах';

  @override
  String invPotentialMargin(String amount) {
    return 'Потенц. наценка $amount';
  }

  @override
  String get invLowOutNegative => 'Мало / нет / минус';

  @override
  String get invAllCategories => 'Все категории';

  @override
  String get invSearchHint => 'Название, артикул, штрихкод';

  @override
  String get invStatusOut => 'Нет';

  @override
  String invSkuShort(String sku) {
    return 'арт. $sku';
  }

  @override
  String invMinShort(String qty) {
    return 'мин. $qty';
  }

  @override
  String get invInactive => 'не активен';

  @override
  String invQuickReceiptTitle(String name) {
    return 'Приход: $name';
  }

  @override
  String invCurrentStock(String qty) {
    return 'Текущий остаток: $qty';
  }

  @override
  String get invUnitCostRequired => 'Цена закупки за ед. *';

  @override
  String get invPostIn => 'Оприходовать';

  @override
  String get invSelectProduct => 'Выберите товар';

  @override
  String get invSpecifyWriteoffReason => 'Укажите причину списания';

  @override
  String get invDescribeReason => 'Опишите причину в комментарии';

  @override
  String get invWriteoffConfirmTitle => 'Списать товар?';

  @override
  String invWriteoffConfirmMessage(
    String name,
    String qty,
    String amount,
    String reason,
  ) {
    return '$name\n$qty на сумму $amount (по себестоимости)\nПричина: $reason';
  }

  @override
  String get invWriteoffAction => 'Списать';

  @override
  String invWrittenOff(String qty, String name) {
    return 'Списано $qty «$name»';
  }

  @override
  String get invChooseProduct => 'Выбрать товар…';

  @override
  String invStockLine(String qty) {
    return 'Остаток: $qty';
  }

  @override
  String invStockLineWithCost(String qty, String cost) {
    return 'Остаток: $qty · себестоимость $cost';
  }

  @override
  String get invCommentRequired => 'Комментарий *';

  @override
  String invWriteoffSum(String amount) {
    return 'Сумма списания: $amount';
  }

  @override
  String get invStockUnchanged => 'Остаток не изменился';

  @override
  String get invStockCorrected => 'Остаток исправлен';

  @override
  String get invAdjustTitle => 'Корректировка остатка';

  @override
  String invBookStock(String qty) {
    return 'Учётный остаток: $qty';
  }

  @override
  String get invActualStock => 'Фактический остаток';

  @override
  String get invReasonRequired => 'Причина *';

  @override
  String get invSpecifyAdjustReason => 'Укажите причину корректировки';

  @override
  String get invUseCountHint =>
      'Для полной проверки остатков используйте инвентаризацию.';

  @override
  String invHistoryTitle(String name) {
    return 'Движения: $name';
  }

  @override
  String get invNoMovementsYet => 'Движений пока нет';

  @override
  String invPriceDetail(String amount) {
    return 'цена $amount';
  }

  @override
  String invStockAfter(String qty) {
    return 'остаток $qty';
  }

  @override
  String get invNewWriteoff => 'Новое списание';

  @override
  String get invWhatToWriteOff => 'Что списываем?';

  @override
  String get invWriteoffs30 => 'Списания за 30 дней';

  @override
  String get invNoWriteoffs30 => 'Списаний за последние 30 дней не было';

  @override
  String invTotalAtCost(String amount) {
    return 'Всего по себестоимости: $amount';
  }

  @override
  String get invDays7 => '7 дней';

  @override
  String get invDays30 => '30 дней';

  @override
  String get invAllTime => 'Всё время';

  @override
  String get invPeriodCustom => 'Период…';

  @override
  String get invMovementsPeriod => 'Период движений';

  @override
  String get invType => 'Тип';

  @override
  String get invAllTypes => 'Все типы';

  @override
  String get invAllProducts => 'Все товары';

  @override
  String get invFilterByProduct => 'Фильтр по товару';

  @override
  String get invNoMovements => 'Движений нет';

  @override
  String get invChangeFiltersOrPeriod => 'Измените фильтры или период';

  @override
  String invRecords(String count) {
    return 'Записей: $count';
  }

  @override
  String invRecordsLimited(String count, String limit) {
    return 'Записей: $count (показаны последние $limit — уточните фильтр)';
  }

  @override
  String invInOut(String inQty, String outQty) {
    return 'приход +$inQty · расход $outQty';
  }

  @override
  String invCurrentStockOf(String name, String qty) {
    return 'Текущий остаток «$name»: $qty';
  }

  @override
  String get invDocsPeriod => 'Период документов';

  @override
  String get invSearchShort => '№ или накладная';

  @override
  String get invSearchLong => 'Поиск: № прихода или накладной';

  @override
  String get invAllSuppliers => 'Все поставщики';

  @override
  String get invNoDocs => 'Документов нет';

  @override
  String get invPostedAppearHere => 'Проведённые приходы появятся здесь';

  @override
  String invDocsCount(String count) {
    return 'Документов: $count';
  }

  @override
  String invDocsCountLimited(String count, String limit) {
    return 'Документов: $count (показаны последние $limit — уточните фильтр)';
  }

  @override
  String invPostedFor(String amount) {
    return 'проведено на $amount';
  }

  @override
  String get invNoSupplier => 'Без поставщика';

  @override
  String get invDeletedSupplier => 'Удалённый поставщик';

  @override
  String invOrderRef(String number) {
    return 'Заказ №$number';
  }

  @override
  String get invOrder => 'Заказ';

  @override
  String get invNoHeader => '№';

  @override
  String invNumber(String number) {
    return '№$number';
  }

  @override
  String get invInvoice => 'Накладная';

  @override
  String get invPositionsHeader => 'Позиций';

  @override
  String get invSource => 'Источник';

  @override
  String invInvoiceShort(String invoice) {
    return 'накл. $invoice';
  }

  @override
  String get invReceiptDocTitle => 'Документ прихода';

  @override
  String invReceiptPostedToast(String number) {
    return 'Приход №$number проведён';
  }

  @override
  String invReceiptPostedToastDetails(String number, String details) {
    return 'Приход №$number проведён · $details';
  }

  @override
  String invReverseTitle(String number) {
    return 'Сторнировать приход №$number?';
  }

  @override
  String get invReverseInfo =>
      'Остатки товаров уменьшатся на количество из документа, себестоимость будет пересчитана. Розничные цены, изменённые этим приходом, вернутся к прежним, если их не меняли позже.';

  @override
  String invReverseSupplierDebt(String supplier, String amount) {
    return 'Долг перед поставщиком $supplier уменьшится на $amount.';
  }

  @override
  String get invReverseIrreversible => 'Отменить сторно нельзя.';

  @override
  String get invReverseReasonLabel => 'Причина сторно *';

  @override
  String get invReverseReasonRequired => 'Укажите причину сторно';

  @override
  String get invReverse => 'Сторнировать';

  @override
  String get invDocNotFound => 'Документ не найден';

  @override
  String get invDocNotFoundMessage =>
      'Возможно, он был удалён или ещё не синхронизирован';

  @override
  String get invSupplierInvoice => 'Накладная поставщика';

  @override
  String get invManualReceipt => 'Ручной приход';

  @override
  String get invAcceptedBy => 'Принял';

  @override
  String invReasonLine(String reason) {
    return 'Причина: $reason';
  }

  @override
  String invTotalsLine(String count, String qty) {
    return 'Позиций: $count · количество $qty';
  }

  @override
  String invTotalLine(String amount) {
    return 'Итого: $amount';
  }

  @override
  String get invPositionsTitle => 'Позиции';

  @override
  String get invNoLinesInDoc => 'В документе нет позиций';

  @override
  String invReversedToast(String number) {
    return 'Приход №$number сторнирован';
  }

  @override
  String get invQtyShort => 'Кол-во';

  @override
  String get invPurchasePrice => 'Цена закупки';

  @override
  String get invNewRetailPrice => 'Новая розн. цена';

  @override
  String invWasPrice(String amount) {
    return 'было $amount';
  }

  @override
  String invPriceWas(String price, String old) {
    return '$price (было $old)';
  }

  @override
  String invRetailPriceLine(String price) {
    return 'Розничная цена: $price';
  }

  @override
  String get invNewReceipt => 'Новый приход';

  @override
  String get invDocuments => 'Документы';

  @override
  String invScanNotFound(String code) {
    return 'Товар со штрихкодом/артикулом «$code» не найден';
  }

  @override
  String get invAddToReceipt => 'Добавить в приход';

  @override
  String get invClearDocTitle => 'Очистить документ?';

  @override
  String get invClearDocMessage => 'Все позиции будут удалены из документа.';

  @override
  String get invCheckFields => 'Проверьте выделенные поля';

  @override
  String get invPostReceiptTitle => 'Провести приход?';

  @override
  String invPostReceiptMessage(String count, String amount) {
    return 'Позиций: $count\nСумма: $amount';
  }

  @override
  String invPostReceiptDebt(String supplier, String amount) {
    return 'Долг перед «$supplier» увеличится на $amount';
  }

  @override
  String get invPost => 'Провести';

  @override
  String invLinesFor(String count, String amount) {
    return '$count поз. на $amount';
  }

  @override
  String invPositionsLower(String count) {
    return 'позиций $count';
  }

  @override
  String get invPostReceipt => 'Провести приход';

  @override
  String get invSupplierHelper =>
      'Если указан, сумма прихода добавится к долгу поставщику';

  @override
  String get invInvoiceNoShort => '№ накладной';

  @override
  String get invInvoiceNoLong => '№ накладной поставщика';

  @override
  String get invScanShort => 'Штрихкод или артикул';

  @override
  String get invScanLong => 'Сканируйте штрихкод или введите артикул';

  @override
  String get invAddProduct => 'Добавить товар';

  @override
  String get invEmptyDoc => 'Документ пуст';

  @override
  String get invEmptyDocMessage =>
      'Отсканируйте товар или нажмите «Добавить товар». Для приёмки по заказу поставщику используйте раздел «Закупки».';

  @override
  String get invSpecifyPurchasePrice => 'Укажите цену закупки';

  @override
  String get invNewPrice => 'Новая цена';

  @override
  String get invNoPricePermission => 'Нет права менять цены';

  @override
  String get invInvalidPrice => 'Неверная цена';

  @override
  String get invDeleteLine => 'Удалить строку';

  @override
  String invLineInfo(String qty, String price) {
    return 'Остаток $qty · розн. $price';
  }

  @override
  String invMarkupPart(String percent) {
    return 'наценка $percent%';
  }

  @override
  String get invNewCount => 'Новая инвентаризация';

  @override
  String get invSelectCount => 'Выберите инвентаризацию';

  @override
  String get invSelectCountMessage =>
      'или создайте новую, чтобы сверить фактические остатки с учётными';

  @override
  String get invNoCountsYet => 'Инвентаризаций ещё не было';

  @override
  String get invNoCountsMessage =>
      'Регулярные пересчёты помогают вовремя находить недостачи';

  @override
  String invCountTitle(String number) {
    return 'Инвентаризация №$number';
  }

  @override
  String get invAddToCount => 'Добавить товар в инвентаризацию';

  @override
  String get invAddAtLeastOneProduct => 'Добавьте хотя бы один товар';

  @override
  String get invSelected => 'Выбранные';

  @override
  String get invCategoryRequired => 'Категория *';

  @override
  String get invRemove => 'Убрать';

  @override
  String get invCountNoteHint => 'зона, ответственный';

  @override
  String get invCountCreateInfo =>
      'Учётные остатки фиксируются в момент создания. Продажи во время пересчёта учитываются при проведении: расхождение считается от текущего остатка.';

  @override
  String invProductNotFound(String code) {
    return 'Товар «$code» не найден';
  }

  @override
  String get invNotInSheetTitle => 'Товара нет в ведомости';

  @override
  String invNotInSheetMessage(String name, String unit) {
    return '«$name» не входит в эту инвентаризацию. Добавить и засчитать 1 $unit?';
  }

  @override
  String invAddedOne(String name) {
    return '«$name» добавлен: 1';
  }

  @override
  String invCompleteTitle(String number) {
    return 'Провести инвентаризацию №$number?';
  }

  @override
  String invCompleteCounted(String counted, String total) {
    return 'Посчитано позиций: $counted из $total.';
  }

  @override
  String invCompleteUncounted(String count) {
    return 'Не посчитано: $count — их остатки не изменятся.';
  }

  @override
  String invCompleteSurplus(String count) {
    return 'Излишки: $count поз.';
  }

  @override
  String invCompleteSurplusSum(String count, String amount) {
    return 'Излишки: $count поз. на $amount';
  }

  @override
  String invCompleteShortage(String count) {
    return 'Недостача: $count поз.';
  }

  @override
  String invCompleteShortageSum(String count, String amount) {
    return 'Недостача: $count поз. на $amount';
  }

  @override
  String invCompleteNet(String amount) {
    return 'Итог: $amount';
  }

  @override
  String invCompleteChanged(String count) {
    return 'По $count поз. остаток изменился после создания ведомости (продажи, приходы). Расхождения рассчитаны от ТЕКУЩЕГО остатка.';
  }

  @override
  String get invCompleteFinal =>
      'Остатки будут приведены к фактическим. Действие необратимо.';

  @override
  String invCountCompletedToast(String number) {
    return 'Инвентаризация №$number проведена';
  }

  @override
  String invCancelCountTitle(String number) {
    return 'Отменить инвентаризацию №$number?';
  }

  @override
  String get invCancelCountMessage =>
      'Введённые данные сохранятся в истории, остатки не изменятся.';

  @override
  String get invCancelCount => 'Отменить инвентаризацию';

  @override
  String get invCountCancelledToast => 'Инвентаризация отменена';

  @override
  String get invCountNotFound => 'Инвентаризация не найдена';

  @override
  String invChangedWarning(String count) {
    return 'По $count поз. учётный остаток изменился после создания ведомости (продажи/приходы). Расхождение считается от текущего остатка.';
  }

  @override
  String get invScanPlusOne => 'Скан: +1 к факту';

  @override
  String get invSearchInSheet => 'Поиск в ведомости';

  @override
  String invFilterAllCount(String count) {
    return 'Все ($count)';
  }

  @override
  String invFilterUncounted(String count) {
    return 'Не посчитано ($count)';
  }

  @override
  String get invDiscrepancies => 'Расхождения';

  @override
  String get invNoLinesForFilter => 'Нет строк по фильтру';

  @override
  String invCreatedAt(String date) {
    return 'создана $date';
  }

  @override
  String invCompletedAt(String date) {
    return 'проведена $date';
  }

  @override
  String invCountedChip(String counted, String total) {
    return 'Посчитано $counted/$total';
  }

  @override
  String invSurplusChip(String count) {
    return 'Излишки $count';
  }

  @override
  String invShortageChip(String count) {
    return 'Недостача $count';
  }

  @override
  String get invSaving => 'Сохранение…';

  @override
  String get invDraftSaved => 'Черновик сохранён';

  @override
  String get invBlank => 'Бланк';

  @override
  String get invCancelShort => 'Отменить';

  @override
  String get invProductBookStock => 'Товар · учётный остаток';

  @override
  String get invFact => 'Факт';

  @override
  String get invDiff => 'Разница';

  @override
  String invBookShort(String qty) {
    return 'учёт $qty';
  }

  @override
  String invNowShort(String qty) {
    return 'сейчас $qty';
  }

  @override
  String get invFactHint => 'факт';

  @override
  String get invNotCounted => 'не считали';

  @override
  String get invNumberQ => 'число?';

  @override
  String get invInvalidShort => 'неверно';

  @override
  String invSheetTitle(String number) {
    return 'Инвентаризационная ведомость №$number';
  }

  @override
  String invPageOf(String page, String total) {
    return 'стр. $page/$total';
  }

  @override
  String invSheetSubtitle(String store, String date, String count) {
    return '$store · создана $date · позиций $count';
  }

  @override
  String get invCountedBy => 'Считал: ____________________';

  @override
  String get invCheckedBy => 'Проверил: ____________________';

  @override
  String invDateLine(String date) {
    return 'Дата: $date';
  }

  @override
  String get invBarcodeSku => 'Штрихкод / арт.';

  @override
  String get invUnitShort => 'Ед.';

  @override
  String get invBook => 'Учёт';

  @override
  String invCountFileName(String number) {
    return 'Инвентаризация $number';
  }

  @override
  String invReceiptPdfTitle(String number, String date) {
    return 'Приходная накладная №$number от $date';
  }

  @override
  String get invHandedBy => 'Сдал: ____________________';

  @override
  String get invAcceptedByLine => 'Принял: ____________________';

  @override
  String get invBasis => 'Основание';

  @override
  String invSupplierOrderRef(String number) {
    return 'Заказ поставщику №$number';
  }

  @override
  String get invReversedCaps => 'СТОРНИРОВАН';

  @override
  String get invNewRetailShort => 'Новая розн.';

  @override
  String invReceiptFileName(String number) {
    return 'Приход $number';
  }

  @override
  String get mktTitle => 'Маркетинг';

  @override
  String get mktTabPromos => 'Акции';

  @override
  String get mktTabGiftCards => 'Сертификаты';

  @override
  String get mktTabLoyalty => 'Лояльность';

  @override
  String get mktTabMailing => 'Рассылки';

  @override
  String get mktTypePercentOrder => 'Скидка % на чек';

  @override
  String get mktTypeAmountOrder => 'Скидка суммой на чек';

  @override
  String get mktTypePercentCategory => 'Скидка % на категорию';

  @override
  String get mktTypePercentProduct => 'Скидка % на товар';

  @override
  String get mktTypeBuyXGetY => 'Купи X — получи Y';

  @override
  String get mktTypePromoCode => 'Промокод';

  @override
  String get mktHelpPercentOrder =>
      'Процент от суммы чека после скидок по позициям. Можно задать минимальную сумму чека. Из скидок на чек применяется только одна — самая выгодная.';

  @override
  String get mktHelpAmountOrder =>
      'Фиксированная сумма скидки на чек (например, 10 000 при покупке от 100 000). Распределяется по позициям пропорционально — возвраты считаются точно.';

  @override
  String get mktHelpPercentCategory =>
      'Процент на все товары выбранной категории. Не суммируется с другими скидками на позицию и персональной скидкой клиента — берётся лучшая.';

  @override
  String get mktHelpPercentProduct =>
      'Процент на один товар. Не суммируется с другими скидками на позицию — берётся лучшая.';

  @override
  String get mktHelpBuyXGetY =>
      'При покупке X штук товара ещё Y штук бесплатно. Например, «2+1»: каждая третья единица бесплатно. Работает на одну позицию товара.';

  @override
  String get mktHelpPromoCode =>
      'Скидка на чек по коду, который кассир вводит на кассе. Можно задать процент или сумму и минимальную сумму чека. Конкурирует с другими скидками на чек — применяется лучшая.';

  @override
  String get mktStatusActive => 'Активна';

  @override
  String get mktStatusScheduled => 'Запланирована';

  @override
  String get mktStatusFinished => 'Завершена';

  @override
  String get mktStatusDisabled => 'Выключена';

  @override
  String get mktErrEnterName => 'Введите название акции';

  @override
  String get mktErrSelectType => 'Выберите тип акции';

  @override
  String get mktErrEnterPercent => 'Укажите процент скидки';

  @override
  String get mktErrPercentRange =>
      'Процент скидки должен быть больше 0 и не больше 100';

  @override
  String get mktErrEnterAmount => 'Укажите сумму скидки';

  @override
  String mktErrPromoCodeMinAmount(String amount) {
    return 'Сумма скидки по промокоду должна быть не меньше $amount';
  }

  @override
  String get mktErrDiscountAboveMin =>
      'Скидка не может быть больше минимальной суммы чека';

  @override
  String get mktErrSelectCategory => 'Выберите категорию';

  @override
  String get mktErrSelectProduct => 'Выберите товар';

  @override
  String get mktErrBuyMin => '«Купи» — минимум 1 шт.';

  @override
  String get mktErrGetMin => '«Получи» — минимум 1 шт.';

  @override
  String get mktErrQtyTooLarge => 'Слишком большое количество';

  @override
  String get mktErrEnterCode => 'Введите промокод';

  @override
  String get mktErrCodeTooShort => 'Промокод — минимум 3 символа';

  @override
  String get mktErrCodeTooLong => 'Промокод слишком длинный';

  @override
  String get mktErrCodeChars => 'Промокод: только буквы, цифры, «-» и «_»';

  @override
  String mktErrCodeTaken(String code) {
    return 'Промокод $code уже используется в другой активной акции';
  }

  @override
  String get mktErrMinNegative =>
      'Минимальная сумма не может быть отрицательной';

  @override
  String get mktErrEndBeforeStart =>
      'Дата окончания должна быть не раньше даты начала';

  @override
  String mktDescMinOrder(String amount) {
    return ' от $amount';
  }

  @override
  String mktDescOrder(String value, String min) {
    return '$value на чек$min';
  }

  @override
  String mktDescCategory(String value, String target) {
    return '$value на категорию «$target»';
  }

  @override
  String mktDescProduct(String value, String target) {
    return '$value на «$target»';
  }

  @override
  String mktDescBuyXGetY(String buy, String get, String target) {
    return '$buy+$get: купи $buy, ещё $get бесплатно — «$target»';
  }

  @override
  String mktDescPromoCode(String code, String value, String min) {
    return 'Код $code: $value на чек$min';
  }

  @override
  String get mktPeriodUnlimited => 'Бессрочно';

  @override
  String mktPeriodUntil(String date) {
    return 'по $date';
  }

  @override
  String mktPeriodFrom(String date) {
    return 'с $date';
  }

  @override
  String get mktPromoSaved => 'Акция сохранена';

  @override
  String get mktDeletePromoTitle => 'Удалить акцию?';

  @override
  String mktDeletePromoMessage(String name) {
    return '«$name» перестанет применяться на кассе. Проданные чеки не изменятся.';
  }

  @override
  String get mktPromoDeleted => 'Акция удалена';

  @override
  String get mktPromoSearchHint => 'Название или промокод';

  @override
  String get mktNewPromo => 'Новая акция';

  @override
  String get mktTestOnReceipt => 'Проверить на чеке';

  @override
  String mktChipAll(String count) {
    return 'Все $count';
  }

  @override
  String get mktPromosEmptyTitle => 'Акций пока нет';

  @override
  String get mktPromosEmptyMessage =>
      'Создайте скидку на чек, на категорию или товар, «2+1» или промокод. Касса применит её автоматически.';

  @override
  String get mktCreatePromo => 'Создать акцию';

  @override
  String get mktPromosNoMatch => 'Нет акций с таким фильтром';

  @override
  String get mktTurnOff => 'Выключить';

  @override
  String get mktTurnOn => 'Включить';

  @override
  String get mktDuplicate => 'Дублировать';

  @override
  String get mktEditPromo => 'Редактирование акции';

  @override
  String mktCopyName(String name) {
    return '$name (копия)';
  }

  @override
  String get mktProductDeleted => 'Товар удалён';

  @override
  String get mktStartDate => 'Дата начала';

  @override
  String get mktLastDay => 'Последний день акции';

  @override
  String get mktPromoProduct => 'Товар для акции';

  @override
  String get mktNameLabel => 'Название *';

  @override
  String get mktNameHint => 'Например: Скидка выходного дня';

  @override
  String get mktEnterName => 'Введите название';

  @override
  String get mktPromoType => 'Тип акции';

  @override
  String get mktValidityPeriod => 'Период действия';

  @override
  String get mktDateFrom => 'С';

  @override
  String get mktDateTo => 'По (включительно)';

  @override
  String get mktPromoEnabled => 'Акция включена';

  @override
  String mktStatusLine(String status) {
    return 'Статус: $status';
  }

  @override
  String get mktUnlimited => 'не ограничено';

  @override
  String get mktPromoCodeLabel => 'Промокод *';

  @override
  String get mktMin3Chars => 'Минимум 3 символа';

  @override
  String get mktDiscountColon => 'Скидка:';

  @override
  String mktAmountIn(String currency) {
    return 'сумма, $currency';
  }

  @override
  String get mktCreateCategoriesFirst =>
      'Сначала создайте категории в разделе «Товары»';

  @override
  String get mktCategoryLabel => 'Категория *';

  @override
  String get mktProductLabel => 'Товар *';

  @override
  String get mktPickProduct => 'Выбрать товар…';

  @override
  String get mktBuyQty => 'Купи (шт.)';

  @override
  String get mktGetQty => 'Получи бесплатно (шт.)';

  @override
  String get mktMin1 => 'Минимум 1';

  @override
  String mktBuyGetPreview(String total, String free) {
    return 'В чеке из $total шт. — $free шт. бесплатно';
  }

  @override
  String get mktDiscountLabel => 'Скидка *';

  @override
  String get mktEnterPercent => 'Введите процент';

  @override
  String get mktPercentRangeShort => 'Больше 0 и не больше 100';

  @override
  String get mktDiscountAmountLabel => 'Сумма скидки *';

  @override
  String get mktMinOrderLabel => 'Мин. сумма чека';

  @override
  String get mktMinOrderHelper => 'Пусто — без ограничения';

  @override
  String get mktSimTitle => 'Проверка акций на чеке';

  @override
  String get mktSimAddProductTitle => 'Добавить товар в тестовый чек';

  @override
  String mktSimIntro(String count) {
    return 'Добавьте товары и посмотрите, какие скидки применит касса. Действует активных акций: $count. Скидки на позицию не суммируются — берётся лучшая из акции на товар/категорию, «N+M» и персональной скидки клиента. Из скидок на чек (акция на чек, промокод) применяется одна, самая выгодная.';
  }

  @override
  String get mktSimAddProduct => 'Добавить товар';

  @override
  String get mktSimCustomerDiscount => 'Скидка клиента';

  @override
  String get mktSim0To100 => 'От 0 до 100';

  @override
  String get mktSimEmptyTitle => 'Тестовый чек пуст';

  @override
  String get mktSimEmptyMessage => 'Добавьте один или несколько товаров';

  @override
  String mktSimPricePer(String price, String unit) {
    return '$price за $unit';
  }

  @override
  String mktSimOrderShare(String amount) {
    return '−$amount · доля скидки на чек';
  }

  @override
  String get mktSimQtyPositive => 'Укажите количество больше нуля';

  @override
  String get mktSimQtyShort => 'Кол-во';

  @override
  String get mktRemove => 'Убрать';

  @override
  String get mktSimSubtotal => 'Сумма без скидок';

  @override
  String get mktSimToPay => 'К оплате';

  @override
  String get mktSimCodeAccepted => 'Промокод принят';

  @override
  String get mktSimCodeRejected =>
      'Промокод не найден, не активен или сумма чека меньше минимальной';

  @override
  String get mktSimApplied => 'Применённые скидки:';

  @override
  String get mktSimNone => 'нет';

  @override
  String get mktLoyaltyProgram => 'Бонусная программа';

  @override
  String get mktLoyaltyOn => 'Включена';

  @override
  String get mktLoyaltyOff => 'Выключена';

  @override
  String get mktLoyaltyEarn => 'Начисление';

  @override
  String mktLoyaltyEarnValue(String percent) {
    return '$percent% от оплаченной суммы (без учёта оплаты бонусами)';
  }

  @override
  String get mktLoyaltyRedeem => 'Оплата бонусами';

  @override
  String mktLoyaltyRedeemValue(String percent) {
    return 'до $percent% суммы чека';
  }

  @override
  String get mktLoyaltyRate => 'Курс';

  @override
  String mktLoyaltyRateValue(String amount) {
    return '1 бонус = $amount';
  }

  @override
  String get mktLoyaltyNote =>
      'Бонусы начисляются автоматически при продаже клиенту и списываются пропорционально при возврате.';

  @override
  String get mktOpenSettings => 'Открыть настройки';

  @override
  String get mktNoSettingsRight => 'Нет права изменять настройки';

  @override
  String get mktEditInSettings => 'Изменить в настройках';

  @override
  String get mktStatLiability => 'Бонусные обязательства';

  @override
  String get mktStatLiabilityShort => 'Обязательства';

  @override
  String mktStatHolders(String count) {
    return 'у $count клиентов';
  }

  @override
  String get mktStatEarned30 => 'Начислено за 30 дней';

  @override
  String get mktStatEarned => 'Начислено';

  @override
  String get mktStat30Days => 'за 30 дней';

  @override
  String get mktStatSpent30 => 'Списано за 30 дней';

  @override
  String get mktStatSpent => 'Списано';

  @override
  String get mktStatAdjusted30 => 'Корректировки за 30 дней';

  @override
  String get mktStatAdjusted => 'Корректировки';

  @override
  String get mktStatAdjustedHint => 'вручную и при возвратах';

  @override
  String mktTplBirthday(String name, String store) {
    return 'Здравствуйте, $name! $store поздравляет вас с днём рождения! Ждём вас за подарком.';
  }

  @override
  String mktTplSleeping(String name, String store, String bonus) {
    return 'Здравствуйте, $name! Давно не виделись — в $store много новинок. Ваши бонусы: $bonus. Ждём вас!';
  }

  @override
  String mktTplDebt(String name, String store, String debt) {
    return 'Здравствуйте, $name! Напоминаем, что ваш долг в $store составляет $debt. Спасибо!';
  }

  @override
  String mktTplVip(String name, String store, String bonus) {
    return 'Здравствуйте, $name! Вы — наш VIP-клиент. Для вас в $store особые предложения. Ваши бонусы: $bonus.';
  }

  @override
  String mktTplAll(String name) {
    return 'Здравствуйте, $name! ';
  }

  @override
  String get mktOurStore => 'наш магазин';

  @override
  String get mktSegment => 'Сегмент';

  @override
  String get mktMessageText => 'Текст сообщения';

  @override
  String mktTemplateVars(
    String name,
    String fullname,
    String store,
    String debt,
    String bonus,
    String discount,
  ) {
    return 'Подстановки: $name — имя, $fullname, $store, $debt, $bonus, $discount';
  }

  @override
  String mktPhonesCopied(String count) {
    return 'Скопировано телефонов: $count';
  }

  @override
  String mktCopyPhones(String count) {
    return 'Копировать телефоны ($count)';
  }

  @override
  String mktMessagesCopied(String count) {
    return 'Скопировано сообщений: $count';
  }

  @override
  String get mktCopyMessages => 'Копировать сообщения';

  @override
  String get mktSmsNote =>
      'SMS-шлюз не подключён: скопируйте список и отправьте сообщения через мессенджер или телефон.';

  @override
  String mktNoPhoneNote(String count) {
    return 'Без телефона: $count клиент(ов) — они не попадут в список.';
  }

  @override
  String get mktNoPhone => 'нет телефона';

  @override
  String get mktToday => 'сегодня';

  @override
  String mktInDays(String days) {
    return 'через $days дн.';
  }

  @override
  String mktLastVisit(String date) {
    return 'был $date';
  }

  @override
  String mktPurchases(String amount) {
    return 'покупки $amount';
  }

  @override
  String get mktOverdue => 'просрочен';

  @override
  String get mktSegmentEmpty => 'В сегменте никого нет';

  @override
  String get mktGiftActive => 'Активен';

  @override
  String get mktGiftUsed => 'Использован';

  @override
  String get mktGiftExpired => 'Истёк';

  @override
  String get mktGiftBlocked => 'Заблокирован';

  @override
  String get mktErrUniqueCode => 'Не удалось сгенерировать уникальный код';

  @override
  String get mktErrUnblockVoided =>
      'Продажа сертификата аннулирована — разблокировка невозможна';

  @override
  String mktBlockTitle(String code) {
    return 'Заблокировать $code?';
  }

  @override
  String get mktGiftBlockedMsg => 'Сертификат заблокирован';

  @override
  String get mktGiftUnblockedMsg => 'Сертификат разблокирован';

  @override
  String get mktGiftSalesSegment => 'Продажи';

  @override
  String get mktNoSellRight => 'Нет права продавать';

  @override
  String get mktStatActiveShort => 'Активных';

  @override
  String get mktStatActive => 'Активных сертификатов';

  @override
  String get mktStatActiveHint => 'сертификатов';

  @override
  String get mktStatOutstandingShort => 'К погашению';

  @override
  String get mktStatOutstanding => 'Остаток к погашению';

  @override
  String get mktStatOutstandingHintShort => 'на сертификатах';

  @override
  String get mktStatOutstandingHint => 'обязательства магазина';

  @override
  String get mktGiftSearchHint => 'Код или клиент';

  @override
  String get mktGiftSaleTooltip => 'Продажа сертификата (аванс, не выручка)';

  @override
  String get mktIssue => 'Выпустить';

  @override
  String get mktCheckBalance => 'Проверить баланс';

  @override
  String get mktGiftsEmptyTitle => 'Сертификатов пока нет';

  @override
  String get mktGiftsEmptyMessage =>
      'Продавайте подарочные сертификаты — их можно принять в оплату на кассе.';

  @override
  String get mktIssueGift => 'Выпустить сертификат';

  @override
  String get mktCustomerLower => 'клиент';

  @override
  String get mktCodeCopied => 'Код скопирован';

  @override
  String mktOfAmount(String amount) {
    return 'из $amount';
  }

  @override
  String get mktFaceValueLower => 'номинал';

  @override
  String mktIssuedOn(String date) {
    return 'выпущен $date';
  }

  @override
  String get mktNoExpiryLower => 'бессрочный';

  @override
  String mktUntil(String date) {
    return 'до $date';
  }

  @override
  String get mktSaleDocument => 'Документ продажи';

  @override
  String get mktGiftBlank => 'Бланк сертификата';

  @override
  String get mktCopyCode => 'Копировать код';

  @override
  String get mktUnblock => 'Разблокировать';

  @override
  String get mktBlock => 'Заблокировать';

  @override
  String get mktGiftBalanceTitle => 'Баланс сертификата';

  @override
  String get mktCodeEnterOrScan => 'Код (введите или отсканируйте)';

  @override
  String get mktFind => 'Найти';

  @override
  String mktFaceValueAmount(String amount) {
    return 'Номинал $amount';
  }

  @override
  String get mktNoExpiry => 'Бессрочный';

  @override
  String mktValidUntil(String date) {
    return 'Действует до $date';
  }

  @override
  String get mktPdfGiftTitle => 'ПОДАРОЧНЫЙ СЕРТИФИКАТ';

  @override
  String mktPdfValidUntil(String date) {
    return 'Действителен до $date';
  }

  @override
  String get mktPdfGiftNote =>
      'Предъявите сертификат на кассе.\nОбмену на деньги не подлежит.';

  @override
  String mktVoidSaleTitle(String number) {
    return 'Аннулировать продажу №$number';
  }

  @override
  String get mktReasonRequired => 'Причина *';

  @override
  String mktVoidSaleQuestion(String number) {
    return 'Аннулировать продажу №$number?';
  }

  @override
  String mktVoidSaleMessage(String code, String amount, String payments) {
    return 'Сертификат $code будет заблокирован. Верните покупателю $amount: $payments. Возврат попадёт в текущую смену.';
  }

  @override
  String get mktVoid => 'Аннулировать';

  @override
  String mktSaleVoided(String number) {
    return 'Продажа №$number аннулирована';
  }

  @override
  String get mktBlank => 'Бланк';

  @override
  String get mktNoSaleDocument =>
      'Сертификат выпущен до появления документов продажи — документа нет, аннулирование недоступно.';

  @override
  String mktFaceValueLowerAmount(String amount) {
    return 'номинал $amount';
  }

  @override
  String get mktNoVoidRight => 'Нет права аннулировать продажи';

  @override
  String get mktOpenShiftToVoid => 'Откройте смену, чтобы аннулировать продажу';

  @override
  String get mktChecking => 'Проверяем…';

  @override
  String mktSaleNumber(String number) {
    return 'Продажа №$number';
  }

  @override
  String mktVoidedAt(String date) {
    return 'Аннулирована $date';
  }

  @override
  String get mktVoidTooltip =>
      'Сертификат будет заблокирован, деньги возвращаются покупателю';

  @override
  String get mktVoidSale => 'Аннулировать продажу';

  @override
  String get mktSaleCompleted => 'Проведена';

  @override
  String get mktSaleVoidedStatus => 'Аннулирована';

  @override
  String get mktPeriod7Days => '7 дней';

  @override
  String get mktPeriod30Days => '30 дней';

  @override
  String get mktPeriodAllTime => 'Всё время';

  @override
  String get mktGiftSalesEmptyTitle => 'Продаж сертификатов нет';

  @override
  String get mktGiftSalesEmptyMessage =>
      'За выбранный период нет документов с таким статусом.';

  @override
  String mktCompletedFor(String amount) {
    return 'проведено на $amount';
  }

  @override
  String mktVoidedCount(String count) {
    return 'аннулировано: $count';
  }

  @override
  String mktReasonLower(String reason) {
    return 'причина: $reason';
  }

  @override
  String get mktPayMixed => 'Смешанная';

  @override
  String get mktValidUntilInclusive => 'Действует до (включительно)';

  @override
  String mktPayExceeds(String amount) {
    return 'Карта и перевод больше номинала на $amount';
  }

  @override
  String get mktPayEnterCardTransfer => 'Укажите сумму картой и/или переводом';

  @override
  String mktPayTenderedShort(String amount) {
    return 'Получено меньше, чем нужно: $amount';
  }

  @override
  String get mktCodeExists => 'Такой код уже существует';

  @override
  String get mktValidUntilLabel => 'Действует до';

  @override
  String get mktNoExpiryCap => 'Без срока';

  @override
  String get mktBuyerOptional => 'Покупатель (необязательно)';

  @override
  String get mktNotSelected => 'Не выбран';

  @override
  String get mktRemoveBuyer => 'Убрать покупателя';

  @override
  String get mktGiftSaleTitle => 'Продажа сертификата';

  @override
  String get mktShiftClosedNote =>
      'Смена закрыта: откройте смену, чтобы продать сертификат.';

  @override
  String mktShiftAdvanceNote(String number) {
    return 'Смена №$number. Это аванс, не выручка: оплата попадёт в раздел «Сертификаты» отчёта смены.';
  }

  @override
  String get mktFaceValueRequired => 'Номинал *';

  @override
  String get mktGiftCodeRequired => 'Код сертификата *';

  @override
  String get mktGiftCodeHelper =>
      'Сгенерирован автоматически; можно отсканировать или ввести свой';

  @override
  String get mktGenerate => 'Сгенерировать';

  @override
  String get mktMin6Chars => 'Минимум 6 символов';

  @override
  String get mktMax32Chars => 'Максимум 32 символа';

  @override
  String get mktSellGift => 'Продать сертификат';

  @override
  String get mktTenderedCash => 'Получено наличными';

  @override
  String get mktTenderedHelper => 'Пусто — без сдачи';

  @override
  String get mktSlipNumber => 'Номер слипа (необязательно)';

  @override
  String get mktTransferNumber => 'Номер перевода (необязательно)';

  @override
  String get mktInCash => 'Наличными';

  @override
  String mktPrintFailed(String error) {
    return 'Не удалось напечатать: $error';
  }

  @override
  String get mktGiftSold => 'Сертификат продан';

  @override
  String notifOutOfStockTitle(String name) {
    return 'Закончился товар: $name';
  }

  @override
  String notifOutOfStockBody(String qty) {
    return 'Остаток $qty. Оформите закупку, чтобы не терять продажи.';
  }

  @override
  String notifLowStockTitle(String name) {
    return 'Мало товара: $name';
  }

  @override
  String notifLowStockBody(String qty, String min) {
    return 'Остаток $qty, минимальный — $min.';
  }

  @override
  String notifDebtTitle(String name) {
    return 'Просрочен долг: $name';
  }

  @override
  String notifDebtBody(String overdue, String date) {
    return 'Просрочено $overdue, срок оплаты истёк $date. Напомните клиенту об оплате.';
  }

  @override
  String notifDebtBodyPartial(String overdue, String debt, String date) {
    return 'Просрочено $overdue из $debt, срок оплаты истёк $date. Напомните клиенту об оплате.';
  }

  @override
  String notifBirthdayTitle(String name) {
    return 'День рождения: $name';
  }

  @override
  String get notifBirthdayBody =>
      'Поздравьте клиента и предложите подарок или бонусы.';

  @override
  String notifBirthdayBodyAge(String age) {
    return 'Исполняется $age. Поздравьте клиента и предложите подарок или бонусы.';
  }

  @override
  String notifShiftTitle(String number, String hours) {
    return 'Смена №$number открыта $hours ч';
  }

  @override
  String notifShiftBody(String date, String time) {
    return 'Открыта $date в $time. Закройте смену и сверьте наличные в кассе.';
  }

  @override
  String get notifKindLowStock => 'Мало товара';

  @override
  String get notifKindOutOfStock => 'Нет в наличии';

  @override
  String get notifKindDebt => 'Долги';

  @override
  String get notifKindBirthday => 'Дни рождения';

  @override
  String get notifKindShift => 'Смены';

  @override
  String get notifKindTask => 'Задачи';

  @override
  String get notifKindSystem => 'Система';

  @override
  String get notifDeleted => 'Уведомление удалено';

  @override
  String get notifUndo => 'Отменить';

  @override
  String get notifCheckNone => 'Проверка завершена — новых уведомлений нет';

  @override
  String notifCheckCreated(String count) {
    return 'Новых уведомлений: $count';
  }

  @override
  String get notifDeleteReadTitle => 'Удалить прочитанные?';

  @override
  String notifDeleteReadMessage(String count) {
    return 'Будет удалено уведомлений: $count. Непрочитанные останутся.';
  }

  @override
  String get notifDeleteReadDone => 'Прочитанные уведомления удалены';

  @override
  String get notifNoAccess =>
      'Нет доступа к разделу — обратитесь к администратору';

  @override
  String get notifAllReadShort => 'Все прочитаны';

  @override
  String notifUnreadCount(String count) {
    return 'Непрочитанных: $count';
  }

  @override
  String get notifCheckNowTooltip => 'Проверить сейчас (F5)';

  @override
  String get notifCheckNow => 'Проверить сейчас';

  @override
  String get notifReadAll => 'Прочитать все';

  @override
  String get notifAllRead => 'Все уведомления прочитаны';

  @override
  String get notifDeleteRead => 'Удалить прочитанные';

  @override
  String get notifEmptyTitle => 'Уведомлений нет';

  @override
  String get notifEmptyMessage =>
      'Здесь появятся напоминания о заканчивающихся товарах, просроченных долгах, днях рождения клиентов и незакрытых сменах. Проверка идёт автоматически каждые 10 минут.';

  @override
  String notifFilterAll(String count) {
    return 'Все ($count)';
  }

  @override
  String notifFilterUnread(String count) {
    return 'Непрочитанные ($count)';
  }

  @override
  String get notifNoneOfKind => 'Нет уведомлений этого типа';

  @override
  String get notifGoTo => 'Перейти';

  @override
  String get notifMarkUnread => 'Отметить непрочитанным';

  @override
  String get notifMarkRead => 'Отметить прочитанным';

  @override
  String posNotFound(String code) {
    return 'Не найдено: $code';
  }

  @override
  String get posShiftNotOpenSell =>
      'Смена не открыта. Откройте смену, чтобы продавать';

  @override
  String get posHints =>
      'F2 поиск · F4 клиент · F8 отложить · F9 отложенные · F12 / Ctrl+Enter оплата · Del удалить · +/− количество · ↑↓ выбор позиции · Esc очистить поиск · 3*код — несколько штук';

  @override
  String get posShiftNotOpenBanner => 'Смена не открыта — продажи недоступны';

  @override
  String get posShiftNotOpenAskManager =>
      'Смена не открыта. Попросите менеджера открыть смену';

  @override
  String get posOpenShift => 'Открыть смену';

  @override
  String get posCartEmpty => 'Чек пуст';

  @override
  String posTotalPositions(String count) {
    return 'Итого · $count поз.';
  }

  @override
  String posReceiptPositions(String count) {
    return 'Чек · $count поз.';
  }

  @override
  String get posParkedReceipts => 'Отложенные чеки';

  @override
  String get posCartActions => 'Действия с чеком';

  @override
  String get posPark => 'Отложить чек';

  @override
  String get posSeller => 'Продавец';

  @override
  String get posSellGiftCard => 'Продать сертификат';

  @override
  String get posClearCart => 'Очистить чек';

  @override
  String get posNoSellPerm => 'Нет права продавать';

  @override
  String get posNeedOpenShift => 'Нужна открытая смена';

  @override
  String posProductInactive(String name) {
    return 'Товар «$name» снят с продажи';
  }

  @override
  String get posBadMultiplier => 'Неверный множитель. Пример: 3*4780000000011';

  @override
  String get posMultipleFound =>
      'Найдено несколько товаров — выберите нужный в списке';

  @override
  String posProductNotFound(String code) {
    return 'Товар «$code» не найден';
  }

  @override
  String get posNoPricePerm => 'Нет права изменять цены';

  @override
  String get posLineDiscount => 'Скидка на позицию';

  @override
  String posLineDiscountFor(String name) {
    return 'Скидка на «$name»';
  }

  @override
  String get posOrderDiscount => 'Скидка на чек';

  @override
  String get posPromoCode => 'Промокод';

  @override
  String get posCode => 'Код';

  @override
  String get posClearCartQ => 'Очистить чек?';

  @override
  String posClearCartMessage(String count) {
    return 'Все $count поз. будут удалены из чека.';
  }

  @override
  String get posNothingToPark => 'Нечего откладывать — чек пуст';

  @override
  String get posParkNote => 'Комментарий (имя покупателя и т.п.)';

  @override
  String get posParkedDone => 'Чек отложен (F9 — список отложенных)';

  @override
  String get posAutoParked => 'Автоматически отложен';

  @override
  String posRestoredRepriced(String count) {
    return 'Чек восстановлен. Цены обновлены по прайсу: $count поз.';
  }

  @override
  String get posRestored => 'Чек восстановлен';

  @override
  String get posGiftNeedShift => 'Откройте смену, чтобы продать сертификат';

  @override
  String get posShiftNotOpen => 'Смена не открыта';

  @override
  String get posGiftNeedShiftDot => 'Откройте смену, чтобы продать сертификат.';

  @override
  String get posNoShiftPerm =>
      'Нет права открывать смену — обратитесь к менеджеру';

  @override
  String get posShiftOpened => 'Смена открыта. Можно продавать';

  @override
  String get posCartEmptyAdd => 'Чек пуст — добавьте товары';

  @override
  String posPromoInvalid(String code) {
    return 'Промокод «$code» недействителен — удалите или исправьте его';
  }

  @override
  String get posManualDiscounts => 'Ручные скидки в чеке';

  @override
  String get posManualOverLimit =>
      'Ручные скидки превышают ваш лимит — нужно подтверждение менеджера или уменьшите скидку';

  @override
  String posQtyIntegerOnly(String unit) {
    return 'Для «$unit» только целое количество';
  }

  @override
  String get posQtyTooSmall => 'Слишком маленькое количество';

  @override
  String get posLineNotFound => 'Позиция не найдена';

  @override
  String get posDiscountNegative => 'Скидка не может быть отрицательной';

  @override
  String get posDiscountOver100 => 'Скидка не может превышать 100%';

  @override
  String get posDiscountOverLine => 'Скидка больше суммы позиции';

  @override
  String get posDiscountOverCart => 'Скидка больше суммы чека';

  @override
  String get posCartEmptyHint =>
      'Отсканируйте штрихкод или выберите товар в каталоге';

  @override
  String posPositions(String count) {
    return '$count поз.';
  }

  @override
  String get posSellerTooltip => 'Продавец-консультант (для мотивации)';

  @override
  String get posParkedTooltip => 'Отложенные чеки (F9)';

  @override
  String get posParkedShort => 'Отложенные';

  @override
  String get posCustomerF4 => 'Клиент (F4)';

  @override
  String posCustDiscount(String percent) {
    return 'скидка $percent%';
  }

  @override
  String posCustBonus(String amount) {
    return 'бонусы $amount';
  }

  @override
  String posCustDebt(String amount) {
    return 'долг $amount';
  }

  @override
  String posCustDebtLimit(String amount) {
    return 'лимит $amount';
  }

  @override
  String get posDetachCustomer => 'Убрать клиента из чека';

  @override
  String get posPromotion => 'Акция';

  @override
  String get posManualDiscount => 'Ручная скидка';

  @override
  String get posApprovedMark => '(подтв.)';

  @override
  String posOrderDiscountLine(String amount) {
    return 'Скидка на чек: −$amount';
  }

  @override
  String posOnlyInStock(String qty) {
    return 'На складе только $qty';
  }

  @override
  String get posLess => 'Меньше (−)';

  @override
  String get posMore => 'Больше (+)';

  @override
  String get posEditPrice => 'Изменить цену';

  @override
  String get posRemoveLine => 'Удалить позицию (Del)';

  @override
  String posPromoInvalidChip(String code) {
    return '$code — недействителен';
  }

  @override
  String get posRemovePromo => 'Убрать промокод';

  @override
  String posOrderDiscountValue(String value) {
    return 'Скидка на чек $value';
  }

  @override
  String get posRemoveDiscount => 'Убрать скидку';

  @override
  String get posSubtotal => 'Подытог';

  @override
  String get posVatIncluded => 'в т.ч. НДС';

  @override
  String posDiscountCalcFailed(String error) {
    return 'Не удалось рассчитать скидки: $error';
  }

  @override
  String get posOpenShiftToSell => 'Откройте смену, чтобы продавать';

  @override
  String get posAddProducts => 'Добавьте товары в чек';

  @override
  String get posPayTooltip => 'Оплата (F12 или Ctrl+Enter)';

  @override
  String get posPay => 'Оплатить';

  @override
  String get posPayF12 => 'Оплатить  ·  F12';

  @override
  String posNonCashOver(String amount) {
    return 'Безналичная оплата больше суммы чека на $amount';
  }

  @override
  String posMissing(String amount) {
    return 'Не хватает $amount';
  }

  @override
  String get posCashNotNeeded => 'Наличные не нужны — чек уже оплачен';

  @override
  String get posDebtDue => 'Срок возврата долга';

  @override
  String posDays(String days) {
    return '$days дн.';
  }

  @override
  String get posPickDate => 'Выбрать дату';

  @override
  String posUntil(String date) {
    return 'до $date';
  }

  @override
  String posBonusMax(String amount) {
    return 'Бонусами можно оплатить не более $amount';
  }

  @override
  String posCreditExceeded(String amount) {
    return 'Превышен кредитный лимит: доступно $amount';
  }

  @override
  String get posCheckGiftCode => 'Проверьте код сертификата';

  @override
  String posGiftOnly(String amount) {
    return 'На сертификате только $amount';
  }

  @override
  String get posEnterGiftCode => 'Введите код сертификата';

  @override
  String get posGiftNotFound => 'Сертификат не найден';

  @override
  String posGiftInactive(String status) {
    return 'Сертификат не активен ($status)';
  }

  @override
  String get posGiftUsed => 'использован';

  @override
  String posGiftExpired(String date) {
    return 'Срок действия истёк $date';
  }

  @override
  String get posGiftEmpty => 'На сертификате нет средств';

  @override
  String get posAll => 'Всё';

  @override
  String get posToPay => 'К оплате';

  @override
  String posRounding(String amount) {
    return 'Округление: −$amount';
  }

  @override
  String posCustomerValue(String name) {
    return 'Клиент: $name';
  }

  @override
  String get posCloseEsc => 'Закрыть (Esc)';

  @override
  String get posCashReceived => 'Наличными получено';

  @override
  String posCashNeeded(String amount) {
    return 'Нужно наличными: $amount';
  }

  @override
  String get posNoChange => 'Без сдачи';

  @override
  String get posByCard => 'Картой';

  @override
  String get posByTransfer => 'Переводом';

  @override
  String get posMixed => 'Смешанная оплата';

  @override
  String get posTransferRef => '№ операции / комментарий (необязательно)';

  @override
  String posBonusHelper(String balance, String max) {
    return 'Баланс $balance · можно списать до $max';
  }

  @override
  String posDebtNoLimit(String debt) {
    return 'Долг $debt · лимит не задан';
  }

  @override
  String posDebtHelper(String debt, String limit, String available) {
    return 'Долг $debt из $limit · доступно $available';
  }

  @override
  String get posSelectCustomerForDebt =>
      'Для оплаты в долг или бонусами выберите клиента';

  @override
  String get posSelectCustomerForDebtF4 =>
      'Для оплаты в долг или бонусами выберите клиента (F4)';

  @override
  String get posGiftCode => 'Код сертификата';

  @override
  String posGiftBalance(String amount) {
    return 'Баланс $amount';
  }

  @override
  String get posCheck => 'Проверить';

  @override
  String get posPayByGift => 'Оплата сертификатом';

  @override
  String get posProcessing => 'Проводим…';

  @override
  String get posConfirmPay => 'Провести оплату';

  @override
  String get posConfirmPayEnter => 'Провести оплату (Enter)';

  @override
  String get posNonCashOverpay => 'Переплата безналом';

  @override
  String get posMissingLabel => 'Не хватает';

  @override
  String get posQtyWeight => 'Количество / вес';

  @override
  String get posQtyExample => 'Например: 0,75';

  @override
  String get posSalePrice => 'Цена продажи';

  @override
  String posListPrice(String amount) {
    return 'Цена по прайсу: $amount';
  }

  @override
  String get posNewPrice => 'Новая цена';

  @override
  String get posRestoreListPrice => 'Вернуть цену прайса';

  @override
  String get posNotMore100 => 'Не больше 100%';

  @override
  String posMoreThanAmount(String amount) {
    return 'Больше суммы ($amount)';
  }

  @override
  String posAmountValue(String amount) {
    return 'Сумма: $amount';
  }

  @override
  String get posPercentSeg => 'Процент, %';

  @override
  String get posDiscountPct => 'Скидка, %';

  @override
  String get posDiscountAmount => 'Скидка, сумма';

  @override
  String posDiscountSummary(String amount, String percent, String due) {
    return 'Скидка: $amount ($percent%) · к оплате $due';
  }

  @override
  String posOverLimit(String limit) {
    return 'Превышает ваш лимит $limit% — потребуется PIN менеджера';
  }

  @override
  String posYourLimit(String limit) {
    return 'Ваш лимит скидки: $limit%';
  }

  @override
  String posApproverNoPerm(String name) {
    return '$name: нет права подтверждать скидки';
  }

  @override
  String posApproverLimitNotHigher(String name) {
    return '$name: лимит скидки не выше, чем у кассира';
  }

  @override
  String posApproverLimit(String name, String limit, String requested) {
    return 'Лимит $name — $limit%, запрошено $requested%';
  }

  @override
  String get posOtherPinNeeded =>
      'Нужен PIN другого сотрудника (менеджера или владельца)';

  @override
  String get posManagerApproval => 'Подтверждение менеджера';

  @override
  String posApprovalMessage(String what, String percent, String limit) {
    return '$what: $percent% — больше лимита кассира ($limit%).\nМенеджер или владелец вводит свой PIN.';
  }

  @override
  String get posOpenShiftHint =>
      'Пересчитайте наличные в денежном ящике и введите сумму размена.';

  @override
  String get posOpeningCash => 'Размен в кассе';

  @override
  String get posOpeningCashHelper => 'Можно 0, если ящик пуст';

  @override
  String get posSellerConsultant => 'Продавец-консультант';

  @override
  String get posCashierDefault => 'Кассир (по умолчанию)';

  @override
  String get posNoParked => 'Нет отложенных чеков';

  @override
  String get posNoParkedHint =>
      'Отложите текущий чек (F8), чтобы обслужить следующего покупателя';

  @override
  String get posParkedTapHint => 'Нажмите на чек, чтобы вернуть его в кассу';

  @override
  String posAndMore(String count) {
    return 'и ещё $count';
  }

  @override
  String posReceiptFrom(String time) {
    return 'Чек от $time';
  }

  @override
  String get posDeleteParked => 'Удалить отложенный чек';

  @override
  String get posDeleteParkedQ => 'Удалить отложенный чек?';

  @override
  String get posDeleteParkedMessage => 'Товары из этого чека будут потеряны.';

  @override
  String get posSearchHintShort => 'Штрихкод или название';

  @override
  String get posSearchHint => 'Сканируйте штрихкод или введите название (F2)';

  @override
  String get posClearEsc => 'Очистить (Esc)';

  @override
  String get posFavorites => 'Избранное';

  @override
  String posNoResults(String query) {
    return 'По запросу «$query» нет товаров. Проверьте название или отсканируйте штрихкод.';
  }

  @override
  String get posCategoryEmpty => 'В категории нет товаров';

  @override
  String get posCatalogEmpty => 'Каталог пуст';

  @override
  String get posCatalogEmptyHint =>
      'Добавьте товары в разделе «Товары», чтобы продавать';

  @override
  String get posNoStockTracking => 'без учёта остатка';

  @override
  String posPrintFailed(String error) {
    return 'Не удалось напечатать чек: $error';
  }

  @override
  String posSaleDone(String number) {
    return 'Чек №$number проведён';
  }

  @override
  String posReceiptSum(String amount) {
    return 'Сумма чека: $amount';
  }

  @override
  String posDiscountValue(String amount) {
    return 'Скидка: $amount';
  }

  @override
  String posBonusEarned(String amount) {
    return 'Начислено бонусов: $amount';
  }

  @override
  String get posPrintAgain => 'Ещё раз';

  @override
  String get posPrintReceipt => 'Печать чека';

  @override
  String get posNewSale => 'Новая продажа (Enter)';

  @override
  String get prodRoundNearest => 'До ближайшего';

  @override
  String get prodRoundUp => 'Вверх';

  @override
  String get prodRoundDown => 'Вниз';

  @override
  String get prodRoundNone => 'Без округления';

  @override
  String prodRoundTo(String amount) {
    return 'До $amount';
  }

  @override
  String get prodStockAll => 'Все остатки';

  @override
  String get prodStockIn => 'В наличии';

  @override
  String get prodStockLow => 'Мало';

  @override
  String get prodStockOut => 'Нет в наличии';

  @override
  String get prodStockNegative => 'Минус';

  @override
  String get prodActive => 'Активные';

  @override
  String get prodArchive => 'Архив';

  @override
  String get prodSortName => 'По названию';

  @override
  String get prodSortPrice => 'По цене';

  @override
  String get prodSortStock => 'По остатку';

  @override
  String get prodSortMargin => 'По марже';

  @override
  String get prodSortUpdated => 'По изменению';

  @override
  String get prodUnitShort => 'Ед.';

  @override
  String get prodDelimTab => 'табуляция';

  @override
  String get prodDelimSemicolon => 'точка с запятой';

  @override
  String get prodDelimComma => 'запятая';

  @override
  String prodImpErrMissing(String field) {
    return '$field: не указана';
  }

  @override
  String prodImpErrNegative(String field) {
    return '$field: не может быть отрицательной';
  }

  @override
  String prodImpErrNotNumber(String field, String value) {
    return '$field: «$value» — не число';
  }

  @override
  String get prodImpErrNoName => 'Не указано название';

  @override
  String get prodNameTooLong => 'Название длиннее 200 символов';

  @override
  String prodImpErrBarcodeSci(String code) {
    return 'Штрихкод «$code» испорчен Excel (экспоненциальный формат)';
  }

  @override
  String prodImpErrBarcodeDup(String code, String line) {
    return 'Штрихкод $code повторяется (строка $line)';
  }

  @override
  String get prodEan13BadCheck => 'Неверная контрольная цифра EAN-13';

  @override
  String prodImpErrUnit(String unit) {
    return 'Неизвестная ед. изм. «$unit» (шт, кг, г, л, м, уп)';
  }

  @override
  String prodImpErrStockNotNumber(String value) {
    return 'Остаток: «$value» — не число';
  }

  @override
  String get prodImpErrStockNegative => 'Остаток не может быть отрицательным';

  @override
  String prodImpErrStockInteger(String unit) {
    return 'Остаток для «$unit» должен быть целым';
  }

  @override
  String get prodPriceBelowCost => 'Цена ниже себестоимости';

  @override
  String get prodMoveReceipt => 'Приход';

  @override
  String get prodMoveReceiptReversal => 'Сторно прихода';

  @override
  String get prodMoveWriteoff => 'Списание';

  @override
  String get prodMoveAdjustment => 'Корректировка';

  @override
  String get prodMoveInventory => 'Инвентаризация';

  @override
  String get prodMoveTransfer => 'Перемещение';

  @override
  String get prodErrEnterName => 'Введите название товара';

  @override
  String get prodErrPriceNegative => 'Цена не может быть отрицательной';

  @override
  String get prodErrCostNegative => 'Себестоимость не может быть отрицательной';

  @override
  String get prodErrWholesaleNegative =>
      'Оптовая цена не может быть отрицательной';

  @override
  String get prodErrVatRange => 'НДС должен быть от 0 до 100%';

  @override
  String get prodErrMinStockNegative =>
      'Минимальный остаток не может быть отрицательным';

  @override
  String get prodErrInitStockNegative =>
      'Начальный остаток не может быть отрицательным';

  @override
  String prodErrBarcodeUsedBy(String code, String name) {
    return 'Штрихкод $code уже используется товаром «$name»';
  }

  @override
  String prodErrInitStockInteger(String unit) {
    return 'Начальный остаток для «$unit» должен быть целым';
  }

  @override
  String get prodNoPricePerm => 'Нет права менять цены';

  @override
  String prodErrBarcodeUsedOther(String code) {
    return 'Штрихкод $code уже используется другим товаром';
  }

  @override
  String get prodErrAlreadyDeleted => 'Товар уже удалён';

  @override
  String prodErrFractionalStock(String qty, String unit) {
    return 'Остаток $qty дробный — сначала исправьте его в разделе «Склад», затем меняйте единицу на «$unit»';
  }

  @override
  String get prodErrHasHistory =>
      'По товару есть операции (продажи, движения). Его можно только архивировать.';

  @override
  String prodErrPriceNegativeFor(String name) {
    return 'Цена не может быть отрицательной: $name';
  }

  @override
  String get prodErrEnterCategoryName => 'Введите название категории';

  @override
  String get prodErrCategoryNameTooLong => 'Название длиннее 120 символов';

  @override
  String prodErrCategoryExists(String name) {
    return 'Категория «$name» уже существует';
  }

  @override
  String prodErrCategoryInUse(String count) {
    return 'В категории $count товаров — выберите, куда их перенести';
  }

  @override
  String get prodErrPickOtherCategory => 'Выберите другую категорию';

  @override
  String get prodImpNoteStockUnchanged =>
      'Остаток не меняется — используйте «Склад»';

  @override
  String prodImpNoteBarcodeTaken(String name) {
    return 'Штрихкод уже у товара «$name»';
  }

  @override
  String get prodNotFoundTitle => 'Товар не найден';

  @override
  String prodBarcodeNotInCatalog(String code) {
    return 'Штрихкода $code нет в каталоге. Создать новый товар с этим штрихкодом?';
  }

  @override
  String get prodCategories => 'Категории';

  @override
  String get prodImportFromCsv => 'Импорт из CSV';

  @override
  String get prodExportToCsv => 'Экспорт в CSV';

  @override
  String get prodByCurrentFilter => 'по текущему фильтру';

  @override
  String get prodWholeCatalog => 'весь каталог';

  @override
  String get prodNewProduct => 'Новый товар';

  @override
  String get prodNoCategory => 'Без категории';

  @override
  String get prodSearchHintShort => 'Название, артикул, штрихкод';

  @override
  String get prodSearchHint => 'Название, артикул или штрихкод (Ctrl+F)';

  @override
  String get prodAllCategories => 'Все категории';

  @override
  String get prodFavorites => 'Избранные';

  @override
  String get prodSortTooltip =>
      'Сортировка (повторный выбор — обратный порядок)';

  @override
  String prodCountLabel(String count) {
    return 'Товаров: $count';
  }

  @override
  String get prodSelect => 'Выбрать';

  @override
  String get prodNoEditPerm => 'Нет права редактировать товары';

  @override
  String get prodPricesPercent => 'Цены, %';

  @override
  String get prodPriceLabels => 'Ценники';

  @override
  String get prodToArchive => 'В архив';

  @override
  String get prodRestore => 'Вернуть';

  @override
  String get prodCancelSelection => 'Отменить выбор (Esc)';

  @override
  String prodSelectedCount(String count) {
    return 'Выбрано: $count';
  }

  @override
  String get prodTryOtherFilters => 'Попробуйте изменить фильтры';

  @override
  String prodNoResultsFor(String query) {
    return 'По запросу «$query» товаров нет';
  }

  @override
  String get prodResetFilters => 'Сбросить фильтры';

  @override
  String get prodCatalogEmpty => 'Каталог пуст';

  @override
  String get prodEmptyHintEditor =>
      'Добавьте первый товар или загрузите список из Excel (CSV).';

  @override
  String get prodEmptyHintViewer =>
      'Товары добавляет менеджер или администратор.';

  @override
  String get prodImportCsv => 'Импорт CSV';

  @override
  String get prodStockUntracked => 'Остаток не учитывается';

  @override
  String prodStockLowTip(String qty) {
    return 'Мало: минимум $qty';
  }

  @override
  String get prodStockNegativeTip =>
      'Отрицательный остаток — проверьте приход/инвентаризацию';

  @override
  String prodSkuShort(String sku) {
    return 'арт. $sku';
  }

  @override
  String get prodCostShort => 'Себест.';

  @override
  String get prodMargin => 'Маржа';

  @override
  String get prodArchiveOneQ => 'Архивировать товар?';

  @override
  String prodArchiveManyQ(String count) {
    return 'Архивировать товары ($count)?';
  }

  @override
  String get prodArchiveMessage =>
      'Архивные товары не продаются и не видны на кассе. История продаж сохраняется. Вернуть можно в любой момент (фильтр «Архив»).';

  @override
  String get prodRestored => 'Товары возвращены в продажу';

  @override
  String get prodArchived => 'Перемещено в архив';

  @override
  String get prodCannotDeleteArchived =>
      'По товару есть операции — удалить нельзя, он уже в архиве';

  @override
  String get prodCannotDeleteTitle => 'Удалить нельзя';

  @override
  String prodCannotDeleteMessage(String name) {
    return 'По товару «$name» есть продажи или движения по складу — для отчётов он должен остаться в базе. Переместить его в архив?';
  }

  @override
  String get prodMovedToArchive => 'Товар перемещён в архив';

  @override
  String prodDeleteQ(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get prodDeleteMessage =>
      'Товар без операций будет удалён из каталога.';

  @override
  String get prodDeleted => 'Товар удалён';

  @override
  String get prodNotFoundOrDeleted => 'Товар не найден или удалён';

  @override
  String get prodPriceLabel => 'Ценник';

  @override
  String get prodDuplicate => 'Дублировать';

  @override
  String get prodUnfavorited => 'Убрано из избранного';

  @override
  String get prodFavorited => 'Добавлено в избранное';

  @override
  String get prodUnfavorite => 'Убрать из избранного';

  @override
  String get prodFavorite => 'В избранное';

  @override
  String get prodRestoreFromArchive => 'Вернуть из архива';

  @override
  String get prodFavoriteChip => 'Избранное';

  @override
  String get prodNoStockTracking => 'Без учёта остатка';

  @override
  String get prodNoReceiptsYet => 'приходов не было';

  @override
  String get prodToday => 'сегодня';

  @override
  String prodDaysAgo(String days) {
    return '$days дн. назад';
  }

  @override
  String prodWholesaleShort(String price) {
    return 'опт. $price';
  }

  @override
  String prodPerUnit(String unit) {
    return 'за 1 $unit';
  }

  @override
  String prodMarginLower(String pct) {
    return 'маржа $pct';
  }

  @override
  String get prodUntrackedLower => 'без учёта';

  @override
  String prodMinShort(String qty) {
    return 'мин. $qty';
  }

  @override
  String get prodMinNotSet => 'минимум не задан';

  @override
  String get prodSold => 'Продано';

  @override
  String get prodLast30Days => 'за 30 дней';

  @override
  String prodLast30DaysReceipts(String count) {
    return 'за 30 дней · чеков: $count';
  }

  @override
  String get prodRevenue => 'Выручка';

  @override
  String get prodLastReceipt => 'Последний приход';

  @override
  String get prodSpecs => 'Характеристики';

  @override
  String get prodWholesalePrice => 'Оптовая цена';

  @override
  String get prodNoVatLower => 'без НДС';

  @override
  String get prodNegativeSale => 'Продажа в минус';

  @override
  String get prodAllowed => 'разрешена';

  @override
  String get prodForbidden => 'запрещена';

  @override
  String get prodWarranty => 'Гарантия';

  @override
  String get prodNoneLower => 'нет';

  @override
  String prodMonthsShort(String count) {
    return '$count мес.';
  }

  @override
  String get prodUpdatedAt => 'Изменён';

  @override
  String get prodMovements => 'Движение товара';

  @override
  String get prodLast50 => 'последние 50';

  @override
  String get prodNoMovements =>
      'Движений пока не было. Приход оформляется в разделе «Склад» или «Закупки».';

  @override
  String prodStockAfterShort(String qty) {
    return 'ост. $qty';
  }

  @override
  String prodCopySuffix(String name) {
    return '$name (копия)';
  }

  @override
  String get prodReplaceBarcodeQ => 'Заменить штрихкод?';

  @override
  String prodReplaceBarcodeMessage(String code) {
    return 'Текущий штрихкод $code будет заменён внутренним. Старые этикетки перестанут сканироваться.';
  }

  @override
  String get prodReplace => 'Заменить';

  @override
  String get prodCloseUnsavedQ => 'Закрыть без сохранения?';

  @override
  String get prodUnsavedLost => 'Внесённые изменения будут потеряны.';

  @override
  String get prodCheckFields => 'Проверьте выделенные поля';

  @override
  String prodBarcodeInUseBy(String name) {
    return 'Уже используется: «$name»';
  }

  @override
  String prodBarcodeAssignedTo(String code, String name) {
    return 'Штрихкод $code уже присвоен товару «$name»';
  }

  @override
  String prodPriceBelowCostMessage(String price, String cost) {
    return 'Цена $price меньше себестоимости $cost. Каждая продажа будет убыточной. Сохранить?';
  }

  @override
  String get prodZeroPrice => 'Нулевая цена';

  @override
  String get prodZeroPriceMessage =>
      'Товар будет продаваться бесплатно. Продолжить?';

  @override
  String prodCreated(String name) {
    return 'Товар «$name» создан';
  }

  @override
  String get prodChangesSaved => 'Изменения сохранены';

  @override
  String get prodCopyTitle => 'Копия товара';

  @override
  String get prodEditTitle => 'Редактирование товара';

  @override
  String get prodCreateProduct => 'Создать товар';

  @override
  String get prodCloseEsc => 'Закрыть (Esc)';

  @override
  String get prodEditorShortcuts => 'Ctrl+S — сохранить, Esc — закрыть';

  @override
  String get prodSectionBasic => 'Основное';

  @override
  String get prodNameRequired => 'Название *';

  @override
  String get prodNewCategory => 'Новая категория';

  @override
  String get prodUnitLabel => 'Единица измерения';

  @override
  String get prodFractionalHint => 'Дробное количество (весовой товар)';

  @override
  String get prodDescription => 'Описание';

  @override
  String get prodActiveSwitch => 'Активен (продаётся)';

  @override
  String get prodFavoriteSwitch => 'Избранное на кассе';

  @override
  String get prodSectionPrices => 'Цены';

  @override
  String get prodRetailPriceRequired => 'Розничная цена *';

  @override
  String get prodRetailPrice => 'Розничная цена';

  @override
  String get prodCostHintNew => 'Для начального остатка';

  @override
  String get prodCostHintAvg => 'Средняя, по приходам';

  @override
  String get prodMarginColon => 'Маржа: ';

  @override
  String get prodMarkupColon => 'Наценка: ';

  @override
  String get prodProfitPerUnitColon => 'Прибыль с единицы: ';

  @override
  String get prodVatIncluded => 'НДС (включён в цену)';

  @override
  String get prodNoVat => 'Без НДС';

  @override
  String get prodVatOther => 'Другой';

  @override
  String get prodInternalEan => 'Внутренний EAN-13';

  @override
  String get prodSectionCodes => 'Коды';

  @override
  String get prodScanOrType => 'Отсканируйте или введите';

  @override
  String get prodGenerateBarcode =>
      'Сгенерировать внутренний EAN-13 (префикс 200)';

  @override
  String get prodBarcodeTooLong => 'Слишком длинный штрихкод';

  @override
  String get prodBarcodeNoSpaces => 'Штрихкод не должен содержать пробелы';

  @override
  String get prodSkuLabel => 'Артикул (SKU)';

  @override
  String prodSkuFree(String sku) {
    return 'Свободный: $sku';
  }

  @override
  String prodSkuUse(String sku) {
    return 'Подставить $sku';
  }

  @override
  String get prodSectionStock => 'Склад';

  @override
  String get prodTrackStock => 'Учитывать остаток';

  @override
  String get prodAllowNegative => 'Разрешить продажу в минус';

  @override
  String get prodMinStock => 'Минимальный остаток';

  @override
  String get prodMinStockHint => 'Ниже — товар помечается «Мало»';

  @override
  String get prodEnterNonNegative => 'Введите число ≥ 0';

  @override
  String get prodInitialStock => 'Начальный остаток';

  @override
  String get prodInitialStockHint => 'Оприходуется как «Начальный остаток»';

  @override
  String get prodCurrentStock => 'Текущий остаток';

  @override
  String get prodCurrentStockHint =>
      'Изменяется в разделе «Склад»: приход, списание, инвентаризация';

  @override
  String get prodSectionWarranty => 'Гарантия и поставщик';

  @override
  String get prodMonthsSuffix => 'мес.';

  @override
  String get prodWarrantyHint => '0 — без гарантии';

  @override
  String get prodWarrantyRange => 'От 0 до 240 месяцев';

  @override
  String get prodSuppliersHint => 'Поставщики добавляются в разделе «Закупки»';

  @override
  String get prodNotSpecified => 'Не указан';

  @override
  String get prodUnitNamePcs => 'Штука (шт)';

  @override
  String get prodUnitNameKg => 'Килограмм (кг)';

  @override
  String get prodUnitNameG => 'Грамм (г)';

  @override
  String get prodUnitNameL => 'Литр (л)';

  @override
  String get prodUnitNameM => 'Метр (м)';

  @override
  String get prodUnitNamePack => 'Упаковка (уп)';

  @override
  String prodBulkCategoryTitle(String count) {
    return 'Категория для $count товаров';
  }

  @override
  String prodBulkCategoryDone(String count) {
    return 'Категория изменена у $count товаров';
  }

  @override
  String get prodBulkPriceTitle => 'Изменить цены на %';

  @override
  String get prodBulkPctError =>
      'Введите процент от −99 до 1000, например 10 или −5';

  @override
  String get prodBulkNoChange =>
      'Цены не изменятся — попробуйте другой процент или округление';

  @override
  String prodBulkPriceConfirmQ(String count) {
    return 'Изменить цены у $count товаров?';
  }

  @override
  String get prodBulkPriceConfirmMessage =>
      'Каждое изменение будет записано в журнал аудита. Ценники нужно будет перепечатать.';

  @override
  String get prodChangePrices => 'Изменить цены';

  @override
  String prodBulkPriceDone(String count) {
    return 'Цены обновлены у $count товаров';
  }

  @override
  String get prodChangePct => 'Изменение, %';

  @override
  String get prodChangePctHint => 'например 10 или -5';

  @override
  String get prodChangePctHelper => 'Плюс — подорожание, минус — скидка';

  @override
  String get prodChangePctRange => 'От −99 до 1000';

  @override
  String get prodRounding => 'Округление';

  @override
  String prodWillChange(String count) {
    return 'Изменится: $count';
  }

  @override
  String prodBelowCostCount(String count) {
    return 'Ниже себестоимости: $count';
  }

  @override
  String prodCostMarginLine(String cost, String margin) {
    return 'себест. $cost · маржа $margin';
  }

  @override
  String prodApplyTo(String count) {
    return 'Применить к $count';
  }

  @override
  String get prodErrEnterNameShort => 'Введите название';

  @override
  String get prodColor => 'Цвет';

  @override
  String prodDeleteCategoryQ(String name) {
    return 'Удалить категорию «$name»?';
  }

  @override
  String get prodCategoryEmptyMsg => 'В категории нет товаров.';

  @override
  String get prodCategoryDeleted => 'Категория удалена';

  @override
  String prodCategoryMoveQ(String count) {
    return 'В категории $count товаров. Куда их перенести?';
  }

  @override
  String get prodMoveTo => 'Перенести в';

  @override
  String get prodMoveAndDelete => 'Перенести и удалить';

  @override
  String get prodCategoryDeletedMoved => 'Категория удалена, товары перенесены';

  @override
  String get prodNoCategoriesYet => 'Категорий пока нет';

  @override
  String get prodCategoriesHint =>
      'Категории помогают быстро находить товары на кассе и в отчётах.';

  @override
  String prodCategoriesFooter(String count) {
    return 'Перетащите, чтобы изменить порядок на кассе. Без категории: $count товаров.';
  }

  @override
  String get prodImportTitle => 'Импорт товаров из CSV';

  @override
  String get prodImpEnterPath => 'Введите путь к файлу .csv';

  @override
  String prodImpFileNotFound(String path) {
    return 'Файл не найден: $path';
  }

  @override
  String get prodImpFileTooBig => 'Файл больше 20 МБ';

  @override
  String prodImpFileLoaded(String name) {
    return 'Файл загружен: $name';
  }

  @override
  String get prodImpPasteOrLoad =>
      'Вставьте данные из Excel или загрузите файл';

  @override
  String get prodImpNoRows => 'Нет строк с данными';

  @override
  String prodImpTooManyRows(String count) {
    return 'Слишком много строк ($count). Разбейте файл на части до 20 000 строк.';
  }

  @override
  String get prodImpNothing =>
      'Нечего импортировать — исправьте ошибки в данных';

  @override
  String prodImpDone(String created, String updated) {
    return 'Создано $created, обновлено $updated';
  }

  @override
  String prodImpDoneSkipped(String count) {
    return ', пропущено $count';
  }

  @override
  String prodImpDoneCategories(String count) {
    return ', новых категорий $count';
  }

  @override
  String get prodImpIntro =>
      'Скопируйте строки из Excel / Google Таблиц и вставьте ниже, либо укажите путь к файлу .csv. Колонки: название; штрихкод; артикул; категория; цена; себестоимость; ед.; остаток. Заголовок и разделитель (; , табуляция) определяются автоматически.';

  @override
  String get prodImpPasteHint => 'Вставьте данные (Ctrl+V)…';

  @override
  String get prodImpOrPath => 'Или путь к файлу';

  @override
  String get prodImpPathHint => 'C:\\Users\\...\\товары.csv';

  @override
  String get prodImpLoad => 'Загрузить';

  @override
  String get prodImpUpdateExisting =>
      'Обновлять существующие товары по штрихкоду';

  @override
  String get prodImpUpdateExistingHint =>
      'Иначе строки с уже известным штрихкодом пропускаются. Остаток существующих товаров не меняется.';

  @override
  String get prodImpSample => 'Пример';

  @override
  String get prodImpCheck => 'Проверить';

  @override
  String prodImpRows(String count) {
    return 'Строк: $count';
  }

  @override
  String prodImpNew(String count) {
    return 'Новых: $count';
  }

  @override
  String prodImpUpdateCount(String count) {
    return 'Обновить: $count';
  }

  @override
  String prodImpSkipErrors(String count) {
    return 'Пропуск/ошибки: $count';
  }

  @override
  String prodImpNewCategories(String count) {
    return 'Новых категорий: $count';
  }

  @override
  String prodImpDelimiterWithHeader(String delimiter) {
    return 'Разделитель: $delimiter, с заголовком';
  }

  @override
  String prodImpDelimiterNoHeader(String delimiter) {
    return 'Разделитель: $delimiter, без заголовка';
  }

  @override
  String get prodImpNoPricePerm =>
      'У вас нет права менять цены: цены существующих товаров не обновятся.';

  @override
  String get prodImpUpdate => 'Обновить';

  @override
  String get prodImpSkip => 'Пропуск';

  @override
  String get prodImpNoName => '(без названия)';

  @override
  String get prodImpBackToData => 'Назад к данным';

  @override
  String prodImpImportN(String count) {
    return 'Импортировать $count';
  }

  @override
  String get prodExpNothing => 'Нет товаров для экспорта по текущему фильтру';

  @override
  String get prodExpFileStem => 'товары';

  @override
  String prodExpDoneTitle(String count) {
    return 'Экспортировано товаров: $count';
  }

  @override
  String get prodExpCopied =>
      'Данные скопированы в буфер обмена — вставьте их в Excel (Ctrl+V).';

  @override
  String get prodExpSaved => 'Файл сохранён:';

  @override
  String prodExpSaveFailed(String error) {
    return 'Файл сохранить не удалось: $error';
  }

  @override
  String get prodExpCopyPath => 'Копировать путь';

  @override
  String get prodLabelSmall => 'Маленькие 4×10 (52×29 мм)';

  @override
  String get prodLabelMedium => 'Средние 3×8 (70×37 мм)';

  @override
  String get prodLabelLarge => 'Крупные 2×5 (105×59 мм)';

  @override
  String get prodPrintLabelsTitle => 'Печать ценников';

  @override
  String get prodCopiesRange => 'Количество копий — от 1 до 100';

  @override
  String prodLabelsIntro(String count) {
    return 'Товаров: $count. Формат A4, линии реза пунктиром.';
  }

  @override
  String get prodLabelSize => 'Размер ценника';

  @override
  String get prodCopiesEach => 'Копий каждого';

  @override
  String prodLabelsTotal(String total, String pages) {
    return 'Всего ценников: $total\nСтраниц A4: $pages';
  }

  @override
  String get prodPrintBarcode => 'Печатать штрихкод';

  @override
  String get prodPreparingPdf => 'Готовим PDF…';

  @override
  String get purActCopied => 'Акт сверки скопирован — вставьте в Excel';

  @override
  String get purActCopyCsv => 'Копировать CSV';

  @override
  String get purActFilePrefix => 'Акт_сверки';

  @override
  String get purActFileSupplier => 'поставщик';

  @override
  String get purActLegend =>
      'Приход (+) увеличивает долг магазина перед поставщиком, расход (−) уменьшает его. Положительный баланс — долг магазина, отрицательный — аванс у поставщика.';

  @override
  String get purActPrint => 'Печать / PDF';

  @override
  String get purActSaveCsv => 'Сохранить CSV (Excel)';

  @override
  String get purActShare => 'Отправить PDF';

  @override
  String get purActShort => 'Акт сверки';

  @override
  String get purActTitle => 'Акт сверки взаиморасчётов';

  @override
  String get purActive => 'Активные';

  @override
  String get purAddOneProduct => 'Добавьте хотя бы один товар';

  @override
  String get purAddSupplier => 'Добавить поставщика';

  @override
  String get purAddToOrder => 'Добавить в заказ';

  @override
  String purAdjustDone(String amount) {
    return 'Корректировка $amount проведена';
  }

  @override
  String get purAdjustReasonHint => 'Например: по акту сверки от …';

  @override
  String get purAdjustTitle => 'Корректировка баланса';

  @override
  String get purAdvanceLower => 'аванс';

  @override
  String purAdvanceLowerValue(String amount) {
    return 'аванс $amount';
  }

  @override
  String purAdvanceSuffix(String amount) {
    return '$amount аванс';
  }

  @override
  String purAdvanceValue(String amount) {
    return 'Аванс у поставщика: $amount';
  }

  @override
  String get purAdvanceWithSupplier => 'Аванс у поставщика';

  @override
  String purAfterAdjust(String value) {
    return 'После корректировки: $value';
  }

  @override
  String get purAllAsOrdered => 'Всё по заказу';

  @override
  String get purAllReceived => 'Все позиции заказа уже приняты';

  @override
  String get purAllTimeLower => 'всё время';

  @override
  String get purAmountRequired => 'Сумма *';

  @override
  String purBalanceLower(String value) {
    return 'баланс $value';
  }

  @override
  String get purBuyer => 'Покупатель';

  @override
  String get purCancelCashHint =>
      'Наличную оплату можно отменить только пока открыта её смена.';

  @override
  String get purCancelOrder => 'Отменить заказ';

  @override
  String purCancelOrderTitle(String number) {
    return 'Отменить заказ №$number?';
  }

  @override
  String get purCancelPayment => 'Отменить оплату';

  @override
  String purCancelPaymentMessage(String date, String method) {
    return 'Оплата от $date ($method) останется в истории с отметкой «Отменена», долг поставщику увеличится на эту сумму.';
  }

  @override
  String purCancelPaymentTitle(String amount) {
    return 'Отменить оплату $amount?';
  }

  @override
  String get purCancelReasonLabel => 'Причина отмены *';

  @override
  String purCancelledAt(String date) {
    return 'Отменена $date';
  }

  @override
  String get purCancelledFem => 'Отменена';

  @override
  String get purCashNeedsShift =>
      'Оплата наличными из кассы требует открытой смены. Откройте смену или выберите другой способ.';

  @override
  String purCashOutFromShift(String number) {
    return 'Будет учтено как выплата из кассы смены №$number';
  }

  @override
  String get purChangesSaved => 'Изменения сохранены';

  @override
  String get purCheckPhone => 'Проверьте номер телефона';

  @override
  String get purChooseAnotherPeriod => 'Выберите другой период';

  @override
  String purCloseOrderTitle(String number) {
    return 'Закрыть заказ №$number без остатка?';
  }

  @override
  String get purCloseWithoutRest => 'Закрыть без остатка';

  @override
  String get purClosingBalance => 'Сальдо на конец периода';

  @override
  String get purClosingShort => 'Сальдо на конец';

  @override
  String purConclusionNone(String at) {
    return 'На $at задолженность между сторонами отсутствует.';
  }

  @override
  String purConclusionStoreOwes(
    String at,
    String store,
    String supplier,
    String amount,
  ) {
    return 'На $at задолженность «$store» перед «$supplier» составляет $amount.';
  }

  @override
  String purConclusionSupplierOwes(
    String at,
    String supplier,
    String store,
    String amount,
  ) {
    return 'На $at задолженность «$supplier» перед «$store» (аванс) составляет $amount.';
  }

  @override
  String get purContactPerson => 'Контактное лицо';

  @override
  String purCoverDays(String days) {
    return 'хватит на $days дн.';
  }

  @override
  String get purCreateOrder => 'Создать заказ';

  @override
  String get purCreateOrders => 'Создать заказы';

  @override
  String purCreatedOn(String date) {
    return 'создан $date';
  }

  @override
  String purDaysShort(String n) {
    return '$n дн.';
  }

  @override
  String get purDaysSuffix => 'дн.';

  @override
  String get purDebtOnly => 'Только с долгом';

  @override
  String get purDecrease => 'Расход (−)';

  @override
  String get purDecreaseDebt => 'Уменьшить долг';

  @override
  String get purDeleteLine => 'Удалить строку';

  @override
  String get purDeleteSupplierMessage =>
      'Поставщик будет скрыт из списков. История заказов и оплат сохранится.';

  @override
  String purDeleteSupplierTitle(String name) {
    return 'Удалить поставщика «$name»?';
  }

  @override
  String get purDeletedProduct => 'Удалённый товар';

  @override
  String get purDeliveryDate => 'Дата поставки';

  @override
  String purDeliveryOn(String date) {
    return 'Поставка $date';
  }

  @override
  String get purDraftSaved => 'Черновик заказа сохранён';

  @override
  String get purEditorEmptyHint =>
      'Добавьте товары: сканером, кнопкой «Товар» или из вкладки «Автозаказ»';

  @override
  String purEditorTotal(String amount, String count) {
    return 'Итого: $amount · позиций $count';
  }

  @override
  String get purEnterAdjustReason => 'Укажите причину корректировки';

  @override
  String get purEnterPrice => 'Укажите цену';

  @override
  String get purEnterReason => 'Укажите причину';

  @override
  String get purEnterSupplierName => 'Введите название поставщика';

  @override
  String get purErrAddOneProduct => 'Добавьте в заказ хотя бы один товар';

  @override
  String get purErrAlreadyClosed => 'Заказ уже закрыт';

  @override
  String get purErrAlreadySent => 'Заказ уже отправлен';

  @override
  String purErrDeleteNonZeroBalance(String balance) {
    return 'Нельзя удалить поставщика с ненулевым балансом ($balance)';
  }

  @override
  String get purErrDuplicateProduct =>
      'Товар повторяется в заказе — объедините строки';

  @override
  String get purErrEnterQtyOneLine =>
      'Укажите количество хотя бы по одной позиции';

  @override
  String get purErrLineNotFound => 'Позиция не найдена в заказе';

  @override
  String purErrLinePriceNegative(String name) {
    return '«$name»: цена не может быть отрицательной';
  }

  @override
  String get purErrLineTwice => 'Позиция заказа указана дважды';

  @override
  String get purErrNameTooLong => 'Название слишком длинное';

  @override
  String get purErrNoLines => 'В заказе нет позиций';

  @override
  String get purErrNothingToOrder => 'Нет позиций для заказа';

  @override
  String get purErrOnlyDraftEditable => 'Изменять можно только черновик заказа';

  @override
  String purErrOrderAlreadyStatus(String number, String status) {
    return 'Заказ №$number уже $status';
  }

  @override
  String purErrReceiveAtMost(String name, String qty) {
    return '«$name»: можно принять не больше $qty';
  }

  @override
  String purErrSupplierExists(String name) {
    return 'Поставщик «$name» уже есть';
  }

  @override
  String purErrSupplierHasOpenOrders(String n) {
    return 'У поставщика есть незакрытые заказы ($n)';
  }

  @override
  String get purErrSupplierNameRequired => 'Укажите название поставщика';

  @override
  String purErrWholeQty(String name) {
    return '«$name»: только целое количество';
  }

  @override
  String purExpectedOn(String date) {
    return 'ожидается $date';
  }

  @override
  String get purFromBuyer => 'От покупателя';

  @override
  String get purFromSupplier => 'От поставщика';

  @override
  String get purFullyReceivedSuffix => ' — заказ получен полностью';

  @override
  String purHeadingAllTime(String period) {
    return 'за $period';
  }

  @override
  String purHeadingPeriod(String period) {
    return 'за период $period';
  }

  @override
  String get purIncrease => 'Приход (+)';

  @override
  String get purIncreaseDebt => 'Увеличить долг';

  @override
  String get purInvalid => 'Неверно';

  @override
  String purInvoiceShort(String number) {
    return 'накл. $number';
  }

  @override
  String purItemProgress(String ordered, String received) {
    return 'заказано $ordered · принято $received';
  }

  @override
  String purItemRestSuffix(String qty) {
    return ' · осталось $qty';
  }

  @override
  String purLastReceipt(String date, String count) {
    return 'последний приход $date · приходов $count';
  }

  @override
  String get purLedgerAdjustment => 'Корректировка';

  @override
  String get purLedgerEmpty => 'Взаиморасчётов ещё не было';

  @override
  String get purLedgerEmptyMessage =>
      'Здесь появятся приходы, оплаты и корректировки с текущим балансом';

  @override
  String get purLedgerEmptyPeriod => 'Операций за период нет';

  @override
  String purLedgerOpNumbered(String op, String number) {
    return '$op №$number';
  }

  @override
  String get purLedgerOpening => 'Начальный остаток';

  @override
  String get purLedgerPaymentCancel => 'Отмена оплаты';

  @override
  String get purLedgerPeriodHelp => 'Период взаиморасчётов';

  @override
  String get purLedgerReceipt => 'Приход';

  @override
  String get purLedgerReceiptReversal => 'Сторно прихода';

  @override
  String get purMarkOrdered => 'Отметить заказанным';

  @override
  String get purMax160Chars => 'Не длиннее 160 символов';

  @override
  String purMaxQty(String qty) {
    return 'Макс. $qty';
  }

  @override
  String get purMethodTransfer => 'Перечисление';

  @override
  String purMinValue(String qty) {
    return 'мин. $qty';
  }

  @override
  String get purNameRequiredLabel => 'Название *';

  @override
  String get purNewOrder => 'Новый заказ';

  @override
  String get purNewPo => 'Новый заказ поставщику';

  @override
  String get purNewSupplier => 'Новый поставщик';

  @override
  String get purNoAccess => 'Нет доступа';

  @override
  String get purNoAccessMessage =>
      'Закупки доступны кладовщику, менеджеру и владельцу';

  @override
  String get purNoCashOutPermission => 'Нет права на выдачу наличных из кассы';

  @override
  String get purNoCashPermission => 'Нет права на операции с наличными';

  @override
  String get purNoChange => 'без изменений';

  @override
  String get purNoDebt => 'нет долга';

  @override
  String get purNoLinesAdded => 'Позиции не добавлены';

  @override
  String get purNoOrders => 'Заказов поставщикам пока нет';

  @override
  String get purNoOrdersForFilter => 'Нет заказов по фильтру';

  @override
  String get purNoOrdersMessage =>
      'Создайте заказ вручную или воспользуйтесь вкладкой «Автозаказ»';

  @override
  String get purNoOrdersYet => 'Заказов ещё не было';

  @override
  String get purNoPaymentsYet => 'Оплат ещё не было';

  @override
  String get purNoProductsForFilter => 'Нет товаров по фильтру';

  @override
  String get purNoReceiptsYet => 'Товар по заказу ещё не принимали';

  @override
  String get purNoSales => 'продаж не было';

  @override
  String get purNoSupplier => 'Без поставщика';

  @override
  String get purNoSupplierHelper =>
      'У этих товаров поставщик не указан в карточке';

  @override
  String get purNoSuppliers => 'Поставщиков пока нет';

  @override
  String get purNoSuppliersMessage =>
      'Добавьте поставщиков, чтобы вести заказы и учитывать долги';

  @override
  String purNowValue(String value) {
    return 'Сейчас: $value';
  }

  @override
  String get purNumberGeZero => 'Число ≥ 0';

  @override
  String purOnOrderValue(String qty) {
    return 'уже в заказах $qty';
  }

  @override
  String get purOpeningBalance => 'Сальдо на начало периода';

  @override
  String get purOpeningShort => 'Сальдо на начало';

  @override
  String get purOperation => 'Операция';

  @override
  String purOrderAmount(String amount) {
    return 'Сумма заказа $amount';
  }

  @override
  String get purOrderButton => 'Заказ';

  @override
  String get purOrderCancelled => 'Заказ отменён';

  @override
  String get purOrderClosed => 'Заказ закрыт';

  @override
  String get purOrderFromSupplier => 'Заказать у поставщика';

  @override
  String purOrderListTitle(String number, String supplier) {
    return '№$number · $supplier';
  }

  @override
  String get purOrderNotFound => 'Заказ не найден';

  @override
  String purOrderNumber(String number) {
    return 'Заказ №$number';
  }

  @override
  String get purOrderReceipts => 'Приходы по заказу';

  @override
  String get purOrderSavedSent => 'Заказ сохранён и отмечен как отправленный';

  @override
  String purOrderSent(String number) {
    return 'Заказ №$number отправлен поставщику';
  }

  @override
  String purOrderedRest(String ordered, String rest) {
    return 'заказано $ordered · осталось $rest';
  }

  @override
  String get purOurDebtLower => 'наш долг';

  @override
  String purOurDebtLowerValue(String amount) {
    return 'наш долг $amount';
  }

  @override
  String get purOurDebtToSupplier => 'Наш долг поставщику';

  @override
  String purOurDebtValue(String amount) {
    return 'Наш долг: $amount';
  }

  @override
  String purOverpayMessage(String debt, String amount, String advance) {
    return 'Долг поставщику: $debt.\nПосле оплаты $amount образуется аванс $advance. Продолжить?';
  }

  @override
  String get purOverpayTitle => 'Сумма больше долга';

  @override
  String purPaidAmount(String amount) {
    return 'Оплачено $amount';
  }

  @override
  String get purPay => 'Оплатить';

  @override
  String get purPayWithAdvance => 'Оплатить с авансом';

  @override
  String purPaymentCancelled(String amount) {
    return 'Оплата $amount отменена';
  }

  @override
  String get purPaymentCommentLabel => 'Комментарий (№ платёжки…)';

  @override
  String purPaymentDone(String amount) {
    return 'Оплата $amount проведена';
  }

  @override
  String get purPaymentTitle => 'Оплата поставщику';

  @override
  String get purPeriodAll => 'Всё время';

  @override
  String get purPeriodCustom => 'Период…';

  @override
  String get purPeriodLastMonth => 'Прошлый месяц';

  @override
  String get purPeriodQuarter => 'Квартал';

  @override
  String get purPeriodThisMonth => 'Этот месяц';

  @override
  String purPeriodUntil(String date) {
    return 'по $date';
  }

  @override
  String get purPoColBarcode => 'Штрихкод / арт.';

  @override
  String get purPoColNo => '№';

  @override
  String get purPoColQty => 'Кол-во';

  @override
  String get purPoColReceived => 'Получено';

  @override
  String purPoDated(String date, String status) {
    return 'от $date · $status';
  }

  @override
  String purPoExpected(String date) {
    return 'Ожидаемая дата поставки: $date';
  }

  @override
  String purPoNote(String note) {
    return 'Примечание: $note';
  }

  @override
  String purPoOrderedBy(String line) {
    return 'Заказал: $line';
  }

  @override
  String purPoPrintName(String number) {
    return 'Заказ поставщику $number';
  }

  @override
  String get purPoShort => 'Заказ поставщику';

  @override
  String purPoSupplier(String name) {
    return 'Поставщик: $name';
  }

  @override
  String purPoTitle(String number) {
    return 'Заказ поставщику №$number';
  }

  @override
  String purPoTotal(String amount) {
    return 'Итого: $amount';
  }

  @override
  String get purPostAdjust => 'Провести корректировку';

  @override
  String get purPriceRiseChip => 'Рост > 10%';

  @override
  String get purPriceRiseFilter => 'Рост цены > 10%';

  @override
  String get purPricesEmpty => 'Приходов за период нет';

  @override
  String get purPricesEmptyMessage =>
      'История закупочных цен строится по приходам товара';

  @override
  String purPricesSummary(String count, String spikes) {
    return 'Товаров с приходами: $count · подорожали более чем на 10%: $spikes';
  }

  @override
  String purProductNotFound(String code) {
    return 'Товар «$code» не найден';
  }

  @override
  String get purPurchasePrice => 'Цена закупки';

  @override
  String get purQtyMoreThanZero => 'больше 0';

  @override
  String get purQtyMoreThanZeroCap => 'Больше 0';

  @override
  String get purQtyWhole => 'целое';

  @override
  String get purQtyWholeCap => 'Целое';

  @override
  String get purReasonRequired => 'Причина *';

  @override
  String get purRecalculate => 'Пересчитать';

  @override
  String purReceiptNumber(String number) {
    return 'Приход №$number';
  }

  @override
  String purReceiptPosted(String number, String amount) {
    return 'Приход №$number проведён на $amount';
  }

  @override
  String purReceiveConfirmMessage(String count, String amount) {
    return 'Позиций: $count на сумму $amount.\nОстатки увеличатся, долг поставщику вырастет на эту сумму.';
  }

  @override
  String get purReceiveConfirmTitle => 'Принять товар?';

  @override
  String get purReceiveEnterQty =>
      'Укажите принятое количество хотя бы по одной позиции';

  @override
  String get purReceiveGoods => 'Принять товар';

  @override
  String get purReceiveShort => 'Принять';

  @override
  String get purReceiveStaysOpen =>
      'Заказ останется открытым — недопоставку можно принять позже.';

  @override
  String purReceiveTitle(String number) {
    return 'Приёмка по заказу №$number';
  }

  @override
  String get purReceiveWillClose => 'Заказ будет закрыт как полученный.';

  @override
  String purReceivedAmount(String amount) {
    return 'Получено на сумму $amount';
  }

  @override
  String get purReceivedField => 'Принято';

  @override
  String purReceivedOn(String date) {
    return 'получен $date';
  }

  @override
  String get purReorderAssignSupplier =>
      'Выберите поставщика для товаров без поставщика';

  @override
  String purReorderConfirmHead(String count) {
    return 'Будет создано черновиков: $count';
  }

  @override
  String purReorderConfirmLine(String name, String count) {
    return '• $name: $count поз.';
  }

  @override
  String get purReorderConfirmTitle => 'Создать заказы?';

  @override
  String purReorderCreated(String count) {
    return 'Создано черновиков заказов: $count. Проверьте их во вкладке «Заказы»';
  }

  @override
  String get purReorderDaysInvalid => 'Укажите запас от 1 до 365 дней';

  @override
  String get purReorderDaysLabel => 'Запас на, дней';

  @override
  String get purReorderEmpty => 'Заказывать нечего';

  @override
  String get purReorderEmptyMessage =>
      'Запасов хватает на выбранный период. Задайте минимальные остатки в карточках товаров.';

  @override
  String get purReorderHint =>
      'Средний расход считается по продажам за 30 дней; учтены остатки, минимум и уже заказанное.';

  @override
  String get purReorderNothingSelected => 'Не выбрано ни одной позиции';

  @override
  String purReorderSkipped(String count) {
    return '$count поз. без поставщика пропущены';
  }

  @override
  String purRetailSuffix(String price) {
    return ' · розница $price';
  }

  @override
  String purSalesPerDay(String value) {
    return 'продаж/день $value';
  }

  @override
  String get purSaveAndSend => 'Сохранить и отправить';

  @override
  String get purSaveDraft => 'Сохранить черновик';

  @override
  String get purSearchOrder => 'Поиск заказа';

  @override
  String get purSelectOrder => 'Выберите заказ';

  @override
  String get purSelectOrderMessage =>
      'Откройте заказ из списка слева или создайте новый';

  @override
  String get purSelectSupplier => 'Выберите поставщика';

  @override
  String purSelectedCount(String count) {
    return 'Выбрано позиций: $count';
  }

  @override
  String get purShiftClosedNoCash =>
      'Смена закрыта — наличные из кассы выдать нельзя';

  @override
  String get purSignatureCaption => 'подпись                         ФИО';

  @override
  String get purStampPlace => 'М.П.';

  @override
  String get purStatusCancelled => 'Отменён';

  @override
  String get purStatusDraft => 'Черновик';

  @override
  String get purStatusOrdered => 'Заказан';

  @override
  String get purStatusPartial => 'Частично получен';

  @override
  String get purStatusReceived => 'Получен';

  @override
  String purStockValue(String qty) {
    return 'остаток $qty';
  }

  @override
  String get purStore => 'Магазин';

  @override
  String get purSupplierAdded => 'Поставщик добавлен';

  @override
  String get purSupplierDeleted => 'Поставщик удалён';

  @override
  String get purSupplierInvoiceNo => '№ накладной поставщика';

  @override
  String get purSupplierNotFound => 'Поставщик не найден или удалён';

  @override
  String get purSupplierRequired => 'Поставщик *';

  @override
  String get purTabLedger => 'Взаиморасчёты';

  @override
  String get purTabOrders => 'Заказы';

  @override
  String get purTabPayments => 'Оплаты';

  @override
  String get purTabPrices => 'Закупочные цены';

  @override
  String get purTabReorder => 'Автозаказ';

  @override
  String get purTabSuppliers => 'Поставщики';

  @override
  String get purTaxId => 'ИНН';

  @override
  String get purTaxIdInvalid => 'ИНН — от 9 до 14 цифр';

  @override
  String purTaxIdValue(String taxId) {
    return 'ИНН $taxId';
  }

  @override
  String get purTitle => 'Закупки';

  @override
  String purToPost(String amount) {
    return 'К оприходованию: $amount';
  }

  @override
  String get purTurnover => 'Обороты за период';

  @override
  String get purUrgent => 'Срочно';

  @override
  String purWeOwe(String amount) {
    return 'Мы должны: $amount';
  }

  @override
  String get purZeroAll => 'Обнулить';

  @override
  String get repAbcHintA => 'Основная выручка (первые 80%)';

  @override
  String get repAbcHintB => 'Средний вклад (следующие 15%)';

  @override
  String get repAbcHintC => 'Малый вклад (последние 5%)';

  @override
  String get repGiftSalesTitle => 'Продажа сертификатов (аванс, не выручка)';

  @override
  String get repGiftSalesHint =>
      'Деньги за проданные сертификаты — аванс. В выручку они попадают при оплате товара сертификатом.';

  @override
  String repGiftSalesSubtitle(String period, String sold, String voided) {
    return '$period · продано $sold, аннулировано $voided';
  }

  @override
  String get repColSold => 'Продано';

  @override
  String get repColVoided => 'Аннулировано';

  @override
  String get repGiftVoidedTooltip =>
      'Возвращено покупателям при аннулировании продажи';

  @override
  String get repPeriodLastMonth => 'Прошлый месяц';

  @override
  String get repPeriodQuarter => 'Квартал';

  @override
  String get repPeriodCustom => 'Произвольный';

  @override
  String get repNoCategory => 'Без категории';

  @override
  String get repNotSpecified => 'Не указан';

  @override
  String get repNoReason => 'Без причины';

  @override
  String get repExportFolder => 'Отчёты';

  @override
  String repForecastTitle(String days) {
    return 'Прогноз спроса и заказ на $days дн.';
  }

  @override
  String repAsOf(String date) {
    return 'на $date';
  }

  @override
  String get repColSalesPerDay => 'Продаж в день';

  @override
  String get repColSalesPerDayTooltip =>
      'Среднее за 28 дней (для новых — за дни с момента создания, не меньше 7)';

  @override
  String get repColTrend7 => 'Тренд 7 дн.';

  @override
  String get repColTrend7Tooltip =>
      'Темп продаж последних 7 дней относительно среднего';

  @override
  String get repColCover => 'Хватит на';

  @override
  String get repColRunsOut => 'Закончится';

  @override
  String get repColToOrder => 'Заказать';

  @override
  String get repColOrderSum => 'Сумма заказа';

  @override
  String repDaysShort(String days) {
    return '$days дн.';
  }

  @override
  String get repAlreadyOut => 'уже нет';

  @override
  String get repOutOfStock => 'Нет в наличии';

  @override
  String get repRisk => 'Риск';

  @override
  String get repNormal => 'Норма';

  @override
  String get repNoSalesShort => 'Нет продаж';

  @override
  String get repRunOutIn7 => 'Закончатся за 7 дней';

  @override
  String get repOutButWanted => 'Нет в наличии, но покупают';

  @override
  String get repItemsToOrder => 'Позиций к заказу';

  @override
  String get repOrderSumAtCost => 'Сумма заказа (по себестоимости)';

  @override
  String get repForecastHow => 'Как считается прогноз';

  @override
  String repForecastHelp(String horizon, String riskDays) {
    return '• Продаж в день = продано за последние 28 дней (за вычетом возвратов) ÷ 28. Для новых товаров — за дни с момента добавления, но не меньше 7.\n• Хватит на = остаток ÷ продаж в день.\n• Заказать = продаж в день × $horizon дн. + минимальный остаток − текущий остаток.\n• «Риск» — товар закончится в ближайшие $riskDays дней.';
  }

  @override
  String repNothingToOrder(String days) {
    return 'Нечего заказывать — запасов хватает на $days дн.';
  }

  @override
  String get repNoTrackedProducts => 'Нет товаров с учётом остатков';

  @override
  String get repOnlyToOrder => 'Только требующие заказа';

  @override
  String get repGoToPurchasing => 'Перейти к закупкам';

  @override
  String repInsQuoted(String name) {
    return '«$name»';
  }

  @override
  String repInsWeekExpl(String week, String prev) {
    return 'За последние 7 дней: $week, за 7 дней до этого: $prev (чистая выручка с учётом возвратов).';
  }

  @override
  String repInsRevenueUpTitle(String pct) {
    return 'Выручка за неделю выросла на $pct';
  }

  @override
  String repInsRevenueUpExpl(String base) {
    return '$base Отличный результат — проверьте, хватит ли остатков ходовых товаров.';
  }

  @override
  String repInsRevenueDownTitle(String pct) {
    return 'Выручка за неделю упала на $pct';
  }

  @override
  String repInsRevenueDownExpl(String base) {
    return '$base Проверьте наличие ходовых товаров и запустите акцию.';
  }

  @override
  String get repInsActLaunchPromo => 'Запустить акцию';

  @override
  String repInsOutOfStockOne(String name) {
    return 'Закончился ходовой товар $name';
  }

  @override
  String repInsOutOfStockMany(String items) {
    return '$items с продажами закончились';
  }

  @override
  String repInsOutOfStockExpl(String names) {
    return '$names — остаток 0, а за последние 4 недели их покупали. Каждый день без товара — потерянная выручка.';
  }

  @override
  String get repInsActOrderSupplier => 'Заказать у поставщика';

  @override
  String repInsStockoutTitle(String name, String days) {
    return 'Товар $name закончится через $days';
  }

  @override
  String repInsStockoutExpl(
    String stock,
    String avg,
    String window,
    String reorder,
    String horizon,
  ) {
    return 'Остаток $stock, продаётся в среднем $avg в день (за $window). Рекомендуем заказать $reorder на $horizon.';
  }

  @override
  String get repInsActPurchase => 'Оформить закупку';

  @override
  String get repInsStockoutMoreOne => 'Ещё 1 товар закончится в течение недели';

  @override
  String repInsStockoutMoreMany(String items) {
    return 'Ещё $items закончатся в течение недели';
  }

  @override
  String get repInsStockoutMoreExpl =>
      'См. вкладку «Прогноз спроса» — там рекомендуемое количество к заказу.';

  @override
  String repInsCategoryTitle(String name, String pct) {
    return 'Категория «$name» даёт $pct прибыли';
  }

  @override
  String repInsCategoryExpl(String profit, String total) {
    return 'За 30 дней: $profit из $total валовой прибыли. Держите эту категорию в наличии и на видном месте.';
  }

  @override
  String get repInsActOpenProducts => 'Открыть товары';

  @override
  String repInsLossTitle(String name) {
    return 'Товар $name продаётся в убыток';
  }

  @override
  String repInsLowMarginTitle(String name) {
    return 'Маржа товара $name ниже 5%';
  }

  @override
  String repInsMarginExpl(String revenue, String cost, String margin) {
    return 'За 30 дней: выручка $revenue, себестоимость $cost, маржа $margin%. Поднимите цену или пересмотрите закупочную цену и скидки.';
  }

  @override
  String get repInsActChangePrice => 'Изменить цену';

  @override
  String repInsInactiveTitle(String customers) {
    return '$customers не приходили 60 дней — запустите акцию';
  }

  @override
  String get repInsInactiveExpl =>
      'Эти клиенты раньше покупали, но не возвращались больше 60 дней. Персональная скидка или бонусы часто возвращают 10–20% из них.';

  @override
  String get repInsActCreatePromo => 'Создать акцию';

  @override
  String repInsDiscountsTitle(String pct) {
    return 'Скидки съели $pct выручки';
  }

  @override
  String repInsDiscountsExpl(String discounts, String subtotal) {
    return 'За 30 дней скидки составили $discounts от $subtotal до скидок. Проверьте акции и ручные скидки кассиров (вкладка «Сотрудники»).';
  }

  @override
  String get repInsActCheckPromos => 'Проверить акции';

  @override
  String repInsReturnsTitle(String pct) {
    return 'Возвраты — $pct от продаж';
  }

  @override
  String repInsReturnsExpl(String returns, String amount) {
    return 'За 30 дней $returns на $amount. Норма для розницы — до 3–5%. Проверьте качество товара и причины возвратов.';
  }

  @override
  String get repInsActOpenReceipts => 'Открыть чеки';

  @override
  String repInsPeakTitle(String from, String to) {
    return 'Пиковые часы $from–$to — поставьте второго кассира';
  }

  @override
  String repInsPeakExpl(String from, String to, String pct) {
    return 'С $from:00 до $to:00 приходится $pct всех чеков за 30 дней. Второй кассир в это время сократит очереди и потерянные продажи.';
  }

  @override
  String get repInsActStaff => 'Сотрудники';

  @override
  String repInsDeadTitle(String items) {
    return '$items не продавались 60 дней';
  }

  @override
  String repInsDeadExplCost(String amount) {
    return 'В них заморожено $amount по себестоимости. Сделайте уценку или акцию, чтобы освободить деньги.';
  }

  @override
  String get repInsDeadExpl =>
      'Сделайте уценку или акцию, чтобы освободить деньги и место на полке.';

  @override
  String get repInsActOpenInventory => 'Открыть склад';

  @override
  String repInsOverdueTitle(String customers) {
    return 'Просроченные долги: $customers';
  }

  @override
  String repInsOverdueExpl(String amount) {
    return 'Просрочено $amount — срок оплаты этих долгов прошёл. Напомните клиентам и не продавайте им в долг до погашения.';
  }

  @override
  String get repInsActOpenCustomers => 'Открыть клиентов';

  @override
  String repInsTopTitle(String name) {
    return 'Хит недели — $name';
  }

  @override
  String repInsTopExpl(String amount, String pct) {
    return 'Выручка $amount за 7 дней ($pct всех продаж). Следите, чтобы он не заканчивался.';
  }

  @override
  String get repInsActCheckStock => 'Проверить остатки';

  @override
  String get repSevCritical => 'Срочно';

  @override
  String get repSevWarning => 'Внимание';

  @override
  String get repSevInfo => 'Совет';

  @override
  String get repSevPositive => 'Хорошо';

  @override
  String get repInsightsIntro =>
      'Подсказки по вашим данным за последние 30 дней. Считаются на этом устройстве, без интернета; каждая объясняет, откуда взялись цифры.';

  @override
  String get repRefresh => 'Обновить';

  @override
  String get repInsightsEmptyTitle => 'Пока нечего подсказать';

  @override
  String get repInsightsEmptyMessage =>
      'Подсказки появятся, когда накопятся продажи хотя бы за неделю. Проблем с остатками, долгами и маржой не найдено.';

  @override
  String get repByProducts => 'По товарам';

  @override
  String get repByCategories => 'По категориям';

  @override
  String get repSalesByCategory => 'Продажи по категориям';

  @override
  String get repColProducts => 'Товаров';

  @override
  String get repColQty => 'Кол-во';

  @override
  String get repColRevenue => 'Выручка';

  @override
  String get repColRevenueShare => 'Доля выручки';

  @override
  String get repProfitByCategory => 'Прибыль по категориям';

  @override
  String get repRevenueByCategory => 'Выручка по категориям';

  @override
  String get repSalesByProduct => 'Продажи по товарам';

  @override
  String get repColShare => 'Доля';

  @override
  String get repAbcTooltip =>
      'A — 80% выручки, B — следующие 15%, C — последние 5%';

  @override
  String repAbcClass(String cls, String hint) {
    return 'Класс $cls — $hint';
  }

  @override
  String repProductsShort(String count) {
    return '$count тов.';
  }

  @override
  String repRevenueSharePct(String pct) {
    return '$pct% выручки';
  }

  @override
  String get repNoSales => 'Нет продаж за период';

  @override
  String get repSearchProduct => 'Поиск товара';

  @override
  String get repNoDataForPeriod => 'Нет данных за период';

  @override
  String repShowMore(String shown, String total) {
    return 'Показать ещё (показано $shown из $total)';
  }

  @override
  String get repNoSort => 'Без сортировки';

  @override
  String repSortBy(String column) {
    return 'Сортировка: $column';
  }

  @override
  String get repCopyCsv => 'Копировать CSV';

  @override
  String get repSaveCsv => 'Сохранить CSV (Excel)';

  @override
  String get repSavePdf => 'Сохранить PDF';

  @override
  String get repTableCopied =>
      'Таблица скопирована — вставьте в Excel или сообщение';

  @override
  String get repFileSaved => 'Файл сохранён';

  @override
  String get repCopyPath => 'Копировать путь';

  @override
  String get repNoSalesInPeriod => 'За выбранный период продаж нет';

  @override
  String get repPickAnotherPeriod => 'Выберите другой период вверху экрана.';

  @override
  String repPrevPeriod(String amount) {
    return 'пред. период: $amount';
  }

  @override
  String get repNetRevenue => 'Чистая выручка';

  @override
  String get repNetRevenueTooltip =>
      'Продажи минус возвраты за период (аннулированные чеки не учитываются)';

  @override
  String get repReturns => 'Возвраты';

  @override
  String repReturnsHint(String count, String pct) {
    return '$count шт. · $pct от продаж';
  }

  @override
  String get repDiscounts => 'Скидки';

  @override
  String repDiscountsHint(String pct) {
    return '$pct от суммы до скидок';
  }

  @override
  String get repReceipts => 'Чеков';

  @override
  String repVoidedCount(String count) {
    return 'аннулировано: $count';
  }

  @override
  String get repNoVoids => 'аннулирований нет';

  @override
  String get repAvgCheck => 'Средний чек';

  @override
  String get repGrossProfit => 'Валовая прибыль';

  @override
  String get repGrossProfitTooltip =>
      'Чистая выручка минус себестоимость проданного (с учётом возвратов на склад)';

  @override
  String get repMargin => 'Маржа';

  @override
  String repCostHint(String amount) {
    return 'себестоимость: $amount';
  }

  @override
  String get repSalesByDay => 'Продажи по дням';

  @override
  String get repProfit => 'Прибыль';

  @override
  String get repNetRevenueByDay => 'Чистая выручка по дням';

  @override
  String repTipNetRevenue(String amount) {
    return 'Чистая выручка: $amount';
  }

  @override
  String repTipReceipts(String count) {
    return 'Чеков: $count';
  }

  @override
  String repTipReturns(String amount) {
    return 'Возвраты: $amount';
  }

  @override
  String get repSalesByHour => 'Продажи по часам';

  @override
  String get repHour => 'Час';

  @override
  String get repReceiptsPerDay => 'Чеков в день';

  @override
  String get repReceiptsPerDayTooltip =>
      'Среднее количество чеков в этот час за день';

  @override
  String get repReceiptsShare => 'Доля чеков';

  @override
  String get repLoadByHour => 'Загрузка по часам';

  @override
  String repPeak(String from, String to) {
    return 'Пик: $from:00–$to:00';
  }

  @override
  String get repLoadByHourHint =>
      'Сколько чеков пробивается в каждый час — помогает планировать смены и второго кассира.';

  @override
  String repTipReceiptsPerDay(String count, String perDay) {
    return 'Чеков: $count (≈$perDay в день)';
  }

  @override
  String repTipSales(String amount) {
    return 'Продажи: $amount';
  }

  @override
  String get repByWeekday => 'По дням недели';

  @override
  String repTipReceiptsLower(String count) {
    return 'чеков: $count';
  }

  @override
  String get repTitle => 'Отчёты';

  @override
  String get repTabSales => 'Продажи';

  @override
  String get repTabStaff => 'Сотрудники';

  @override
  String get repTabPayments => 'Оплаты';

  @override
  String get repTabStock => 'Склад';

  @override
  String get repTabForecast => 'Прогноз спроса';

  @override
  String get repTabInsights => 'AI-аналитика';

  @override
  String get repForecastSubtitle => 'По продажам за последние 28 дней';

  @override
  String get repLast30Days => 'Последние 30 дней';

  @override
  String repPeriodTooltip(String period) {
    return 'Период: $period';
  }

  @override
  String get repPeriodCustomMenu => 'Произвольный…';

  @override
  String get repPickPeriod => 'Выберите период';

  @override
  String get repFrom => 'С';

  @override
  String get repTo => 'По';

  @override
  String get repWdMon => 'Пн';

  @override
  String get repWdTue => 'Вт';

  @override
  String get repWdWed => 'Ср';

  @override
  String get repWdThu => 'Чт';

  @override
  String get repWdFri => 'Пт';

  @override
  String get repWdSat => 'Сб';

  @override
  String get repWdSun => 'Вс';

  @override
  String get repDeltaNew => 'новое';

  @override
  String get repSalesByCashier => 'Продажи по кассирам';

  @override
  String get repSalesBySeller => 'Продажи по продавцам';

  @override
  String get repStaffDiscountsTooltip =>
      'Сумма скидок в чеках сотрудника и доля от суммы до скидок';

  @override
  String get repStaffReturnsTooltip =>
      'Возвраты по чекам этого сотрудника, оформленные в периоде';

  @override
  String get repColVoidedShort => 'Аннулир.';

  @override
  String get repVoidedReceipts => 'Аннулированные чеки';

  @override
  String get repCashiers => 'Кассиры';

  @override
  String get repSellers => 'Продавцы';

  @override
  String get repNetRevenueByStaff => 'Чистая выручка по сотрудникам';

  @override
  String get repPaymentsByMethod => 'Оплаты по способам';

  @override
  String get repColReceived => 'Получено';

  @override
  String get repColRefunded => 'Возвращено';

  @override
  String get repPaymentsStructure => 'Структура оплат';

  @override
  String get repNoPayments => 'Нет оплат за период';

  @override
  String get repCustomerDebts => 'Долги клиентов';

  @override
  String get repDebtIssued => 'Выдано в долг';

  @override
  String get repDebtCollected => 'Погашено';

  @override
  String get repDebtAdjusted => 'Корректировки (возвраты, аннулирования)';

  @override
  String get repDebtChange => 'Изменение долга за период';

  @override
  String repDebtOutstanding(String count) {
    return 'Текущий долг клиентов ($count)';
  }

  @override
  String get repStockByCategory => 'Остатки по категориям (на сейчас)';

  @override
  String get repColPositions => 'Позиций';

  @override
  String get repColAtCost => 'По себестоимости';

  @override
  String get repColAtRetail => 'По рознице';

  @override
  String get repColPotentialProfit => 'Потенц. прибыль';

  @override
  String get repPositionsInStock => 'Позиций в наличии';

  @override
  String repCategoriesCount(String count) {
    return 'категорий: $count';
  }

  @override
  String get repStockAtCost => 'Склад по себестоимости';

  @override
  String get repStockAtCostTooltip => 'Сколько денег вложено в товар на складе';

  @override
  String get repStockAtCostHint => 'вложено в товар';

  @override
  String get repStockAtRetail => 'Склад по розничным ценам';

  @override
  String get repStockAtRetailHint => 'если продать всё по текущим ценам';

  @override
  String get repPotentialProfit => 'Потенциальная прибыль';

  @override
  String repAvgMarkup(String pct) {
    return 'наценка в среднем $pct';
  }

  @override
  String get repNoStock => 'На складе нет товаров с положительным остатком';

  @override
  String repDeadStockTitle(String days) {
    return 'Неликвид: нет продаж $days дней';
  }

  @override
  String get repColFrozen => 'Заморожено';

  @override
  String get repColLastSale => 'Последняя продажа';

  @override
  String get repNeverSold => 'не продавался';

  @override
  String get repNoDeadStock => 'Отлично — неликвидных товаров нет';

  @override
  String repDeadStockHint(String days) {
    return 'Товары с остатком, которые не продавались $days дней. Сделайте уценку, акцию или верните поставщику.';
  }

  @override
  String get repWriteOffsByReason => 'Списания по причинам';

  @override
  String get repColOperations => 'Операций';

  @override
  String get repNoWriteOffs => 'Списаний за период нет';

  @override
  String get salesStatusCompleted => 'Проведён';

  @override
  String get salesStatusPartial => 'Частичный возврат';

  @override
  String get salesStatusReturned => 'Возвращён';

  @override
  String get salesStatusHeld => 'Отложен';

  @override
  String get salesPeriodWeek => '7 дней';

  @override
  String get salesPeriodAll => 'Всё время';

  @override
  String get salesPeriodCustom => 'Период…';

  @override
  String get salesRefundHintCash => 'Выдать деньги из кассы';

  @override
  String get salesRefundHintCard => 'Вернуть на карту через терминал';

  @override
  String get salesRefundHintTransfer => 'Вернуть переводом';

  @override
  String get salesRefundHintDebt => 'Уменьшить долг клиента';

  @override
  String get salesRefundHintBonus => 'Начислить на бонусный счёт клиента';

  @override
  String salesReturnPeriodExpired(String days) {
    return 'Срок возврата ($days дн.) истёк';
  }

  @override
  String get salesVoidAlready => 'Чек уже аннулирован';

  @override
  String get salesVoidOnlyNoReturns =>
      'Аннулировать можно только чек без возвратов';

  @override
  String get salesVoidShiftClosed => 'Смена чека закрыта — оформите возврат';

  @override
  String get salesVoidOtherShift => 'Чек из другой смены — оформите возврат';

  @override
  String get salesReasonDefect => 'Брак';

  @override
  String get salesReasonNotFit => 'Не подошёл';

  @override
  String get salesReasonCashierError => 'Ошибка кассира';

  @override
  String get salesReasonOther => 'Другое';

  @override
  String get salesPickPeriod => 'Выберите период';

  @override
  String salesSlipTitle(String number) {
    return 'АКТ ВОЗВРАТА ТОВАРА №$number';
  }

  @override
  String get salesSlipBySale => 'По чеку';

  @override
  String salesSlipSaleRef(String number, String date) {
    return '№$number от $date';
  }

  @override
  String get salesSlipBuyer => 'Покупатель';

  @override
  String get salesSlipMethod => 'Способ возврата';

  @override
  String get salesSlipRestock => 'На склад';

  @override
  String get salesSlipYes => 'да';

  @override
  String get salesSlipNoRestock => 'нет (брак / не подлежит продаже)';

  @override
  String get salesSlipQty => 'Кол-во';

  @override
  String salesSlipTotal(String amount) {
    return 'Итого к возврату: $amount';
  }

  @override
  String salesSlipIssued(String name) {
    return 'Выдал: $name ____________';
  }

  @override
  String get salesSlipReceived => 'Получил: ____________';

  @override
  String salesSlipJobName(String number) {
    return 'Возврат $number';
  }

  @override
  String salesReturnWizardTitle(String number) {
    return 'Возврат по чеку №$number';
  }

  @override
  String salesNotMore(String qty) {
    return 'Не больше $qty';
  }

  @override
  String get salesIntegerOnly => 'Только целое';

  @override
  String get salesCheckQty => 'Проверьте количество в отмеченных строках';

  @override
  String get salesSelectItems => 'Выберите товары и количество для возврата';

  @override
  String get salesEnterReason => 'Укажите причину возврата';

  @override
  String get salesOpenShiftForCash => 'Для возврата наличными откройте смену';

  @override
  String get salesConfirmReturnTitle => 'Оформить возврат?';

  @override
  String salesConfirmReturnMessage(
    String method,
    String amount,
    String count,
    String restock,
  ) {
    return '$method: $amount\nПозиций: $count. $restock';
  }

  @override
  String get salesRestockYes => 'Товар вернётся на склад.';

  @override
  String get salesRestockNo => 'Товар НЕ вернётся на склад.';

  @override
  String get salesDoReturn => 'Оформить возврат';

  @override
  String get salesAllReturned => 'Все товары уже возвращены';

  @override
  String salesReturnExpiredBanner(String reason, String date) {
    return '$reason. Возврат по чеку от $date невозможен — для брака оформите гарантийную заявку.';
  }

  @override
  String get salesWhatToReturn => 'Что возвращаем';

  @override
  String get salesReturnAll => 'Вернуть всё';

  @override
  String get salesHowToRefund => 'Как вернуть деньги';

  @override
  String get salesNoShiftNoCash =>
      'Смена не открыта — возврат наличными невозможен';

  @override
  String salesDebtExcess(String debt, String excess) {
    return 'Долг клиента $debt — излишек $excess станет авансом клиента';
  }

  @override
  String salesPaidList(String list) {
    return 'Оплачено: $list';
  }

  @override
  String get salesRestockTitle => 'Вернуть товар на склад';

  @override
  String get salesRestockOn => 'Остаток увеличится на возвращаемое количество';

  @override
  String get salesRestockOff =>
      'Товар не вернётся в остаток (брак). После возврата можно оформить гарантийную заявку';

  @override
  String get salesReasonLabel => 'Причина возврата *';

  @override
  String get salesReasonRequired => 'Укажите причину';

  @override
  String salesBonusClawback(String amount) {
    return 'С клиента будет списано до $amount начисленных бонусов';
  }

  @override
  String get salesToRefund => 'К возврату';

  @override
  String salesBought(String qty) {
    return 'куплено $qty';
  }

  @override
  String salesReturnedQty(String qty) {
    return 'возвращено $qty';
  }

  @override
  String salesPaidAmount(String amount) {
    return 'оплачено $amount';
  }

  @override
  String get salesLess => 'Меньше';

  @override
  String get salesMore => 'Больше';

  @override
  String salesOfQty(String qty) {
    return 'из $qty';
  }

  @override
  String get salesReceiptNotFound => 'Чек не найден';

  @override
  String get salesReceiptVoided => 'Чек аннулирован';

  @override
  String get salesReceiptCopy => 'Копия чека';

  @override
  String get salesReceiptText => 'Текст чека';

  @override
  String get salesVoid => 'Аннулировать';

  @override
  String salesReturnsSection(String count) {
    return 'Возвраты ($count)';
  }

  @override
  String salesReceiptNo(String number) {
    return 'Чек №$number';
  }

  @override
  String salesShiftNo(String number) {
    return 'смена №$number';
  }

  @override
  String salesVoidedReason(String reason) {
    return 'Аннулирован: $reason';
  }

  @override
  String get salesParticipants => 'Участники';

  @override
  String get salesSeller => 'Продавец';

  @override
  String get salesNoCustomer => 'без клиента';

  @override
  String get salesPromoCode => 'Промокод';

  @override
  String salesItemsSection(String count) {
    return 'Товары ($count)';
  }

  @override
  String get salesSubtotal => 'Сумма без скидки';

  @override
  String get salesVatIncluded => 'в т.ч. НДС';

  @override
  String get salesBonusEarned => 'Начислено бонусов';

  @override
  String get salesRefunded => 'Возвращено';

  @override
  String get salesReceiptTextCopied => 'Текст чека скопирован';

  @override
  String get salesCopy => 'Копировать';

  @override
  String salesVoidPromptTitle(String number) {
    return 'Аннулировать чек №$number';
  }

  @override
  String get salesReasonRequiredLabel => 'Причина *';

  @override
  String get salesVoidConfirmTitle => 'Аннулировать чек?';

  @override
  String salesVoidConfirmMessage(String number, String amount) {
    return 'Чек №$number на $amount будет отменён целиком: товар вернётся на склад, оплата — по исходным способам. Действие необратимо.';
  }

  @override
  String salesVoidDone(String number) {
    return 'Чек №$number аннулирован';
  }

  @override
  String salesReturnDoneTitle(String number) {
    return 'Возврат №$number оформлен';
  }

  @override
  String get salesNotRestockedHint =>
      'Товар не возвращён на склад. Если это брак по гарантии — оформите гарантийную заявку.';

  @override
  String get salesWarrantyClaim => 'Гарантийная заявка';

  @override
  String get salesReturnSlip => 'Акт возврата';

  @override
  String salesItemDiscount(String amount) {
    return 'скидка $amount';
  }

  @override
  String salesItemWarranty(String date) {
    return 'гарантия до $date';
  }

  @override
  String salesReturnHeader(String number, String date) {
    return 'Возврат №$number · $date';
  }

  @override
  String get salesToStock => 'на склад';

  @override
  String get salesNoRestock => 'без возврата на склад';

  @override
  String salesReasonValue(String reason) {
    return 'Причина: $reason';
  }

  @override
  String salesReceiptNoNotFound(String number) {
    return 'Чек №$number не найден';
  }

  @override
  String get salesTitle => 'Чеки';

  @override
  String get salesSubtitle => 'История продаж и возвраты';

  @override
  String get salesTabReturns => 'Возвраты';

  @override
  String get salesNoShiftReceipts =>
      'Смена не открыта. Вы видите только чеки текущей смены.';

  @override
  String salesShiftReceipts(String number) {
    return 'Показаны чеки текущей смены №$number';
  }

  @override
  String get salesSelectReceipt => 'Выберите чек';

  @override
  String get salesSelectReceiptHint =>
      'Здесь появятся состав чека, оплаты, возвраты и действия';

  @override
  String get salesNoReceipts => 'Чеков не найдено';

  @override
  String get salesNoReceiptsFiltered =>
      'Измените условия поиска или сбросьте фильтры';

  @override
  String get salesNoSalesInShift => 'В текущей смене продаж пока нет';

  @override
  String get salesNoSalesInPeriod => 'За выбранный период продаж нет';

  @override
  String get salesResetFilters => 'Сбросить фильтры';

  @override
  String get salesShowAllTime => 'Показать за всё время';

  @override
  String get salesShowMore => 'Показать ещё';

  @override
  String get salesSearchHint => 'Номер чека, клиент или товар';

  @override
  String get salesAnyFem => 'Любая';

  @override
  String get salesReceiptsLabel => 'Чеков';

  @override
  String get salesSalesLabel => 'Продажи';

  @override
  String get salesVoidedLabel => 'Аннулировано';

  @override
  String salesPositionsShort(String n) {
    return '$n поз.';
  }

  @override
  String get salesNoReturns => 'Возвратов нет';

  @override
  String get salesChangeSearch => 'Измените условия поиска';

  @override
  String get salesNoReturnsHint =>
      'Возвраты оформляются из карточки чека во вкладке «Чеки»';

  @override
  String salesReturnTitle(String number, String sale) {
    return 'Возврат №$number · чек №$sale';
  }

  @override
  String get salesReturnsSearchHint => 'Номер, клиент или причина';

  @override
  String get salesMethodLabel => 'Способ';

  @override
  String get salesAnyMasc => 'Любой';

  @override
  String get salesNoShiftReturns =>
      'Смена не открыта. Вы видите только возвраты текущей смены.';

  @override
  String salesShiftReturns(String number) {
    return 'Показаны возвраты текущей смены №$number';
  }

  @override
  String get salesReturnsCountLabel => 'Возвратов';

  @override
  String get salesSumLabel => 'На сумму';

  @override
  String get salesSelectReturn => 'Выберите возврат';

  @override
  String get salesSelectReturnHint =>
      'Здесь появятся чек, состав возврата и акт для печати';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsNoAccess => 'Нет доступа';

  @override
  String get settingsNoAccessMessage =>
      'Настройки может менять только владелец или администратор.';

  @override
  String get settingsSecStore => 'Магазин';

  @override
  String get settingsSecStoreHint => 'Название, реквизиты, чек';

  @override
  String get settingsSecCurrency => 'Валюта и налоги';

  @override
  String get settingsSecCurrencyHint => 'Валюта учёта, НДС';

  @override
  String get settingsSecSales => 'Продажи';

  @override
  String get settingsSecSalesHint => 'Смены, возвраты, оплата';

  @override
  String get settingsSecLoyalty => 'Лояльность';

  @override
  String get settingsSecLoyaltyHint => 'Бонусная программа';

  @override
  String get settingsSecDevices => 'Кассы и устройства';

  @override
  String get settingsSecDevicesHint => 'Кассы, принтер, сканер';

  @override
  String get settingsSecAppearance => 'Внешний вид';

  @override
  String get settingsSecAppearanceHint => 'Светлая и тёмная тема';

  @override
  String get settingsSecBackup => 'Резервное копирование';

  @override
  String get settingsSecBackupHint => 'Копии и восстановление';

  @override
  String get settingsSecData => 'Данные';

  @override
  String get settingsSecDataHint => 'Демо-режим, экспорт';

  @override
  String get settingsSecAbout => 'О программе';

  @override
  String get settingsSecAboutHint => 'Версия, лицензия, помощь';

  @override
  String get settingsDiscardTitle => 'Отменить изменения?';

  @override
  String get settingsDiscardMessage =>
      'В разделе есть несохранённые изменения. Если уйти, они будут потеряны.';

  @override
  String get settingsDiscardOk => 'Не сохранять';

  @override
  String get settingsUnsavedBar =>
      'Есть несохранённые изменения (Ctrl+S — сохранить)';

  @override
  String get settingsCancelVerb => 'Отменить';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String settingsSwitchOn(String title) {
    return '«$title» — включено';
  }

  @override
  String settingsSwitchOff(String title) {
    return '«$title» — выключено';
  }

  @override
  String get settingsCopied => 'Скопировано';

  @override
  String settingsErrPercentRange(String min, String max) {
    return 'Укажите значение от $min до $max';
  }

  @override
  String get settingsErrPercentNumber => 'Введите число, например 2 или 2,5';

  @override
  String settingsErrPercentAllowed(String min, String max) {
    return 'Допустимо от $min до $max %';
  }

  @override
  String get settingsErrTwoDecimals => 'Не больше двух знаков после запятой';

  @override
  String get settingsErrReturnDaysEmpty =>
      'Укажите количество дней (0 — без ограничения)';

  @override
  String get settingsErrReturnDaysInt => 'Введите целое число дней';

  @override
  String get settingsErrNotNegative => 'Не может быть отрицательным';

  @override
  String get settingsErrReturnDaysMax => 'Не больше 3650 дней (10 лет)';

  @override
  String get settingsErrStoreNameRequired =>
      'Название магазина обязательно — оно печатается в чеке';

  @override
  String settingsErrMaxLength(String max) {
    return 'Не длиннее $max символов';
  }

  @override
  String get settingsErrPhoneChars => 'Только цифры, пробел, +, - и скобки';

  @override
  String get settingsErrPhoneDigits => 'Проверьте номер: от 5 до 15 цифр';

  @override
  String get settingsErrTaxIdDigits => 'ИНН состоит только из цифр';

  @override
  String get settingsErrTaxIdLength => 'ИНН должен содержать от 9 до 14 цифр';

  @override
  String get settingsErrFooterLines => 'Не больше 6 строк';

  @override
  String settingsErrBanknoteNotNumber(String value) {
    return '«$value» — не число. Дробную часть пишите через точку';
  }

  @override
  String settingsErrBanknoteNoFraction(String value, String code) {
    return '«$value»: у $code нет дробных единиц';
  }

  @override
  String settingsErrBanknoteTooManyDecimals(String value) {
    return '«$value»: слишком много знаков после точки';
  }

  @override
  String settingsErrBanknotePositive(String value) {
    return '«$value» — номинал должен быть больше нуля';
  }

  @override
  String settingsErrBanknoteTooBig(String value) {
    return '«$value» — слишком большой номинал';
  }

  @override
  String settingsErrBanknoteDuplicate(String value) {
    return 'Номинал «$value» указан дважды';
  }

  @override
  String settingsErrBanknotesMax(String max) {
    return 'Не больше $max номиналов — кнопки должны помещаться на экране';
  }

  @override
  String get settingsErrRegisterNameEmpty => 'Введите название кассы';

  @override
  String get settingsErrRegisterDuplicate => 'Касса с таким названием уже есть';

  @override
  String get settingsCurrencyLocked =>
      'Валюту нельзя менять: в базе уже есть продажи';

  @override
  String get settingsRegisterBusy =>
      'На этой кассе открыта смена. Сначала закройте смену, затем отключайте или удаляйте кассу.';

  @override
  String get settingsRoundingNone => 'Без округления';

  @override
  String settingsRoundingStep(String amount) {
    return 'Кратно $amount';
  }

  @override
  String settingsLoyaltyExample(
    String purchase,
    String earned,
    String symbol,
    String percent,
    String redeem,
  ) {
    return 'С покупки $purchase начислится $earned бонусов (1 бонус = 1 $symbol). Бонусами можно оплатить до $percent% чека — до $redeem.';
  }

  @override
  String settingsBytes(String n) {
    return '$n Б';
  }

  @override
  String settingsKilobytes(String n) {
    return '$n КБ';
  }

  @override
  String settingsMegabytes(String n) {
    return '$n МБ';
  }

  @override
  String settingsGigabytes(String n) {
    return '$n ГБ';
  }

  @override
  String get settingsSampleCashier => 'Образец';

  @override
  String get settingsSampleItemMilk => 'Молоко 2,5% 1 л';

  @override
  String get settingsSampleItemBread => 'Хлеб белый';

  @override
  String get settingsSampleItemTea => 'Чай чёрный 100 г';

  @override
  String settingsDiagPlatform(String value) {
    return 'Платформа: $value';
  }

  @override
  String settingsDiagStore(String value) {
    return 'Магазин: $value';
  }

  @override
  String settingsCurrencyValue(String value) {
    return 'Валюта: $value';
  }

  @override
  String settingsDiagDemo(String value) {
    return 'Демо-режим: $value';
  }

  @override
  String get settingsYesLower => 'да';

  @override
  String get settingsNoLower => 'нет';

  @override
  String settingsDiagDbSize(String value) {
    return 'Размер базы: $value';
  }

  @override
  String settingsDiagProducts(String value) {
    return 'Товаров: $value';
  }

  @override
  String settingsDiagSales(String value) {
    return 'Продаж: $value';
  }

  @override
  String settingsDiagCustomers(String value) {
    return 'Клиентов: $value';
  }

  @override
  String settingsDiagUsers(String value) {
    return 'Сотрудников: $value';
  }

  @override
  String settingsDiagLastBackup(String value) {
    return 'Последняя резервная копия: $value';
  }

  @override
  String settingsDiagGenerated(String value) {
    return 'Сформировано: $value';
  }

  @override
  String get settingsErrBackupFailed => 'Не удалось создать резервную копию';

  @override
  String settingsErrNotBackup(String name) {
    return 'Файл «$name» не является резервной копией DreamPOS';
  }

  @override
  String get settingsCsvName => 'Наименование';

  @override
  String get settingsCsvMinStock => 'Мин. остаток';

  @override
  String get settingsCsvVatPercent => 'НДС %';

  @override
  String get settingsCsvActive => 'Активен';

  @override
  String get settingsCsvCard => 'Карта';

  @override
  String get settingsCsvDiscountPercent => 'Скидка %';

  @override
  String get settingsCsvDebtLimit => 'Лимит долга';

  @override
  String get settingsCsvTotalSpent => 'Покупок на сумму';

  @override
  String get settingsCsvVisits => 'Визитов';

  @override
  String settingsVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get settingsAboutTagline =>
      'Касса и учёт для розничных магазинов. Работает без интернета.';

  @override
  String get settingsLicense => 'Лицензия';

  @override
  String get settingsPlan => 'Тариф: «Магазин» (1 точка)';

  @override
  String get settingsTrialExpired => 'Пробный период истёк';

  @override
  String get settingsTrial => 'Пробный период';

  @override
  String get settingsTrialEnded =>
      'Пробный период закончился. Свяжитесь с поддержкой для продления — данные сохранены.';

  @override
  String settingsTrialLeft(int count, String total, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count дня из $total · установлено $date',
      many: 'Осталось $count дней из $total · установлено $date',
      few: 'Осталось $count дня из $total · установлено $date',
      one: 'Осталось $count день из $total · установлено $date',
    );
    return '$_temp0';
  }

  @override
  String get settingsSupport => 'Связаться с поддержкой';

  @override
  String get settingsSupportHint =>
      'При обращении в поддержку приложите сведения ниже — они помогут быстрее разобраться. Личные данные клиентов в них не входят.';

  @override
  String get settingsInfoCopied => 'Сведения скопированы';

  @override
  String get settingsCopyInfo => 'Копировать сведения';

  @override
  String get settingsRefresh => 'Обновить';

  @override
  String get settingsAppearanceDesc =>
      'Тема оформления применяется сразу на всех экранах этой программы.';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeAuto => 'Авто';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsThemeHint =>
      '«Авто» — как в настройках Windows/Android. Тёмная тема снижает нагрузку на глаза в вечернюю смену и экономит заряд на телефонах с OLED-экраном. Светлая лучше читается при ярком освещении торгового зала.';

  @override
  String settingsBackupCreated(String name, String size) {
    return 'Копия создана: $name ($size)';
  }

  @override
  String get settingsBackupDeleteTitle => 'Удалить копию?';

  @override
  String settingsBackupDeleteMessage(String name, String date, String size) {
    return '$name\n$date · $size\n\nФайл будет удалён с диска без возможности восстановления.';
  }

  @override
  String get settingsBackupDeleted => 'Копия удалена';

  @override
  String get settingsRestoreTitle => 'Восстановить данные из копии?';

  @override
  String settingsRestoreMessage(String date) {
    return 'Копия от $date заменит ВСЕ текущие данные: товары, продажи, клиентов, смены и настройки. Всё, что сделано после этой даты, пропадёт.\n\nПеред восстановлением будет автоматически создана копия текущих данных.\n\nДанные заменятся при следующем запуске программы.';
  }

  @override
  String get settingsRestore => 'Восстановить';

  @override
  String get settingsRestartTitle => 'Перезапустите программу';

  @override
  String get settingsRestartMessage =>
      'Восстановление подготовлено.\n\n1. Закройте DreamPOS на этом компьютере.\n2. Запустите программу снова — данные будут заменены копией.\n3. Войдите и проверьте товары и последние продажи.\n\nДо перезапуска не проводите продажи: они будут потеряны.';

  @override
  String get settingsGotIt => 'Понятно';

  @override
  String get settingsRestoreCancelled => 'Восстановление отменено';

  @override
  String get settingsBackupDesc =>
      'Копия базы данных защищает от потери данных при поломке компьютера, вирусе или ошибке. Храните копии также на флешке или в облаке.';

  @override
  String get settingsRestorePending =>
      'Восстановление из копии подготовлено. Перезапустите программу, чтобы заменить данные.';

  @override
  String get settingsLastBackup => 'Последняя копия';

  @override
  String get settingsNeverBackedUp => 'ещё не создавалась';

  @override
  String get settingsBackupWeekly =>
      'Рекомендуем делать копию хотя бы раз в неделю';

  @override
  String get settingsBackupCreateNow => 'Создать копию сейчас';

  @override
  String get settingsAutoBackup => 'Ежедневная автоматическая копия';

  @override
  String get settingsAutoBackupHint =>
      'Создаётся раз в сутки при запуске программы';

  @override
  String get settingsBackupFolder => 'Папка с копиями';

  @override
  String get settingsCopyPath => 'Копировать путь';

  @override
  String get settingsPathCopied => 'Путь скопирован';

  @override
  String get settingsBackups => 'Копии';

  @override
  String get settingsNoBackups =>
      'Копий пока нет. Нажмите «Создать копию сейчас».';

  @override
  String get settingsRestoreInfo =>
      'Восстановление заменяет все данные программы содержимым копии и требует перезапуска. Перед восстановлением автоматически создаётся копия текущих данных.';

  @override
  String get settingsCurUzs => 'Узбекский сум';

  @override
  String get settingsCurTjs => 'Таджикский сомони';

  @override
  String get settingsCurKzt => 'Казахстанский тенге';

  @override
  String get settingsCurKgs => 'Киргизский сом';

  @override
  String get settingsCurRub => 'Российский рубль';

  @override
  String get settingsCurUsd => 'Доллар США';

  @override
  String settingsCurChangeTitle(String code) {
    return 'Сменить валюту на $code?';
  }

  @override
  String settingsCurChangeSymbol(String symbol) {
    return 'Все суммы будут показываться в «$symbol».';
  }

  @override
  String settingsCurChangeRescale(String products, String from, String to) {
    return 'Внимание: у вас уже заведено товаров: $products. Цены хранятся в минимальных единицах, поэтому цена $from станет $to. Проверьте и исправьте цены после смены валюты.';
  }

  @override
  String get settingsCurChangeResetsCash =>
      'Номиналы купюр быстрой оплаты и округление наличных будут сброшены на стандартные для новой валюты (раздел «Продажи»).';

  @override
  String get settingsCurChangeFinal =>
      'После первой продажи валюту изменить будет нельзя.';

  @override
  String get settingsCurChangeOk => 'Сменить валюту';

  @override
  String get settingsCurrencyDesc =>
      'Валюта, в которой ведётся учёт, и ставка НДС по умолчанию для новых товаров.';

  @override
  String get settingsCurBase => 'Валюта учёта';

  @override
  String get settingsCurLockedTooltip =>
      'Валюта зафиксирована после первой продажи';

  @override
  String get settingsCurLockedBanner =>
      'Валюта зафиксирована: в базе уже есть продажи. Все суммы в чеках, отчётах, долгах и бонусах хранятся в этой валюте — её смена исказила бы всю историю.';

  @override
  String settingsCurCheckFailed(String error) {
    return 'Не удалось проверить наличие продаж: $error';
  }

  @override
  String settingsCurExampleCents(String amount) {
    return 'Пример: $amount · с копейками';
  }

  @override
  String settingsCurExampleNoCents(String amount) {
    return 'Пример: $amount · без копеек';
  }

  @override
  String get settingsVatDefault => 'НДС по умолчанию для новых товаров';

  @override
  String get settingsVatHelper => '0 — если магазин не плательщик НДС';

  @override
  String get settingsVatInfo =>
      'Цены товаров указываются с НДС. Сумма НДС выделяется из цены по ставке товара и печатается в чеке строкой «в т.ч. НДС». Ставку можно изменить в карточке товара.';

  @override
  String settingsFileSaved(String path) {
    return 'Файл сохранён: $path';
  }

  @override
  String get settingsDataDesc =>
      'Демо-режим и выгрузка справочников в файлы для Excel.';

  @override
  String get settingsMode => 'Режим работы';

  @override
  String get settingsDemoMode => 'Демо-режим';

  @override
  String get settingsLiveDb => 'Рабочая база';

  @override
  String get settingsDemoText =>
      'Сейчас в базе демонстрационные товары, клиенты и продажи. Они нужны, чтобы познакомиться с программой. Не смешивайте их с реальной торговлей.';

  @override
  String get settingsLiveText =>
      'Программа работает с реальными данными магазина.';

  @override
  String get settingsDemoWarning =>
      'Удалить демо-данные кнопкой нельзя: это необратимо и затронуло бы отчёты, остатки и журнал. Чтобы начать работу с чистой базой:';

  @override
  String get settingsDemoStep1 =>
      'Создайте резервную копию (раздел «Резервное копирование») — на случай, если демо-данные ещё понадобятся.';

  @override
  String get settingsDemoStep2 => 'Закройте программу.';

  @override
  String get settingsDemoStep3 =>
      'Удалите файл базы данных и, если есть, файлы рядом с ним, имя которых оканчивается на «wal» или «shm».';

  @override
  String settingsDbFile(String path) {
    return 'Файл базы: $path';
  }

  @override
  String get settingsDemoStep4 =>
      'Запустите DreamPOS — откроется мастер первоначальной настройки. Не отмечайте «Демо-данные».';

  @override
  String get settingsCopyDbPath => 'Копировать путь к базе';

  @override
  String get settingsExportProductsHint =>
      'Наименование, штрихкод, цены, остатки';

  @override
  String get settingsExportCustomersHint => 'Контакты, скидки, бонусы и долги';

  @override
  String get settingsExportInfo =>
      'Файлы сохраняются в папку «Документы/DreamPOS/exports» в формате CSV (разделитель «;», кодировка UTF-8) — открываются в Excel и Google Таблицах. Файл клиентов содержит телефоны и долги — не пересылайте его посторонним.';

  @override
  String get settingsLastFile => 'Последний файл';

  @override
  String get settingsDevicesDesc =>
      'Кассовые места магазина, привязка этого компьютера к кассе, сканер и принтер чеков.';

  @override
  String settingsRegisterAdded(String name) {
    return 'Касса «$name» добавлена';
  }

  @override
  String get settingsRegisterSaved => 'Касса сохранена';

  @override
  String settingsRegisterDeleteTitle(String name) {
    return 'Удалить кассу «$name»?';
  }

  @override
  String get settingsRegisterDeleteMessage =>
      'Касса исчезнет из списка. Проданные на ней чеки и отчёты сохранятся.';

  @override
  String get settingsRegisterDeleted => 'Касса удалена';

  @override
  String get settingsRegisters => 'Кассы';

  @override
  String get settingsNoRegisters =>
      'Касс пока нет. Добавьте кассу, если в магазине несколько кассовых мест — тогда в отчётах будет видно, где пробит чек.';

  @override
  String get settingsRegisterDisabled => 'Отключена';

  @override
  String get settingsThisDevice => 'Этот компьютер';

  @override
  String settingsRegisterDefaultName(String number) {
    return 'Касса $number';
  }

  @override
  String get settingsNewRegister => 'Новая касса';

  @override
  String get settingsRegister => 'Касса';

  @override
  String get settingsRegisterNameHint => 'Касса 1, Склад, Отдел №2';

  @override
  String get settingsRegisterActive => 'Активна';

  @override
  String get settingsRegisterActiveHint =>
      'Отключённую кассу нельзя выбрать для работы';

  @override
  String get settingsThisDeviceHint =>
      'Выберите, какой кассой работает это устройство. Настройка хранится только на этом компьютере и не переносится на другие.';

  @override
  String get settingsAddRegisterFirst =>
      'Сначала добавьте хотя бы одну активную кассу.';

  @override
  String get settingsDeviceRegister => 'Касса этого устройства';

  @override
  String get settingsNotSelected => 'Не выбрана';

  @override
  String get settingsDeviceRegisterSet => 'Касса для этого устройства выбрана';

  @override
  String get settingsDeviceRegisterGone =>
      'Ранее выбранная касса удалена или отключена — выберите другую.';

  @override
  String get settingsTestPrintTitle => 'ТЕСТОВАЯ ПЕЧАТЬ';

  @override
  String get settingsNotFiscal => 'Не является фискальным документом';

  @override
  String get settingsTestReceiptJob => 'Тестовый чек';

  @override
  String get settingsPrinter => 'Принтер чеков';

  @override
  String settingsPrinterHint(String width) {
    return 'Чек печатается через системный диалог печати. Установите драйвер принтера и выберите его принтером по умолчанию. Ширина ленты сейчас: $width мм (меняется в разделе «Магазин»).';
  }

  @override
  String get settingsPrintTest => 'Напечатать тестовый чек';

  @override
  String get settingsScanner => 'Сканер штрихкодов';

  @override
  String get settingsScannerTip1 =>
      'Подключите USB‑сканер — он работает как клавиатура, драйвер обычно не нужен.';

  @override
  String get settingsScannerTip2 =>
      'Сканер должен отправлять Enter после кода (суффикс CR). Так настроено у большинства моделей.';

  @override
  String get settingsScannerTip3 =>
      'Раскладка клавиатуры: если вместо цифр печатаются другие символы, переключите раскладку на EN или настройте сканер на «цифровой» режим.';

  @override
  String get settingsScannerTip4 =>
      'Проверка: откройте поиск товара и отсканируйте штрихкод — код должен появиться целиком.';

  @override
  String get settingsScannerTip5 =>
      'Беспроводные сканеры работают так же; держите базу в пределах 10 м от кассы.';

  @override
  String get settingsLoyaltyDesc =>
      'Бонусная программа: клиент получает бонусы с покупок и оплачивает ими часть следующих покупок. 1 бонус = 1 единица валюты.';

  @override
  String get settingsLoyaltyEnabled => 'Бонусная программа включена';

  @override
  String get settingsLoyaltyEnabledHint =>
      'Бонусы начисляются только покупателям, выбранным в чеке';

  @override
  String get settingsRules => 'Правила';

  @override
  String get settingsLoyaltyOff =>
      'Программа выключена: бонусы не начисляются и не списываются. Накопленные балансы клиентов сохраняются.';

  @override
  String get settingsEarnLabel => 'Начислять с покупки';

  @override
  String get settingsPercentRangeHelper => 'От 0 до 100';

  @override
  String get settingsRedeemLabel => 'Оплата бонусами, не больше';

  @override
  String get settingsRedeemSuffix => '% чека';

  @override
  String get settingsLoyaltyEnterPercents =>
      'Введите проценты от 0 до 100, чтобы увидеть пример.';

  @override
  String get settingsLoyaltyReturnInfo =>
      'При возврате товара начисленные за него бонусы списываются пропорционально. Новые проценты действуют для следующих продаж; прошлые чеки не пересчитываются.';

  @override
  String get settingsShiftOffTitle => 'Разрешить продажи без смены?';

  @override
  String get settingsShiftOffMessage =>
      'Не рекомендуется. Без открытой смены:\n• не будет контроля наличных в кассе и Z-отчёта;\n• продажи не попадут ни в одну смену, расхождения не найти;\n• кассиры смогут продавать, не пересчитав размен.\n\nОтключайте, только если касса не принимает наличные.';

  @override
  String get settingsShiftOffOk => 'Всё равно отключить';

  @override
  String get settingsNegativeTitle => 'Разрешить продажу при нулевом остатке?';

  @override
  String get settingsNegativeMessage =>
      'Остаток сможет уйти в минус. Это удобно, если приход оформляют позже продажи, но скрывает пересорт и недостачи. Отрицательные остатки нужно регулярно исправлять приходом или инвентаризацией.';

  @override
  String get settingsAllow => 'Разрешить';

  @override
  String get settingsSalesDesc =>
      'Правила, которые касса проверяет при каждой продаже и возврате.';

  @override
  String get settingsControl => 'Контроль';

  @override
  String get settingsRequireShift => 'Продавать только при открытой смене';

  @override
  String get settingsRequireShiftHint =>
      'Рекомендуется: контроль наличных и Z-отчёт по каждой смене';

  @override
  String get settingsAllowNegative => 'Разрешить продажу при нулевом остатке';

  @override
  String get settingsAllowNegativeHint =>
      'Остаток может уйти в минус (для всех товаров)';

  @override
  String get settingsDebtLimit => 'В долг — только клиентам с лимитом';

  @override
  String get settingsDebtLimitHint =>
      'Продажа в долг клиенту без установленного лимита будет запрещена';

  @override
  String get settingsReturns => 'Возвраты';

  @override
  String get settingsReturnDays => 'Срок возврата, дней';

  @override
  String get settingsDaysSuffix => 'дн.';

  @override
  String get settingsReturnNoLimit => 'Без ограничения срока';

  @override
  String settingsReturnWithin(String days) {
    return 'Возврат по чеку возможен в течение $days дней. 0 — без ограничения';
  }

  @override
  String get settingsQuickCash => 'Быстрая оплата наличными';

  @override
  String get settingsBanknotesLabel => 'Номиналы купюр на экране оплаты';

  @override
  String settingsBanknotesHelper(String max) {
    return 'Через запятую, до $max штук. Пусто — стандартный набор';
  }

  @override
  String get settingsPosButtons => 'Кнопки на кассе:';

  @override
  String get settingsCashRounding => 'Округление наличных';

  @override
  String get settingsRoundingLabel => 'Округлять итог при оплате наличными';

  @override
  String settingsRoundingChanged(String value) {
    return 'Округление: $value';
  }

  @override
  String get settingsRoundingOff => 'Итог к оплате наличными не округляется.';

  @override
  String settingsRoundingExample(String from, String to) {
    return 'Пример: $from → $to. Округляется вниз, в пользу покупателя, только при оплате наличными.';
  }

  @override
  String get settingsStoreName => 'Название магазина *';

  @override
  String get settingsStoreNameHelper =>
      'Печатается в шапке чека и на экране входа';

  @override
  String get settingsAddressHint => 'г. Ташкент, ул. Навои, 12';

  @override
  String get settingsTaxId => 'ИНН / БИН';

  @override
  String get settingsTaxIdHelper => 'Только цифры, 9–14 знаков';

  @override
  String get settingsFooter => 'Текст внизу чека';

  @override
  String get settingsFooterHint =>
      'Спасибо за покупку!\nОбмен и возврат в течение 14 дней';

  @override
  String get settingsPaperWidth => 'Ширина ленты';

  @override
  String get settingsPaperWidthHint =>
      'Смотрите в инструкции принтера: 58 мм — компактные, 80 мм — стандартные';

  @override
  String settingsMm(String width) {
    return '$width мм';
  }

  @override
  String get settingsAutoPrint => 'Печатать чек автоматически';

  @override
  String get settingsAutoPrintHint => 'Сразу после оплаты, без вопроса кассиру';

  @override
  String get settingsStoreDesc =>
      'Реквизиты магазина и оформление чека. Изменения сразу видны в образце чека.';

  @override
  String get settingsReceiptSample => 'Образец чека';

  @override
  String get settingsSecSync => 'Синхронизация';

  @override
  String get settingsSecSyncHint => 'Несколько касс, облако';

  @override
  String get shiftClosingTitle => 'Закрытие смены';

  @override
  String get shiftClosed => 'Смена закрыта';

  @override
  String get shiftCloseConfirmTitle => 'Закрыть смену?';

  @override
  String shiftCountedValue(String amount) {
    return 'Пересчитано: $amount';
  }

  @override
  String shiftExpectedValue(String amount) {
    return 'Ожидалось: $amount';
  }

  @override
  String get shiftShortage => 'Недостача';

  @override
  String get shiftSurplus => 'Излишек';

  @override
  String shiftCollectionAtCloseValue(String amount) {
    return 'Инкассация при закрытии: $amount';
  }

  @override
  String get shiftCloseConfirmMessage =>
      'После закрытия продажи будут недоступны до открытия новой смены.';

  @override
  String get shiftCloseAction => 'Закрыть смену';

  @override
  String get shiftCountCashHint => 'Пересчитайте наличные в денежном ящике.';

  @override
  String get shiftByDenomination => 'По купюрам';

  @override
  String get shiftByTotal => 'Общей суммой';

  @override
  String get shiftCashInDrawer => 'Наличные в кассе';

  @override
  String get shiftExpectedInDrawer => 'Ожидается в кассе';

  @override
  String get shiftInclGiftCash => 'в т.ч. сертификаты (нал.)';

  @override
  String get shiftCounted => 'Пересчитано';

  @override
  String get shiftDifference => 'Расхождение';

  @override
  String get shiftDiffReasonLabel => 'Причина расхождения *';

  @override
  String get shiftNoteOptional => 'Примечание (необязательно)';

  @override
  String get shiftCollectionAtClose => 'Инкассация при закрытии';

  @override
  String shiftCollectionSummary(String collect, String leave) {
    return 'Сдать $collect, оставить $leave на размен';
  }

  @override
  String get shiftCollectionHint =>
      'Сдать часть выручки и оставить размен на следующую смену';

  @override
  String get shiftCollectionAmount => 'Сумма инкассации';

  @override
  String get shiftCollectAll => 'Сдать всё';

  @override
  String get shiftNoDifference => 'без расхождений';

  @override
  String get shiftShortageLower => 'недостача';

  @override
  String get shiftSurplusLower => 'излишек';

  @override
  String shiftOpenedToast(String amount) {
    return 'Смена открыта. Размен: $amount';
  }

  @override
  String get shiftOpenHint =>
      'Чтобы начать продавать, откройте смену и укажите сумму размена в кассе.';

  @override
  String get shiftOpeningCash => 'Размен на начало смены';

  @override
  String get shiftOpeningSuggested => 'Предложено: остаток после прошлой смены';

  @override
  String get shiftOpeningCashNow => 'Наличные в денежном ящике сейчас';

  @override
  String get shiftNoRightOpen => 'Нет права открывать смену';

  @override
  String get shiftOpenAction => 'Открыть смену';

  @override
  String get shiftSales => 'Продажи';

  @override
  String shiftSalesHint(String receipts, String avg) {
    return '$receipts · средний $avg';
  }

  @override
  String get shiftReturns => 'Возвраты';

  @override
  String get shiftNoReturns => 'Возвратов не было';

  @override
  String get shiftGrossProfit => 'Валовая прибыль';

  @override
  String get shiftNetRevenue => 'Выручка без возвратов';

  @override
  String shiftRevenueValue(String amount) {
    return 'Выручка $amount';
  }

  @override
  String shiftExpectedHint(String amount) {
    return 'Наличные · размен $amount';
  }

  @override
  String get shiftXReport => 'X-отчёт';

  @override
  String get shiftZReport => 'Z-отчёт';

  @override
  String shiftNumber(String number) {
    return 'Смена №$number';
  }

  @override
  String get shiftStatusOpen => 'Открыта';

  @override
  String shiftOpenedAt(String date) {
    return 'Открыта $date';
  }

  @override
  String get shiftJustNow => 'только что';

  @override
  String shiftRunning(String duration) {
    return 'идёт $duration';
  }

  @override
  String shiftHoursMinutes(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String shiftMinutes(String minutes) {
    return '$minutes мин';
  }

  @override
  String get shiftCloseTooltip => 'Пересчитать кассу и закрыть смену (Z-отчёт)';

  @override
  String get shiftNoRightClose => 'Нет права закрывать смену';

  @override
  String get shiftCashOperations => 'Кассовые операции';

  @override
  String get shiftNoRightCash => 'Нет права на кассовые операции';

  @override
  String get shiftOperationsList => 'Операции за смену';

  @override
  String get shiftNoOperations => 'Внесений и выплат ещё не было';

  @override
  String shiftNumberOpen(String number) {
    return 'Смена №$number открыта';
  }

  @override
  String get shiftTabCurrent => 'Текущая смена';

  @override
  String get shiftTabHistory => 'История смен';

  @override
  String get shiftOnlyMine => 'Только мои смены';

  @override
  String get shiftHistoryEmptyTitle => 'Смен пока нет';

  @override
  String get shiftHistoryEmptyMessage =>
      'Закрытые смены и их Z-отчёты появятся здесь';

  @override
  String get shiftPickShift => 'Выберите смену';

  @override
  String get shiftPickShiftMessage =>
      'Здесь будет её отчёт с возможностью печати';

  @override
  String get shiftNow => 'сейчас';

  @override
  String get shiftEnterCountedCash => 'Введите сумму наличных в кассе';

  @override
  String get shiftAmountNegative => 'Сумма не может быть отрицательной';

  @override
  String get shiftCollectionNegative =>
      'Сумма инкассации не может быть отрицательной';

  @override
  String get shiftCollectionTooBig =>
      'Инкассация не может превышать пересчитанную сумму';

  @override
  String get shiftEnterDiffReason => 'Укажите причину расхождения';

  @override
  String get shiftKindPayIn => 'Внесение';

  @override
  String get shiftKindPayOut => 'Выплата';

  @override
  String get shiftKindExpense => 'Расход';

  @override
  String get shiftKindCollection => 'Инкассация';

  @override
  String get shiftExpRent => 'Аренда';

  @override
  String get shiftExpSalary => 'Зарплата';

  @override
  String get shiftExpSupplies => 'Хозтовары';

  @override
  String get shiftExpTransport => 'Транспорт';

  @override
  String get shiftExpUtilities => 'Коммунальные';

  @override
  String get shiftExpOther => 'Прочее';

  @override
  String get shiftKindPayInHint => 'Размен, возврат подотчёта и т.п.';

  @override
  String get shiftKindPayOutHint =>
      'Выдача наличных из кассы (подотчёт, аванс)';

  @override
  String get shiftKindExpenseHint => 'Оплата расходов магазина из кассы';

  @override
  String get shiftKindCollectionHint => 'Сдача выручки владельцу / в банк';

  @override
  String get shiftPickExpenseCategory => 'Выберите категорию расхода';

  @override
  String shiftCashInDrawerNow(String amount) {
    return 'В кассе сейчас: $amount';
  }

  @override
  String get shiftEnterAmount => 'Введите сумму';

  @override
  String shiftOnlyInDrawer(String amount) {
    return 'В кассе только $amount';
  }

  @override
  String get shiftExpenseCategory => 'Категория расхода';

  @override
  String get shiftReasonRequired => 'Основание / комментарий *';

  @override
  String get shiftPayOutHint => 'Кому и зачем выданы деньги';

  @override
  String get shiftEnterReason => 'Укажите основание';

  @override
  String get shiftSaving => 'Сохранение…';

  @override
  String get shiftPost => 'Провести';

  @override
  String get shiftZShiftNo => 'Смена №';

  @override
  String get shiftZOpened => 'Открыта';

  @override
  String get shiftZClosed => 'Закрыта';

  @override
  String get shiftZReceipts => 'Чеков';

  @override
  String get shiftZSalesTotal => 'Сумма продаж';

  @override
  String shiftZIncl(String method) {
    return 'в т.ч. $method';
  }

  @override
  String get shiftZDiscounts => 'Скидки';

  @override
  String get shiftZAvgCheck => 'Средний чек';

  @override
  String get shiftZVoidedReceipts => 'Аннулировано чеков';

  @override
  String get shiftZReturnsCount => 'Возвратов';

  @override
  String get shiftZReturnsTotal => 'Сумма возвратов';

  @override
  String get shiftZGiftCards => 'Сертификаты';

  @override
  String get shiftZSold => 'Продано';

  @override
  String get shiftZGiftSalesTotal => 'Сумма продаж (аванс)';

  @override
  String get shiftZVoided => 'Аннулировано';

  @override
  String get shiftZRefundedToBuyers => 'Возвращено покупателям';

  @override
  String get shiftZCashImpact => 'Влияние на кассу (нал.)';

  @override
  String get shiftZAdvanceNote => 'аванс, не входит в выручку';

  @override
  String get shiftZSummary => 'Итог';

  @override
  String get shiftZNetRevenue => 'Выручка (за вычетом возвратов)';

  @override
  String get shiftZCash => 'Касса (наличные)';

  @override
  String get shiftZOpeningCash => 'Размен на начало';

  @override
  String get shiftZCashSales => 'Наличные продажи';

  @override
  String get shiftZCashRefunds => 'Наличные возвраты';

  @override
  String get shiftZDebtCash => 'Погашение долгов (нал.)';

  @override
  String get shiftZDebtNonCash => 'Погашение долгов (безнал.)';

  @override
  String get shiftZSupplierPaid => 'Оплаты поставщикам';

  @override
  String get shiftZGiftCash => 'Сертификаты (нал., аванс)';

  @override
  String get shiftZActual => 'Фактически';

  @override
  String shiftZPrinted(String date) {
    return 'Печать: $date';
  }

  @override
  String get shiftZCashierSign => 'Кассир';

  @override
  String get shiftZReceivedSign => 'Принял';

  @override
  String shiftZTitleA4(String title, String number) {
    return '$title — смена №$number';
  }

  @override
  String shiftZGenerated(String date) {
    return 'Сформирован: $date';
  }

  @override
  String shiftZFileName(String title, String number) {
    return '$title смена $number';
  }

  @override
  String get shiftPrintUnavailable => 'Печать недоступна';

  @override
  String get shiftRoll80 => 'Чековая лента 80 мм';

  @override
  String get shiftSheetA4 => 'Лист A4';

  @override
  String shiftReportHeader(String title, String number) {
    return '$title · смена №$number';
  }

  @override
  String get shiftReportTitle => 'Отчёт по смене';

  @override
  String get staffTitle => 'Сотрудники';

  @override
  String get staffNoAccess => 'Нет доступа';

  @override
  String get staffNoAccessHint => 'Раздел доступен владельцу и администратору';

  @override
  String get staffTabTime => 'Рабочее время';

  @override
  String get staffTabMotivation => 'Мотивация';

  @override
  String get staffTabRoles => 'Роли и права';

  @override
  String get staffTabAudit => 'Журнал действий';

  @override
  String get staffRolesHint =>
      'Права ролей заданы системой. Чтобы изменить доступ сотрудника, смените его роль.';

  @override
  String get staffPermColumn => 'Право';

  @override
  String get staffErrLastOwner =>
      'Это единственный активный владелец. Сначала назначьте другого владельца';

  @override
  String get staffErrNameTooLong => 'Имя слишком длинное';

  @override
  String get staffErrSetPin => 'Задайте PIN';

  @override
  String get staffErrMaxDiscountRange => 'Макс. скидка — от 0 до 100%';

  @override
  String get staffErrCommissionRange => 'Комиссия — от 0 до 100%';

  @override
  String get staffErrPlanNegative => 'План не может быть отрицательным';

  @override
  String get staffErrPhoneFormat => 'Неверный формат телефона';

  @override
  String get staffErrOwnerRoleOnlyOwner =>
      'Назначить роль «Владелец» может только владелец';

  @override
  String get staffErrOwnerEditOnlyOwner =>
      'Изменять данные владельца может только владелец';

  @override
  String get staffErrCannotDeactivateSelf =>
      'Нельзя деактивировать собственную учётную запись';

  @override
  String get staffErrActivateNeedsPin =>
      'Для активации задайте сотруднику новый PIN';

  @override
  String staffDurationMin(String m) {
    return '$m мин';
  }

  @override
  String staffDurationHm(String h, String m) {
    return '$h ч $m мин';
  }

  @override
  String staffErrAlreadyClockedIn(String time) {
    return 'Приход уже отмечен в $time';
  }

  @override
  String get staffErrClockInFirst => 'Сначала отметьте приход';

  @override
  String get staffErrEndBeforeStart =>
      'Время ухода должно быть позже времени прихода';

  @override
  String get staffErrStartInFuture => 'Время прихода не может быть в будущем';

  @override
  String get staffErrEndInFuture => 'Время ухода не может быть в будущем';

  @override
  String get staffErrTooLong => 'Смена не может длиться больше 24 часов';

  @override
  String staffErrOverlap(String from, String to) {
    return 'Пересекается с другой записью ($from — $to)';
  }

  @override
  String get staffNow => 'сейчас';

  @override
  String get staffErrOpenExists => 'У сотрудника уже есть незавершённая запись';

  @override
  String get staffPermSell => 'Продажа (касса)';

  @override
  String get staffPermApplyDiscount => 'Ручные скидки';

  @override
  String get staffPermVoidSale => 'Аннулирование чеков';

  @override
  String get staffPermRefund => 'Возвраты';

  @override
  String get staffPermOpenCloseShift => 'Открытие/закрытие смены';

  @override
  String get staffPermCashInOut => 'Внесения и выплаты';

  @override
  String get staffPermViewProducts => 'Просмотр товаров';

  @override
  String get staffPermEditProducts => 'Редактирование товаров';

  @override
  String get staffPermEditPrices => 'Изменение цен';

  @override
  String get staffPermViewCost => 'Себестоимость и прибыль';

  @override
  String get staffPermStockOps => 'Складские операции';

  @override
  String get staffPermPurchasing => 'Закупки';

  @override
  String get staffPermViewCustomers => 'Просмотр клиентов';

  @override
  String get staffPermEditCustomers => 'Редактирование клиентов';

  @override
  String get staffPermManageDebts => 'Долги клиентов';

  @override
  String get staffPermManagePromotions => 'Акции и маркетинг';

  @override
  String get staffPermViewReports => 'Отчёты';

  @override
  String get staffPermViewAllShifts => 'Все смены';

  @override
  String get staffPermManageStaff => 'Управление сотрудниками';

  @override
  String get staffPermManageSettings => 'Настройки';

  @override
  String get staffPermViewAudit => 'Журнал действий';

  @override
  String get staffAuditAuthLogin => 'Вход в систему';

  @override
  String get staffAuditAuthFail => 'Неверный PIN';

  @override
  String get staffAuditAuthLogout => 'Выход из системы';

  @override
  String get staffAuditSaleDiscount => 'Скидка в чеке';

  @override
  String get staffAuditSaleReturn => 'Возврат';

  @override
  String get staffAuditSaleVoid => 'Аннулирование чека';

  @override
  String get staffAuditSaleCreate => 'Продажа';

  @override
  String get staffAuditShiftOpen => 'Открытие смены';

  @override
  String get staffAuditShiftClose => 'Закрытие смены';

  @override
  String get staffAuditCashPayIn => 'Внесение в кассу';

  @override
  String get staffAuditCashPayOut => 'Выплата из кассы';

  @override
  String get staffAuditCashExpense => 'Расход из кассы';

  @override
  String get staffAuditCashCollection => 'Инкассация';

  @override
  String get staffAuditStockReceive => 'Приход товара';

  @override
  String get staffAuditStockWriteoff => 'Списание товара';

  @override
  String get staffAuditStockAdjust => 'Корректировка остатка';

  @override
  String get staffAuditStockSet => 'Установка остатка';

  @override
  String get staffAuditUserCreate => 'Создан сотрудник';

  @override
  String get staffAuditUserUpdate => 'Изменены данные сотрудника';

  @override
  String get staffAuditUserRole => 'Изменена роль сотрудника';

  @override
  String get staffAuditUserPinChange => 'Смена PIN';

  @override
  String get staffAuditUserActivate => 'Сотрудник активирован';

  @override
  String get staffAuditUserDeactivate => 'Сотрудник деактивирован';

  @override
  String get staffAuditProductPrice => 'Изменение цены';

  @override
  String get staffAuditDebtPayment => 'Погашение долга';

  @override
  String get staffAuditBonusAdjust => 'Корректировка бонусов';

  @override
  String get staffAuditInventoryComplete => 'Инвентаризация проведена';

  @override
  String get staffAuditDiscountOverride => 'Скидка сверх лимита';

  @override
  String get staffAuditDiscountApprove => 'Скидка подтверждена менеджером';

  @override
  String get staffAuditAuthApproveFail => 'Неверный PIN подтверждения';

  @override
  String get staffAuditBackupAuto => 'Автоматическая резервная копия';

  @override
  String get staffAuditTimeClockIn => 'Приход на работу';

  @override
  String get staffAuditTimeClockOut => 'Уход с работы';

  @override
  String get staffAuditTimeAdd => 'Добавлена запись рабочего времени';

  @override
  String get staffAuditTimeEdit => 'Изменена запись рабочего времени';

  @override
  String get staffAuditTimeDelete => 'Удалена запись рабочего времени';

  @override
  String get staffAuditStockReceipt => 'Приход товара';

  @override
  String get staffAuditProductCreate => 'Создан товар';

  @override
  String get staffAuditProductUpdate => 'Изменён товар';

  @override
  String get staffAuditProductDelete => 'Удалён товар';

  @override
  String get staffAuditProductCost => 'Изменение себестоимости';

  @override
  String get staffAuditProductImport => 'Импорт товаров';

  @override
  String get staffAuditProductBulkPrice => 'Массовое изменение цен';

  @override
  String get staffAuditProductBulkCategory => 'Массовая смена категории';

  @override
  String get staffAuditCategoryDelete => 'Удалена категория';

  @override
  String get staffAuditCustomerCreate => 'Создан клиент';

  @override
  String get staffAuditCustomerDelete => 'Удалён клиент';

  @override
  String get staffAuditCustomerTerms => 'Изменены условия клиента';

  @override
  String get staffAuditSupplierPayment => 'Оплата поставщику';

  @override
  String get staffAuditSupplierDelete => 'Удалён поставщик';

  @override
  String get staffAuditPoOrdered => 'Заказ поставщику отправлен';

  @override
  String get staffAuditPoReceive => 'Приёмка заказа поставщика';

  @override
  String get staffAuditPromotionCreate => 'Создана акция';

  @override
  String get staffAuditPromotionUpdate => 'Изменена акция';

  @override
  String get staffAuditPromotionDelete => 'Удалена акция';

  @override
  String get staffAuditGiftCardIssue => 'Выпущен подарочный сертификат';

  @override
  String get staffAuditWarrantyCreate => 'Гарантийное обращение';

  @override
  String get staffAuditWarrantyStatus => 'Статус гарантийного обращения';

  @override
  String get staffAuditInventoryCreate => 'Начата инвентаризация';

  @override
  String get staffAuditInventoryCancel => 'Инвентаризация отменена';

  @override
  String get staffAuditPosPriceEdit => 'Изменение цены в чеке';

  @override
  String get staffAuditPosCartClear => 'Очистка чека';

  @override
  String get staffAuditSettingsChange => 'Изменены настройки';

  @override
  String get staffAuditRegisterDelete => 'Удалена касса';

  @override
  String get staffAuditRegisterBindDevice => 'Привязка устройства к кассе';

  @override
  String get staffAuditDataExport => 'Экспорт данных';

  @override
  String get staffAuditBackupCreate => 'Создана резервная копия';

  @override
  String get staffAuditBackupDelete => 'Удалена резервная копия';

  @override
  String get staffAuditBackupRestoreScheduled => 'Запланировано восстановление';

  @override
  String get staffAuditBackupRestoreCancelled => 'Восстановление отменено';

  @override
  String get staffAuditBackupRestoreApplied => 'Данные восстановлены из копии';

  @override
  String get staffGroupAuth => 'Вход';

  @override
  String get staffGroupSale => 'Продажи';

  @override
  String get staffGroupShift => 'Смены';

  @override
  String get staffGroupCash => 'Касса';

  @override
  String get staffGroupStock => 'Склад';

  @override
  String get staffGroupInventory => 'Инвентаризация';

  @override
  String get staffGroupUser => 'Сотрудники';

  @override
  String get staffGroupTime => 'Рабочее время';

  @override
  String get staffGroupProduct => 'Товары';

  @override
  String get staffGroupDebt => 'Долги';

  @override
  String get staffGroupBonus => 'Бонусы';

  @override
  String get staffGroupDiscount => 'Скидки';

  @override
  String get staffGroupPos => 'Касса (чек)';

  @override
  String get staffGroupCustomer => 'Клиенты';

  @override
  String get staffGroupSupplier => 'Поставщики';

  @override
  String get staffGroupPo => 'Закупки';

  @override
  String get staffGroupPromotion => 'Акции';

  @override
  String get staffGroupSettings => 'Настройки';

  @override
  String get staffGroupBackup => 'Резервные копии';

  @override
  String get staffDetailDiscount => 'скидка';

  @override
  String get staffDetailTotal => 'сумма';

  @override
  String get staffDetailOpening => 'размен';

  @override
  String get staffDetailExpected => 'ожидалось';

  @override
  String get staffDetailCounted => 'пересчитано';

  @override
  String get staffDetailManual => 'ручная скидка';

  @override
  String get staffDetailMethod => 'способ';

  @override
  String get staffMethodCash => 'наличные';

  @override
  String get staffMethodCard => 'карта';

  @override
  String get staffMethodDebt => 'в долг';

  @override
  String get staffMethodBonus => 'бонусы';

  @override
  String get staffMethodTransfer => 'перевод';

  @override
  String get staffMethodGiftCard => 'сертификат';

  @override
  String staffDetailPromos(String list) {
    return 'акции: $list';
  }

  @override
  String staffDetailReturnNo(String number) {
    return 'чек возврата №$number';
  }

  @override
  String get staffSearchHint => 'Имя или телефон';

  @override
  String get staffInactiveFilter => 'Неактивные';

  @override
  String get staffInactiveFilterTip => 'Показать деактивированных сотрудников';

  @override
  String get staffAddUser => 'Добавить сотрудника';

  @override
  String get staffEmpty => 'Сотрудников пока нет';

  @override
  String get staffNobodyFound => 'Никого не найдено';

  @override
  String get staffEmptyHint =>
      'Добавьте кассиров и менеджеров, чтобы они могли входить по PIN';

  @override
  String staffDeactivateTitle(String name) {
    return 'Деактивировать $name?';
  }

  @override
  String get staffDeactivateMessage =>
      'Сотрудник не сможет входить в систему, его открытая отметка рабочего времени будет закрыта. История продаж и смен сохранится. Активировать можно в любой момент.';

  @override
  String get staffDeactivate => 'Деактивировать';

  @override
  String staffDeactivated(String name) {
    return '$name деактивирован(а)';
  }

  @override
  String staffActivateTitle(String name) {
    return 'Активировать $name';
  }

  @override
  String get staffActivateMessage =>
      'Задайте новый PIN — старый мог быть выдан другому сотруднику.';

  @override
  String staffReactivated(String name) {
    return '$name снова активен(на)';
  }

  @override
  String get staffNeverLoggedIn => 'ещё не входил(а)';

  @override
  String staffLastLogin(String date) {
    return 'вход $date';
  }

  @override
  String get staffYou => 'Вы';

  @override
  String get staffInactiveChip => 'Неактивен';

  @override
  String get staffAtWork => 'На работе';

  @override
  String get staffTodayLower => 'сегодня';

  @override
  String get staffEditAction => 'Редактировать';

  @override
  String get staffActivate => 'Активировать';

  @override
  String get staffNewUser => 'Новый сотрудник';

  @override
  String staffUserTitle(String name) {
    return 'Сотрудник: $name';
  }

  @override
  String get staffDemoteTitle => 'Понизить собственную роль?';

  @override
  String staffDemoteMessage(String role) {
    return 'После сохранения у вас («$role») не будет доступа к разделу «Сотрудники». Вернуть права сможет только владелец или администратор.';
  }

  @override
  String get staffDemote => 'Понизить';

  @override
  String get staffUserAdded => 'Сотрудник добавлен';

  @override
  String get staffChangesSaved => 'Изменения сохранены';

  @override
  String get staffFrom0To100 => 'От 0 до 100';

  @override
  String get staffNameLabel => 'Имя *';

  @override
  String get staffOwnerRoleLocked =>
      'Изменить роль владельца может только владелец';

  @override
  String get staffRoleLabel => 'Роль *';

  @override
  String get staffPinSection => 'PIN для входа';

  @override
  String get staffResetPin => 'Сбросить PIN';

  @override
  String get staffResetPinHint => 'Сотрудник будет входить с новым PIN';

  @override
  String get staffPinLabel => 'PIN *';

  @override
  String get staffPinRepeatLabel => 'PIN ещё раз *';

  @override
  String get staffPinMismatch => 'PIN не совпадает';

  @override
  String get staffPinHint => '4–8 цифр, уникальный для каждого сотрудника';

  @override
  String get staffLimitsSection => 'Ограничения и мотивация';

  @override
  String get staffMaxDiscount => 'Макс. скидка';

  @override
  String get staffMaxDiscountHelper => 'без согласования';

  @override
  String get staffCommission => 'Комиссия';

  @override
  String get staffCommissionHelper => 'от чистой выручки';

  @override
  String get staffSalesPlan => 'План продаж на месяц';

  @override
  String get staffSalesPlanHelper => '0 или пусто — без плана';

  @override
  String get staffSaving => 'Сохранение…';

  @override
  String get staffEnterPin => 'Введите PIN';

  @override
  String get staffPinMin4 => 'Минимум 4 цифры';

  @override
  String get staffNewPin => 'Новый PIN';

  @override
  String get staffPin4to8 => 'От 4 до 8 цифр';

  @override
  String get staffRepeatPin => 'Повторите PIN';

  @override
  String get staffNoPlan => 'без плана';

  @override
  String get staffClockIn => 'Отметить начало работы';

  @override
  String staffClockedIn(String time) {
    return 'Начало работы отмечено в $time';
  }

  @override
  String get staffClockInShort => 'Начать работу';

  @override
  String get staffClockOutTitle => 'Отметить уход?';

  @override
  String staffClockOutMessage(String time, String duration) {
    return 'На работе с $time ($duration).';
  }

  @override
  String get staffClockOut => 'Отметить уход';

  @override
  String get staffClockedOut => 'Уход отмечен';

  @override
  String staffClockOutTip(String time) {
    return 'На работе с $time · отметить уход';
  }

  @override
  String staffAtWorkSince(String time) {
    return 'На работе с $time';
  }

  @override
  String staffClockOutShortDur(String duration) {
    return 'Уход · $duration';
  }

  @override
  String staffClockOutDur(String duration) {
    return 'Отметить уход · $duration';
  }

  @override
  String get staffThisWeek => 'Эта неделя';

  @override
  String get staffThisMonth => 'Этот месяц';

  @override
  String get staffLastMonth => 'Прошлый месяц';

  @override
  String get staffAllEmployees => 'Все сотрудники';

  @override
  String get staffEntryShort => 'Запись';

  @override
  String get staffAddEntry => 'Добавить запись';

  @override
  String get staffNoMarks => 'Нет отметок за период';

  @override
  String get staffNoMarksHint =>
      'Сотрудники отмечают приход и уход кнопкой «Отметить начало работы»';

  @override
  String get staffAtWorkLower => 'на работе';

  @override
  String get staffNewEntryTitle => 'Новая запись рабочего времени';

  @override
  String get staffEntryTitle => 'Запись рабочего времени';

  @override
  String get staffSelectEmployee => 'Выберите сотрудника';

  @override
  String get staffEntrySaved => 'Запись сохранена';

  @override
  String get staffDeleteEntryTitle => 'Удалить запись?';

  @override
  String get staffDeleteEntryMessage => 'Действие будет записано в журнал.';

  @override
  String get staffEntryDeleted => 'Запись удалена';

  @override
  String get staffEmployeeRequired => 'Сотрудник *';

  @override
  String get staffClockInField => 'Приход';

  @override
  String get staffClockOutField => 'Уход';

  @override
  String get staffStillAtWorkLower => 'ещё на работе';

  @override
  String get staffStillAtWork => 'Ещё на работе';

  @override
  String get staffEndBeforeStartShort => 'Уход раньше прихода';

  @override
  String staffDurationLabel(String duration) {
    return 'Длительность: $duration';
  }

  @override
  String get staffEntryNote => 'Комментарий (причина правки)';

  @override
  String get staffMonth1 => 'Январь';

  @override
  String get staffMonth2 => 'Февраль';

  @override
  String get staffMonth3 => 'Март';

  @override
  String get staffMonth4 => 'Апрель';

  @override
  String get staffMonth5 => 'Май';

  @override
  String get staffMonth6 => 'Июнь';

  @override
  String get staffMonth7 => 'Июль';

  @override
  String get staffMonth8 => 'Август';

  @override
  String get staffMonth9 => 'Сентябрь';

  @override
  String get staffMonth10 => 'Октябрь';

  @override
  String get staffMonth11 => 'Ноябрь';

  @override
  String get staffMonth12 => 'Декабрь';

  @override
  String get staffPrevMonth => 'Предыдущий месяц';

  @override
  String get staffNextMonth => 'Следующий месяц';

  @override
  String get staffCurrentMonth => 'Текущий';

  @override
  String get staffMotivationHint =>
      'Выручка продавца без аннулированных чеков, за вычетом возвратов, сделанных в этом месяце';

  @override
  String get staffNoSellers => 'Нет продавцов';

  @override
  String get staffNoSellersHint =>
      'Задайте сотрудникам план продаж и комиссию в карточке сотрудника';

  @override
  String get staffNetRevenue => 'Чистая выручка';

  @override
  String staffPlanValue(String amount) {
    return 'План $amount';
  }

  @override
  String get staffCommissionDue => 'Комиссия к выплате';

  @override
  String get staffRevenue => 'Выручка';

  @override
  String get staffRefunds => 'Возвраты';

  @override
  String get staffReceiptsLabel => 'Чеков';

  @override
  String get staffAvgCheck => 'Средний чек';

  @override
  String staffCommissionPct(String pct) {
    return 'Комиссия $pct%';
  }

  @override
  String staffPlanLeft(String done, String plan, String left) {
    return '$done из $plan · осталось $left';
  }

  @override
  String staffPlanDone(String done, String plan) {
    return '$done из $plan · план выполнен';
  }

  @override
  String get staffActionLabel => 'Действие';

  @override
  String get staffAllActions => 'Все действия';

  @override
  String get staffNoRecords => 'Записей не найдено';

  @override
  String get staffNoRecordsHint => 'Измените период или фильтры';

  @override
  String staffAuditLimit(String n) {
    return 'Показаны последние $n записей — уточните фильтр';
  }

  @override
  String get staffSystem => 'система';

  @override
  String get syncErrNetwork =>
      'Нет связи с сервером синхронизации. Проверьте интернет.';

  @override
  String get syncErrAuth =>
      'Неверный email или пароль, либо сессия истекла. Войдите снова.';

  @override
  String get syncErrForbidden => 'Нет доступа к этому магазину.';

  @override
  String get syncErrEnvironmentMismatch =>
      'Демо-база может подключаться только к тестовому магазину.';

  @override
  String get syncErrNotEmpty =>
      'В этой базе уже есть данные (товары, продажи, клиенты). Подключить её к существующему магазину нельзя: две базы не объединяются. Используйте чистую установку.';

  @override
  String get syncErrServer => 'Ошибка сервера синхронизации.';

  @override
  String get syncErrNotConfigured => 'Синхронизация не настроена.';

  @override
  String get syncErrNotSignedIn => 'Сначала войдите в аккаунт синхронизации.';

  @override
  String get syncErrInvalidProject =>
      'Неверный ID проекта: только строчные латинские буквы, цифры и дефис, от 6 до 30 символов.';

  @override
  String get syncErrInvalidApiKey =>
      'Неверный Web API key. Скопируйте его заново из настроек проекта Firebase.';

  @override
  String get syncErrProjectMismatch =>
      'Web API key относится к другому проекту Firebase. Скопируйте ID проекта и Web API key из настроек одного и того же проекта.';

  @override
  String get syncErrSignInDisabled =>
      'В проекте Firebase не включён вход по email и паролю (Authentication › Sign-in method › Email/Password).';

  @override
  String get syncErrAccountDisabled =>
      'Этот аккаунт отключён в проекте Firebase.';

  @override
  String get syncErrTooManyAttempts =>
      'Слишком много попыток входа. Подождите несколько минут и попробуйте снова.';

  @override
  String get syncErrProtocol => 'Неожиданный ответ сервера синхронизации.';

  @override
  String get syncErrStoreNotFound => 'Магазин не найден.';

  @override
  String get syncErrAlreadyConnected =>
      'Эта база уже подключена к магазину. Сначала отключите синхронизацию.';

  @override
  String get syncPhaseOff => 'Выключена';

  @override
  String get syncPhaseIdle => 'Синхронизировано';

  @override
  String get syncPhaseSyncing => 'Синхронизация…';

  @override
  String get syncPhaseError => 'Ошибка синхронизации';

  @override
  String get syncPhaseOffline => 'Нет связи';

  @override
  String get syncEnvTest => 'Тестовый магазин';

  @override
  String get syncEnvProduction => 'Рабочий магазин';

  @override
  String syncConflictTitle(String subject) {
    return 'Конфликт синхронизации: $subject';
  }

  @override
  String syncConflictSubjectBarcode(String code) {
    return 'штрихкод $code';
  }

  @override
  String syncConflictSubjectCard(String code) {
    return 'карта клиента $code';
  }

  @override
  String syncConflictSubjectGiftCard(String code) {
    return 'сертификат $code';
  }

  @override
  String syncConflictSubjectStock(String name) {
    return 'остаток «$name»';
  }

  @override
  String syncConflictSubjectBonus(String name) {
    return 'бонусы «$name»';
  }

  @override
  String syncConflictBarcodeBody(String code, String winner, String loser) {
    return 'Штрихкод $code был назначен двум товарам на разных кассах. Он оставлен у товара «$winner», у товара «$loser» штрихкод очищен.';
  }

  @override
  String syncConflictCardBody(String code, String winner, String loser) {
    return 'Номер карты $code был назначен двум клиентам на разных кассах. Он оставлен у клиента «$winner», у клиента «$loser» номер карты очищен.';
  }

  @override
  String syncConflictGiftCodeBody(String code, String newCode) {
    return 'Код сертификата $code совпал на разных кассах. Дубликат заблокирован и получил код $newCode.';
  }

  @override
  String syncConflictStockBody(String name, String qty) {
    return 'Остаток товара «$name» стал отрицательным ($qty) после продаж на разных кассах. Проверьте остаток.';
  }

  @override
  String syncConflictGiftBalanceBody(String code, String amount) {
    return 'Сертификат $code списан на разных кассах больше номинала: баланс $amount.';
  }

  @override
  String syncConflictBonusBody(String name, String amount) {
    return 'Бонусы клиента «$name» стали отрицательными ($amount) после операций на разных кассах.';
  }

  @override
  String get syncSectionDesc =>
      'Несколько касс одного магазина работают с общими товарами, клиентами и продажами через облако. Без интернета касса продолжает работать, изменения отправятся при появлении связи.';

  @override
  String get syncUnavailable =>
      'В этой версии программы синхронизация недоступна.';

  @override
  String get syncOffTitle => 'Синхронизация выключена';

  @override
  String get syncOffMessage =>
      'Эта касса работает отдельно. Подключите её к магазину в облаке, чтобы все кассы видели общие данные.';

  @override
  String get syncConnect => 'Подключить';

  @override
  String get syncSyncNow => 'Синхронизировать сейчас';

  @override
  String get syncDisconnect => 'Отключить';

  @override
  String get syncSignInAgain => 'Войти снова';

  @override
  String get syncStoreLabel => 'Магазин';

  @override
  String get syncDeviceCode => 'Код кассы';

  @override
  String syncDeviceCodeExample(String example) {
    return 'номера чеков: $example';
  }

  @override
  String get syncPending => 'Ожидают отправки';

  @override
  String get syncLastSync => 'Последняя синхронизация';

  @override
  String get syncNever => 'ещё не было';

  @override
  String get syncAccount => 'Аккаунт';

  @override
  String syncNextRetry(String time) {
    return 'Следующая попытка в $time';
  }

  @override
  String syncDoneToast(String pushed, String pulled) {
    return 'Синхронизация завершена: отправлено $pushed, получено $pulled';
  }

  @override
  String get syncDisconnectTitle => 'Отключить синхронизацию?';

  @override
  String syncDisconnectMessage(String store) {
    return 'Касса перестанет обмениваться данными с магазином «$store». Все данные на этой кассе сохранятся, номера чеков останутся уникальными. Подключиться снова можно в любой момент.';
  }

  @override
  String get syncDisconnectedToast =>
      'Синхронизация отключена. Данные на кассе сохранены.';

  @override
  String get syncConnectTitle => 'Подключение к облаку';

  @override
  String get syncSignInIntro =>
      'Введите ID проекта Firebase, Web API key и данные аккаунта владельца магазина.';

  @override
  String get syncProjectId => 'ID проекта Firebase *';

  @override
  String get syncProjectIdHint => 'например, dreampos-1a2b3';

  @override
  String get syncProjectIdHelp =>
      'Firebase › Настройки проекта › Общие › ID проекта';

  @override
  String get syncApiKey => 'Web API key *';

  @override
  String get syncApiKeyHelp => 'Там же: Web API key (начинается с AIza)';

  @override
  String get syncEmail => 'Email *';

  @override
  String get syncPassword => 'Пароль *';

  @override
  String get syncPasswordShow => 'Показать пароль';

  @override
  String get syncPasswordHide => 'Скрыть пароль';

  @override
  String get syncPasswordNote => 'Пароль не сохраняется на кассе.';

  @override
  String get syncSignIn => 'Войти';

  @override
  String get syncInvalidEmail => 'Неверный email';

  @override
  String syncSignedInAs(String email) {
    return 'Вход выполнен: $email';
  }

  @override
  String get syncChooseAction => 'Что сделать с этой кассой?';

  @override
  String get syncCreateStore => 'Создать магазин в облаке';

  @override
  String get syncCreateStoreHint =>
      'Эта касса станет первой. Все её данные будут загружены в облако.';

  @override
  String get syncJoinStore => 'Подключить к существующему';

  @override
  String get syncJoinStoreHint =>
      'Данные магазина будут загружены на эту кассу. Только для пустой базы.';

  @override
  String get syncStoreName => 'Название магазина *';

  @override
  String get syncEnvironment => 'Тип магазина';

  @override
  String get syncEnvTestHint =>
      'Для обучения и проверки. Демо-база может подключаться только сюда.';

  @override
  String get syncEnvProductionHint =>
      'Для реальной работы. Тип нельзя изменить позже.';

  @override
  String get syncEnvProductionDemo => 'Недоступно для демо-базы';

  @override
  String get syncCreateAndUpload => 'Создать и загрузить';

  @override
  String get syncChooseStore => 'Выберите магазин';

  @override
  String get syncNoStores =>
      'У этого аккаунта нет магазинов. Создайте магазин на первой кассе или попросите владельца добавить вас.';

  @override
  String get syncUploading => 'Загружаем данные в облако…';

  @override
  String get syncDownloading => 'Загружаем данные магазина…';

  @override
  String syncConnectedToast(String store, String code) {
    return 'Касса подключена к магазину «$store». Код кассы: $code';
  }

  @override
  String get syncIntegrityTitle => 'Проверка целостности';

  @override
  String get syncIntegrityDesc =>
      'Сверяет остатки, долги, бонусы и балансы с журналами движений. Ничего не меняет.';

  @override
  String get syncIntegrityRun => 'Проверить';

  @override
  String get syncIntegrityNotRun => 'Проверка ещё не запускалась.';

  @override
  String get syncIntegrityOk =>
      'Расхождений нет: все остатки и балансы совпадают с журналами.';

  @override
  String syncIntegrityFound(String count) {
    return 'Найдено расхождений: $count';
  }

  @override
  String syncIntegrityValues(String cached, String derived) {
    return 'сохранено $cached · по журналу $derived';
  }

  @override
  String get syncCacheStock => 'Остаток товара';

  @override
  String get syncCacheDebt => 'Долг клиента';

  @override
  String get syncCacheBonus => 'Бонусы клиента';

  @override
  String get syncCacheSupplierBalance => 'Баланс поставщика';

  @override
  String get syncCacheGiftBalance => 'Баланс сертификата';

  @override
  String get syncCacheGiftStatus => 'Статус сертификата';

  @override
  String get syncCachePoPaid => 'Оплачено по заказу';

  @override
  String get syncCachePoReceived => 'Получено по позиции заказа';

  @override
  String get syncCacheSaleRefunded => 'Возвращено по чеку';

  @override
  String get syncCacheSaleStatus => 'Статус чека';

  @override
  String get syncCacheReturnedQty => 'Возвращено по позиции чека';

  @override
  String get syncConflictsTitle => 'Конфликты синхронизации';

  @override
  String get syncConflictsSubtitle =>
      'Что пришлось решить автоматически при обмене данными между кассами';

  @override
  String get syncConflictsEmpty => 'Конфликтов нет';

  @override
  String get syncConflictsShowResolved => 'Показать просмотренные';

  @override
  String get syncConflictsMarkAll => 'Отметить все просмотренными';

  @override
  String get syncConflictMarkRead => 'Отметить просмотренным';

  @override
  String get syncConflictKindBarcode => 'Совпадение штрихкода';

  @override
  String get syncConflictKindCard => 'Совпадение номера карты';

  @override
  String get syncConflictKindGiftCode => 'Совпадение кода сертификата';

  @override
  String get syncConflictKindStock => 'Отрицательный остаток';

  @override
  String get syncConflictKindGiftBalance => 'Отрицательный баланс сертификата';

  @override
  String get syncConflictKindBonus => 'Отрицательные бонусы';

  @override
  String get syncConflictKindNormalize => 'Выравнивание при обновлении';

  @override
  String get syncConflictKindOther => 'Конфликт';

  @override
  String syncIndicatorTooltip(String state, String count) {
    return '$state. Ожидают отправки: $count. Нажмите, чтобы синхронизировать.';
  }

  @override
  String syncSubjectReceipt(String number) {
    return 'Чек №$number';
  }

  @override
  String syncSubjectOrder(String number) {
    return 'Заказ №$number';
  }

  @override
  String get syncErrTestData =>
      'Эта база была подключена к тестовому магазину и может содержать тестовые данные других касс. Создать из неё рабочий магазин нельзя: используйте базу без тестовых данных.';

  @override
  String syncConflictSubjectSale(String number) {
    return 'чек №$number';
  }

  @override
  String syncConflictSubjectDocNumber(String number) {
    return 'номер документа $number';
  }

  @override
  String get syncConflictSubjectDevice => 'код кассы';

  @override
  String syncConflictNumberBody(String number, String newNumber) {
    return 'Номер $number оказался у двух разных документов (например, после восстановления резервной копии на подключённой кассе). Более новый документ получил номер $newNumber.';
  }

  @override
  String syncConflictVoidReturnBody(String number, String amount) {
    return 'Чек №$number аннулирован на одной кассе, а на другой по нему оформлен возврат на $amount. Деньги и товар учтены дважды: проверьте кассу и остатки.';
  }

  @override
  String syncConflictOverReturnBody(
    String number,
    String refunded,
    String total,
  ) {
    return 'По чеку №$number на разных кассах вернули больше, чем было продано: возвраты на $refunded при сумме чека $total. Проверьте кассу и остатки.';
  }

  @override
  String syncConflictIdentityBody(String oldCode, String newCode) {
    return 'Эта база оказалась копией кассы $oldCode, которая продолжала работать (восстановлена резервная копия или база скопирована на другой компьютер). Данные, которых не было в копии, загружены из облака, а касса получила новый код $newCode, чтобы номера документов не повторялись.';
  }

  @override
  String get syncConflictKindNumber => 'Совпадение номера документа';

  @override
  String get syncConflictKindVoidReturn => 'Возврат по аннулированному чеку';

  @override
  String get syncConflictKindOverReturn => 'Возврат больше продажи';

  @override
  String get syncConflictKindIdentity => 'Копия базы кассы';

  @override
  String get syncConflictKindDoubleVoid => 'Двойное аннулирование сертификата';

  @override
  String syncConflictDoubleVoidBody(
    String code,
    String number,
    String amount,
    String shift,
  ) {
    return 'Продажа сертификата $code (№$number) аннулирована на двух кассах, и деньги ($amount) вернули дважды. Учтено одно аннулирование: в отчёте смены №$shift этого возврата нет. Проверьте кассу.';
  }

  @override
  String get syncConflictKindVoidRedeem => 'Оплата аннулированным сертификатом';

  @override
  String syncConflictVoidRedeemBody(String code, String amount) {
    return 'Сертификат $code аннулирован на одной кассе (деньги возвращены), а на другой им оплатили $amount. Сумма учтена дважды: проверьте кассу.';
  }

  @override
  String syncJoinRejoinHint(String name) {
    return 'В базе уже есть данные, поэтому подключиться можно только к магазину «$name», от которого эта касса была отключена.';
  }

  @override
  String get syncConflictKindJoinUsers => 'Сотрудники этой кассы отключены';

  @override
  String get syncConflictSubjectJoinUsers => 'сотрудники этой кассы';

  @override
  String syncConflictJoinUsersBody(String names) {
    return 'При подключении к магазину сотрудники, созданные на этой кассе до подключения, отключены: $names. Их PIN-коды могли совпасть с PIN-кодами сотрудников магазина. Входите PIN-кодами сотрудников магазина; нужного сотрудника можно включить заново с новым PIN-кодом.';
  }

  @override
  String get syncConflictKindRejected => 'Изменение из облака пропущено';

  @override
  String syncConflictRejectedBody(String entity, String id) {
    return 'Изменение записи $entity ($id) пришло из облака повреждённым или от несовместимой версии программы, поэтому оно пропущено. Остальные данные синхронизируются как обычно. Проверьте, что на всех кассах установлена одна версия DreamPOS.';
  }

  @override
  String get syncErrEmailExists =>
      'Аккаунт с этим email уже есть. Войдите с ним («Войти») или укажите другой email.';

  @override
  String get syncErrWeakPassword =>
      'Облако не приняло пароль: он слишком простой. Придумайте пароль длиннее (не менее 8 символов, буквы и цифры).';

  @override
  String get syncErrInvalidEmail =>
      'Облако не приняло этот email. Проверьте адрес.';

  @override
  String get syncErrSignUpDisabled =>
      'В проекте Firebase отключена регистрация новых аккаунтов (Authentication › Settings › User actions › Enable create (sign-up)). Создайте аккаунт в консоли Firebase (Authentication › Users › Add user) и войдите с ним или временно включите регистрацию.';

  @override
  String get syncErrSignUpTooManyAttempts =>
      'Слишком много попыток регистрации с этого устройства. Подождите несколько минут и попробуйте снова.';

  @override
  String get syncAuthModeSignIn => 'Войти';

  @override
  String get syncAuthModeSignUp => 'Создать аккаунт владельца';

  @override
  String get syncSignUpIntro =>
      'В вашем проекте Firebase будет создан новый аккаунт владельца магазина. Затем вы создадите магазин в облаке или подключитесь к существующему.';

  @override
  String get syncPasswordNewHelp =>
      'Не менее 8 символов. Пароль не сохраняется на кассе.';

  @override
  String get syncPasswordRepeat => 'Повторите пароль *';

  @override
  String get syncPasswordTooShort => 'Не менее 8 символов';

  @override
  String get syncPasswordMismatch => 'Пароли не совпадают';

  @override
  String get syncSignUpSubmit => 'Создать аккаунт';

  @override
  String get syncNoAccountSignUp => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get syncHaveAccountSignIn => 'Уже есть аккаунт? Войти';

  @override
  String syncAccountCreated(String email) {
    return 'Аккаунт создан: $email';
  }

  @override
  String get syncNewAccountNoStores =>
      'У нового аккаунта пока нет магазинов. Нажмите «Создать новый магазин», настройте его, затем в разделе Настройки › Синхронизация войдите этим аккаунтом и выберите «Создать магазин в облаке».';

  @override
  String get syncErrPasswordPolicy =>
      'Пароль не подходит под требования к паролям вашего проекта Firebase (Authentication › Settings › Password policy): например, нужны заглавные буквы, цифры или символы. Придумайте пароль, который им соответствует.';

  @override
  String get syncSignUpDisableHint =>
      'Аккаунт владельца создан. Теперь закройте самостоятельную регистрацию в консоли Firebase: Authentication › Settings › User actions — снимите «Enable create (sign-up)». Иначе любой, кто знает Web API key, сможет заводить аккаунты.';

  @override
  String get syncSignInWithThisEmail => 'Войти с этим email';

  @override
  String get warrantyTitle => 'Гарантия';

  @override
  String get warrantySubtitle => 'Гарантийные и сервисные заявки';

  @override
  String get warrantyStatusReceived => 'Принят';

  @override
  String get warrantyStatusInRepair => 'В ремонте';

  @override
  String get warrantyStatusReplaced => 'Замена';

  @override
  String get warrantyStatusRefunded => 'Возврат денег';

  @override
  String get warrantyStatusRejected => 'Отказ';

  @override
  String get warrantyStatusReturned => 'Выдан клиенту';

  @override
  String get warrantyActionInRepair => 'Передать в ремонт';

  @override
  String get warrantyActionReplace => 'Заменить товар';

  @override
  String get warrantyActionRefund => 'Вернуть деньги';

  @override
  String get warrantyActionReject => 'Отказать';

  @override
  String get warrantyActionReturn => 'Выдать клиенту';

  @override
  String get warrantyGroupOpen => 'В работе';

  @override
  String get warrantyGroupResolved => 'Решены';

  @override
  String get warrantyGroupClosed => 'Выданы';

  @override
  String get warrantyNotSet => 'не установлена';

  @override
  String warrantyActUntilActive(String date) {
    return 'до $date (действует)';
  }

  @override
  String warrantyActUntilExpired(String date) {
    return 'до $date (истекла)';
  }

  @override
  String get warrantyActTitle =>
      'АКТ ПРИЁМА ТОВАРА НА ГАРАНТИЙНОЕ ОБСЛУЖИВАНИЕ';

  @override
  String warrantyActNumber(String number, String date) {
    return '№$number от $date';
  }

  @override
  String get warrantySerialNumber => 'Серийный номер';

  @override
  String get warrantyActPurchaseDoc => 'Документ покупки';

  @override
  String get warrantyActNotPresented => 'не предъявлен';

  @override
  String warrantyReceiptRef(String number, String date) {
    return 'чек №$number от $date';
  }

  @override
  String get warrantyWarranty => 'Гарантия';

  @override
  String get warrantyActProblem => 'Заявленная неисправность';

  @override
  String get warrantyActCompleteness => 'Комплектность и внешний вид';

  @override
  String get warrantyResolution => 'Решение';

  @override
  String get warrantyActTerms =>
      'Срок рассмотрения заявки — в соответствии с законодательством о защите прав потребителей. Товар выдаётся при предъявлении настоящего акта.';

  @override
  String get warrantyActHandedBy => 'Сдал (клиент):';

  @override
  String get warrantyActReceivedBy => 'Принял (сотрудник):';

  @override
  String warrantyActJobName(String number) {
    return 'Гарантия $number';
  }

  @override
  String warrantyClaimAccepted(String number) {
    return 'Заявка №$number принята';
  }

  @override
  String get warrantyPrintActQuestion =>
      'Распечатать акт приёма для подписи клиента?';

  @override
  String get warrantyPrintAct => 'Печать акта';

  @override
  String get warrantySearchHintWide =>
      'Номер заявки или чека, клиент, серийный номер, товар';

  @override
  String get warrantySearchHint => 'Заявка, чек, клиент, S/N, товар';

  @override
  String get warrantyNewClaim => 'Новая заявка';

  @override
  String get warrantyClaimFab => 'Заявка';

  @override
  String get warrantySelectClaim => 'Выберите заявку';

  @override
  String get warrantySelectClaimHint =>
      'Карточка заявки, смена статуса и печать акта';

  @override
  String get warrantyEmptyTitle => 'Заявок пока нет';

  @override
  String get warrantyEmptyFiltered =>
      'Измените поиск или выберите другой статус';

  @override
  String get warrantyEmptyHint =>
      'Примите товар на гарантию по номеру чека или вручную';

  @override
  String get warrantyShowMore => 'Показать ещё';

  @override
  String get warrantyNoProduct => 'товар не указан';

  @override
  String warrantyReceiptShort(String number) {
    return 'чек №$number';
  }

  @override
  String warrantyDaysShort(String days) {
    return '$days дн.';
  }

  @override
  String get warrantyClaimTitle => 'Гарантийная заявка';

  @override
  String get warrantyClaimNotFound => 'Заявка не найдена';

  @override
  String warrantyClaimNumber(String number) {
    return 'Заявка №$number';
  }

  @override
  String warrantyAcceptedAt(String date) {
    return 'принята $date';
  }

  @override
  String get warrantyActButton => 'Акт приёма';

  @override
  String get warrantyProductName => 'Наименование';

  @override
  String get warrantyPurchase => 'Покупка';

  @override
  String get warrantyNoReceipt => 'без чека';

  @override
  String get warrantyOpenReceipt => 'Открыть чек';

  @override
  String warrantyUntil(String date) {
    return 'до $date';
  }

  @override
  String warrantyExpiredOn(String date) {
    return 'истекла $date';
  }

  @override
  String get warrantyNotSpecified => 'не указан';

  @override
  String get warrantyProblem => 'Неисправность';

  @override
  String get warrantyHistory => 'История';

  @override
  String get warrantyHistoryCreated => 'Заявка принята';

  @override
  String warrantyStatusChanged(String status) {
    return 'Статус: $status';
  }

  @override
  String warrantyStatusChangedWriteOff(String status) {
    return 'Статус: $status · 1 ед. списана';
  }

  @override
  String get warrantyRefundTitle => 'Оформите возврат денег';

  @override
  String get warrantyRefundMessage =>
      'Деньги возвращаются только через возврат по чеку в разделе «Чеки» — так касса, склад и отчёты останутся верными. Перейти к оформлению?';

  @override
  String get warrantyOpenReceipts => 'Открыть «Чеки»';

  @override
  String warrantyOpenReceiptNumber(String number) {
    return 'Открыть чек №$number';
  }

  @override
  String get warrantyRefundHint =>
      'Решение — возврат денег. Оформите возврат по чеку (без возврата на склад).';

  @override
  String get warrantyToReceipt => 'К чеку';

  @override
  String get warrantyHintInRepair => 'Сервисный центр, ориентировочный срок';

  @override
  String get warrantyHintReplaced => 'Например: заменён на новый, серийный № …';

  @override
  String get warrantyHintRefunded =>
      'Например: дефект подтверждён, возврат денег';

  @override
  String get warrantyHintRejected =>
      'Причина отказа: следы удара, вскрытие, нарушение условий…';

  @override
  String get warrantyHintReturned => 'Кому и когда выдано';

  @override
  String warrantyTransition(String number, String from, String to) {
    return 'Заявка №$number: $from → $to';
  }

  @override
  String get warrantyResolutionRequired => 'Решение *';

  @override
  String get warrantyEnterResolution => 'Укажите решение';

  @override
  String get warrantyWriteOffOne => 'Списать 1 ед. со склада';

  @override
  String get warrantyWriteOffHint =>
      'Причина: «Гарантийная замена» — выданный клиенту товар уйдёт из остатка';

  @override
  String get warrantyWriteOffUnavailable =>
      'Недоступно: нет прав на складские операции или не указан товар';

  @override
  String get warrantyRefundNote =>
      'Статус не двигает деньги. После сохранения оформите возврат по чеку в разделе «Чеки».';

  @override
  String get warrantyNewClaimTitle => 'Новая гарантийная заявка';

  @override
  String get warrantyEnterReceiptDigits => 'Введите номер чека цифрами';

  @override
  String warrantyReceiptNotFound(String number) {
    return 'Чек №$number не найден';
  }

  @override
  String get warrantyBlockVoided => 'чек аннулирован';

  @override
  String get warrantyBlockReturned => 'товар возвращён';

  @override
  String get warrantyExpiredTitle => 'Гарантия истекла';

  @override
  String get warrantyNotSetTitle => 'Гарантия не установлена';

  @override
  String get warrantyPaidRepairQuestion =>
      'Заявку можно принять как платный ремонт или на экспертизу. Принять?';

  @override
  String get warrantyAccept => 'Принять';

  @override
  String get warrantyDuplicateTitle => 'Уже есть открытая заявка';

  @override
  String warrantyDuplicateMessage(String number, String status) {
    return 'По этому товару из чека уже принята заявка №$number ($status). Создать ещё одну?';
  }

  @override
  String get warrantyFindReceiptAndItem =>
      'Найдите чек и выберите товар из него';

  @override
  String get warrantySelectProduct => 'Выберите товар';

  @override
  String get warrantyByReceipt => 'По чеку';

  @override
  String get warrantyWithoutReceipt => 'Без чека';

  @override
  String get warrantySerialImei => 'Серийный номер / IMEI';

  @override
  String get warrantyProblemLabel => 'Описание неисправности *';

  @override
  String get warrantyProblemHint =>
      'Что не работает, когда проявилось, внешний вид, комплектность';

  @override
  String get warrantyDescribeProblem => 'Опишите неисправность';

  @override
  String get warrantySubmit => 'Принять заявку';

  @override
  String get warrantyReceiptNumber => 'Номер чека';

  @override
  String get warrantyFind => 'Найти';

  @override
  String warrantyReceiptPickItem(String number, String date) {
    return 'Чек №$number от $date — выберите товар';
  }

  @override
  String get warrantyReceiptVoided =>
      'Чек аннулирован — принять товар по нему нельзя. Используйте режим «Без чека».';

  @override
  String get warrantyNoWarranty => 'без гарантии';

  @override
  String warrantyChipUntil(String date) {
    return 'гарантия до $date';
  }

  @override
  String warrantyChipExpired(String date) {
    return 'гарантия истекла $date';
  }

  @override
  String warrantyBannerActive(String date) {
    return 'На гарантии до $date';
  }

  @override
  String warrantyBannerExpired(String date) {
    return 'Гарантия истекла $date. Заявку можно принять как платный ремонт.';
  }

  @override
  String get warrantyBannerNone => 'На этот товар гарантия не установлена';

  @override
  String get warrantySelectProductRequired => 'Выберите товар *';

  @override
  String get warrantyRequiredNoReceipt => 'Обязательно для заявки без чека';

  @override
  String get warrantyManualHint =>
      'Для товара без чека или проданного вне системы';

  @override
  String get warrantyCustomerOptional => 'Клиент (необязательно)';

  @override
  String get warrantyCustomerHint => 'Нужен для связи о готовности';

  @override
  String get warrantyRemoveCustomer => 'Убрать клиента';

  @override
  String get warrantyReceiptLineNotFound => 'Позиция чека не найдена';

  @override
  String warrantyCannotTransition(String from, String to) {
    return 'Нельзя перевести заявку из «$from» в «$to»';
  }

  @override
  String get warrantyEnterClaimResolution => 'Укажите решение по заявке';

  @override
  String get warrantyWriteOffOnlyReplace =>
      'Списание возможно только при замене';

  @override
  String get warrantyNoProductInClaim => 'В заявке не указан товар';

  @override
  String get warrantyStockUnavailable => 'Склад недоступен';

  @override
  String get warrantyChangedByOther =>
      'Заявка уже изменена другим пользователем';
}
