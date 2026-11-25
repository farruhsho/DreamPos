import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('en'),
    Locale('ky'),
    Locale('uz'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get commonSearch;

  /// No description provided for @commonAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get commonEdit;

  /// No description provided for @commonCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get commonCreate;

  /// No description provided for @commonConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get commonConfirm;

  /// No description provided for @commonOk.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get commonNo;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get commonError;

  /// No description provided for @commonEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get commonEmpty;

  /// No description provided for @commonNothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get commonNothingFound;

  /// No description provided for @commonPrint.
  ///
  /// In ru, this message translates to:
  /// **'Печать'**
  String get commonPrint;

  /// No description provided for @commonExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get commonExport;

  /// No description provided for @commonImport.
  ///
  /// In ru, this message translates to:
  /// **'Импорт'**
  String get commonImport;

  /// No description provided for @commonTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get commonTotal;

  /// No description provided for @commonDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get commonDate;

  /// No description provided for @commonTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get commonTime;

  /// No description provided for @commonAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get commonAmount;

  /// No description provided for @commonQty.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get commonQty;

  /// No description provided for @commonPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get commonPrice;

  /// No description provided for @commonCost.
  ///
  /// In ru, this message translates to:
  /// **'Себестоимость'**
  String get commonCost;

  /// No description provided for @commonStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get commonStatus;

  /// No description provided for @commonReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get commonReason;

  /// No description provided for @commonComment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get commonComment;

  /// No description provided for @commonNote.
  ///
  /// In ru, this message translates to:
  /// **'Примечание'**
  String get commonNote;

  /// No description provided for @commonName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get commonName;

  /// No description provided for @commonPersonName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get commonPersonName;

  /// No description provided for @commonPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get commonPhone;

  /// No description provided for @commonAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get commonAddress;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// No description provided for @commonApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get commonApply;

  /// No description provided for @commonReset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get commonReset;

  /// No description provided for @commonClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get commonClear;

  /// No description provided for @commonAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get commonAll;

  /// No description provided for @commonFilter.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get commonFilter;

  /// No description provided for @commonSort.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get commonSort;

  /// No description provided for @commonPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Период'**
  String get commonPeriod;

  /// No description provided for @commonToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get commonYesterday;

  /// No description provided for @commonWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get commonWeek;

  /// No description provided for @commonMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get commonMonth;

  /// No description provided for @commonYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get commonYear;

  /// No description provided for @commonActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get commonActions;

  /// No description provided for @commonDetails.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get commonDetails;

  /// No description provided for @commonMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get commonMore;

  /// No description provided for @commonShowAll.
  ///
  /// In ru, this message translates to:
  /// **'Показать все'**
  String get commonShowAll;

  /// No description provided for @commonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательное поле'**
  String get commonRequired;

  /// No description provided for @commonInvalidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Неверная сумма'**
  String get commonInvalidAmount;

  /// No description provided for @commonEnterNumber.
  ///
  /// In ru, this message translates to:
  /// **'Введите число'**
  String get commonEnterNumber;

  /// No description provided for @commonMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть больше нуля'**
  String get commonMustBePositive;

  /// No description provided for @commonAmountMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'Должна быть больше нуля'**
  String get commonAmountMustBePositive;

  /// No description provided for @commonCannotBeNegative.
  ///
  /// In ru, this message translates to:
  /// **'Не может быть отрицательной'**
  String get commonCannotBeNegative;

  /// No description provided for @commonIntegerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только целое число'**
  String get commonIntegerOnly;

  /// No description provided for @commonEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get commonEnterName;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonProduct.
  ///
  /// In ru, this message translates to:
  /// **'Товар'**
  String get commonProduct;

  /// No description provided for @commonProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get commonProducts;

  /// No description provided for @commonCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get commonCustomer;

  /// No description provided for @commonCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Клиенты'**
  String get commonCustomers;

  /// No description provided for @commonSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get commonSupplier;

  /// No description provided for @commonCashier.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get commonCashier;

  /// No description provided for @commonEmployee.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник'**
  String get commonEmployee;

  /// No description provided for @commonShift.
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get commonShift;

  /// No description provided for @commonReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Чек'**
  String get commonReceipt;

  /// No description provided for @commonSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажа'**
  String get commonSale;

  /// No description provided for @commonReturn.
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get commonReturn;

  /// No description provided for @commonPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get commonPayment;

  /// No description provided for @commonPaymentMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get commonPaymentMethod;

  /// No description provided for @commonDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get commonDiscount;

  /// No description provided for @commonChange.
  ///
  /// In ru, this message translates to:
  /// **'Сдача'**
  String get commonChange;

  /// No description provided for @commonDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долг'**
  String get commonDebt;

  /// No description provided for @commonBonuses.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get commonBonuses;

  /// No description provided for @commonBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get commonBalance;

  /// No description provided for @commonGiftCard.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат'**
  String get commonGiftCard;

  /// No description provided for @commonCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get commonCategory;

  /// No description provided for @commonBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод'**
  String get commonBarcode;

  /// No description provided for @commonSku.
  ///
  /// In ru, this message translates to:
  /// **'Артикул'**
  String get commonSku;

  /// No description provided for @commonStock.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get commonStock;

  /// No description provided for @commonUnit.
  ///
  /// In ru, this message translates to:
  /// **'Ед. изм.'**
  String get commonUnit;

  /// No description provided for @commonVat.
  ///
  /// In ru, this message translates to:
  /// **'НДС'**
  String get commonVat;

  /// No description provided for @commonDocument.
  ///
  /// In ru, this message translates to:
  /// **'Документ'**
  String get commonDocument;

  /// No description provided for @commonVoided.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирован'**
  String get commonVoided;

  /// No description provided for @commonEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get commonEnabled;

  /// No description provided for @commonDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get commonDisabled;

  /// No description provided for @commonNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый'**
  String get commonNew;

  /// No description provided for @commonOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get commonOpen;

  /// No description provided for @commonCustomerNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Клиент не найден'**
  String get commonCustomerNotFound;

  /// No description provided for @commonPositionsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} позиция} few{{count} позиции} many{{count} позиций} other{{count} позиции}}'**
  String commonPositionsCount(int count);

  /// No description provided for @commonDocumentsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} документ} few{{count} документа} many{{count} документов} other{{count} документа}}'**
  String commonDocumentsCount(int count);

  /// No description provided for @commonReceiptsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} чек} few{{count} чека} many{{count} чеков} other{{count} чека}}'**
  String commonReceiptsCount(int count);

  /// No description provided for @commonReturnsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} возврат} few{{count} возврата} many{{count} возвратов} other{{count} возврата}}'**
  String commonReturnsCount(int count);

  /// No description provided for @commonMarksCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} отметка} few{{count} отметки} many{{count} отметок} other{{count} отметки}}'**
  String commonMarksCount(int count);

  /// No description provided for @commonProductsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} товар} few{{count} товара} many{{count} товаров} other{{count} товара}}'**
  String commonProductsCount(int count);

  /// No description provided for @commonCustomersCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} клиент} few{{count} клиента} many{{count} клиентов} other{{count} клиента}}'**
  String commonCustomersCount(int count);

  /// No description provided for @commonDaysCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} день} few{{count} дня} many{{count} дней} other{{count} дня}}'**
  String commonDaysCount(int count);

  /// No description provided for @payCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get payCash;

  /// No description provided for @payCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get payCard;

  /// No description provided for @payTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Перевод'**
  String get payTransfer;

  /// No description provided for @payBonus.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get payBonus;

  /// No description provided for @payDebt.
  ///
  /// In ru, this message translates to:
  /// **'В долг'**
  String get payDebt;

  /// No description provided for @payGiftCard.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат'**
  String get payGiftCard;

  /// No description provided for @unitPcs.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get unitPcs;

  /// No description provided for @unitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get unitL;

  /// No description provided for @unitM.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get unitM;

  /// No description provided for @unitPack.
  ///
  /// In ru, this message translates to:
  /// **'уп'**
  String get unitPack;

  /// No description provided for @roleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In ru, this message translates to:
  /// **'Менеджер'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get roleCashier;

  /// No description provided for @roleStorekeeper.
  ///
  /// In ru, this message translates to:
  /// **'Кладовщик'**
  String get roleStorekeeper;

  /// No description provided for @coreLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get coreLanguage;

  /// No description provided for @coreUiLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык интерфейса'**
  String get coreUiLanguage;

  /// No description provided for @coreReceiptLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык чека'**
  String get coreReceiptLanguage;

  /// No description provided for @coreDuplicateBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Товар с таким штрихкодом уже существует'**
  String get coreDuplicateBarcode;

  /// No description provided for @coreDuplicateCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта с таким номером уже есть'**
  String get coreDuplicateCard;

  /// No description provided for @coreDuplicateCode.
  ///
  /// In ru, this message translates to:
  /// **'Такой код уже существует'**
  String get coreDuplicateCode;

  /// No description provided for @coreDuplicateRecord.
  ///
  /// In ru, this message translates to:
  /// **'Такая запись уже существует'**
  String get coreDuplicateRecord;

  /// No description provided for @coreErase.
  ///
  /// In ru, this message translates to:
  /// **'Стереть'**
  String get coreErase;

  /// No description provided for @corePickProductTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбор товара'**
  String get corePickProductTitle;

  /// No description provided for @corePickProductHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, артикул или штрихкод'**
  String get corePickProductHint;

  /// No description provided for @coreSkuShort.
  ///
  /// In ru, this message translates to:
  /// **'арт. {sku}'**
  String coreSkuShort(String sku);

  /// No description provided for @coreStockShort.
  ///
  /// In ru, this message translates to:
  /// **'остаток {qty}'**
  String coreStockShort(String qty);

  /// No description provided for @coreNewCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Новый клиент'**
  String get coreNewCustomer;

  /// No description provided for @coreNameRequiredLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя *'**
  String get coreNameRequiredLabel;

  /// No description provided for @coreCustomerSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя, телефон или номер карты'**
  String get coreCustomerSearchHint;

  /// No description provided for @coreCreateCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Создать клиента'**
  String get coreCreateCustomer;

  /// No description provided for @coreCardShort.
  ///
  /// In ru, this message translates to:
  /// **'карта {number}'**
  String coreCardShort(String number);

  /// No description provided for @coreDiscountShort.
  ///
  /// In ru, this message translates to:
  /// **'скидка {percent}%'**
  String coreDiscountShort(String percent);

  /// No description provided for @coreDebtShort.
  ///
  /// In ru, this message translates to:
  /// **'долг {amount}'**
  String coreDebtShort(String amount);

  /// No description provided for @coreBonusShort.
  ///
  /// In ru, this message translates to:
  /// **'бонусы {amount}'**
  String coreBonusShort(String amount);

  /// No description provided for @corePinFormat.
  ///
  /// In ru, this message translates to:
  /// **'PIN — от 4 до 8 цифр'**
  String get corePinFormat;

  /// No description provided for @corePinTooSimple.
  ///
  /// In ru, this message translates to:
  /// **'Слишком простой PIN'**
  String get corePinTooSimple;

  /// No description provided for @corePrintPhone.
  ///
  /// In ru, this message translates to:
  /// **'Тел: {phone}'**
  String corePrintPhone(String phone);

  /// No description provided for @corePrintTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН: {taxId}'**
  String corePrintTaxId(String taxId);

  /// No description provided for @coreReceiptTitle.
  ///
  /// In ru, this message translates to:
  /// **'ЧЕК №{number}'**
  String coreReceiptTitle(String number);

  /// No description provided for @coreReceiptCopyTitle.
  ///
  /// In ru, this message translates to:
  /// **'КОПИЯ ЧЕК №{number}'**
  String coreReceiptCopyTitle(String number);

  /// No description provided for @corePrintCashier.
  ///
  /// In ru, this message translates to:
  /// **'Кассир: {name}'**
  String corePrintCashier(String name);

  /// No description provided for @corePrintCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Клиент: {name}'**
  String corePrintCustomer(String name);

  /// No description provided for @corePrintWarrantyUntil.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия до {date}'**
  String corePrintWarrantyUntil(String date);

  /// No description provided for @corePrintTotal.
  ///
  /// In ru, this message translates to:
  /// **'ИТОГО'**
  String get corePrintTotal;

  /// No description provided for @corePrintVatIncluded.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. НДС'**
  String get corePrintVatIncluded;

  /// No description provided for @corePrintBonusEarned.
  ///
  /// In ru, this message translates to:
  /// **'Начислено бонусов'**
  String get corePrintBonusEarned;

  /// No description provided for @corePrintCustomerDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долг клиента'**
  String get corePrintCustomerDebt;

  /// No description provided for @corePrintVoided.
  ///
  /// In ru, this message translates to:
  /// **'*** АННУЛИРОВАН ***'**
  String get corePrintVoided;

  /// No description provided for @corePrintReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина: {reason}'**
  String corePrintReason(String reason);

  /// No description provided for @corePrintJobReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Чек {number}'**
  String corePrintJobReceipt(String number);

  /// No description provided for @corePrintJobGift.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {number}'**
  String corePrintJobGift(String number);

  /// No description provided for @coreGiftSlipTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата №{number}'**
  String coreGiftSlipTitle(String number);

  /// No description provided for @coreGiftSlipCopyTitle.
  ///
  /// In ru, this message translates to:
  /// **'КОПИЯ Продажа сертификата №{number}'**
  String coreGiftSlipCopyTitle(String number);

  /// No description provided for @coreGiftSlipNote.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат не является фискальным чеком на товар'**
  String get coreGiftSlipNote;

  /// No description provided for @coreGiftCode.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата'**
  String get coreGiftCode;

  /// No description provided for @coreGiftFaceValue.
  ///
  /// In ru, this message translates to:
  /// **'Номинал'**
  String get coreGiftFaceValue;

  /// No description provided for @coreGiftValidity.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия'**
  String get coreGiftValidity;

  /// No description provided for @coreGiftNoExpiry.
  ///
  /// In ru, this message translates to:
  /// **'без срока'**
  String get coreGiftNoExpiry;

  /// No description provided for @coreGiftUntil.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String coreGiftUntil(String date);

  /// No description provided for @navDashboard.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get navDashboard;

  /// No description provided for @navPos.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get navPos;

  /// No description provided for @navSales.
  ///
  /// In ru, this message translates to:
  /// **'Чеки'**
  String get navSales;

  /// No description provided for @navShifts.
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get navShifts;

  /// No description provided for @navProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get navProducts;

  /// No description provided for @navInventory.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get navInventory;

  /// No description provided for @navPurchasing.
  ///
  /// In ru, this message translates to:
  /// **'Закупки'**
  String get navPurchasing;

  /// No description provided for @navCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Клиенты'**
  String get navCustomers;

  /// No description provided for @navMarketing.
  ///
  /// In ru, this message translates to:
  /// **'Маркетинг'**
  String get navMarketing;

  /// No description provided for @navWarranty.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия'**
  String get navWarranty;

  /// No description provided for @navReports.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get navReports;

  /// No description provided for @navStaff.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get navStaff;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettings;

  /// No description provided for @navNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get navNotifications;

  /// No description provided for @appMenu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get appMenu;

  /// No description provided for @appShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get appShiftClosed;

  /// No description provided for @appShiftChip.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} · с {time}'**
  String appShiftChip(String number, String time);

  /// No description provided for @appShiftChipShort.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number}'**
  String appShiftChipShort(String number);

  /// No description provided for @appShiftChipNumber.
  ///
  /// In ru, this message translates to:
  /// **'№{number}'**
  String appShiftChipNumber(String number);

  /// No description provided for @appProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get appProfile;

  /// No description provided for @appLockSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать / сменить кассира'**
  String get appLockSwitch;

  /// No description provided for @domCustomerDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка клиента'**
  String get domCustomerDiscount;

  /// No description provided for @errPinInUse.
  ///
  /// In ru, this message translates to:
  /// **'Этот PIN уже используется другим сотрудником'**
  String get errPinInUse;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много неверных попыток. Подождите {minutes} минут'**
  String errTooManyAttempts(String minutes);

  /// No description provided for @errAccountLockedTryLater.
  ///
  /// In ru, this message translates to:
  /// **'Учётная запись временно заблокирована. Попробуйте позже'**
  String get errAccountLockedTryLater;

  /// No description provided for @errAccountLocked.
  ///
  /// In ru, this message translates to:
  /// **'Учётная запись временно заблокирована'**
  String get errAccountLocked;

  /// No description provided for @errWrongPin.
  ///
  /// In ru, this message translates to:
  /// **'Неверный PIN'**
  String get errWrongPin;

  /// No description provided for @errAmountMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'Сумма должна быть больше нуля'**
  String get errAmountMustBePositive;

  /// No description provided for @errNoDebt.
  ///
  /// In ru, this message translates to:
  /// **'У клиента нет долга'**
  String get errNoDebt;

  /// No description provided for @errAmountExceedsDebt.
  ///
  /// In ru, this message translates to:
  /// **'Сумма больше долга клиента'**
  String get errAmountExceedsDebt;

  /// No description provided for @errOpenShiftForCash.
  ///
  /// In ru, this message translates to:
  /// **'Для приёма наличных откройте смену'**
  String get errOpenShiftForCash;

  /// No description provided for @errBonusNegative.
  ///
  /// In ru, this message translates to:
  /// **'Баланс бонусов не может быть отрицательным'**
  String get errBonusNegative;

  /// No description provided for @errGiftCodeTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата — минимум 6 символов'**
  String get errGiftCodeTooShort;

  /// No description provided for @errGiftCodeTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата слишком длинный'**
  String get errGiftCodeTooLong;

  /// No description provided for @errGiftCodeChars.
  ///
  /// In ru, this message translates to:
  /// **'Код: только латинские буквы и цифры'**
  String get errGiftCodeChars;

  /// No description provided for @errFaceValuePositive.
  ///
  /// In ru, this message translates to:
  /// **'Номинал должен быть больше нуля'**
  String get errFaceValuePositive;

  /// No description provided for @errExpiryPassed.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия уже истёк'**
  String get errExpiryPassed;

  /// No description provided for @errOpenShiftToSellGift.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы продать сертификат'**
  String get errOpenShiftToSellGift;

  /// No description provided for @errChoosePaymentMethod.
  ///
  /// In ru, this message translates to:
  /// **'Выберите способ оплаты'**
  String get errChoosePaymentMethod;

  /// No description provided for @errGiftPaymentMethods.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат можно оплатить только наличными, картой или переводом'**
  String get errGiftPaymentMethods;

  /// No description provided for @errPaymentMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'Сумма оплаты должна быть больше нуля'**
  String get errPaymentMustBePositive;

  /// No description provided for @errGiftPaymentsMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Сумма оплат не совпадает с номиналом сертификата'**
  String get errGiftPaymentsMismatch;

  /// No description provided for @errCashNotInPayment.
  ///
  /// In ru, this message translates to:
  /// **'Наличные не входят в оплату'**
  String get errCashNotInPayment;

  /// No description provided for @errCashTenderedLess.
  ///
  /// In ru, this message translates to:
  /// **'Получено наличных меньше суммы к оплате'**
  String get errCashTenderedLess;

  /// No description provided for @errGiftCodeExists.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат с кодом {code} уже существует'**
  String errGiftCodeExists(String code);

  /// No description provided for @errDocumentNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Документ не найден'**
  String get errDocumentNotFound;

  /// No description provided for @errGiftSaleAlreadyVoided.
  ///
  /// In ru, this message translates to:
  /// **'Продажа уже аннулирована'**
  String get errGiftSaleAlreadyVoided;

  /// No description provided for @errGiftNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат не найден'**
  String get errGiftNotFound;

  /// No description provided for @errGiftUsedCannotVoid.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат уже использован — аннулирование невозможно'**
  String get errGiftUsedCannotVoid;

  /// No description provided for @errVoidReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину аннулирования'**
  String get errVoidReasonRequired;

  /// No description provided for @errOpenShiftToVoid.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы аннулировать продажу'**
  String get errOpenShiftToVoid;

  /// No description provided for @errGiftSaleNumberVoided.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата №{number} уже аннулирована'**
  String errGiftSaleNumberVoided(String number);

  /// No description provided for @errAddLine.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одну позицию'**
  String get errAddLine;

  /// No description provided for @errPurchasePriceNegative.
  ///
  /// In ru, this message translates to:
  /// **'Цена закупки не может быть отрицательной'**
  String get errPurchasePriceNegative;

  /// No description provided for @errRetailPricePositive.
  ///
  /// In ru, this message translates to:
  /// **'Розничная цена должна быть больше нуля'**
  String get errRetailPricePositive;

  /// No description provided for @errProductNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Товар не найден'**
  String get errProductNotFound;

  /// No description provided for @errProductDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{name}» удалён'**
  String errProductDeleted(String name);

  /// No description provided for @errLinePurchasePriceNegative.
  ///
  /// In ru, this message translates to:
  /// **'{name}: цена закупки отрицательная'**
  String errLinePurchasePriceNegative(String name);

  /// No description provided for @errProductRepeated.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{name}» повторяется в документе — объедините строки'**
  String errProductRepeated(String name);

  /// No description provided for @errSupplierNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик не найден'**
  String get errSupplierNotFound;

  /// No description provided for @errOrderNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Заказ не найден'**
  String get errOrderNotFound;

  /// No description provided for @errOrderOtherSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Заказ не относится к этому поставщику'**
  String get errOrderOtherSupplier;

  /// No description provided for @errOrderClosed.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number} уже закрыт'**
  String errOrderClosed(String number);

  /// No description provided for @errOrderLineNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Позиция не найдена в заказе'**
  String get errOrderLineNotFound;

  /// No description provided for @errOrderLineWithoutOrder.
  ///
  /// In ru, this message translates to:
  /// **'Позиция заказа указана без заказа'**
  String get errOrderLineWithoutOrder;

  /// No description provided for @errReversalReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину сторно'**
  String get errReversalReasonRequired;

  /// No description provided for @errReceiptNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Приход не найден'**
  String get errReceiptNotFound;

  /// No description provided for @errReceiptAlreadyReversed.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} уже сторнирован'**
  String errReceiptAlreadyReversed(String number);

  /// No description provided for @errSupplierDeletedNoReversal.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик «{name}» удалён — сторно прихода №{number} невозможно'**
  String errSupplierDeletedNoReversal(String name, String number);

  /// No description provided for @errQtyMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'Количество должно быть больше нуля'**
  String get errQtyMustBePositive;

  /// No description provided for @errQtyIntegerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Для «{unit}» допускается только целое число'**
  String errQtyIntegerOnly(String unit);

  /// No description provided for @errQtyTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большое количество'**
  String get errQtyTooLarge;

  /// No description provided for @errCartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Чек пуст'**
  String get errCartEmpty;

  /// No description provided for @errPriceNegative.
  ///
  /// In ru, this message translates to:
  /// **'Цена не может быть отрицательной'**
  String get errPriceNegative;

  /// No description provided for @errPaymentNegative.
  ///
  /// In ru, this message translates to:
  /// **'Сумма оплаты не может быть отрицательной'**
  String get errPaymentNegative;

  /// No description provided for @errUnknownPaymentMethodNamed.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный способ оплаты: {method}'**
  String errUnknownPaymentMethodNamed(String method);

  /// No description provided for @errUnknownPaymentMethod.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный способ оплаты'**
  String get errUnknownPaymentMethod;

  /// No description provided for @errOpenShiftToSell.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы продавать'**
  String get errOpenShiftToSell;

  /// No description provided for @errShiftClosedOpenNew.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта. Откройте новую смену'**
  String get errShiftClosedOpenNew;

  /// No description provided for @errProductNotFoundOrDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар не найден или удалён'**
  String get errProductNotFoundOrDeleted;

  /// No description provided for @errPromoInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Промокод недействителен'**
  String get errPromoInvalid;

  /// No description provided for @errManualDiscountLimit.
  ///
  /// In ru, this message translates to:
  /// **'Ручная скидка {percent}% превышает допустимую ({limit}%). Нужно подтверждение менеджера'**
  String errManualDiscountLimit(String percent, String limit);

  /// No description provided for @errNonCashExceedsTotal.
  ///
  /// In ru, this message translates to:
  /// **'Безналичная оплата превышает сумму чека'**
  String get errNonCashExceedsTotal;

  /// No description provided for @errInsufficientPayment.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно оплаты: не хватает {amount}'**
  String errInsufficientPayment(String amount);

  /// No description provided for @errBonusNeedsCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Для оплаты бонусами выберите клиента'**
  String get errBonusNeedsCustomer;

  /// No description provided for @errLoyaltyDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа выключена'**
  String get errLoyaltyDisabled;

  /// No description provided for @errInsufficientBonus.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно бонусов: доступно {amount}'**
  String errInsufficientBonus(String amount);

  /// No description provided for @errBonusMaxRedeem.
  ///
  /// In ru, this message translates to:
  /// **'Бонусами можно оплатить не более {amount}'**
  String errBonusMaxRedeem(String amount);

  /// No description provided for @errDebtNeedsCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Для продажи в долг выберите клиента'**
  String get errDebtNeedsCustomer;

  /// No description provided for @errCreditLimitExceeded.
  ///
  /// In ru, this message translates to:
  /// **'Превышен кредитный лимит клиента ({limit}). Текущий долг: {debt}'**
  String errCreditLimitExceeded(String limit, String debt);

  /// No description provided for @errNoCredit.
  ///
  /// In ru, this message translates to:
  /// **'Клиенту не открыт кредит'**
  String get errNoCredit;

  /// No description provided for @errGiftCardNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {code} не найден'**
  String errGiftCardNotFound(String code);

  /// No description provided for @errGiftCardInactive.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {code} не активен'**
  String errGiftCardInactive(String code);

  /// No description provided for @errGiftCardExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия сертификата {code} истёк'**
  String errGiftCardExpired(String code);

  /// No description provided for @errGiftCardInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'На сертификате {code} только {amount}'**
  String errGiftCardInsufficient(String code, String amount);

  /// No description provided for @errSelectReturnItems.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товары для возврата'**
  String get errSelectReturnItems;

  /// No description provided for @errSaleNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Чек не найден'**
  String get errSaleNotFound;

  /// No description provided for @errFullyReturned.
  ///
  /// In ru, this message translates to:
  /// **'По этому чеку уже оформлен полный возврат'**
  String get errFullyReturned;

  /// No description provided for @errReturnPeriodExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок возврата ({days} дн.) истёк'**
  String errReturnPeriodExpired(String days);

  /// No description provided for @errLineNotInSale.
  ///
  /// In ru, this message translates to:
  /// **'Позиция не из этого чека'**
  String get errLineNotInSale;

  /// No description provided for @errReturnQtyExceeded.
  ///
  /// In ru, this message translates to:
  /// **'«{name}»: можно вернуть не более {qty}'**
  String errReturnQtyExceeded(String name, String qty);

  /// No description provided for @errSaleNoCustomer.
  ///
  /// In ru, this message translates to:
  /// **'В чеке нет клиента'**
  String get errSaleNoCustomer;

  /// No description provided for @errOpenShiftForCashRefund.
  ///
  /// In ru, this message translates to:
  /// **'Для возврата наличными откройте смену'**
  String get errOpenShiftForCashRefund;

  /// No description provided for @errVoidOnlyWithoutReturns.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать можно только чек без возвратов'**
  String get errVoidOnlyWithoutReturns;

  /// No description provided for @errSaleOtherShift.
  ///
  /// In ru, this message translates to:
  /// **'Чек из другой смены — оформите возврат'**
  String get errSaleOtherShift;

  /// No description provided for @errAmountNegative.
  ///
  /// In ru, this message translates to:
  /// **'Сумма не может быть отрицательной'**
  String get errAmountNegative;

  /// No description provided for @errShiftAlreadyOpen.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} уже открыта'**
  String errShiftAlreadyOpen(String number);

  /// No description provided for @errUnknownOperation.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная операция'**
  String get errUnknownOperation;

  /// No description provided for @errShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get errShiftClosed;

  /// No description provided for @errNotEnoughCash.
  ///
  /// In ru, this message translates to:
  /// **'В кассе недостаточно наличных'**
  String get errNotEnoughCash;

  /// No description provided for @errShiftAlreadyClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена уже закрыта'**
  String get errShiftAlreadyClosed;

  /// No description provided for @errInsufficientStock.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно товара «{name}»: в наличии {qty}'**
  String errInsufficientStock(String name, String qty);

  /// No description provided for @errCountClosed.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация уже закрыта'**
  String get errCountClosed;

  /// No description provided for @errSupplierDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик «{name}» удалён — операция невозможна'**
  String errSupplierDeleted(String name);

  /// No description provided for @errOpenShiftForCashPayout.
  ///
  /// In ru, this message translates to:
  /// **'Для оплаты наличными из кассы откройте смену'**
  String get errOpenShiftForCashPayout;

  /// No description provided for @errOverpaySupplier.
  ///
  /// In ru, this message translates to:
  /// **'Сумма больше долга поставщику ({amount}). Подтвердите переплату.'**
  String errOverpaySupplier(String amount);

  /// No description provided for @errOrderCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number} отменён'**
  String errOrderCancelled(String number);

  /// No description provided for @errShiftClosedOpenShift.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта — откройте смену'**
  String get errShiftClosedOpenShift;

  /// No description provided for @errCancelReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину отмены оплаты'**
  String get errCancelReasonRequired;

  /// No description provided for @errPaymentNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Оплата не найдена'**
  String get errPaymentNotFound;

  /// No description provided for @errPaymentAlreadyCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Оплата уже отменена'**
  String get errPaymentAlreadyCancelled;

  /// No description provided for @errPaymentShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена оплаты закрыта — отмена невозможна'**
  String get errPaymentShiftClosed;

  /// No description provided for @errAdjustmentZero.
  ///
  /// In ru, this message translates to:
  /// **'Сумма корректировки не может быть нулевой'**
  String get errAdjustmentZero;

  /// No description provided for @errAdjustmentReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину корректировки'**
  String get errAdjustmentReasonRequired;

  /// No description provided for @errPinAmbiguous.
  ///
  /// In ru, this message translates to:
  /// **'Этот PIN-код есть у нескольких сотрудников (после синхронизации касс). Войдите другим сотрудником и смените PIN одному из них.'**
  String get errPinAmbiguous;

  /// No description provided for @errPaymentOtherRegisterShift.
  ///
  /// In ru, this message translates to:
  /// **'Оплата наличными внесена в смене другой кассы — отменить её можно только на той кассе'**
  String get errPaymentOtherRegisterShift;

  /// No description provided for @errReceiptOpeningNoReversal.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} — начальный остаток синхронизации, его нельзя сторнировать'**
  String errReceiptOpeningNoReversal(String number);

  /// No description provided for @errEffectDoneElsewhere.
  ///
  /// In ru, this message translates to:
  /// **'Этот документ уже проведён на другой кассе, но его изменения ещё не все пришли. Синхронизируйте кассу и откройте документ снова.'**
  String get errEffectDoneElsewhere;

  /// No description provided for @authEnterPin.
  ///
  /// In ru, this message translates to:
  /// **'Введите PIN-код'**
  String get authEnterPin;

  /// No description provided for @authDemoMode.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим'**
  String get authDemoMode;

  /// No description provided for @setupDefaultReceiptFooter.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за покупку!'**
  String get setupDefaultReceiptFooter;

  /// No description provided for @setupWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в DreamPOS'**
  String get setupWelcome;

  /// No description provided for @setupIntro.
  ///
  /// In ru, this message translates to:
  /// **'Настройка займёт меньше минуты. Всё можно изменить позже в «Настройках».'**
  String get setupIntro;

  /// No description provided for @setupStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать работу'**
  String get setupStart;

  /// No description provided for @setupStoreName.
  ///
  /// In ru, this message translates to:
  /// **'Название магазина *'**
  String get setupStoreName;

  /// No description provided for @setupEnterStoreName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get setupEnterStoreName;

  /// No description provided for @setupTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН / STIR'**
  String get setupTaxId;

  /// No description provided for @setupCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта учёта'**
  String get setupCurrency;

  /// No description provided for @setupCurrencyExample.
  ///
  /// In ru, this message translates to:
  /// **'Пример: {amount}'**
  String setupCurrencyExample(String amount);

  /// No description provided for @setupCurrencyWarning.
  ///
  /// In ru, this message translates to:
  /// **'Валюту нельзя менять после первой продажи — от неё зависят все суммы в базе.'**
  String get setupCurrencyWarning;

  /// No description provided for @setupOwnerName.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя (владелец) *'**
  String get setupOwnerName;

  /// No description provided for @setupPin.
  ///
  /// In ru, this message translates to:
  /// **'PIN-код (4–8 цифр) *'**
  String get setupPin;

  /// No description provided for @setupPinRepeat.
  ///
  /// In ru, this message translates to:
  /// **'Повторите PIN *'**
  String get setupPinRepeat;

  /// No description provided for @setupPinMismatch.
  ///
  /// In ru, this message translates to:
  /// **'PIN не совпадает'**
  String get setupPinMismatch;

  /// No description provided for @setupDemo.
  ///
  /// In ru, this message translates to:
  /// **'Заполнить демо-данными'**
  String get setupDemo;

  /// No description provided for @setupDemoHint.
  ///
  /// In ru, this message translates to:
  /// **'Товары, клиенты и акции для знакомства с системой. Не включайте для реального магазина.'**
  String get setupDemoHint;

  /// No description provided for @setupStepStore.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get setupStepStore;

  /// No description provided for @setupStepCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта'**
  String get setupStepCurrency;

  /// No description provided for @setupStepOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get setupStepOwner;

  /// No description provided for @setupOr.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get setupOr;

  /// No description provided for @setupJoinStore.
  ///
  /// In ru, this message translates to:
  /// **'Подключиться к существующему магазину'**
  String get setupJoinStore;

  /// No description provided for @setupJoinStoreHint.
  ///
  /// In ru, this message translates to:
  /// **'Если магазин уже работает в облаке на другой кассе: товары, клиенты и пользователи загрузятся оттуда.'**
  String get setupJoinStoreHint;

  /// No description provided for @setupJoinTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к магазину'**
  String get setupJoinTitle;

  /// No description provided for @setupJoinIntro.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт облака и выберите магазин. Его данные и пользователи загрузятся на эту кассу, затем войдите по PIN-коду.'**
  String get setupJoinIntro;

  /// No description provided for @setupJoinNewStore.
  ///
  /// In ru, this message translates to:
  /// **'Создать новый магазин'**
  String get setupJoinNewStore;

  /// No description provided for @setupJoinDone.
  ///
  /// In ru, this message translates to:
  /// **'Данные магазина загружены. Войдите по PIN-коду.'**
  String get setupJoinDone;

  /// No description provided for @setupJoinPartial.
  ///
  /// In ru, this message translates to:
  /// **'Касса подключена, но загрузка данных не завершилась. Проверьте связь и повторите.'**
  String get setupJoinPartial;

  /// No description provided for @setupJoinRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку'**
  String get setupJoinRetry;

  /// No description provided for @custCreated.
  ///
  /// In ru, this message translates to:
  /// **'Клиент создан'**
  String get custCreated;

  /// No description provided for @custNoneToExport.
  ///
  /// In ru, this message translates to:
  /// **'Нет клиентов для экспорта'**
  String get custNoneToExport;

  /// No description provided for @custCsvCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано {count} клиентов в формате CSV — вставьте в Excel'**
  String custCsvCopied(String count);

  /// No description provided for @custTotalCount.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String custTotalCount(String count);

  /// No description provided for @custExportTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать текущий список в CSV (для Excel)'**
  String get custExportTooltip;

  /// No description provided for @custNewTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Новый клиент (Ctrl+N)'**
  String get custNewTooltip;

  /// No description provided for @custNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый клиент'**
  String get custNew;

  /// No description provided for @custSelectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите клиента'**
  String get custSelectTitle;

  /// No description provided for @custSelectMessage.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся покупки, долги, бонусы и любимые товары клиента.'**
  String get custSelectMessage;

  /// No description provided for @custStatCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Клиентов'**
  String get custStatCustomers;

  /// No description provided for @custStatReceivable.
  ///
  /// In ru, this message translates to:
  /// **'Дебиторка'**
  String get custStatReceivable;

  /// No description provided for @custOverdueLower.
  ///
  /// In ru, this message translates to:
  /// **'просрочено {amount}'**
  String custOverdueLower(String amount);

  /// No description provided for @custOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено {amount}'**
  String custOverdue(String amount);

  /// No description provided for @custStatBonusLiability.
  ///
  /// In ru, this message translates to:
  /// **'Бонусные обязательства'**
  String get custStatBonusLiability;

  /// No description provided for @custSearchHintWide.
  ///
  /// In ru, this message translates to:
  /// **'Имя, телефон или карта (Ctrl+F)'**
  String get custSearchHintWide;

  /// No description provided for @custSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя, телефон, карта'**
  String get custSearchHint;

  /// No description provided for @custSortTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка: {sort}'**
  String custSortTooltip(String sort);

  /// No description provided for @custTagFilter.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр по тегу'**
  String get custTagFilter;

  /// No description provided for @custTagTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Тег: {tag}'**
  String custTagTooltip(String tag);

  /// No description provided for @custAllTags.
  ///
  /// In ru, this message translates to:
  /// **'Все теги'**
  String get custAllTags;

  /// No description provided for @custEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Клиентов пока нет'**
  String get custEmptyTitle;

  /// No description provided for @custEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте клиентов, чтобы давать скидки, начислять бонусы и продавать в долг.'**
  String get custEmptyMessage;

  /// No description provided for @custAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить клиента'**
  String get custAdd;

  /// No description provided for @custNotFoundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено'**
  String get custNotFoundTitle;

  /// No description provided for @custNotFoundMessage.
  ///
  /// In ru, this message translates to:
  /// **'Измените запрос или сбросьте фильтры'**
  String get custNotFoundMessage;

  /// No description provided for @custResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get custResetFilters;

  /// No description provided for @custTileCard.
  ///
  /// In ru, this message translates to:
  /// **'карта {card}'**
  String custTileCard(String card);

  /// No description provided for @custDiscountLower.
  ///
  /// In ru, this message translates to:
  /// **'скидка {value}'**
  String custDiscountLower(String value);

  /// No description provided for @custTilePurchases.
  ///
  /// In ru, this message translates to:
  /// **'покупки {amount}'**
  String custTilePurchases(String amount);

  /// No description provided for @custTileVisits.
  ///
  /// In ru, this message translates to:
  /// **'{count} виз.'**
  String custTileVisits(String count);

  /// No description provided for @custTileNeverBought.
  ///
  /// In ru, this message translates to:
  /// **'не покупал'**
  String get custTileNeverBought;

  /// No description provided for @custTileLastVisit.
  ///
  /// In ru, this message translates to:
  /// **'был {date}'**
  String custTileLastVisit(String date);

  /// No description provided for @custBirthdayToday.
  ///
  /// In ru, this message translates to:
  /// **'День рождения сегодня'**
  String get custBirthdayToday;

  /// No description provided for @custBirthdayIn.
  ///
  /// In ru, this message translates to:
  /// **'День рождения через {days} дн.'**
  String custBirthdayIn(String days);

  /// No description provided for @custTileDebt.
  ///
  /// In ru, this message translates to:
  /// **'долг {amount}'**
  String custTileDebt(String amount);

  /// No description provided for @custTileOverdueChip.
  ///
  /// In ru, this message translates to:
  /// **'просрочен'**
  String get custTileOverdueChip;

  /// No description provided for @custTileBonus.
  ///
  /// In ru, this message translates to:
  /// **'бонусы {amount}'**
  String custTileBonus(String amount);

  /// No description provided for @custCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Карточка клиента'**
  String get custCardTitle;

  /// No description provided for @custDeleteDebt.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя удалить клиента с долгом {amount}. Сначала примите оплату.'**
  String custDeleteDebt(String amount);

  /// No description provided for @custDeleteOverpaid.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя удалить клиента с переплатой.'**
  String get custDeleteOverpaid;

  /// No description provided for @custDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить клиента?'**
  String get custDeleteTitle;

  /// No description provided for @custDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» будет скрыт из списка. История продаж сохранится.'**
  String custDeleteMessage(String name);

  /// No description provided for @custDeleteBonusLost.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы {amount} будут недоступны.'**
  String custDeleteBonusLost(String amount);

  /// No description provided for @custDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Клиент удалён'**
  String get custDeleted;

  /// No description provided for @custNotFoundOrDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Клиент не найден или удалён'**
  String get custNotFoundOrDeleted;

  /// No description provided for @custKpiSpent.
  ///
  /// In ru, this message translates to:
  /// **'Сумма покупок'**
  String get custKpiSpent;

  /// No description provided for @custKpiVisits.
  ///
  /// In ru, this message translates to:
  /// **'Визитов'**
  String get custKpiVisits;

  /// No description provided for @custKpiAvg.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get custKpiAvg;

  /// No description provided for @custKpiLastVisit.
  ///
  /// In ru, this message translates to:
  /// **'Последний визит'**
  String get custKpiLastVisit;

  /// No description provided for @custNoPurchasesYet.
  ///
  /// In ru, this message translates to:
  /// **'Покупок ещё не было'**
  String get custNoPurchasesYet;

  /// No description provided for @custNoPurchasesLower.
  ///
  /// In ru, this message translates to:
  /// **'покупок не было'**
  String get custNoPurchasesLower;

  /// No description provided for @custLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит {amount}'**
  String custLimit(String amount);

  /// No description provided for @custLimitLower.
  ///
  /// In ru, this message translates to:
  /// **'лимит {amount}'**
  String custLimitLower(String amount);

  /// No description provided for @custNoCredit.
  ///
  /// In ru, this message translates to:
  /// **'Кредит не открыт'**
  String get custNoCredit;

  /// No description provided for @custNoCreditLower.
  ///
  /// In ru, this message translates to:
  /// **'кредит не открыт'**
  String get custNoCreditLower;

  /// No description provided for @custBdayToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня!'**
  String get custBdayToday;

  /// No description provided for @custBdayIn.
  ///
  /// In ru, this message translates to:
  /// **'через {days} дн.'**
  String custBdayIn(String days);

  /// No description provided for @custDiscountChip.
  ///
  /// In ru, this message translates to:
  /// **'Скидка {percent}%'**
  String custDiscountChip(String percent);

  /// No description provided for @custDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить клиента'**
  String get custDelete;

  /// No description provided for @custNoPayPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права принимать оплату'**
  String get custNoPayPerm;

  /// No description provided for @custAcceptDebtPayment.
  ///
  /// In ru, this message translates to:
  /// **'Принять оплату долга'**
  String get custAcceptDebtPayment;

  /// No description provided for @custNoEditPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права редактировать клиентов'**
  String get custNoEditPerm;

  /// No description provided for @custRemind.
  ///
  /// In ru, this message translates to:
  /// **'Напомнить'**
  String get custRemind;

  /// No description provided for @custNeedPromoPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нужно право «Акции и бонусы»'**
  String get custNeedPromoPerm;

  /// No description provided for @custReminder.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание'**
  String get custReminder;

  /// No description provided for @custTabSales.
  ///
  /// In ru, this message translates to:
  /// **'Покупки'**
  String get custTabSales;

  /// No description provided for @custTabSalesShort.
  ///
  /// In ru, this message translates to:
  /// **'Покупки'**
  String get custTabSalesShort;

  /// No description provided for @custTabLedgerShort.
  ///
  /// In ru, this message translates to:
  /// **'Операции'**
  String get custTabLedgerShort;

  /// No description provided for @custTabLedger.
  ///
  /// In ru, this message translates to:
  /// **'Долги и бонусы'**
  String get custTabLedger;

  /// No description provided for @custTabFavShort.
  ///
  /// In ru, this message translates to:
  /// **'Любимое'**
  String get custTabFavShort;

  /// No description provided for @custTabFav.
  ///
  /// In ru, this message translates to:
  /// **'Любимые товары'**
  String get custTabFav;

  /// No description provided for @custAgoToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get custAgoToday;

  /// No description provided for @custAgoYesterday.
  ///
  /// In ru, this message translates to:
  /// **'вчера'**
  String get custAgoYesterday;

  /// No description provided for @custAgoDays.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн. назад'**
  String custAgoDays(String days);

  /// No description provided for @custCopy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get custCopy;

  /// No description provided for @custCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано: {text}'**
  String custCopied(String text);

  /// No description provided for @custSalesEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Покупок пока нет'**
  String get custSalesEmptyTitle;

  /// No description provided for @custSalesEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Выберите клиента на кассе, чтобы копить историю и бонусы.'**
  String get custSalesEmptyMessage;

  /// No description provided for @custReceiptNo.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number}'**
  String custReceiptNo(String number);

  /// No description provided for @custReturnLower.
  ///
  /// In ru, this message translates to:
  /// **'возврат {amount}'**
  String custReturnLower(String amount);

  /// No description provided for @custReturnedQty.
  ///
  /// In ru, this message translates to:
  /// **'возвращено {qty}'**
  String custReturnedQty(String qty);

  /// No description provided for @custBonusEarned.
  ///
  /// In ru, this message translates to:
  /// **'Начислено бонусов: {amount}'**
  String custBonusEarned(String amount);

  /// No description provided for @custLedgerEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Операций по долгу и бонусам нет'**
  String get custLedgerEmpty;

  /// No description provided for @custDueUntil.
  ///
  /// In ru, this message translates to:
  /// **'срок до {date}'**
  String custDueUntil(String date);

  /// No description provided for @custBalanceAfter.
  ///
  /// In ru, this message translates to:
  /// **'остаток {amount}'**
  String custBalanceAfter(String amount);

  /// No description provided for @custDuePassed.
  ///
  /// In ru, this message translates to:
  /// **'срок прошёл'**
  String get custDuePassed;

  /// No description provided for @custFavEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных о покупках'**
  String get custFavEmpty;

  /// No description provided for @custBought.
  ///
  /// In ru, this message translates to:
  /// **'куплено {qty}'**
  String custBought(String qty);

  /// No description provided for @custSegDebtors.
  ///
  /// In ru, this message translates to:
  /// **'Должники'**
  String get custSegDebtors;

  /// No description provided for @custSegOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Просрочка'**
  String get custSegOverdue;

  /// No description provided for @custSegVip.
  ///
  /// In ru, this message translates to:
  /// **'VIP'**
  String get custSegVip;

  /// No description provided for @custSegSleeping.
  ///
  /// In ru, this message translates to:
  /// **'Спящие'**
  String get custSegSleeping;

  /// No description provided for @custSegBirthdays.
  ///
  /// In ru, this message translates to:
  /// **'Именинники'**
  String get custSegBirthdays;

  /// No description provided for @custSegAllHint.
  ///
  /// In ru, this message translates to:
  /// **'Все клиенты'**
  String get custSegAllHint;

  /// No description provided for @custSegDebtorsHint.
  ///
  /// In ru, this message translates to:
  /// **'Клиенты с непогашенным долгом'**
  String get custSegDebtorsHint;

  /// No description provided for @custSegOverdueHint.
  ///
  /// In ru, this message translates to:
  /// **'Срок оплаты долга прошёл'**
  String get custSegOverdueHint;

  /// No description provided for @custSegVipHint.
  ///
  /// In ru, this message translates to:
  /// **'Топ-10% клиентов по сумме покупок'**
  String get custSegVipHint;

  /// No description provided for @custSegSleepingHint.
  ///
  /// In ru, this message translates to:
  /// **'Не покупали больше {days} дней'**
  String custSegSleepingHint(String days);

  /// No description provided for @custSegBirthdaysHint.
  ///
  /// In ru, this message translates to:
  /// **'День рождения в ближайшие {days} дней'**
  String custSegBirthdaysHint(String days);

  /// No description provided for @custSortName.
  ///
  /// In ru, this message translates to:
  /// **'По имени'**
  String get custSortName;

  /// No description provided for @custSortLastVisit.
  ///
  /// In ru, this message translates to:
  /// **'По последнему визиту'**
  String get custSortLastVisit;

  /// No description provided for @custSortSpent.
  ///
  /// In ru, this message translates to:
  /// **'По сумме покупок'**
  String get custSortSpent;

  /// No description provided for @custSortDebt.
  ///
  /// In ru, this message translates to:
  /// **'По долгу'**
  String get custSortDebt;

  /// No description provided for @custSortBonus.
  ///
  /// In ru, this message translates to:
  /// **'По бонусам'**
  String get custSortBonus;

  /// No description provided for @custSortCreated.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новые'**
  String get custSortCreated;

  /// No description provided for @custLedgerDebtSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажа в долг'**
  String get custLedgerDebtSale;

  /// No description provided for @custLedgerDebtPayment.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долга'**
  String get custLedgerDebtPayment;

  /// No description provided for @custLedgerDebtAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка долга'**
  String get custLedgerDebtAdjust;

  /// No description provided for @custLedgerBonusEarn.
  ///
  /// In ru, this message translates to:
  /// **'Начисление бонусов'**
  String get custLedgerBonusEarn;

  /// No description provided for @custLedgerBonusSpend.
  ///
  /// In ru, this message translates to:
  /// **'Списание бонусов'**
  String get custLedgerBonusSpend;

  /// No description provided for @custLedgerBonusAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка бонусов'**
  String get custLedgerBonusAdjust;

  /// No description provided for @custStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Оплачен'**
  String get custStatusCompleted;

  /// No description provided for @custStatusPartReturned.
  ///
  /// In ru, this message translates to:
  /// **'Частичный возврат'**
  String get custStatusPartReturned;

  /// No description provided for @custStatusReturned.
  ///
  /// In ru, this message translates to:
  /// **'Возвращён'**
  String get custStatusReturned;

  /// No description provided for @custStatusHeld.
  ///
  /// In ru, this message translates to:
  /// **'Отложен'**
  String get custStatusHeld;

  /// No description provided for @custReminderGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! Ваш долг в {store} составляет {debt}.'**
  String custReminderGreeting(String name, String store, String debt);

  /// No description provided for @custReminderOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Из них просрочено: {amount}.'**
  String custReminderOverdue(String amount);

  /// No description provided for @custReminderDue.
  ///
  /// In ru, this message translates to:
  /// **'Срок оплаты — до {date}.'**
  String custReminderDue(String date);

  /// No description provided for @custReminderAsk.
  ///
  /// In ru, this message translates to:
  /// **'Просим погасить задолженность при ближайшем посещении магазина.'**
  String get custReminderAsk;

  /// No description provided for @custReminderPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон для связи: {phone}.'**
  String custReminderPhone(String phone);

  /// No description provided for @custThanks.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо!'**
  String get custThanks;

  /// No description provided for @custCsvCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get custCsvCard;

  /// No description provided for @custCsvDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка %'**
  String get custCsvDiscount;

  /// No description provided for @custPaymentAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Оплата {amount} принята'**
  String custPaymentAccepted(String amount);

  /// No description provided for @custCurrentDebt.
  ///
  /// In ru, this message translates to:
  /// **'Текущий долг:'**
  String get custCurrentDebt;

  /// No description provided for @custPayAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма оплаты *'**
  String get custPayAmount;

  /// No description provided for @custNotMoreThanDebt.
  ///
  /// In ru, this message translates to:
  /// **'Не больше долга ({amount})'**
  String custNotMoreThanDebt(String amount);

  /// No description provided for @custFullAmountValue.
  ///
  /// In ru, this message translates to:
  /// **'Вся сумма: {amount}'**
  String custFullAmountValue(String amount);

  /// No description provided for @custFullAmount.
  ///
  /// In ru, this message translates to:
  /// **'Вся сумма'**
  String get custFullAmount;

  /// No description provided for @custShiftClosedCash.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта: для приёма наличных откройте смену или выберите другой способ.'**
  String get custShiftClosedCash;

  /// No description provided for @custCashToShift.
  ///
  /// In ru, this message translates to:
  /// **'Наличные будут учтены в кассе смены №{number}'**
  String custCashToShift(String number);

  /// No description provided for @custPrintSlip.
  ///
  /// In ru, this message translates to:
  /// **'Распечатать квитанцию'**
  String get custPrintSlip;

  /// No description provided for @custAcceptPayment.
  ///
  /// In ru, this message translates to:
  /// **'Принять оплату'**
  String get custAcceptPayment;

  /// No description provided for @custPdfSlipTitle.
  ///
  /// In ru, this message translates to:
  /// **'КВИТАНЦИЯ'**
  String get custPdfSlipTitle;

  /// No description provided for @custPdfSlipSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'об оплате долга'**
  String get custPdfSlipSubtitle;

  /// No description provided for @custPdfDebtBefore.
  ///
  /// In ru, this message translates to:
  /// **'Долг до оплаты'**
  String get custPdfDebtBefore;

  /// No description provided for @custPdfPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено ({method})'**
  String custPdfPaid(String method);

  /// No description provided for @custPdfDebtAfter.
  ///
  /// In ru, this message translates to:
  /// **'Остаток долга'**
  String get custPdfDebtAfter;

  /// No description provided for @custPdfSignature.
  ///
  /// In ru, this message translates to:
  /// **'Подпись клиента: ____________'**
  String get custPdfSignature;

  /// No description provided for @custPdfJobName.
  ///
  /// In ru, this message translates to:
  /// **'Квитанция {name}'**
  String custPdfJobName(String name);

  /// No description provided for @custBonusAdded.
  ///
  /// In ru, this message translates to:
  /// **'Начислено {amount}'**
  String custBonusAdded(String amount);

  /// No description provided for @custBonusRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Списано {amount}'**
  String custBonusRemoved(String amount);

  /// No description provided for @custBonusHeader.
  ///
  /// In ru, this message translates to:
  /// **'{name} · баланс {amount}'**
  String custBonusHeader(String name, String amount);

  /// No description provided for @custBonusAdd.
  ///
  /// In ru, this message translates to:
  /// **'Начислить'**
  String get custBonusAdd;

  /// No description provided for @custBonusRemove.
  ///
  /// In ru, this message translates to:
  /// **'Списать'**
  String get custBonusRemove;

  /// No description provided for @custBonusAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма бонусов *'**
  String get custBonusAmount;

  /// No description provided for @custBonusOnlyOnBalance.
  ///
  /// In ru, this message translates to:
  /// **'На балансе только {amount}'**
  String custBonusOnlyOnBalance(String amount);

  /// No description provided for @custReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Причина *'**
  String get custReasonRequired;

  /// No description provided for @custReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: компенсация за задержку заказа'**
  String get custReasonHint;

  /// No description provided for @custReasonError.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину корректировки'**
  String get custReasonError;

  /// No description provided for @custOurStore.
  ///
  /// In ru, this message translates to:
  /// **'наш магазин'**
  String get custOurStore;

  /// No description provided for @custReminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание о долге'**
  String get custReminderTitle;

  /// No description provided for @custPhoneCopied.
  ///
  /// In ru, this message translates to:
  /// **'Телефон скопирован'**
  String get custPhoneCopied;

  /// No description provided for @custReminderEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Текст напоминания пуст'**
  String get custReminderEmpty;

  /// No description provided for @custReminderCopied.
  ///
  /// In ru, this message translates to:
  /// **'Текст напоминания скопирован'**
  String get custReminderCopied;

  /// No description provided for @custPhoneValue.
  ///
  /// In ru, this message translates to:
  /// **'Телефон: {phone}'**
  String custPhoneValue(String phone);

  /// No description provided for @custReminderSendHint.
  ///
  /// In ru, this message translates to:
  /// **'Отправьте текст в мессенджере или SMS со своего телефона.'**
  String get custReminderSendHint;

  /// No description provided for @custCopyPhone.
  ///
  /// In ru, this message translates to:
  /// **'Копировать телефон'**
  String get custCopyPhone;

  /// No description provided for @custCopyText.
  ///
  /// In ru, this message translates to:
  /// **'Копировать текст'**
  String get custCopyText;

  /// No description provided for @custEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование клиента'**
  String get custEditTitle;

  /// No description provided for @custBirthday.
  ///
  /// In ru, this message translates to:
  /// **'День рождения'**
  String get custBirthday;

  /// No description provided for @custCardTaken.
  ///
  /// In ru, this message translates to:
  /// **'Эта карта уже привязана к другому клиенту'**
  String get custCardTaken;

  /// No description provided for @custPhoneUsedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Телефон уже используется'**
  String get custPhoneUsedTitle;

  /// No description provided for @custPhoneUsedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Номер {phone} уже есть у клиента «{name}». Сохранить ещё одного клиента с этим номером?'**
  String custPhoneUsedMessage(String phone, String name);

  /// No description provided for @custNameField.
  ///
  /// In ru, this message translates to:
  /// **'Имя *'**
  String get custNameField;

  /// No description provided for @custEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя клиента'**
  String get custEnterName;

  /// No description provided for @custPhoneExists.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть: {names}'**
  String custPhoneExists(String names);

  /// No description provided for @custPhoneTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Слишком короткий номер'**
  String get custPhoneTooShort;

  /// No description provided for @custPhoneTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Слишком длинный номер'**
  String get custPhoneTooLong;

  /// No description provided for @custEmailInvalidFormat.
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат email'**
  String get custEmailInvalidFormat;

  /// No description provided for @custCardNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер карты'**
  String get custCardNumber;

  /// No description provided for @custGenerateCard.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать номер карты'**
  String get custGenerateCard;

  /// No description provided for @custNotSet.
  ///
  /// In ru, this message translates to:
  /// **'Не указан'**
  String get custNotSet;

  /// No description provided for @custNoDiscountPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права изменять скидку'**
  String get custNoDiscountPerm;

  /// No description provided for @custPersonalDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Персональная скидка'**
  String get custPersonalDiscount;

  /// No description provided for @custDiscountHelper.
  ///
  /// In ru, this message translates to:
  /// **'Не суммируется с акциями: берётся лучшая'**
  String get custDiscountHelper;

  /// No description provided for @custPercentRange.
  ///
  /// In ru, this message translates to:
  /// **'От 0 до 100%'**
  String get custPercentRange;

  /// No description provided for @custNoDebtPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права управлять долгами'**
  String get custNoDebtPerm;

  /// No description provided for @custDebtLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит долга'**
  String get custDebtLimit;

  /// No description provided for @custDebtLimitHelper.
  ///
  /// In ru, this message translates to:
  /// **'0 — продажа в долг запрещена'**
  String get custDebtLimitHelper;

  /// No description provided for @custManagerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только для менеджера'**
  String get custManagerOnly;

  /// No description provided for @custTags.
  ///
  /// In ru, this message translates to:
  /// **'Теги'**
  String get custTags;

  /// No description provided for @custTagsHelper.
  ///
  /// In ru, this message translates to:
  /// **'Через запятую, например: опт, постоянный'**
  String get custTagsHelper;

  /// No description provided for @custNote.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get custNote;

  /// No description provided for @custCardGenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать номер карты, попробуйте ещё раз'**
  String get custCardGenFailed;

  /// No description provided for @custNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Имя слишком длинное'**
  String get custNameTooLong;

  /// No description provided for @custDiscountRange.
  ///
  /// In ru, this message translates to:
  /// **'Скидка должна быть от 0 до 100%'**
  String get custDiscountRange;

  /// No description provided for @custDebtLimitNegative.
  ///
  /// In ru, this message translates to:
  /// **'Лимит долга не может быть отрицательным'**
  String get custDebtLimitNegative;

  /// No description provided for @custEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email'**
  String get custEmailInvalid;

  /// No description provided for @custCardTakenBy.
  ///
  /// In ru, this message translates to:
  /// **'Карта {card} уже привязана к другому клиенту'**
  String custCardTakenBy(String card);

  /// No description provided for @custNoAssignDiscountPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права назначать скидку клиенту'**
  String get custNoAssignDiscountPerm;

  /// No description provided for @custNoOpenCreditPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права открывать кредит клиенту'**
  String get custNoOpenCreditPerm;

  /// No description provided for @custNoChangeDiscountPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права изменять скидку клиента'**
  String get custNoChangeDiscountPerm;

  /// No description provided for @custNoChangeDebtLimitPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права изменять лимит долга'**
  String get custNoChangeDebtLimitPerm;

  /// No description provided for @custDeleteDebtRepo.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя удалить клиента с долгом. Сначала примите оплату долга.'**
  String get custDeleteDebtRepo;

  /// No description provided for @dash7Days.
  ///
  /// In ru, this message translates to:
  /// **'7 дн.'**
  String get dash7Days;

  /// No description provided for @dashAllReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Все чеки'**
  String get dashAllReceipts;

  /// No description provided for @dashAvgCheck.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get dashAvgCheck;

  /// No description provided for @dashBarTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Выручка: {revenue}\nЧеков: {receipts}'**
  String dashBarTooltip(String revenue, String receipts);

  /// No description provided for @dashDebtAllPaid.
  ///
  /// In ru, this message translates to:
  /// **'Все клиенты рассчитались'**
  String get dashDebtAllPaid;

  /// No description provided for @dashDebtLoading.
  ///
  /// In ru, this message translates to:
  /// **'Долги…'**
  String get dashDebtLoading;

  /// No description provided for @dashDebtNone.
  ///
  /// In ru, this message translates to:
  /// **'Долгов нет'**
  String get dashDebtNone;

  /// No description provided for @dashDebtTotal.
  ///
  /// In ru, this message translates to:
  /// **'Долг клиентов: {amount}'**
  String dashDebtTotal(String amount);

  /// No description provided for @dashDebtors.
  ///
  /// In ru, this message translates to:
  /// **'Должников: {count}'**
  String dashDebtors(String count);

  /// No description provided for @dashDuration.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String dashDuration(String hours, String minutes);

  /// No description provided for @dashGrossProfit.
  ///
  /// In ru, this message translates to:
  /// **'Валовая прибыль'**
  String get dashGrossProfit;

  /// No description provided for @dashMargin.
  ///
  /// In ru, this message translates to:
  /// **'маржа {pct}%'**
  String dashMargin(String pct);

  /// No description provided for @dashNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к разделу'**
  String get dashNoAccess;

  /// No description provided for @dashNoPaymentsToday.
  ///
  /// In ru, this message translates to:
  /// **'Оплат сегодня ещё не было'**
  String get dashNoPaymentsToday;

  /// No description provided for @dashNoReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков пока нет'**
  String get dashNoReceipts;

  /// No description provided for @dashNoSales.
  ///
  /// In ru, this message translates to:
  /// **'Продаж пока нет'**
  String get dashNoSales;

  /// No description provided for @dashOnbProductsButton.
  ///
  /// In ru, this message translates to:
  /// **'К товарам'**
  String get dashOnbProductsButton;

  /// No description provided for @dashOnbProductsDone.
  ///
  /// In ru, this message translates to:
  /// **'В каталоге {count} тов. Можно добавить ещё или загрузить остатки.'**
  String dashOnbProductsDone(String count);

  /// No description provided for @dashOnbProductsText.
  ///
  /// In ru, this message translates to:
  /// **'Заведите товары с ценами и остатками — вручную или сканером штрихкодов.'**
  String get dashOnbProductsText;

  /// No description provided for @dashOnbProductsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары'**
  String get dashOnbProductsTitle;

  /// No description provided for @dashOnbSaleButton.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в кассу'**
  String get dashOnbSaleButton;

  /// No description provided for @dashOnbSaleText.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте товар или выберите его в кассе и примите оплату.'**
  String get dashOnbSaleText;

  /// No description provided for @dashOnbSaleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сделайте первую продажу'**
  String get dashOnbSaleTitle;

  /// No description provided for @dashOnbShiftButton.
  ///
  /// In ru, this message translates to:
  /// **'Открыть смену'**
  String get dashOnbShiftButton;

  /// No description provided for @dashOnbShiftDone.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} открыта — можно продавать.'**
  String dashOnbShiftDone(String number);

  /// No description provided for @dashOnbShiftText.
  ///
  /// In ru, this message translates to:
  /// **'Укажите сумму размена в кассе, чтобы вечером сверить наличные.'**
  String get dashOnbShiftText;

  /// No description provided for @dashOnbShiftTitle.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену'**
  String get dashOnbShiftTitle;

  /// No description provided for @dashPaymentsToday.
  ///
  /// In ru, this message translates to:
  /// **'Оплаты сегодня'**
  String get dashPaymentsToday;

  /// No description provided for @dashPcs.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт.'**
  String dashPcs(String count);

  /// No description provided for @dashPos.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get dashPos;

  /// No description provided for @dashReceiptNumber.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number}'**
  String dashReceiptNumber(String number);

  /// No description provided for @dashReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get dashReceipts;

  /// No description provided for @dashRecentReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Последние чеки'**
  String get dashRecentReceipts;

  /// No description provided for @dashReports.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get dashReports;

  /// No description provided for @dashReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get dashReturns;

  /// No description provided for @dashRevenue14.
  ///
  /// In ru, this message translates to:
  /// **'Выручка за 14 дней'**
  String get dashRevenue14;

  /// No description provided for @dashRevenueSummary.
  ///
  /// In ru, this message translates to:
  /// **'Итого {total} · в среднем {avg} в торговый день'**
  String dashRevenueSummary(String total, String avg);

  /// No description provided for @dashRevenueToday.
  ///
  /// In ru, this message translates to:
  /// **'Выручка сегодня'**
  String get dashRevenueToday;

  /// No description provided for @dashRevenueTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Продажи минус возвраты (аннулированные чеки не учитываются)'**
  String get dashRevenueTooltip;

  /// No description provided for @dashShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get dashShiftClosed;

  /// No description provided for @dashShiftClosedText.
  ///
  /// In ru, this message translates to:
  /// **'Продажи невозможны, пока смена не открыта'**
  String get dashShiftClosedText;

  /// No description provided for @dashShiftLong.
  ///
  /// In ru, this message translates to:
  /// **'Долго открыта'**
  String get dashShiftLong;

  /// No description provided for @dashShiftLongText.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта больше 16 часов — закройте её и сверьте кассу.'**
  String get dashShiftLongText;

  /// No description provided for @dashShiftOpen.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} открыта'**
  String dashShiftOpen(String number);

  /// No description provided for @dashShiftRunning.
  ///
  /// In ru, this message translates to:
  /// **'Идёт'**
  String get dashShiftRunning;

  /// No description provided for @dashShiftSince.
  ///
  /// In ru, this message translates to:
  /// **'С {time}'**
  String dashShiftSince(String time);

  /// No description provided for @dashShiftTotals.
  ///
  /// In ru, this message translates to:
  /// **'Чеков: {receipts} · выручка {revenue}'**
  String dashShiftTotals(String receipts, String revenue);

  /// No description provided for @dashStatusPartReturned.
  ///
  /// In ru, this message translates to:
  /// **'частичный возврат'**
  String get dashStatusPartReturned;

  /// No description provided for @dashStatusReturned.
  ///
  /// In ru, this message translates to:
  /// **'возврат'**
  String get dashStatusReturned;

  /// No description provided for @dashStatusVoided.
  ///
  /// In ru, this message translates to:
  /// **'аннулирован'**
  String get dashStatusVoided;

  /// No description provided for @dashStepsDone.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено {done} из {total}'**
  String dashStepsDone(String done, String total);

  /// No description provided for @dashStockLoading.
  ///
  /// In ru, this message translates to:
  /// **'Остатки…'**
  String get dashStockLoading;

  /// No description provided for @dashStockLow.
  ///
  /// In ru, this message translates to:
  /// **'Заканчиваются: {low} · нет в наличии: {out}'**
  String dashStockLow(String low, String out);

  /// No description provided for @dashStockOk.
  ///
  /// In ru, this message translates to:
  /// **'Остатков достаточно'**
  String get dashStockOk;

  /// No description provided for @dashStockSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Товары с остатком ниже минимального'**
  String get dashStockSubtitle;

  /// No description provided for @dashTitle.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get dashTitle;

  /// No description provided for @dashTodayDate.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня, {date}'**
  String dashTodayDate(String date);

  /// No description provided for @dashTop5.
  ///
  /// In ru, this message translates to:
  /// **'Топ-5 товаров'**
  String get dashTop5;

  /// No description provided for @dashVoidedSuffix.
  ///
  /// In ru, this message translates to:
  /// **' · аннулировано чеков: {count}'**
  String dashVoidedSuffix(String count);

  /// No description provided for @dashWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в DreamPOS!'**
  String get dashWelcome;

  /// No description provided for @dashWelcomeText.
  ///
  /// In ru, this message translates to:
  /// **'Три шага — и здесь появятся выручка, прибыль, лучшие товары и подсказки.'**
  String get dashWelcomeText;

  /// No description provided for @dashYesterdaySoFar.
  ///
  /// In ru, this message translates to:
  /// **'вчера к этому часу: {value}'**
  String dashYesterdaySoFar(String value);

  /// No description provided for @invReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get invReceipt;

  /// No description provided for @invMoveReceiptReversal.
  ///
  /// In ru, this message translates to:
  /// **'Сторно прихода'**
  String get invMoveReceiptReversal;

  /// No description provided for @invWriteoff.
  ///
  /// In ru, this message translates to:
  /// **'Списание'**
  String get invWriteoff;

  /// No description provided for @invAdjustment.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка'**
  String get invAdjustment;

  /// No description provided for @invCount.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация'**
  String get invCount;

  /// No description provided for @invMoveTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Перемещение'**
  String get invMoveTransfer;

  /// No description provided for @invMovements.
  ///
  /// In ru, this message translates to:
  /// **'Движения'**
  String get invMovements;

  /// No description provided for @invStockTab.
  ///
  /// In ru, this message translates to:
  /// **'Остатки'**
  String get invStockTab;

  /// No description provided for @invReasonDefect.
  ///
  /// In ru, this message translates to:
  /// **'Брак'**
  String get invReasonDefect;

  /// No description provided for @invReasonExpired.
  ///
  /// In ru, this message translates to:
  /// **'Просрочка'**
  String get invReasonExpired;

  /// No description provided for @invReasonSpoiled.
  ///
  /// In ru, this message translates to:
  /// **'Порча'**
  String get invReasonSpoiled;

  /// No description provided for @invReasonShortage.
  ///
  /// In ru, this message translates to:
  /// **'Недостача'**
  String get invReasonShortage;

  /// No description provided for @invReasonPersonalUse.
  ///
  /// In ru, this message translates to:
  /// **'Личное потребление'**
  String get invReasonPersonalUse;

  /// No description provided for @invReasonOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get invReasonOther;

  /// No description provided for @invReceiptPosted.
  ///
  /// In ru, this message translates to:
  /// **'Проведён'**
  String get invReceiptPosted;

  /// No description provided for @invReceiptReversed.
  ///
  /// In ru, this message translates to:
  /// **'Сторнирован'**
  String get invReceiptReversed;

  /// No description provided for @invCountDraft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get invCountDraft;

  /// No description provided for @invCountCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Проведена'**
  String get invCountCompleted;

  /// No description provided for @invCountCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменена'**
  String get invCountCancelled;

  /// No description provided for @invDeletedProduct.
  ///
  /// In ru, this message translates to:
  /// **'Удалённый товар'**
  String get invDeletedProduct;

  /// No description provided for @invReceiptRef.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number}'**
  String invReceiptRef(String number);

  /// No description provided for @invFilterLow.
  ///
  /// In ru, this message translates to:
  /// **'Мало'**
  String get invFilterLow;

  /// No description provided for @invFilterOut.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get invFilterOut;

  /// No description provided for @invFilterNegative.
  ///
  /// In ru, this message translates to:
  /// **'Минус'**
  String get invFilterNegative;

  /// No description provided for @invQtyRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите количество'**
  String get invQtyRequired;

  /// No description provided for @invQtyNegative.
  ///
  /// In ru, this message translates to:
  /// **'Количество не может быть отрицательным'**
  String get invQtyNegative;

  /// No description provided for @invQtyPositive.
  ///
  /// In ru, this message translates to:
  /// **'Количество должно быть больше нуля'**
  String get invQtyPositive;

  /// No description provided for @invQtyIntegerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Для «{unit}» допускается только целое число'**
  String invQtyIntegerOnly(String unit);

  /// No description provided for @invQtyTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большое количество'**
  String get invQtyTooLarge;

  /// No description provided for @invAddAtLeastOneLine.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одну позицию'**
  String get invAddAtLeastOneLine;

  /// No description provided for @invCostNegative.
  ///
  /// In ru, this message translates to:
  /// **'{name}: цена закупки отрицательная'**
  String invCostNegative(String name);

  /// No description provided for @invRetailMustBePositive.
  ///
  /// In ru, this message translates to:
  /// **'{name}: розничная цена должна быть больше нуля'**
  String invRetailMustBePositive(String name);

  /// No description provided for @invSelectCategory.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get invSelectCategory;

  /// No description provided for @invSelectProducts.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товары'**
  String get invSelectProducts;

  /// No description provided for @invNoProductsToCount.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров для инвентаризации'**
  String get invNoProductsToCount;

  /// No description provided for @invCountClosed.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация уже закрыта'**
  String get invCountClosed;

  /// No description provided for @invNoCountedQty.
  ///
  /// In ru, this message translates to:
  /// **'Не введено ни одного фактического количества'**
  String get invNoCountedQty;

  /// No description provided for @invNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа'**
  String get invNoAccess;

  /// No description provided for @invNoAccessMessage.
  ///
  /// In ru, this message translates to:
  /// **'Складские операции доступны кладовщику, менеджеру и владельцу'**
  String get invNoAccessMessage;

  /// No description provided for @invNoProductsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товаров пока нет'**
  String get invNoProductsTitle;

  /// No description provided for @invNoProductsMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары в разделе «Товары», затем оформите приход.'**
  String get invNoProductsMessage;

  /// No description provided for @invChangeFiltersOrQuery.
  ///
  /// In ru, this message translates to:
  /// **'Измените фильтры или запрос'**
  String get invChangeFiltersOrQuery;

  /// No description provided for @invStockValue.
  ///
  /// In ru, this message translates to:
  /// **'Сумма запаса'**
  String get invStockValue;

  /// No description provided for @invPositionsTracked.
  ///
  /// In ru, this message translates to:
  /// **'Позиций на учёте'**
  String get invPositionsTracked;

  /// No description provided for @invStockAtCost.
  ///
  /// In ru, this message translates to:
  /// **'Запас по себестоимости'**
  String get invStockAtCost;

  /// No description provided for @invStockAtRetail.
  ///
  /// In ru, this message translates to:
  /// **'Запас в розничных ценах'**
  String get invStockAtRetail;

  /// No description provided for @invPotentialMargin.
  ///
  /// In ru, this message translates to:
  /// **'Потенц. наценка {amount}'**
  String invPotentialMargin(String amount);

  /// No description provided for @invLowOutNegative.
  ///
  /// In ru, this message translates to:
  /// **'Мало / нет / минус'**
  String get invLowOutNegative;

  /// No description provided for @invAllCategories.
  ///
  /// In ru, this message translates to:
  /// **'Все категории'**
  String get invAllCategories;

  /// No description provided for @invSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, артикул, штрихкод'**
  String get invSearchHint;

  /// No description provided for @invStatusOut.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get invStatusOut;

  /// No description provided for @invSkuShort.
  ///
  /// In ru, this message translates to:
  /// **'арт. {sku}'**
  String invSkuShort(String sku);

  /// No description provided for @invMinShort.
  ///
  /// In ru, this message translates to:
  /// **'мин. {qty}'**
  String invMinShort(String qty);

  /// No description provided for @invInactive.
  ///
  /// In ru, this message translates to:
  /// **'не активен'**
  String get invInactive;

  /// No description provided for @invQuickReceiptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приход: {name}'**
  String invQuickReceiptTitle(String name);

  /// No description provided for @invCurrentStock.
  ///
  /// In ru, this message translates to:
  /// **'Текущий остаток: {qty}'**
  String invCurrentStock(String qty);

  /// No description provided for @invUnitCostRequired.
  ///
  /// In ru, this message translates to:
  /// **'Цена закупки за ед. *'**
  String get invUnitCostRequired;

  /// No description provided for @invPostIn.
  ///
  /// In ru, this message translates to:
  /// **'Оприходовать'**
  String get invPostIn;

  /// No description provided for @invSelectProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товар'**
  String get invSelectProduct;

  /// No description provided for @invSpecifyWriteoffReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину списания'**
  String get invSpecifyWriteoffReason;

  /// No description provided for @invDescribeReason.
  ///
  /// In ru, this message translates to:
  /// **'Опишите причину в комментарии'**
  String get invDescribeReason;

  /// No description provided for @invWriteoffConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Списать товар?'**
  String get invWriteoffConfirmTitle;

  /// No description provided for @invWriteoffConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'{name}\n{qty} на сумму {amount} (по себестоимости)\nПричина: {reason}'**
  String invWriteoffConfirmMessage(
    String name,
    String qty,
    String amount,
    String reason,
  );

  /// No description provided for @invWriteoffAction.
  ///
  /// In ru, this message translates to:
  /// **'Списать'**
  String get invWriteoffAction;

  /// No description provided for @invWrittenOff.
  ///
  /// In ru, this message translates to:
  /// **'Списано {qty} «{name}»'**
  String invWrittenOff(String qty, String name);

  /// No description provided for @invChooseProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать товар…'**
  String get invChooseProduct;

  /// No description provided for @invStockLine.
  ///
  /// In ru, this message translates to:
  /// **'Остаток: {qty}'**
  String invStockLine(String qty);

  /// No description provided for @invStockLineWithCost.
  ///
  /// In ru, this message translates to:
  /// **'Остаток: {qty} · себестоимость {cost}'**
  String invStockLineWithCost(String qty, String cost);

  /// No description provided for @invCommentRequired.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий *'**
  String get invCommentRequired;

  /// No description provided for @invWriteoffSum.
  ///
  /// In ru, this message translates to:
  /// **'Сумма списания: {amount}'**
  String invWriteoffSum(String amount);

  /// No description provided for @invStockUnchanged.
  ///
  /// In ru, this message translates to:
  /// **'Остаток не изменился'**
  String get invStockUnchanged;

  /// No description provided for @invStockCorrected.
  ///
  /// In ru, this message translates to:
  /// **'Остаток исправлен'**
  String get invStockCorrected;

  /// No description provided for @invAdjustTitle.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка остатка'**
  String get invAdjustTitle;

  /// No description provided for @invBookStock.
  ///
  /// In ru, this message translates to:
  /// **'Учётный остаток: {qty}'**
  String invBookStock(String qty);

  /// No description provided for @invActualStock.
  ///
  /// In ru, this message translates to:
  /// **'Фактический остаток'**
  String get invActualStock;

  /// No description provided for @invReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Причина *'**
  String get invReasonRequired;

  /// No description provided for @invSpecifyAdjustReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину корректировки'**
  String get invSpecifyAdjustReason;

  /// No description provided for @invUseCountHint.
  ///
  /// In ru, this message translates to:
  /// **'Для полной проверки остатков используйте инвентаризацию.'**
  String get invUseCountHint;

  /// No description provided for @invHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Движения: {name}'**
  String invHistoryTitle(String name);

  /// No description provided for @invNoMovementsYet.
  ///
  /// In ru, this message translates to:
  /// **'Движений пока нет'**
  String get invNoMovementsYet;

  /// No description provided for @invPriceDetail.
  ///
  /// In ru, this message translates to:
  /// **'цена {amount}'**
  String invPriceDetail(String amount);

  /// No description provided for @invStockAfter.
  ///
  /// In ru, this message translates to:
  /// **'остаток {qty}'**
  String invStockAfter(String qty);

  /// No description provided for @invNewWriteoff.
  ///
  /// In ru, this message translates to:
  /// **'Новое списание'**
  String get invNewWriteoff;

  /// No description provided for @invWhatToWriteOff.
  ///
  /// In ru, this message translates to:
  /// **'Что списываем?'**
  String get invWhatToWriteOff;

  /// No description provided for @invWriteoffs30.
  ///
  /// In ru, this message translates to:
  /// **'Списания за 30 дней'**
  String get invWriteoffs30;

  /// No description provided for @invNoWriteoffs30.
  ///
  /// In ru, this message translates to:
  /// **'Списаний за последние 30 дней не было'**
  String get invNoWriteoffs30;

  /// No description provided for @invTotalAtCost.
  ///
  /// In ru, this message translates to:
  /// **'Всего по себестоимости: {amount}'**
  String invTotalAtCost(String amount);

  /// No description provided for @invDays7.
  ///
  /// In ru, this message translates to:
  /// **'7 дней'**
  String get invDays7;

  /// No description provided for @invDays30.
  ///
  /// In ru, this message translates to:
  /// **'30 дней'**
  String get invDays30;

  /// No description provided for @invAllTime.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get invAllTime;

  /// No description provided for @invPeriodCustom.
  ///
  /// In ru, this message translates to:
  /// **'Период…'**
  String get invPeriodCustom;

  /// No description provided for @invMovementsPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Период движений'**
  String get invMovementsPeriod;

  /// No description provided for @invType.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get invType;

  /// No description provided for @invAllTypes.
  ///
  /// In ru, this message translates to:
  /// **'Все типы'**
  String get invAllTypes;

  /// No description provided for @invAllProducts.
  ///
  /// In ru, this message translates to:
  /// **'Все товары'**
  String get invAllProducts;

  /// No description provided for @invFilterByProduct.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр по товару'**
  String get invFilterByProduct;

  /// No description provided for @invNoMovements.
  ///
  /// In ru, this message translates to:
  /// **'Движений нет'**
  String get invNoMovements;

  /// No description provided for @invChangeFiltersOrPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Измените фильтры или период'**
  String get invChangeFiltersOrPeriod;

  /// No description provided for @invRecords.
  ///
  /// In ru, this message translates to:
  /// **'Записей: {count}'**
  String invRecords(String count);

  /// No description provided for @invRecordsLimited.
  ///
  /// In ru, this message translates to:
  /// **'Записей: {count} (показаны последние {limit} — уточните фильтр)'**
  String invRecordsLimited(String count, String limit);

  /// No description provided for @invInOut.
  ///
  /// In ru, this message translates to:
  /// **'приход +{inQty} · расход {outQty}'**
  String invInOut(String inQty, String outQty);

  /// No description provided for @invCurrentStockOf.
  ///
  /// In ru, this message translates to:
  /// **'Текущий остаток «{name}»: {qty}'**
  String invCurrentStockOf(String name, String qty);

  /// No description provided for @invDocsPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Период документов'**
  String get invDocsPeriod;

  /// No description provided for @invSearchShort.
  ///
  /// In ru, this message translates to:
  /// **'№ или накладная'**
  String get invSearchShort;

  /// No description provided for @invSearchLong.
  ///
  /// In ru, this message translates to:
  /// **'Поиск: № прихода или накладной'**
  String get invSearchLong;

  /// No description provided for @invAllSuppliers.
  ///
  /// In ru, this message translates to:
  /// **'Все поставщики'**
  String get invAllSuppliers;

  /// No description provided for @invNoDocs.
  ///
  /// In ru, this message translates to:
  /// **'Документов нет'**
  String get invNoDocs;

  /// No description provided for @invPostedAppearHere.
  ///
  /// In ru, this message translates to:
  /// **'Проведённые приходы появятся здесь'**
  String get invPostedAppearHere;

  /// No description provided for @invDocsCount.
  ///
  /// In ru, this message translates to:
  /// **'Документов: {count}'**
  String invDocsCount(String count);

  /// No description provided for @invDocsCountLimited.
  ///
  /// In ru, this message translates to:
  /// **'Документов: {count} (показаны последние {limit} — уточните фильтр)'**
  String invDocsCountLimited(String count, String limit);

  /// No description provided for @invPostedFor.
  ///
  /// In ru, this message translates to:
  /// **'проведено на {amount}'**
  String invPostedFor(String amount);

  /// No description provided for @invNoSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Без поставщика'**
  String get invNoSupplier;

  /// No description provided for @invDeletedSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Удалённый поставщик'**
  String get invDeletedSupplier;

  /// No description provided for @invOrderRef.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number}'**
  String invOrderRef(String number);

  /// No description provided for @invOrder.
  ///
  /// In ru, this message translates to:
  /// **'Заказ'**
  String get invOrder;

  /// No description provided for @invNoHeader.
  ///
  /// In ru, this message translates to:
  /// **'№'**
  String get invNoHeader;

  /// No description provided for @invNumber.
  ///
  /// In ru, this message translates to:
  /// **'№{number}'**
  String invNumber(String number);

  /// No description provided for @invInvoice.
  ///
  /// In ru, this message translates to:
  /// **'Накладная'**
  String get invInvoice;

  /// No description provided for @invPositionsHeader.
  ///
  /// In ru, this message translates to:
  /// **'Позиций'**
  String get invPositionsHeader;

  /// No description provided for @invSource.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get invSource;

  /// No description provided for @invInvoiceShort.
  ///
  /// In ru, this message translates to:
  /// **'накл. {invoice}'**
  String invInvoiceShort(String invoice);

  /// No description provided for @invReceiptDocTitle.
  ///
  /// In ru, this message translates to:
  /// **'Документ прихода'**
  String get invReceiptDocTitle;

  /// No description provided for @invReceiptPostedToast.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} проведён'**
  String invReceiptPostedToast(String number);

  /// No description provided for @invReceiptPostedToastDetails.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} проведён · {details}'**
  String invReceiptPostedToastDetails(String number, String details);

  /// No description provided for @invReverseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сторнировать приход №{number}?'**
  String invReverseTitle(String number);

  /// No description provided for @invReverseInfo.
  ///
  /// In ru, this message translates to:
  /// **'Остатки товаров уменьшатся на количество из документа, себестоимость будет пересчитана. Розничные цены, изменённые этим приходом, вернутся к прежним, если их не меняли позже.'**
  String get invReverseInfo;

  /// No description provided for @invReverseSupplierDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долг перед поставщиком {supplier} уменьшится на {amount}.'**
  String invReverseSupplierDebt(String supplier, String amount);

  /// No description provided for @invReverseIrreversible.
  ///
  /// In ru, this message translates to:
  /// **'Отменить сторно нельзя.'**
  String get invReverseIrreversible;

  /// No description provided for @invReverseReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина сторно *'**
  String get invReverseReasonLabel;

  /// No description provided for @invReverseReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину сторно'**
  String get invReverseReasonRequired;

  /// No description provided for @invReverse.
  ///
  /// In ru, this message translates to:
  /// **'Сторнировать'**
  String get invReverse;

  /// No description provided for @invDocNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Документ не найден'**
  String get invDocNotFound;

  /// No description provided for @invDocNotFoundMessage.
  ///
  /// In ru, this message translates to:
  /// **'Возможно, он был удалён или ещё не синхронизирован'**
  String get invDocNotFoundMessage;

  /// No description provided for @invSupplierInvoice.
  ///
  /// In ru, this message translates to:
  /// **'Накладная поставщика'**
  String get invSupplierInvoice;

  /// No description provided for @invManualReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Ручной приход'**
  String get invManualReceipt;

  /// No description provided for @invAcceptedBy.
  ///
  /// In ru, this message translates to:
  /// **'Принял'**
  String get invAcceptedBy;

  /// No description provided for @invReasonLine.
  ///
  /// In ru, this message translates to:
  /// **'Причина: {reason}'**
  String invReasonLine(String reason);

  /// No description provided for @invTotalsLine.
  ///
  /// In ru, this message translates to:
  /// **'Позиций: {count} · количество {qty}'**
  String invTotalsLine(String count, String qty);

  /// No description provided for @invTotalLine.
  ///
  /// In ru, this message translates to:
  /// **'Итого: {amount}'**
  String invTotalLine(String amount);

  /// No description provided for @invPositionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Позиции'**
  String get invPositionsTitle;

  /// No description provided for @invNoLinesInDoc.
  ///
  /// In ru, this message translates to:
  /// **'В документе нет позиций'**
  String get invNoLinesInDoc;

  /// No description provided for @invReversedToast.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} сторнирован'**
  String invReversedToast(String number);

  /// No description provided for @invQtyShort.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get invQtyShort;

  /// No description provided for @invPurchasePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена закупки'**
  String get invPurchasePrice;

  /// No description provided for @invNewRetailPrice.
  ///
  /// In ru, this message translates to:
  /// **'Новая розн. цена'**
  String get invNewRetailPrice;

  /// No description provided for @invWasPrice.
  ///
  /// In ru, this message translates to:
  /// **'было {amount}'**
  String invWasPrice(String amount);

  /// No description provided for @invPriceWas.
  ///
  /// In ru, this message translates to:
  /// **'{price} (было {old})'**
  String invPriceWas(String price, String old);

  /// No description provided for @invRetailPriceLine.
  ///
  /// In ru, this message translates to:
  /// **'Розничная цена: {price}'**
  String invRetailPriceLine(String price);

  /// No description provided for @invNewReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Новый приход'**
  String get invNewReceipt;

  /// No description provided for @invDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get invDocuments;

  /// No description provided for @invScanNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Товар со штрихкодом/артикулом «{code}» не найден'**
  String invScanNotFound(String code);

  /// No description provided for @invAddToReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в приход'**
  String get invAddToReceipt;

  /// No description provided for @invClearDocTitle.
  ///
  /// In ru, this message translates to:
  /// **'Очистить документ?'**
  String get invClearDocTitle;

  /// No description provided for @invClearDocMessage.
  ///
  /// In ru, this message translates to:
  /// **'Все позиции будут удалены из документа.'**
  String get invClearDocMessage;

  /// No description provided for @invCheckFields.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте выделенные поля'**
  String get invCheckFields;

  /// No description provided for @invPostReceiptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Провести приход?'**
  String get invPostReceiptTitle;

  /// No description provided for @invPostReceiptMessage.
  ///
  /// In ru, this message translates to:
  /// **'Позиций: {count}\nСумма: {amount}'**
  String invPostReceiptMessage(String count, String amount);

  /// No description provided for @invPostReceiptDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долг перед «{supplier}» увеличится на {amount}'**
  String invPostReceiptDebt(String supplier, String amount);

  /// No description provided for @invPost.
  ///
  /// In ru, this message translates to:
  /// **'Провести'**
  String get invPost;

  /// No description provided for @invLinesFor.
  ///
  /// In ru, this message translates to:
  /// **'{count} поз. на {amount}'**
  String invLinesFor(String count, String amount);

  /// No description provided for @invPositionsLower.
  ///
  /// In ru, this message translates to:
  /// **'позиций {count}'**
  String invPositionsLower(String count);

  /// No description provided for @invPostReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Провести приход'**
  String get invPostReceipt;

  /// No description provided for @invSupplierHelper.
  ///
  /// In ru, this message translates to:
  /// **'Если указан, сумма прихода добавится к долгу поставщику'**
  String get invSupplierHelper;

  /// No description provided for @invInvoiceNoShort.
  ///
  /// In ru, this message translates to:
  /// **'№ накладной'**
  String get invInvoiceNoShort;

  /// No description provided for @invInvoiceNoLong.
  ///
  /// In ru, this message translates to:
  /// **'№ накладной поставщика'**
  String get invInvoiceNoLong;

  /// No description provided for @invScanShort.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод или артикул'**
  String get invScanShort;

  /// No description provided for @invScanLong.
  ///
  /// In ru, this message translates to:
  /// **'Сканируйте штрихкод или введите артикул'**
  String get invScanLong;

  /// No description provided for @invAddProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар'**
  String get invAddProduct;

  /// No description provided for @invEmptyDoc.
  ///
  /// In ru, this message translates to:
  /// **'Документ пуст'**
  String get invEmptyDoc;

  /// No description provided for @invEmptyDocMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте товар или нажмите «Добавить товар». Для приёмки по заказу поставщику используйте раздел «Закупки».'**
  String get invEmptyDocMessage;

  /// No description provided for @invSpecifyPurchasePrice.
  ///
  /// In ru, this message translates to:
  /// **'Укажите цену закупки'**
  String get invSpecifyPurchasePrice;

  /// No description provided for @invNewPrice.
  ///
  /// In ru, this message translates to:
  /// **'Новая цена'**
  String get invNewPrice;

  /// No description provided for @invNoPricePermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет права менять цены'**
  String get invNoPricePermission;

  /// No description provided for @invInvalidPrice.
  ///
  /// In ru, this message translates to:
  /// **'Неверная цена'**
  String get invInvalidPrice;

  /// No description provided for @invDeleteLine.
  ///
  /// In ru, this message translates to:
  /// **'Удалить строку'**
  String get invDeleteLine;

  /// No description provided for @invLineInfo.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {qty} · розн. {price}'**
  String invLineInfo(String qty, String price);

  /// No description provided for @invMarkupPart.
  ///
  /// In ru, this message translates to:
  /// **'наценка {percent}%'**
  String invMarkupPart(String percent);

  /// No description provided for @invNewCount.
  ///
  /// In ru, this message translates to:
  /// **'Новая инвентаризация'**
  String get invNewCount;

  /// No description provided for @invSelectCount.
  ///
  /// In ru, this message translates to:
  /// **'Выберите инвентаризацию'**
  String get invSelectCount;

  /// No description provided for @invSelectCountMessage.
  ///
  /// In ru, this message translates to:
  /// **'или создайте новую, чтобы сверить фактические остатки с учётными'**
  String get invSelectCountMessage;

  /// No description provided for @invNoCountsYet.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризаций ещё не было'**
  String get invNoCountsYet;

  /// No description provided for @invNoCountsMessage.
  ///
  /// In ru, this message translates to:
  /// **'Регулярные пересчёты помогают вовремя находить недостачи'**
  String get invNoCountsMessage;

  /// No description provided for @invCountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация №{number}'**
  String invCountTitle(String number);

  /// No description provided for @invAddToCount.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар в инвентаризацию'**
  String get invAddToCount;

  /// No description provided for @invAddAtLeastOneProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы один товар'**
  String get invAddAtLeastOneProduct;

  /// No description provided for @invSelected.
  ///
  /// In ru, this message translates to:
  /// **'Выбранные'**
  String get invSelected;

  /// No description provided for @invCategoryRequired.
  ///
  /// In ru, this message translates to:
  /// **'Категория *'**
  String get invCategoryRequired;

  /// No description provided for @invRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get invRemove;

  /// No description provided for @invCountNoteHint.
  ///
  /// In ru, this message translates to:
  /// **'зона, ответственный'**
  String get invCountNoteHint;

  /// No description provided for @invCountCreateInfo.
  ///
  /// In ru, this message translates to:
  /// **'Учётные остатки фиксируются в момент создания. Продажи во время пересчёта учитываются при проведении: расхождение считается от текущего остатка.'**
  String get invCountCreateInfo;

  /// No description provided for @invProductNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{code}» не найден'**
  String invProductNotFound(String code);

  /// No description provided for @invNotInSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товара нет в ведомости'**
  String get invNotInSheetTitle;

  /// No description provided for @invNotInSheetMessage.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» не входит в эту инвентаризацию. Добавить и засчитать 1 {unit}?'**
  String invNotInSheetMessage(String name, String unit);

  /// No description provided for @invAddedOne.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» добавлен: 1'**
  String invAddedOne(String name);

  /// No description provided for @invCompleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Провести инвентаризацию №{number}?'**
  String invCompleteTitle(String number);

  /// No description provided for @invCompleteCounted.
  ///
  /// In ru, this message translates to:
  /// **'Посчитано позиций: {counted} из {total}.'**
  String invCompleteCounted(String counted, String total);

  /// No description provided for @invCompleteUncounted.
  ///
  /// In ru, this message translates to:
  /// **'Не посчитано: {count} — их остатки не изменятся.'**
  String invCompleteUncounted(String count);

  /// No description provided for @invCompleteSurplus.
  ///
  /// In ru, this message translates to:
  /// **'Излишки: {count} поз.'**
  String invCompleteSurplus(String count);

  /// No description provided for @invCompleteSurplusSum.
  ///
  /// In ru, this message translates to:
  /// **'Излишки: {count} поз. на {amount}'**
  String invCompleteSurplusSum(String count, String amount);

  /// No description provided for @invCompleteShortage.
  ///
  /// In ru, this message translates to:
  /// **'Недостача: {count} поз.'**
  String invCompleteShortage(String count);

  /// No description provided for @invCompleteShortageSum.
  ///
  /// In ru, this message translates to:
  /// **'Недостача: {count} поз. на {amount}'**
  String invCompleteShortageSum(String count, String amount);

  /// No description provided for @invCompleteNet.
  ///
  /// In ru, this message translates to:
  /// **'Итог: {amount}'**
  String invCompleteNet(String amount);

  /// No description provided for @invCompleteChanged.
  ///
  /// In ru, this message translates to:
  /// **'По {count} поз. остаток изменился после создания ведомости (продажи, приходы). Расхождения рассчитаны от ТЕКУЩЕГО остатка.'**
  String invCompleteChanged(String count);

  /// No description provided for @invCompleteFinal.
  ///
  /// In ru, this message translates to:
  /// **'Остатки будут приведены к фактическим. Действие необратимо.'**
  String get invCompleteFinal;

  /// No description provided for @invCountCompletedToast.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация №{number} проведена'**
  String invCountCompletedToast(String number);

  /// No description provided for @invCancelCountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить инвентаризацию №{number}?'**
  String invCancelCountTitle(String number);

  /// No description provided for @invCancelCountMessage.
  ///
  /// In ru, this message translates to:
  /// **'Введённые данные сохранятся в истории, остатки не изменятся.'**
  String get invCancelCountMessage;

  /// No description provided for @invCancelCount.
  ///
  /// In ru, this message translates to:
  /// **'Отменить инвентаризацию'**
  String get invCancelCount;

  /// No description provided for @invCountCancelledToast.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация отменена'**
  String get invCountCancelledToast;

  /// No description provided for @invCountNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация не найдена'**
  String get invCountNotFound;

  /// No description provided for @invChangedWarning.
  ///
  /// In ru, this message translates to:
  /// **'По {count} поз. учётный остаток изменился после создания ведомости (продажи/приходы). Расхождение считается от текущего остатка.'**
  String invChangedWarning(String count);

  /// No description provided for @invScanPlusOne.
  ///
  /// In ru, this message translates to:
  /// **'Скан: +1 к факту'**
  String get invScanPlusOne;

  /// No description provided for @invSearchInSheet.
  ///
  /// In ru, this message translates to:
  /// **'Поиск в ведомости'**
  String get invSearchInSheet;

  /// No description provided for @invFilterAllCount.
  ///
  /// In ru, this message translates to:
  /// **'Все ({count})'**
  String invFilterAllCount(String count);

  /// No description provided for @invFilterUncounted.
  ///
  /// In ru, this message translates to:
  /// **'Не посчитано ({count})'**
  String invFilterUncounted(String count);

  /// No description provided for @invDiscrepancies.
  ///
  /// In ru, this message translates to:
  /// **'Расхождения'**
  String get invDiscrepancies;

  /// No description provided for @invNoLinesForFilter.
  ///
  /// In ru, this message translates to:
  /// **'Нет строк по фильтру'**
  String get invNoLinesForFilter;

  /// No description provided for @invCreatedAt.
  ///
  /// In ru, this message translates to:
  /// **'создана {date}'**
  String invCreatedAt(String date);

  /// No description provided for @invCompletedAt.
  ///
  /// In ru, this message translates to:
  /// **'проведена {date}'**
  String invCompletedAt(String date);

  /// No description provided for @invCountedChip.
  ///
  /// In ru, this message translates to:
  /// **'Посчитано {counted}/{total}'**
  String invCountedChip(String counted, String total);

  /// No description provided for @invSurplusChip.
  ///
  /// In ru, this message translates to:
  /// **'Излишки {count}'**
  String invSurplusChip(String count);

  /// No description provided for @invShortageChip.
  ///
  /// In ru, this message translates to:
  /// **'Недостача {count}'**
  String invShortageChip(String count);

  /// No description provided for @invSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get invSaving;

  /// No description provided for @invDraftSaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик сохранён'**
  String get invDraftSaved;

  /// No description provided for @invBlank.
  ///
  /// In ru, this message translates to:
  /// **'Бланк'**
  String get invBlank;

  /// No description provided for @invCancelShort.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get invCancelShort;

  /// No description provided for @invProductBookStock.
  ///
  /// In ru, this message translates to:
  /// **'Товар · учётный остаток'**
  String get invProductBookStock;

  /// No description provided for @invFact.
  ///
  /// In ru, this message translates to:
  /// **'Факт'**
  String get invFact;

  /// No description provided for @invDiff.
  ///
  /// In ru, this message translates to:
  /// **'Разница'**
  String get invDiff;

  /// No description provided for @invBookShort.
  ///
  /// In ru, this message translates to:
  /// **'учёт {qty}'**
  String invBookShort(String qty);

  /// No description provided for @invNowShort.
  ///
  /// In ru, this message translates to:
  /// **'сейчас {qty}'**
  String invNowShort(String qty);

  /// No description provided for @invFactHint.
  ///
  /// In ru, this message translates to:
  /// **'факт'**
  String get invFactHint;

  /// No description provided for @invNotCounted.
  ///
  /// In ru, this message translates to:
  /// **'не считали'**
  String get invNotCounted;

  /// No description provided for @invNumberQ.
  ///
  /// In ru, this message translates to:
  /// **'число?'**
  String get invNumberQ;

  /// No description provided for @invInvalidShort.
  ///
  /// In ru, this message translates to:
  /// **'неверно'**
  String get invInvalidShort;

  /// No description provided for @invSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризационная ведомость №{number}'**
  String invSheetTitle(String number);

  /// No description provided for @invPageOf.
  ///
  /// In ru, this message translates to:
  /// **'стр. {page}/{total}'**
  String invPageOf(String page, String total);

  /// No description provided for @invSheetSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'{store} · создана {date} · позиций {count}'**
  String invSheetSubtitle(String store, String date, String count);

  /// No description provided for @invCountedBy.
  ///
  /// In ru, this message translates to:
  /// **'Считал: ____________________'**
  String get invCountedBy;

  /// No description provided for @invCheckedBy.
  ///
  /// In ru, this message translates to:
  /// **'Проверил: ____________________'**
  String get invCheckedBy;

  /// No description provided for @invDateLine.
  ///
  /// In ru, this message translates to:
  /// **'Дата: {date}'**
  String invDateLine(String date);

  /// No description provided for @invBarcodeSku.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод / арт.'**
  String get invBarcodeSku;

  /// No description provided for @invUnitShort.
  ///
  /// In ru, this message translates to:
  /// **'Ед.'**
  String get invUnitShort;

  /// No description provided for @invBook.
  ///
  /// In ru, this message translates to:
  /// **'Учёт'**
  String get invBook;

  /// No description provided for @invCountFileName.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация {number}'**
  String invCountFileName(String number);

  /// No description provided for @invReceiptPdfTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приходная накладная №{number} от {date}'**
  String invReceiptPdfTitle(String number, String date);

  /// No description provided for @invHandedBy.
  ///
  /// In ru, this message translates to:
  /// **'Сдал: ____________________'**
  String get invHandedBy;

  /// No description provided for @invAcceptedByLine.
  ///
  /// In ru, this message translates to:
  /// **'Принял: ____________________'**
  String get invAcceptedByLine;

  /// No description provided for @invBasis.
  ///
  /// In ru, this message translates to:
  /// **'Основание'**
  String get invBasis;

  /// No description provided for @invSupplierOrderRef.
  ///
  /// In ru, this message translates to:
  /// **'Заказ поставщику №{number}'**
  String invSupplierOrderRef(String number);

  /// No description provided for @invReversedCaps.
  ///
  /// In ru, this message translates to:
  /// **'СТОРНИРОВАН'**
  String get invReversedCaps;

  /// No description provided for @invNewRetailShort.
  ///
  /// In ru, this message translates to:
  /// **'Новая розн.'**
  String get invNewRetailShort;

  /// No description provided for @invReceiptFileName.
  ///
  /// In ru, this message translates to:
  /// **'Приход {number}'**
  String invReceiptFileName(String number);

  /// No description provided for @mktTitle.
  ///
  /// In ru, this message translates to:
  /// **'Маркетинг'**
  String get mktTitle;

  /// No description provided for @mktTabPromos.
  ///
  /// In ru, this message translates to:
  /// **'Акции'**
  String get mktTabPromos;

  /// No description provided for @mktTabGiftCards.
  ///
  /// In ru, this message translates to:
  /// **'Сертификаты'**
  String get mktTabGiftCards;

  /// No description provided for @mktTabLoyalty.
  ///
  /// In ru, this message translates to:
  /// **'Лояльность'**
  String get mktTabLoyalty;

  /// No description provided for @mktTabMailing.
  ///
  /// In ru, this message translates to:
  /// **'Рассылки'**
  String get mktTabMailing;

  /// No description provided for @mktTypePercentOrder.
  ///
  /// In ru, this message translates to:
  /// **'Скидка % на чек'**
  String get mktTypePercentOrder;

  /// No description provided for @mktTypeAmountOrder.
  ///
  /// In ru, this message translates to:
  /// **'Скидка суммой на чек'**
  String get mktTypeAmountOrder;

  /// No description provided for @mktTypePercentCategory.
  ///
  /// In ru, this message translates to:
  /// **'Скидка % на категорию'**
  String get mktTypePercentCategory;

  /// No description provided for @mktTypePercentProduct.
  ///
  /// In ru, this message translates to:
  /// **'Скидка % на товар'**
  String get mktTypePercentProduct;

  /// No description provided for @mktTypeBuyXGetY.
  ///
  /// In ru, this message translates to:
  /// **'Купи X — получи Y'**
  String get mktTypeBuyXGetY;

  /// No description provided for @mktTypePromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get mktTypePromoCode;

  /// No description provided for @mktHelpPercentOrder.
  ///
  /// In ru, this message translates to:
  /// **'Процент от суммы чека после скидок по позициям. Можно задать минимальную сумму чека. Из скидок на чек применяется только одна — самая выгодная.'**
  String get mktHelpPercentOrder;

  /// No description provided for @mktHelpAmountOrder.
  ///
  /// In ru, this message translates to:
  /// **'Фиксированная сумма скидки на чек (например, 10 000 при покупке от 100 000). Распределяется по позициям пропорционально — возвраты считаются точно.'**
  String get mktHelpAmountOrder;

  /// No description provided for @mktHelpPercentCategory.
  ///
  /// In ru, this message translates to:
  /// **'Процент на все товары выбранной категории. Не суммируется с другими скидками на позицию и персональной скидкой клиента — берётся лучшая.'**
  String get mktHelpPercentCategory;

  /// No description provided for @mktHelpPercentProduct.
  ///
  /// In ru, this message translates to:
  /// **'Процент на один товар. Не суммируется с другими скидками на позицию — берётся лучшая.'**
  String get mktHelpPercentProduct;

  /// No description provided for @mktHelpBuyXGetY.
  ///
  /// In ru, this message translates to:
  /// **'При покупке X штук товара ещё Y штук бесплатно. Например, «2+1»: каждая третья единица бесплатно. Работает на одну позицию товара.'**
  String get mktHelpBuyXGetY;

  /// No description provided for @mktHelpPromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на чек по коду, который кассир вводит на кассе. Можно задать процент или сумму и минимальную сумму чека. Конкурирует с другими скидками на чек — применяется лучшая.'**
  String get mktHelpPromoCode;

  /// No description provided for @mktStatusActive.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get mktStatusActive;

  /// No description provided for @mktStatusScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Запланирована'**
  String get mktStatusScheduled;

  /// No description provided for @mktStatusFinished.
  ///
  /// In ru, this message translates to:
  /// **'Завершена'**
  String get mktStatusFinished;

  /// No description provided for @mktStatusDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключена'**
  String get mktStatusDisabled;

  /// No description provided for @mktErrEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название акции'**
  String get mktErrEnterName;

  /// No description provided for @mktErrSelectType.
  ///
  /// In ru, this message translates to:
  /// **'Выберите тип акции'**
  String get mktErrSelectType;

  /// No description provided for @mktErrEnterPercent.
  ///
  /// In ru, this message translates to:
  /// **'Укажите процент скидки'**
  String get mktErrEnterPercent;

  /// No description provided for @mktErrPercentRange.
  ///
  /// In ru, this message translates to:
  /// **'Процент скидки должен быть больше 0 и не больше 100'**
  String get mktErrPercentRange;

  /// No description provided for @mktErrEnterAmount.
  ///
  /// In ru, this message translates to:
  /// **'Укажите сумму скидки'**
  String get mktErrEnterAmount;

  /// No description provided for @mktErrPromoCodeMinAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма скидки по промокоду должна быть не меньше {amount}'**
  String mktErrPromoCodeMinAmount(String amount);

  /// No description provided for @mktErrDiscountAboveMin.
  ///
  /// In ru, this message translates to:
  /// **'Скидка не может быть больше минимальной суммы чека'**
  String get mktErrDiscountAboveMin;

  /// No description provided for @mktErrSelectCategory.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию'**
  String get mktErrSelectCategory;

  /// No description provided for @mktErrSelectProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товар'**
  String get mktErrSelectProduct;

  /// No description provided for @mktErrBuyMin.
  ///
  /// In ru, this message translates to:
  /// **'«Купи» — минимум 1 шт.'**
  String get mktErrBuyMin;

  /// No description provided for @mktErrGetMin.
  ///
  /// In ru, this message translates to:
  /// **'«Получи» — минимум 1 шт.'**
  String get mktErrGetMin;

  /// No description provided for @mktErrQtyTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Слишком большое количество'**
  String get mktErrQtyTooLarge;

  /// No description provided for @mktErrEnterCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите промокод'**
  String get mktErrEnterCode;

  /// No description provided for @mktErrCodeTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Промокод — минимум 3 символа'**
  String get mktErrCodeTooShort;

  /// No description provided for @mktErrCodeTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Промокод слишком длинный'**
  String get mktErrCodeTooLong;

  /// No description provided for @mktErrCodeChars.
  ///
  /// In ru, this message translates to:
  /// **'Промокод: только буквы, цифры, «-» и «_»'**
  String get mktErrCodeChars;

  /// No description provided for @mktErrCodeTaken.
  ///
  /// In ru, this message translates to:
  /// **'Промокод {code} уже используется в другой активной акции'**
  String mktErrCodeTaken(String code);

  /// No description provided for @mktErrMinNegative.
  ///
  /// In ru, this message translates to:
  /// **'Минимальная сумма не может быть отрицательной'**
  String get mktErrMinNegative;

  /// No description provided for @mktErrEndBeforeStart.
  ///
  /// In ru, this message translates to:
  /// **'Дата окончания должна быть не раньше даты начала'**
  String get mktErrEndBeforeStart;

  /// No description provided for @mktDescMinOrder.
  ///
  /// In ru, this message translates to:
  /// **' от {amount}'**
  String mktDescMinOrder(String amount);

  /// No description provided for @mktDescOrder.
  ///
  /// In ru, this message translates to:
  /// **'{value} на чек{min}'**
  String mktDescOrder(String value, String min);

  /// No description provided for @mktDescCategory.
  ///
  /// In ru, this message translates to:
  /// **'{value} на категорию «{target}»'**
  String mktDescCategory(String value, String target);

  /// No description provided for @mktDescProduct.
  ///
  /// In ru, this message translates to:
  /// **'{value} на «{target}»'**
  String mktDescProduct(String value, String target);

  /// No description provided for @mktDescBuyXGetY.
  ///
  /// In ru, this message translates to:
  /// **'{buy}+{get}: купи {buy}, ещё {get} бесплатно — «{target}»'**
  String mktDescBuyXGetY(String buy, String get, String target);

  /// No description provided for @mktDescPromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Код {code}: {value} на чек{min}'**
  String mktDescPromoCode(String code, String value, String min);

  /// No description provided for @mktPeriodUnlimited.
  ///
  /// In ru, this message translates to:
  /// **'Бессрочно'**
  String get mktPeriodUnlimited;

  /// No description provided for @mktPeriodUntil.
  ///
  /// In ru, this message translates to:
  /// **'по {date}'**
  String mktPeriodUntil(String date);

  /// No description provided for @mktPeriodFrom.
  ///
  /// In ru, this message translates to:
  /// **'с {date}'**
  String mktPeriodFrom(String date);

  /// No description provided for @mktPromoSaved.
  ///
  /// In ru, this message translates to:
  /// **'Акция сохранена'**
  String get mktPromoSaved;

  /// No description provided for @mktDeletePromoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить акцию?'**
  String get mktDeletePromoTitle;

  /// No description provided for @mktDeletePromoMessage.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» перестанет применяться на кассе. Проданные чеки не изменятся.'**
  String mktDeletePromoMessage(String name);

  /// No description provided for @mktPromoDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Акция удалена'**
  String get mktPromoDeleted;

  /// No description provided for @mktPromoSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название или промокод'**
  String get mktPromoSearchHint;

  /// No description provided for @mktNewPromo.
  ///
  /// In ru, this message translates to:
  /// **'Новая акция'**
  String get mktNewPromo;

  /// No description provided for @mktTestOnReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Проверить на чеке'**
  String get mktTestOnReceipt;

  /// No description provided for @mktChipAll.
  ///
  /// In ru, this message translates to:
  /// **'Все {count}'**
  String mktChipAll(String count);

  /// No description provided for @mktPromosEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Акций пока нет'**
  String get mktPromosEmptyTitle;

  /// No description provided for @mktPromosEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Создайте скидку на чек, на категорию или товар, «2+1» или промокод. Касса применит её автоматически.'**
  String get mktPromosEmptyMessage;

  /// No description provided for @mktCreatePromo.
  ///
  /// In ru, this message translates to:
  /// **'Создать акцию'**
  String get mktCreatePromo;

  /// No description provided for @mktPromosNoMatch.
  ///
  /// In ru, this message translates to:
  /// **'Нет акций с таким фильтром'**
  String get mktPromosNoMatch;

  /// No description provided for @mktTurnOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключить'**
  String get mktTurnOff;

  /// No description provided for @mktTurnOn.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get mktTurnOn;

  /// No description provided for @mktDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Дублировать'**
  String get mktDuplicate;

  /// No description provided for @mktEditPromo.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование акции'**
  String get mktEditPromo;

  /// No description provided for @mktCopyName.
  ///
  /// In ru, this message translates to:
  /// **'{name} (копия)'**
  String mktCopyName(String name);

  /// No description provided for @mktProductDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get mktProductDeleted;

  /// No description provided for @mktStartDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата начала'**
  String get mktStartDate;

  /// No description provided for @mktLastDay.
  ///
  /// In ru, this message translates to:
  /// **'Последний день акции'**
  String get mktLastDay;

  /// No description provided for @mktPromoProduct.
  ///
  /// In ru, this message translates to:
  /// **'Товар для акции'**
  String get mktPromoProduct;

  /// No description provided for @mktNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название *'**
  String get mktNameLabel;

  /// No description provided for @mktNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Скидка выходного дня'**
  String get mktNameHint;

  /// No description provided for @mktEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get mktEnterName;

  /// No description provided for @mktPromoType.
  ///
  /// In ru, this message translates to:
  /// **'Тип акции'**
  String get mktPromoType;

  /// No description provided for @mktValidityPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Период действия'**
  String get mktValidityPeriod;

  /// No description provided for @mktDateFrom.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get mktDateFrom;

  /// No description provided for @mktDateTo.
  ///
  /// In ru, this message translates to:
  /// **'По (включительно)'**
  String get mktDateTo;

  /// No description provided for @mktPromoEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Акция включена'**
  String get mktPromoEnabled;

  /// No description provided for @mktStatusLine.
  ///
  /// In ru, this message translates to:
  /// **'Статус: {status}'**
  String mktStatusLine(String status);

  /// No description provided for @mktUnlimited.
  ///
  /// In ru, this message translates to:
  /// **'не ограничено'**
  String get mktUnlimited;

  /// No description provided for @mktPromoCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Промокод *'**
  String get mktPromoCodeLabel;

  /// No description provided for @mktMin3Chars.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 3 символа'**
  String get mktMin3Chars;

  /// No description provided for @mktDiscountColon.
  ///
  /// In ru, this message translates to:
  /// **'Скидка:'**
  String get mktDiscountColon;

  /// No description provided for @mktAmountIn.
  ///
  /// In ru, this message translates to:
  /// **'сумма, {currency}'**
  String mktAmountIn(String currency);

  /// No description provided for @mktCreateCategoriesFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала создайте категории в разделе «Товары»'**
  String get mktCreateCategoriesFirst;

  /// No description provided for @mktCategoryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Категория *'**
  String get mktCategoryLabel;

  /// No description provided for @mktProductLabel.
  ///
  /// In ru, this message translates to:
  /// **'Товар *'**
  String get mktProductLabel;

  /// No description provided for @mktPickProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать товар…'**
  String get mktPickProduct;

  /// No description provided for @mktBuyQty.
  ///
  /// In ru, this message translates to:
  /// **'Купи (шт.)'**
  String get mktBuyQty;

  /// No description provided for @mktGetQty.
  ///
  /// In ru, this message translates to:
  /// **'Получи бесплатно (шт.)'**
  String get mktGetQty;

  /// No description provided for @mktMin1.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 1'**
  String get mktMin1;

  /// No description provided for @mktBuyGetPreview.
  ///
  /// In ru, this message translates to:
  /// **'В чеке из {total} шт. — {free} шт. бесплатно'**
  String mktBuyGetPreview(String total, String free);

  /// No description provided for @mktDiscountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Скидка *'**
  String get mktDiscountLabel;

  /// No description provided for @mktEnterPercent.
  ///
  /// In ru, this message translates to:
  /// **'Введите процент'**
  String get mktEnterPercent;

  /// No description provided for @mktPercentRangeShort.
  ///
  /// In ru, this message translates to:
  /// **'Больше 0 и не больше 100'**
  String get mktPercentRangeShort;

  /// No description provided for @mktDiscountAmountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сумма скидки *'**
  String get mktDiscountAmountLabel;

  /// No description provided for @mktMinOrderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Мин. сумма чека'**
  String get mktMinOrderLabel;

  /// No description provided for @mktMinOrderHelper.
  ///
  /// In ru, this message translates to:
  /// **'Пусто — без ограничения'**
  String get mktMinOrderHelper;

  /// No description provided for @mktSimTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка акций на чеке'**
  String get mktSimTitle;

  /// No description provided for @mktSimAddProductTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар в тестовый чек'**
  String get mktSimAddProductTitle;

  /// No description provided for @mktSimIntro.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары и посмотрите, какие скидки применит касса. Действует активных акций: {count}. Скидки на позицию не суммируются — берётся лучшая из акции на товар/категорию, «N+M» и персональной скидки клиента. Из скидок на чек (акция на чек, промокод) применяется одна, самая выгодная.'**
  String mktSimIntro(String count);

  /// No description provided for @mktSimAddProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар'**
  String get mktSimAddProduct;

  /// No description provided for @mktSimCustomerDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка клиента'**
  String get mktSimCustomerDiscount;

  /// No description provided for @mktSim0To100.
  ///
  /// In ru, this message translates to:
  /// **'От 0 до 100'**
  String get mktSim0To100;

  /// No description provided for @mktSimEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый чек пуст'**
  String get mktSimEmptyTitle;

  /// No description provided for @mktSimEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте один или несколько товаров'**
  String get mktSimEmptyMessage;

  /// No description provided for @mktSimPricePer.
  ///
  /// In ru, this message translates to:
  /// **'{price} за {unit}'**
  String mktSimPricePer(String price, String unit);

  /// No description provided for @mktSimOrderShare.
  ///
  /// In ru, this message translates to:
  /// **'−{amount} · доля скидки на чек'**
  String mktSimOrderShare(String amount);

  /// No description provided for @mktSimQtyPositive.
  ///
  /// In ru, this message translates to:
  /// **'Укажите количество больше нуля'**
  String get mktSimQtyPositive;

  /// No description provided for @mktSimQtyShort.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get mktSimQtyShort;

  /// No description provided for @mktRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get mktRemove;

  /// No description provided for @mktSimSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма без скидок'**
  String get mktSimSubtotal;

  /// No description provided for @mktSimToPay.
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get mktSimToPay;

  /// No description provided for @mktSimCodeAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Промокод принят'**
  String get mktSimCodeAccepted;

  /// No description provided for @mktSimCodeRejected.
  ///
  /// In ru, this message translates to:
  /// **'Промокод не найден, не активен или сумма чека меньше минимальной'**
  String get mktSimCodeRejected;

  /// No description provided for @mktSimApplied.
  ///
  /// In ru, this message translates to:
  /// **'Применённые скидки:'**
  String get mktSimApplied;

  /// No description provided for @mktSimNone.
  ///
  /// In ru, this message translates to:
  /// **'нет'**
  String get mktSimNone;

  /// No description provided for @mktLoyaltyProgram.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа'**
  String get mktLoyaltyProgram;

  /// No description provided for @mktLoyaltyOn.
  ///
  /// In ru, this message translates to:
  /// **'Включена'**
  String get mktLoyaltyOn;

  /// No description provided for @mktLoyaltyOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключена'**
  String get mktLoyaltyOff;

  /// No description provided for @mktLoyaltyEarn.
  ///
  /// In ru, this message translates to:
  /// **'Начисление'**
  String get mktLoyaltyEarn;

  /// No description provided for @mktLoyaltyEarnValue.
  ///
  /// In ru, this message translates to:
  /// **'{percent}% от оплаченной суммы (без учёта оплаты бонусами)'**
  String mktLoyaltyEarnValue(String percent);

  /// No description provided for @mktLoyaltyRedeem.
  ///
  /// In ru, this message translates to:
  /// **'Оплата бонусами'**
  String get mktLoyaltyRedeem;

  /// No description provided for @mktLoyaltyRedeemValue.
  ///
  /// In ru, this message translates to:
  /// **'до {percent}% суммы чека'**
  String mktLoyaltyRedeemValue(String percent);

  /// No description provided for @mktLoyaltyRate.
  ///
  /// In ru, this message translates to:
  /// **'Курс'**
  String get mktLoyaltyRate;

  /// No description provided for @mktLoyaltyRateValue.
  ///
  /// In ru, this message translates to:
  /// **'1 бонус = {amount}'**
  String mktLoyaltyRateValue(String amount);

  /// No description provided for @mktLoyaltyNote.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы начисляются автоматически при продаже клиенту и списываются пропорционально при возврате.'**
  String get mktLoyaltyNote;

  /// No description provided for @mktOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get mktOpenSettings;

  /// No description provided for @mktNoSettingsRight.
  ///
  /// In ru, this message translates to:
  /// **'Нет права изменять настройки'**
  String get mktNoSettingsRight;

  /// No description provided for @mktEditInSettings.
  ///
  /// In ru, this message translates to:
  /// **'Изменить в настройках'**
  String get mktEditInSettings;

  /// No description provided for @mktStatLiability.
  ///
  /// In ru, this message translates to:
  /// **'Бонусные обязательства'**
  String get mktStatLiability;

  /// No description provided for @mktStatLiabilityShort.
  ///
  /// In ru, this message translates to:
  /// **'Обязательства'**
  String get mktStatLiabilityShort;

  /// No description provided for @mktStatHolders.
  ///
  /// In ru, this message translates to:
  /// **'у {count} клиентов'**
  String mktStatHolders(String count);

  /// No description provided for @mktStatEarned30.
  ///
  /// In ru, this message translates to:
  /// **'Начислено за 30 дней'**
  String get mktStatEarned30;

  /// No description provided for @mktStatEarned.
  ///
  /// In ru, this message translates to:
  /// **'Начислено'**
  String get mktStatEarned;

  /// No description provided for @mktStat30Days.
  ///
  /// In ru, this message translates to:
  /// **'за 30 дней'**
  String get mktStat30Days;

  /// No description provided for @mktStatSpent30.
  ///
  /// In ru, this message translates to:
  /// **'Списано за 30 дней'**
  String get mktStatSpent30;

  /// No description provided for @mktStatSpent.
  ///
  /// In ru, this message translates to:
  /// **'Списано'**
  String get mktStatSpent;

  /// No description provided for @mktStatAdjusted30.
  ///
  /// In ru, this message translates to:
  /// **'Корректировки за 30 дней'**
  String get mktStatAdjusted30;

  /// No description provided for @mktStatAdjusted.
  ///
  /// In ru, this message translates to:
  /// **'Корректировки'**
  String get mktStatAdjusted;

  /// No description provided for @mktStatAdjustedHint.
  ///
  /// In ru, this message translates to:
  /// **'вручную и при возвратах'**
  String get mktStatAdjustedHint;

  /// No description provided for @mktTplBirthday.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! {store} поздравляет вас с днём рождения! Ждём вас за подарком.'**
  String mktTplBirthday(String name, String store);

  /// No description provided for @mktTplSleeping.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! Давно не виделись — в {store} много новинок. Ваши бонусы: {bonus}. Ждём вас!'**
  String mktTplSleeping(String name, String store, String bonus);

  /// No description provided for @mktTplDebt.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! Напоминаем, что ваш долг в {store} составляет {debt}. Спасибо!'**
  String mktTplDebt(String name, String store, String debt);

  /// No description provided for @mktTplVip.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! Вы — наш VIP-клиент. Для вас в {store} особые предложения. Ваши бонусы: {bonus}.'**
  String mktTplVip(String name, String store, String bonus);

  /// No description provided for @mktTplAll.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}! '**
  String mktTplAll(String name);

  /// No description provided for @mktOurStore.
  ///
  /// In ru, this message translates to:
  /// **'наш магазин'**
  String get mktOurStore;

  /// No description provided for @mktSegment.
  ///
  /// In ru, this message translates to:
  /// **'Сегмент'**
  String get mktSegment;

  /// No description provided for @mktMessageText.
  ///
  /// In ru, this message translates to:
  /// **'Текст сообщения'**
  String get mktMessageText;

  /// No description provided for @mktTemplateVars.
  ///
  /// In ru, this message translates to:
  /// **'Подстановки: {name} — имя, {fullname}, {store}, {debt}, {bonus}, {discount}'**
  String mktTemplateVars(
    String name,
    String fullname,
    String store,
    String debt,
    String bonus,
    String discount,
  );

  /// No description provided for @mktPhonesCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано телефонов: {count}'**
  String mktPhonesCopied(String count);

  /// No description provided for @mktCopyPhones.
  ///
  /// In ru, this message translates to:
  /// **'Копировать телефоны ({count})'**
  String mktCopyPhones(String count);

  /// No description provided for @mktMessagesCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано сообщений: {count}'**
  String mktMessagesCopied(String count);

  /// No description provided for @mktCopyMessages.
  ///
  /// In ru, this message translates to:
  /// **'Копировать сообщения'**
  String get mktCopyMessages;

  /// No description provided for @mktSmsNote.
  ///
  /// In ru, this message translates to:
  /// **'SMS-шлюз не подключён: скопируйте список и отправьте сообщения через мессенджер или телефон.'**
  String get mktSmsNote;

  /// No description provided for @mktNoPhoneNote.
  ///
  /// In ru, this message translates to:
  /// **'Без телефона: {count} клиент(ов) — они не попадут в список.'**
  String mktNoPhoneNote(String count);

  /// No description provided for @mktNoPhone.
  ///
  /// In ru, this message translates to:
  /// **'нет телефона'**
  String get mktNoPhone;

  /// No description provided for @mktToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get mktToday;

  /// No description provided for @mktInDays.
  ///
  /// In ru, this message translates to:
  /// **'через {days} дн.'**
  String mktInDays(String days);

  /// No description provided for @mktLastVisit.
  ///
  /// In ru, this message translates to:
  /// **'был {date}'**
  String mktLastVisit(String date);

  /// No description provided for @mktPurchases.
  ///
  /// In ru, this message translates to:
  /// **'покупки {amount}'**
  String mktPurchases(String amount);

  /// No description provided for @mktOverdue.
  ///
  /// In ru, this message translates to:
  /// **'просрочен'**
  String get mktOverdue;

  /// No description provided for @mktSegmentEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В сегменте никого нет'**
  String get mktSegmentEmpty;

  /// No description provided for @mktGiftActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get mktGiftActive;

  /// No description provided for @mktGiftUsed.
  ///
  /// In ru, this message translates to:
  /// **'Использован'**
  String get mktGiftUsed;

  /// No description provided for @mktGiftExpired.
  ///
  /// In ru, this message translates to:
  /// **'Истёк'**
  String get mktGiftExpired;

  /// No description provided for @mktGiftBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Заблокирован'**
  String get mktGiftBlocked;

  /// No description provided for @mktErrUniqueCode.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сгенерировать уникальный код'**
  String get mktErrUniqueCode;

  /// No description provided for @mktErrUnblockVoided.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата аннулирована — разблокировка невозможна'**
  String get mktErrUnblockVoided;

  /// No description provided for @mktBlockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать {code}?'**
  String mktBlockTitle(String code);

  /// No description provided for @mktGiftBlockedMsg.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат заблокирован'**
  String get mktGiftBlockedMsg;

  /// No description provided for @mktGiftUnblockedMsg.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат разблокирован'**
  String get mktGiftUnblockedMsg;

  /// No description provided for @mktGiftSalesSegment.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get mktGiftSalesSegment;

  /// No description provided for @mktNoSellRight.
  ///
  /// In ru, this message translates to:
  /// **'Нет права продавать'**
  String get mktNoSellRight;

  /// No description provided for @mktStatActiveShort.
  ///
  /// In ru, this message translates to:
  /// **'Активных'**
  String get mktStatActiveShort;

  /// No description provided for @mktStatActive.
  ///
  /// In ru, this message translates to:
  /// **'Активных сертификатов'**
  String get mktStatActive;

  /// No description provided for @mktStatActiveHint.
  ///
  /// In ru, this message translates to:
  /// **'сертификатов'**
  String get mktStatActiveHint;

  /// No description provided for @mktStatOutstandingShort.
  ///
  /// In ru, this message translates to:
  /// **'К погашению'**
  String get mktStatOutstandingShort;

  /// No description provided for @mktStatOutstanding.
  ///
  /// In ru, this message translates to:
  /// **'Остаток к погашению'**
  String get mktStatOutstanding;

  /// No description provided for @mktStatOutstandingHintShort.
  ///
  /// In ru, this message translates to:
  /// **'на сертификатах'**
  String get mktStatOutstandingHintShort;

  /// No description provided for @mktStatOutstandingHint.
  ///
  /// In ru, this message translates to:
  /// **'обязательства магазина'**
  String get mktStatOutstandingHint;

  /// No description provided for @mktGiftSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Код или клиент'**
  String get mktGiftSearchHint;

  /// No description provided for @mktGiftSaleTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата (аванс, не выручка)'**
  String get mktGiftSaleTooltip;

  /// No description provided for @mktIssue.
  ///
  /// In ru, this message translates to:
  /// **'Выпустить'**
  String get mktIssue;

  /// No description provided for @mktCheckBalance.
  ///
  /// In ru, this message translates to:
  /// **'Проверить баланс'**
  String get mktCheckBalance;

  /// No description provided for @mktGiftsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сертификатов пока нет'**
  String get mktGiftsEmptyTitle;

  /// No description provided for @mktGiftsEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Продавайте подарочные сертификаты — их можно принять в оплату на кассе.'**
  String get mktGiftsEmptyMessage;

  /// No description provided for @mktIssueGift.
  ///
  /// In ru, this message translates to:
  /// **'Выпустить сертификат'**
  String get mktIssueGift;

  /// No description provided for @mktCustomerLower.
  ///
  /// In ru, this message translates to:
  /// **'клиент'**
  String get mktCustomerLower;

  /// No description provided for @mktCodeCopied.
  ///
  /// In ru, this message translates to:
  /// **'Код скопирован'**
  String get mktCodeCopied;

  /// No description provided for @mktOfAmount.
  ///
  /// In ru, this message translates to:
  /// **'из {amount}'**
  String mktOfAmount(String amount);

  /// No description provided for @mktFaceValueLower.
  ///
  /// In ru, this message translates to:
  /// **'номинал'**
  String get mktFaceValueLower;

  /// No description provided for @mktIssuedOn.
  ///
  /// In ru, this message translates to:
  /// **'выпущен {date}'**
  String mktIssuedOn(String date);

  /// No description provided for @mktNoExpiryLower.
  ///
  /// In ru, this message translates to:
  /// **'бессрочный'**
  String get mktNoExpiryLower;

  /// No description provided for @mktUntil.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String mktUntil(String date);

  /// No description provided for @mktSaleDocument.
  ///
  /// In ru, this message translates to:
  /// **'Документ продажи'**
  String get mktSaleDocument;

  /// No description provided for @mktGiftBlank.
  ///
  /// In ru, this message translates to:
  /// **'Бланк сертификата'**
  String get mktGiftBlank;

  /// No description provided for @mktCopyCode.
  ///
  /// In ru, this message translates to:
  /// **'Копировать код'**
  String get mktCopyCode;

  /// No description provided for @mktUnblock.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get mktUnblock;

  /// No description provided for @mktBlock.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get mktBlock;

  /// No description provided for @mktGiftBalanceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Баланс сертификата'**
  String get mktGiftBalanceTitle;

  /// No description provided for @mktCodeEnterOrScan.
  ///
  /// In ru, this message translates to:
  /// **'Код (введите или отсканируйте)'**
  String get mktCodeEnterOrScan;

  /// No description provided for @mktFind.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get mktFind;

  /// No description provided for @mktFaceValueAmount.
  ///
  /// In ru, this message translates to:
  /// **'Номинал {amount}'**
  String mktFaceValueAmount(String amount);

  /// No description provided for @mktNoExpiry.
  ///
  /// In ru, this message translates to:
  /// **'Бессрочный'**
  String get mktNoExpiry;

  /// No description provided for @mktValidUntil.
  ///
  /// In ru, this message translates to:
  /// **'Действует до {date}'**
  String mktValidUntil(String date);

  /// No description provided for @mktPdfGiftTitle.
  ///
  /// In ru, this message translates to:
  /// **'ПОДАРОЧНЫЙ СЕРТИФИКАТ'**
  String get mktPdfGiftTitle;

  /// No description provided for @mktPdfValidUntil.
  ///
  /// In ru, this message translates to:
  /// **'Действителен до {date}'**
  String mktPdfValidUntil(String date);

  /// No description provided for @mktPdfGiftNote.
  ///
  /// In ru, this message translates to:
  /// **'Предъявите сертификат на кассе.\nОбмену на деньги не подлежит.'**
  String get mktPdfGiftNote;

  /// No description provided for @mktVoidSaleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать продажу №{number}'**
  String mktVoidSaleTitle(String number);

  /// No description provided for @mktReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Причина *'**
  String get mktReasonRequired;

  /// No description provided for @mktVoidSaleQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать продажу №{number}?'**
  String mktVoidSaleQuestion(String number);

  /// No description provided for @mktVoidSaleMessage.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {code} будет заблокирован. Верните покупателю {amount}: {payments}. Возврат попадёт в текущую смену.'**
  String mktVoidSaleMessage(String code, String amount, String payments);

  /// No description provided for @mktVoid.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать'**
  String get mktVoid;

  /// No description provided for @mktSaleVoided.
  ///
  /// In ru, this message translates to:
  /// **'Продажа №{number} аннулирована'**
  String mktSaleVoided(String number);

  /// No description provided for @mktBlank.
  ///
  /// In ru, this message translates to:
  /// **'Бланк'**
  String get mktBlank;

  /// No description provided for @mktNoSaleDocument.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат выпущен до появления документов продажи — документа нет, аннулирование недоступно.'**
  String get mktNoSaleDocument;

  /// No description provided for @mktFaceValueLowerAmount.
  ///
  /// In ru, this message translates to:
  /// **'номинал {amount}'**
  String mktFaceValueLowerAmount(String amount);

  /// No description provided for @mktNoVoidRight.
  ///
  /// In ru, this message translates to:
  /// **'Нет права аннулировать продажи'**
  String get mktNoVoidRight;

  /// No description provided for @mktOpenShiftToVoid.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы аннулировать продажу'**
  String get mktOpenShiftToVoid;

  /// No description provided for @mktChecking.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем…'**
  String get mktChecking;

  /// No description provided for @mktSaleNumber.
  ///
  /// In ru, this message translates to:
  /// **'Продажа №{number}'**
  String mktSaleNumber(String number);

  /// No description provided for @mktVoidedAt.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирована {date}'**
  String mktVoidedAt(String date);

  /// No description provided for @mktVoidTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат будет заблокирован, деньги возвращаются покупателю'**
  String get mktVoidTooltip;

  /// No description provided for @mktVoidSale.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать продажу'**
  String get mktVoidSale;

  /// No description provided for @mktSaleCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Проведена'**
  String get mktSaleCompleted;

  /// No description provided for @mktSaleVoidedStatus.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирована'**
  String get mktSaleVoidedStatus;

  /// No description provided for @mktPeriod7Days.
  ///
  /// In ru, this message translates to:
  /// **'7 дней'**
  String get mktPeriod7Days;

  /// No description provided for @mktPeriod30Days.
  ///
  /// In ru, this message translates to:
  /// **'30 дней'**
  String get mktPeriod30Days;

  /// No description provided for @mktPeriodAllTime.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get mktPeriodAllTime;

  /// No description provided for @mktGiftSalesEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продаж сертификатов нет'**
  String get mktGiftSalesEmptyTitle;

  /// No description provided for @mktGiftSalesEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'За выбранный период нет документов с таким статусом.'**
  String get mktGiftSalesEmptyMessage;

  /// No description provided for @mktCompletedFor.
  ///
  /// In ru, this message translates to:
  /// **'проведено на {amount}'**
  String mktCompletedFor(String amount);

  /// No description provided for @mktVoidedCount.
  ///
  /// In ru, this message translates to:
  /// **'аннулировано: {count}'**
  String mktVoidedCount(String count);

  /// No description provided for @mktReasonLower.
  ///
  /// In ru, this message translates to:
  /// **'причина: {reason}'**
  String mktReasonLower(String reason);

  /// No description provided for @mktPayMixed.
  ///
  /// In ru, this message translates to:
  /// **'Смешанная'**
  String get mktPayMixed;

  /// No description provided for @mktValidUntilInclusive.
  ///
  /// In ru, this message translates to:
  /// **'Действует до (включительно)'**
  String get mktValidUntilInclusive;

  /// No description provided for @mktPayExceeds.
  ///
  /// In ru, this message translates to:
  /// **'Карта и перевод больше номинала на {amount}'**
  String mktPayExceeds(String amount);

  /// No description provided for @mktPayEnterCardTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Укажите сумму картой и/или переводом'**
  String get mktPayEnterCardTransfer;

  /// No description provided for @mktPayTenderedShort.
  ///
  /// In ru, this message translates to:
  /// **'Получено меньше, чем нужно: {amount}'**
  String mktPayTenderedShort(String amount);

  /// No description provided for @mktCodeExists.
  ///
  /// In ru, this message translates to:
  /// **'Такой код уже существует'**
  String get mktCodeExists;

  /// No description provided for @mktValidUntilLabel.
  ///
  /// In ru, this message translates to:
  /// **'Действует до'**
  String get mktValidUntilLabel;

  /// No description provided for @mktNoExpiryCap.
  ///
  /// In ru, this message translates to:
  /// **'Без срока'**
  String get mktNoExpiryCap;

  /// No description provided for @mktBuyerOptional.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель (необязательно)'**
  String get mktBuyerOptional;

  /// No description provided for @mktNotSelected.
  ///
  /// In ru, this message translates to:
  /// **'Не выбран'**
  String get mktNotSelected;

  /// No description provided for @mktRemoveBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Убрать покупателя'**
  String get mktRemoveBuyer;

  /// No description provided for @mktGiftSaleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата'**
  String get mktGiftSaleTitle;

  /// No description provided for @mktShiftClosedNote.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта: откройте смену, чтобы продать сертификат.'**
  String get mktShiftClosedNote;

  /// No description provided for @mktShiftAdvanceNote.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number}. Это аванс, не выручка: оплата попадёт в раздел «Сертификаты» отчёта смены.'**
  String mktShiftAdvanceNote(String number);

  /// No description provided for @mktFaceValueRequired.
  ///
  /// In ru, this message translates to:
  /// **'Номинал *'**
  String get mktFaceValueRequired;

  /// No description provided for @mktGiftCodeRequired.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата *'**
  String get mktGiftCodeRequired;

  /// No description provided for @mktGiftCodeHelper.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерирован автоматически; можно отсканировать или ввести свой'**
  String get mktGiftCodeHelper;

  /// No description provided for @mktGenerate.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать'**
  String get mktGenerate;

  /// No description provided for @mktMin6Chars.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 6 символов'**
  String get mktMin6Chars;

  /// No description provided for @mktMax32Chars.
  ///
  /// In ru, this message translates to:
  /// **'Максимум 32 символа'**
  String get mktMax32Chars;

  /// No description provided for @mktSellGift.
  ///
  /// In ru, this message translates to:
  /// **'Продать сертификат'**
  String get mktSellGift;

  /// No description provided for @mktTenderedCash.
  ///
  /// In ru, this message translates to:
  /// **'Получено наличными'**
  String get mktTenderedCash;

  /// No description provided for @mktTenderedHelper.
  ///
  /// In ru, this message translates to:
  /// **'Пусто — без сдачи'**
  String get mktTenderedHelper;

  /// No description provided for @mktSlipNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер слипа (необязательно)'**
  String get mktSlipNumber;

  /// No description provided for @mktTransferNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер перевода (необязательно)'**
  String get mktTransferNumber;

  /// No description provided for @mktInCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличными'**
  String get mktInCash;

  /// No description provided for @mktPrintFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось напечатать: {error}'**
  String mktPrintFailed(String error);

  /// No description provided for @mktGiftSold.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат продан'**
  String get mktGiftSold;

  /// No description provided for @notifOutOfStockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закончился товар: {name}'**
  String notifOutOfStockTitle(String name);

  /// No description provided for @notifOutOfStockBody.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {qty}. Оформите закупку, чтобы не терять продажи.'**
  String notifOutOfStockBody(String qty);

  /// No description provided for @notifLowStockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мало товара: {name}'**
  String notifLowStockTitle(String name);

  /// No description provided for @notifLowStockBody.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {qty}, минимальный — {min}.'**
  String notifLowStockBody(String qty, String min);

  /// No description provided for @notifDebtTitle.
  ///
  /// In ru, this message translates to:
  /// **'Просрочен долг: {name}'**
  String notifDebtTitle(String name);

  /// No description provided for @notifDebtBody.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено {overdue}, срок оплаты истёк {date}. Напомните клиенту об оплате.'**
  String notifDebtBody(String overdue, String date);

  /// No description provided for @notifDebtBodyPartial.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено {overdue} из {debt}, срок оплаты истёк {date}. Напомните клиенту об оплате.'**
  String notifDebtBodyPartial(String overdue, String debt, String date);

  /// No description provided for @notifBirthdayTitle.
  ///
  /// In ru, this message translates to:
  /// **'День рождения: {name}'**
  String notifBirthdayTitle(String name);

  /// No description provided for @notifBirthdayBody.
  ///
  /// In ru, this message translates to:
  /// **'Поздравьте клиента и предложите подарок или бонусы.'**
  String get notifBirthdayBody;

  /// No description provided for @notifBirthdayBodyAge.
  ///
  /// In ru, this message translates to:
  /// **'Исполняется {age}. Поздравьте клиента и предложите подарок или бонусы.'**
  String notifBirthdayBodyAge(String age);

  /// No description provided for @notifShiftTitle.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} открыта {hours} ч'**
  String notifShiftTitle(String number, String hours);

  /// No description provided for @notifShiftBody.
  ///
  /// In ru, this message translates to:
  /// **'Открыта {date} в {time}. Закройте смену и сверьте наличные в кассе.'**
  String notifShiftBody(String date, String time);

  /// No description provided for @notifKindLowStock.
  ///
  /// In ru, this message translates to:
  /// **'Мало товара'**
  String get notifKindLowStock;

  /// No description provided for @notifKindOutOfStock.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get notifKindOutOfStock;

  /// No description provided for @notifKindDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долги'**
  String get notifKindDebt;

  /// No description provided for @notifKindBirthday.
  ///
  /// In ru, this message translates to:
  /// **'Дни рождения'**
  String get notifKindBirthday;

  /// No description provided for @notifKindShift.
  ///
  /// In ru, this message translates to:
  /// **'Смены'**
  String get notifKindShift;

  /// No description provided for @notifKindTask.
  ///
  /// In ru, this message translates to:
  /// **'Задачи'**
  String get notifKindTask;

  /// No description provided for @notifKindSystem.
  ///
  /// In ru, this message translates to:
  /// **'Система'**
  String get notifKindSystem;

  /// No description provided for @notifDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Уведомление удалено'**
  String get notifDeleted;

  /// No description provided for @notifUndo.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get notifUndo;

  /// No description provided for @notifCheckNone.
  ///
  /// In ru, this message translates to:
  /// **'Проверка завершена — новых уведомлений нет'**
  String get notifCheckNone;

  /// No description provided for @notifCheckCreated.
  ///
  /// In ru, this message translates to:
  /// **'Новых уведомлений: {count}'**
  String notifCheckCreated(String count);

  /// No description provided for @notifDeleteReadTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить прочитанные?'**
  String get notifDeleteReadTitle;

  /// No description provided for @notifDeleteReadMessage.
  ///
  /// In ru, this message translates to:
  /// **'Будет удалено уведомлений: {count}. Непрочитанные останутся.'**
  String notifDeleteReadMessage(String count);

  /// No description provided for @notifDeleteReadDone.
  ///
  /// In ru, this message translates to:
  /// **'Прочитанные уведомления удалены'**
  String get notifDeleteReadDone;

  /// No description provided for @notifNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к разделу — обратитесь к администратору'**
  String get notifNoAccess;

  /// No description provided for @notifAllReadShort.
  ///
  /// In ru, this message translates to:
  /// **'Все прочитаны'**
  String get notifAllReadShort;

  /// No description provided for @notifUnreadCount.
  ///
  /// In ru, this message translates to:
  /// **'Непрочитанных: {count}'**
  String notifUnreadCount(String count);

  /// No description provided for @notifCheckNowTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Проверить сейчас (F5)'**
  String get notifCheckNowTooltip;

  /// No description provided for @notifCheckNow.
  ///
  /// In ru, this message translates to:
  /// **'Проверить сейчас'**
  String get notifCheckNow;

  /// No description provided for @notifReadAll.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get notifReadAll;

  /// No description provided for @notifAllRead.
  ///
  /// In ru, this message translates to:
  /// **'Все уведомления прочитаны'**
  String get notifAllRead;

  /// No description provided for @notifDeleteRead.
  ///
  /// In ru, this message translates to:
  /// **'Удалить прочитанные'**
  String get notifDeleteRead;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомлений нет'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся напоминания о заканчивающихся товарах, просроченных долгах, днях рождения клиентов и незакрытых сменах. Проверка идёт автоматически каждые 10 минут.'**
  String get notifEmptyMessage;

  /// No description provided for @notifFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все ({count})'**
  String notifFilterAll(String count);

  /// No description provided for @notifFilterUnread.
  ///
  /// In ru, this message translates to:
  /// **'Непрочитанные ({count})'**
  String notifFilterUnread(String count);

  /// No description provided for @notifNoneOfKind.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений этого типа'**
  String get notifNoneOfKind;

  /// No description provided for @notifGoTo.
  ///
  /// In ru, this message translates to:
  /// **'Перейти'**
  String get notifGoTo;

  /// No description provided for @notifMarkUnread.
  ///
  /// In ru, this message translates to:
  /// **'Отметить непрочитанным'**
  String get notifMarkUnread;

  /// No description provided for @notifMarkRead.
  ///
  /// In ru, this message translates to:
  /// **'Отметить прочитанным'**
  String get notifMarkRead;

  /// No description provided for @posNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено: {code}'**
  String posNotFound(String code);

  /// No description provided for @posShiftNotOpenSell.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта. Откройте смену, чтобы продавать'**
  String get posShiftNotOpenSell;

  /// No description provided for @posHints.
  ///
  /// In ru, this message translates to:
  /// **'F2 поиск · F4 клиент · F8 отложить · F9 отложенные · F12 / Ctrl+Enter оплата · Del удалить · +/− количество · ↑↓ выбор позиции · Esc очистить поиск · 3*код — несколько штук'**
  String get posHints;

  /// No description provided for @posShiftNotOpenBanner.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта — продажи недоступны'**
  String get posShiftNotOpenBanner;

  /// No description provided for @posShiftNotOpenAskManager.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта. Попросите менеджера открыть смену'**
  String get posShiftNotOpenAskManager;

  /// No description provided for @posOpenShift.
  ///
  /// In ru, this message translates to:
  /// **'Открыть смену'**
  String get posOpenShift;

  /// No description provided for @posCartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Чек пуст'**
  String get posCartEmpty;

  /// No description provided for @posTotalPositions.
  ///
  /// In ru, this message translates to:
  /// **'Итого · {count} поз.'**
  String posTotalPositions(String count);

  /// No description provided for @posReceiptPositions.
  ///
  /// In ru, this message translates to:
  /// **'Чек · {count} поз.'**
  String posReceiptPositions(String count);

  /// No description provided for @posParkedReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Отложенные чеки'**
  String get posParkedReceipts;

  /// No description provided for @posCartActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с чеком'**
  String get posCartActions;

  /// No description provided for @posPark.
  ///
  /// In ru, this message translates to:
  /// **'Отложить чек'**
  String get posPark;

  /// No description provided for @posSeller.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get posSeller;

  /// No description provided for @posSellGiftCard.
  ///
  /// In ru, this message translates to:
  /// **'Продать сертификат'**
  String get posSellGiftCard;

  /// No description provided for @posClearCart.
  ///
  /// In ru, this message translates to:
  /// **'Очистить чек'**
  String get posClearCart;

  /// No description provided for @posNoSellPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права продавать'**
  String get posNoSellPerm;

  /// No description provided for @posNeedOpenShift.
  ///
  /// In ru, this message translates to:
  /// **'Нужна открытая смена'**
  String get posNeedOpenShift;

  /// No description provided for @posProductInactive.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{name}» снят с продажи'**
  String posProductInactive(String name);

  /// No description provided for @posBadMultiplier.
  ///
  /// In ru, this message translates to:
  /// **'Неверный множитель. Пример: 3*4780000000011'**
  String get posBadMultiplier;

  /// No description provided for @posMultipleFound.
  ///
  /// In ru, this message translates to:
  /// **'Найдено несколько товаров — выберите нужный в списке'**
  String get posMultipleFound;

  /// No description provided for @posProductNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{code}» не найден'**
  String posProductNotFound(String code);

  /// No description provided for @posNoPricePerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права изменять цены'**
  String get posNoPricePerm;

  /// No description provided for @posLineDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на позицию'**
  String get posLineDiscount;

  /// No description provided for @posLineDiscountFor.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на «{name}»'**
  String posLineDiscountFor(String name);

  /// No description provided for @posOrderDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на чек'**
  String get posOrderDiscount;

  /// No description provided for @posPromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get posPromoCode;

  /// No description provided for @posCode.
  ///
  /// In ru, this message translates to:
  /// **'Код'**
  String get posCode;

  /// No description provided for @posClearCartQ.
  ///
  /// In ru, this message translates to:
  /// **'Очистить чек?'**
  String get posClearCartQ;

  /// No description provided for @posClearCartMessage.
  ///
  /// In ru, this message translates to:
  /// **'Все {count} поз. будут удалены из чека.'**
  String posClearCartMessage(String count);

  /// No description provided for @posNothingToPark.
  ///
  /// In ru, this message translates to:
  /// **'Нечего откладывать — чек пуст'**
  String get posNothingToPark;

  /// No description provided for @posParkNote.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (имя покупателя и т.п.)'**
  String get posParkNote;

  /// No description provided for @posParkedDone.
  ///
  /// In ru, this message translates to:
  /// **'Чек отложен (F9 — список отложенных)'**
  String get posParkedDone;

  /// No description provided for @posAutoParked.
  ///
  /// In ru, this message translates to:
  /// **'Автоматически отложен'**
  String get posAutoParked;

  /// No description provided for @posRestoredRepriced.
  ///
  /// In ru, this message translates to:
  /// **'Чек восстановлен. Цены обновлены по прайсу: {count} поз.'**
  String posRestoredRepriced(String count);

  /// No description provided for @posRestored.
  ///
  /// In ru, this message translates to:
  /// **'Чек восстановлен'**
  String get posRestored;

  /// No description provided for @posGiftNeedShift.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы продать сертификат'**
  String get posGiftNeedShift;

  /// No description provided for @posShiftNotOpen.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта'**
  String get posShiftNotOpen;

  /// No description provided for @posGiftNeedShiftDot.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы продать сертификат.'**
  String get posGiftNeedShiftDot;

  /// No description provided for @posNoShiftPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права открывать смену — обратитесь к менеджеру'**
  String get posNoShiftPerm;

  /// No description provided for @posShiftOpened.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта. Можно продавать'**
  String get posShiftOpened;

  /// No description provided for @posCartEmptyAdd.
  ///
  /// In ru, this message translates to:
  /// **'Чек пуст — добавьте товары'**
  String get posCartEmptyAdd;

  /// No description provided for @posPromoInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Промокод «{code}» недействителен — удалите или исправьте его'**
  String posPromoInvalid(String code);

  /// No description provided for @posManualDiscounts.
  ///
  /// In ru, this message translates to:
  /// **'Ручные скидки в чеке'**
  String get posManualDiscounts;

  /// No description provided for @posManualOverLimit.
  ///
  /// In ru, this message translates to:
  /// **'Ручные скидки превышают ваш лимит — нужно подтверждение менеджера или уменьшите скидку'**
  String get posManualOverLimit;

  /// No description provided for @posQtyIntegerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Для «{unit}» только целое количество'**
  String posQtyIntegerOnly(String unit);

  /// No description provided for @posQtyTooSmall.
  ///
  /// In ru, this message translates to:
  /// **'Слишком маленькое количество'**
  String get posQtyTooSmall;

  /// No description provided for @posLineNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Позиция не найдена'**
  String get posLineNotFound;

  /// No description provided for @posDiscountNegative.
  ///
  /// In ru, this message translates to:
  /// **'Скидка не может быть отрицательной'**
  String get posDiscountNegative;

  /// No description provided for @posDiscountOver100.
  ///
  /// In ru, this message translates to:
  /// **'Скидка не может превышать 100%'**
  String get posDiscountOver100;

  /// No description provided for @posDiscountOverLine.
  ///
  /// In ru, this message translates to:
  /// **'Скидка больше суммы позиции'**
  String get posDiscountOverLine;

  /// No description provided for @posDiscountOverCart.
  ///
  /// In ru, this message translates to:
  /// **'Скидка больше суммы чека'**
  String get posDiscountOverCart;

  /// No description provided for @posCartEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте штрихкод или выберите товар в каталоге'**
  String get posCartEmptyHint;

  /// No description provided for @posPositions.
  ///
  /// In ru, this message translates to:
  /// **'{count} поз.'**
  String posPositions(String count);

  /// No description provided for @posSellerTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Продавец-консультант (для мотивации)'**
  String get posSellerTooltip;

  /// No description provided for @posParkedTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Отложенные чеки (F9)'**
  String get posParkedTooltip;

  /// No description provided for @posParkedShort.
  ///
  /// In ru, this message translates to:
  /// **'Отложенные'**
  String get posParkedShort;

  /// No description provided for @posCustomerF4.
  ///
  /// In ru, this message translates to:
  /// **'Клиент (F4)'**
  String get posCustomerF4;

  /// No description provided for @posCustDiscount.
  ///
  /// In ru, this message translates to:
  /// **'скидка {percent}%'**
  String posCustDiscount(String percent);

  /// No description provided for @posCustBonus.
  ///
  /// In ru, this message translates to:
  /// **'бонусы {amount}'**
  String posCustBonus(String amount);

  /// No description provided for @posCustDebt.
  ///
  /// In ru, this message translates to:
  /// **'долг {amount}'**
  String posCustDebt(String amount);

  /// No description provided for @posCustDebtLimit.
  ///
  /// In ru, this message translates to:
  /// **'лимит {amount}'**
  String posCustDebtLimit(String amount);

  /// No description provided for @posDetachCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Убрать клиента из чека'**
  String get posDetachCustomer;

  /// No description provided for @posPromotion.
  ///
  /// In ru, this message translates to:
  /// **'Акция'**
  String get posPromotion;

  /// No description provided for @posManualDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Ручная скидка'**
  String get posManualDiscount;

  /// No description provided for @posApprovedMark.
  ///
  /// In ru, this message translates to:
  /// **'(подтв.)'**
  String get posApprovedMark;

  /// No description provided for @posOrderDiscountLine.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на чек: −{amount}'**
  String posOrderDiscountLine(String amount);

  /// No description provided for @posOnlyInStock.
  ///
  /// In ru, this message translates to:
  /// **'На складе только {qty}'**
  String posOnlyInStock(String qty);

  /// No description provided for @posLess.
  ///
  /// In ru, this message translates to:
  /// **'Меньше (−)'**
  String get posLess;

  /// No description provided for @posMore.
  ///
  /// In ru, this message translates to:
  /// **'Больше (+)'**
  String get posMore;

  /// No description provided for @posEditPrice.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цену'**
  String get posEditPrice;

  /// No description provided for @posRemoveLine.
  ///
  /// In ru, this message translates to:
  /// **'Удалить позицию (Del)'**
  String get posRemoveLine;

  /// No description provided for @posPromoInvalidChip.
  ///
  /// In ru, this message translates to:
  /// **'{code} — недействителен'**
  String posPromoInvalidChip(String code);

  /// No description provided for @posRemovePromo.
  ///
  /// In ru, this message translates to:
  /// **'Убрать промокод'**
  String get posRemovePromo;

  /// No description provided for @posOrderDiscountValue.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на чек {value}'**
  String posOrderDiscountValue(String value);

  /// No description provided for @posRemoveDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Убрать скидку'**
  String get posRemoveDiscount;

  /// No description provided for @posSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Подытог'**
  String get posSubtotal;

  /// No description provided for @posVatIncluded.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. НДС'**
  String get posVatIncluded;

  /// No description provided for @posDiscountCalcFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось рассчитать скидки: {error}'**
  String posDiscountCalcFailed(String error);

  /// No description provided for @posOpenShiftToSell.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену, чтобы продавать'**
  String get posOpenShiftToSell;

  /// No description provided for @posAddProducts.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары в чек'**
  String get posAddProducts;

  /// No description provided for @posPayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Оплата (F12 или Ctrl+Enter)'**
  String get posPayTooltip;

  /// No description provided for @posPay.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get posPay;

  /// No description provided for @posPayF12.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить  ·  F12'**
  String get posPayF12;

  /// No description provided for @posNonCashOver.
  ///
  /// In ru, this message translates to:
  /// **'Безналичная оплата больше суммы чека на {amount}'**
  String posNonCashOver(String amount);

  /// No description provided for @posMissing.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает {amount}'**
  String posMissing(String amount);

  /// No description provided for @posCashNotNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Наличные не нужны — чек уже оплачен'**
  String get posCashNotNeeded;

  /// No description provided for @posDebtDue.
  ///
  /// In ru, this message translates to:
  /// **'Срок возврата долга'**
  String get posDebtDue;

  /// No description provided for @posDays.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String posDays(String days);

  /// No description provided for @posPickDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get posPickDate;

  /// No description provided for @posUntil.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String posUntil(String date);

  /// No description provided for @posBonusMax.
  ///
  /// In ru, this message translates to:
  /// **'Бонусами можно оплатить не более {amount}'**
  String posBonusMax(String amount);

  /// No description provided for @posCreditExceeded.
  ///
  /// In ru, this message translates to:
  /// **'Превышен кредитный лимит: доступно {amount}'**
  String posCreditExceeded(String amount);

  /// No description provided for @posCheckGiftCode.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте код сертификата'**
  String get posCheckGiftCode;

  /// No description provided for @posGiftOnly.
  ///
  /// In ru, this message translates to:
  /// **'На сертификате только {amount}'**
  String posGiftOnly(String amount);

  /// No description provided for @posEnterGiftCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите код сертификата'**
  String get posEnterGiftCode;

  /// No description provided for @posGiftNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат не найден'**
  String get posGiftNotFound;

  /// No description provided for @posGiftInactive.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат не активен ({status})'**
  String posGiftInactive(String status);

  /// No description provided for @posGiftUsed.
  ///
  /// In ru, this message translates to:
  /// **'использован'**
  String get posGiftUsed;

  /// No description provided for @posGiftExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок действия истёк {date}'**
  String posGiftExpired(String date);

  /// No description provided for @posGiftEmpty.
  ///
  /// In ru, this message translates to:
  /// **'На сертификате нет средств'**
  String get posGiftEmpty;

  /// No description provided for @posAll.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get posAll;

  /// No description provided for @posToPay.
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get posToPay;

  /// No description provided for @posRounding.
  ///
  /// In ru, this message translates to:
  /// **'Округление: −{amount}'**
  String posRounding(String amount);

  /// No description provided for @posCustomerValue.
  ///
  /// In ru, this message translates to:
  /// **'Клиент: {name}'**
  String posCustomerValue(String name);

  /// No description provided for @posCloseEsc.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть (Esc)'**
  String get posCloseEsc;

  /// No description provided for @posCashReceived.
  ///
  /// In ru, this message translates to:
  /// **'Наличными получено'**
  String get posCashReceived;

  /// No description provided for @posCashNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Нужно наличными: {amount}'**
  String posCashNeeded(String amount);

  /// No description provided for @posNoChange.
  ///
  /// In ru, this message translates to:
  /// **'Без сдачи'**
  String get posNoChange;

  /// No description provided for @posByCard.
  ///
  /// In ru, this message translates to:
  /// **'Картой'**
  String get posByCard;

  /// No description provided for @posByTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Переводом'**
  String get posByTransfer;

  /// No description provided for @posMixed.
  ///
  /// In ru, this message translates to:
  /// **'Смешанная оплата'**
  String get posMixed;

  /// No description provided for @posTransferRef.
  ///
  /// In ru, this message translates to:
  /// **'№ операции / комментарий (необязательно)'**
  String get posTransferRef;

  /// No description provided for @posBonusHelper.
  ///
  /// In ru, this message translates to:
  /// **'Баланс {balance} · можно списать до {max}'**
  String posBonusHelper(String balance, String max);

  /// No description provided for @posDebtNoLimit.
  ///
  /// In ru, this message translates to:
  /// **'Долг {debt} · лимит не задан'**
  String posDebtNoLimit(String debt);

  /// No description provided for @posDebtHelper.
  ///
  /// In ru, this message translates to:
  /// **'Долг {debt} из {limit} · доступно {available}'**
  String posDebtHelper(String debt, String limit, String available);

  /// No description provided for @posSelectCustomerForDebt.
  ///
  /// In ru, this message translates to:
  /// **'Для оплаты в долг или бонусами выберите клиента'**
  String get posSelectCustomerForDebt;

  /// No description provided for @posSelectCustomerForDebtF4.
  ///
  /// In ru, this message translates to:
  /// **'Для оплаты в долг или бонусами выберите клиента (F4)'**
  String get posSelectCustomerForDebtF4;

  /// No description provided for @posGiftCode.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата'**
  String get posGiftCode;

  /// No description provided for @posGiftBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс {amount}'**
  String posGiftBalance(String amount);

  /// No description provided for @posCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get posCheck;

  /// No description provided for @posPayByGift.
  ///
  /// In ru, this message translates to:
  /// **'Оплата сертификатом'**
  String get posPayByGift;

  /// No description provided for @posProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Проводим…'**
  String get posProcessing;

  /// No description provided for @posConfirmPay.
  ///
  /// In ru, this message translates to:
  /// **'Провести оплату'**
  String get posConfirmPay;

  /// No description provided for @posConfirmPayEnter.
  ///
  /// In ru, this message translates to:
  /// **'Провести оплату (Enter)'**
  String get posConfirmPayEnter;

  /// No description provided for @posNonCashOverpay.
  ///
  /// In ru, this message translates to:
  /// **'Переплата безналом'**
  String get posNonCashOverpay;

  /// No description provided for @posMissingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Не хватает'**
  String get posMissingLabel;

  /// No description provided for @posQtyWeight.
  ///
  /// In ru, this message translates to:
  /// **'Количество / вес'**
  String get posQtyWeight;

  /// No description provided for @posQtyExample.
  ///
  /// In ru, this message translates to:
  /// **'Например: 0,75'**
  String get posQtyExample;

  /// No description provided for @posSalePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена продажи'**
  String get posSalePrice;

  /// No description provided for @posListPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена по прайсу: {amount}'**
  String posListPrice(String amount);

  /// No description provided for @posNewPrice.
  ///
  /// In ru, this message translates to:
  /// **'Новая цена'**
  String get posNewPrice;

  /// No description provided for @posRestoreListPrice.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть цену прайса'**
  String get posRestoreListPrice;

  /// No description provided for @posNotMore100.
  ///
  /// In ru, this message translates to:
  /// **'Не больше 100%'**
  String get posNotMore100;

  /// No description provided for @posMoreThanAmount.
  ///
  /// In ru, this message translates to:
  /// **'Больше суммы ({amount})'**
  String posMoreThanAmount(String amount);

  /// No description provided for @posAmountValue.
  ///
  /// In ru, this message translates to:
  /// **'Сумма: {amount}'**
  String posAmountValue(String amount);

  /// No description provided for @posPercentSeg.
  ///
  /// In ru, this message translates to:
  /// **'Процент, %'**
  String get posPercentSeg;

  /// No description provided for @posDiscountPct.
  ///
  /// In ru, this message translates to:
  /// **'Скидка, %'**
  String get posDiscountPct;

  /// No description provided for @posDiscountAmount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка, сумма'**
  String get posDiscountAmount;

  /// No description provided for @posDiscountSummary.
  ///
  /// In ru, this message translates to:
  /// **'Скидка: {amount} ({percent}%) · к оплате {due}'**
  String posDiscountSummary(String amount, String percent, String due);

  /// No description provided for @posOverLimit.
  ///
  /// In ru, this message translates to:
  /// **'Превышает ваш лимит {limit}% — потребуется PIN менеджера'**
  String posOverLimit(String limit);

  /// No description provided for @posYourLimit.
  ///
  /// In ru, this message translates to:
  /// **'Ваш лимит скидки: {limit}%'**
  String posYourLimit(String limit);

  /// No description provided for @posApproverNoPerm.
  ///
  /// In ru, this message translates to:
  /// **'{name}: нет права подтверждать скидки'**
  String posApproverNoPerm(String name);

  /// No description provided for @posApproverLimitNotHigher.
  ///
  /// In ru, this message translates to:
  /// **'{name}: лимит скидки не выше, чем у кассира'**
  String posApproverLimitNotHigher(String name);

  /// No description provided for @posApproverLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит {name} — {limit}%, запрошено {requested}%'**
  String posApproverLimit(String name, String limit, String requested);

  /// No description provided for @posOtherPinNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Нужен PIN другого сотрудника (менеджера или владельца)'**
  String get posOtherPinNeeded;

  /// No description provided for @posManagerApproval.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение менеджера'**
  String get posManagerApproval;

  /// No description provided for @posApprovalMessage.
  ///
  /// In ru, this message translates to:
  /// **'{what}: {percent}% — больше лимита кассира ({limit}%).\nМенеджер или владелец вводит свой PIN.'**
  String posApprovalMessage(String what, String percent, String limit);

  /// No description provided for @posOpenShiftHint.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитайте наличные в денежном ящике и введите сумму размена.'**
  String get posOpenShiftHint;

  /// No description provided for @posOpeningCash.
  ///
  /// In ru, this message translates to:
  /// **'Размен в кассе'**
  String get posOpeningCash;

  /// No description provided for @posOpeningCashHelper.
  ///
  /// In ru, this message translates to:
  /// **'Можно 0, если ящик пуст'**
  String get posOpeningCashHelper;

  /// No description provided for @posSellerConsultant.
  ///
  /// In ru, this message translates to:
  /// **'Продавец-консультант'**
  String get posSellerConsultant;

  /// No description provided for @posCashierDefault.
  ///
  /// In ru, this message translates to:
  /// **'Кассир (по умолчанию)'**
  String get posCashierDefault;

  /// No description provided for @posNoParked.
  ///
  /// In ru, this message translates to:
  /// **'Нет отложенных чеков'**
  String get posNoParked;

  /// No description provided for @posNoParkedHint.
  ///
  /// In ru, this message translates to:
  /// **'Отложите текущий чек (F8), чтобы обслужить следующего покупателя'**
  String get posNoParkedHint;

  /// No description provided for @posParkedTapHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на чек, чтобы вернуть его в кассу'**
  String get posParkedTapHint;

  /// No description provided for @posAndMore.
  ///
  /// In ru, this message translates to:
  /// **'и ещё {count}'**
  String posAndMore(String count);

  /// No description provided for @posReceiptFrom.
  ///
  /// In ru, this message translates to:
  /// **'Чек от {time}'**
  String posReceiptFrom(String time);

  /// No description provided for @posDeleteParked.
  ///
  /// In ru, this message translates to:
  /// **'Удалить отложенный чек'**
  String get posDeleteParked;

  /// No description provided for @posDeleteParkedQ.
  ///
  /// In ru, this message translates to:
  /// **'Удалить отложенный чек?'**
  String get posDeleteParkedQ;

  /// No description provided for @posDeleteParkedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Товары из этого чека будут потеряны.'**
  String get posDeleteParkedMessage;

  /// No description provided for @posSearchHintShort.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод или название'**
  String get posSearchHintShort;

  /// No description provided for @posSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Сканируйте штрихкод или введите название (F2)'**
  String get posSearchHint;

  /// No description provided for @posClearEsc.
  ///
  /// In ru, this message translates to:
  /// **'Очистить (Esc)'**
  String get posClearEsc;

  /// No description provided for @posFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get posFavorites;

  /// No description provided for @posNoResults.
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» нет товаров. Проверьте название или отсканируйте штрихкод.'**
  String posNoResults(String query);

  /// No description provided for @posCategoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В категории нет товаров'**
  String get posCategoryEmpty;

  /// No description provided for @posCatalogEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Каталог пуст'**
  String get posCatalogEmpty;

  /// No description provided for @posCatalogEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары в разделе «Товары», чтобы продавать'**
  String get posCatalogEmptyHint;

  /// No description provided for @posNoStockTracking.
  ///
  /// In ru, this message translates to:
  /// **'без учёта остатка'**
  String get posNoStockTracking;

  /// No description provided for @posPrintFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось напечатать чек: {error}'**
  String posPrintFailed(String error);

  /// No description provided for @posSaleDone.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} проведён'**
  String posSaleDone(String number);

  /// No description provided for @posReceiptSum.
  ///
  /// In ru, this message translates to:
  /// **'Сумма чека: {amount}'**
  String posReceiptSum(String amount);

  /// No description provided for @posDiscountValue.
  ///
  /// In ru, this message translates to:
  /// **'Скидка: {amount}'**
  String posDiscountValue(String amount);

  /// No description provided for @posBonusEarned.
  ///
  /// In ru, this message translates to:
  /// **'Начислено бонусов: {amount}'**
  String posBonusEarned(String amount);

  /// No description provided for @posPrintAgain.
  ///
  /// In ru, this message translates to:
  /// **'Ещё раз'**
  String get posPrintAgain;

  /// No description provided for @posPrintReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Печать чека'**
  String get posPrintReceipt;

  /// No description provided for @posNewSale.
  ///
  /// In ru, this message translates to:
  /// **'Новая продажа (Enter)'**
  String get posNewSale;

  /// No description provided for @prodRoundNearest.
  ///
  /// In ru, this message translates to:
  /// **'До ближайшего'**
  String get prodRoundNearest;

  /// No description provided for @prodRoundUp.
  ///
  /// In ru, this message translates to:
  /// **'Вверх'**
  String get prodRoundUp;

  /// No description provided for @prodRoundDown.
  ///
  /// In ru, this message translates to:
  /// **'Вниз'**
  String get prodRoundDown;

  /// No description provided for @prodRoundNone.
  ///
  /// In ru, this message translates to:
  /// **'Без округления'**
  String get prodRoundNone;

  /// No description provided for @prodRoundTo.
  ///
  /// In ru, this message translates to:
  /// **'До {amount}'**
  String prodRoundTo(String amount);

  /// No description provided for @prodStockAll.
  ///
  /// In ru, this message translates to:
  /// **'Все остатки'**
  String get prodStockAll;

  /// No description provided for @prodStockIn.
  ///
  /// In ru, this message translates to:
  /// **'В наличии'**
  String get prodStockIn;

  /// No description provided for @prodStockLow.
  ///
  /// In ru, this message translates to:
  /// **'Мало'**
  String get prodStockLow;

  /// No description provided for @prodStockOut.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get prodStockOut;

  /// No description provided for @prodStockNegative.
  ///
  /// In ru, this message translates to:
  /// **'Минус'**
  String get prodStockNegative;

  /// No description provided for @prodActive.
  ///
  /// In ru, this message translates to:
  /// **'Активные'**
  String get prodActive;

  /// No description provided for @prodArchive.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get prodArchive;

  /// No description provided for @prodSortName.
  ///
  /// In ru, this message translates to:
  /// **'По названию'**
  String get prodSortName;

  /// No description provided for @prodSortPrice.
  ///
  /// In ru, this message translates to:
  /// **'По цене'**
  String get prodSortPrice;

  /// No description provided for @prodSortStock.
  ///
  /// In ru, this message translates to:
  /// **'По остатку'**
  String get prodSortStock;

  /// No description provided for @prodSortMargin.
  ///
  /// In ru, this message translates to:
  /// **'По марже'**
  String get prodSortMargin;

  /// No description provided for @prodSortUpdated.
  ///
  /// In ru, this message translates to:
  /// **'По изменению'**
  String get prodSortUpdated;

  /// No description provided for @prodUnitShort.
  ///
  /// In ru, this message translates to:
  /// **'Ед.'**
  String get prodUnitShort;

  /// No description provided for @prodDelimTab.
  ///
  /// In ru, this message translates to:
  /// **'табуляция'**
  String get prodDelimTab;

  /// No description provided for @prodDelimSemicolon.
  ///
  /// In ru, this message translates to:
  /// **'точка с запятой'**
  String get prodDelimSemicolon;

  /// No description provided for @prodDelimComma.
  ///
  /// In ru, this message translates to:
  /// **'запятая'**
  String get prodDelimComma;

  /// No description provided for @prodImpErrMissing.
  ///
  /// In ru, this message translates to:
  /// **'{field}: не указана'**
  String prodImpErrMissing(String field);

  /// No description provided for @prodImpErrNegative.
  ///
  /// In ru, this message translates to:
  /// **'{field}: не может быть отрицательной'**
  String prodImpErrNegative(String field);

  /// No description provided for @prodImpErrNotNumber.
  ///
  /// In ru, this message translates to:
  /// **'{field}: «{value}» — не число'**
  String prodImpErrNotNumber(String field, String value);

  /// No description provided for @prodImpErrNoName.
  ///
  /// In ru, this message translates to:
  /// **'Не указано название'**
  String get prodImpErrNoName;

  /// No description provided for @prodNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Название длиннее 200 символов'**
  String get prodNameTooLong;

  /// No description provided for @prodImpErrBarcodeSci.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод «{code}» испорчен Excel (экспоненциальный формат)'**
  String prodImpErrBarcodeSci(String code);

  /// No description provided for @prodImpErrBarcodeDup.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод {code} повторяется (строка {line})'**
  String prodImpErrBarcodeDup(String code, String line);

  /// No description provided for @prodEan13BadCheck.
  ///
  /// In ru, this message translates to:
  /// **'Неверная контрольная цифра EAN-13'**
  String get prodEan13BadCheck;

  /// No description provided for @prodImpErrUnit.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ед. изм. «{unit}» (шт, кг, г, л, м, уп)'**
  String prodImpErrUnit(String unit);

  /// No description provided for @prodImpErrStockNotNumber.
  ///
  /// In ru, this message translates to:
  /// **'Остаток: «{value}» — не число'**
  String prodImpErrStockNotNumber(String value);

  /// No description provided for @prodImpErrStockNegative.
  ///
  /// In ru, this message translates to:
  /// **'Остаток не может быть отрицательным'**
  String get prodImpErrStockNegative;

  /// No description provided for @prodImpErrStockInteger.
  ///
  /// In ru, this message translates to:
  /// **'Остаток для «{unit}» должен быть целым'**
  String prodImpErrStockInteger(String unit);

  /// No description provided for @prodPriceBelowCost.
  ///
  /// In ru, this message translates to:
  /// **'Цена ниже себестоимости'**
  String get prodPriceBelowCost;

  /// No description provided for @prodMoveReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get prodMoveReceipt;

  /// No description provided for @prodMoveReceiptReversal.
  ///
  /// In ru, this message translates to:
  /// **'Сторно прихода'**
  String get prodMoveReceiptReversal;

  /// No description provided for @prodMoveWriteoff.
  ///
  /// In ru, this message translates to:
  /// **'Списание'**
  String get prodMoveWriteoff;

  /// No description provided for @prodMoveAdjustment.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка'**
  String get prodMoveAdjustment;

  /// No description provided for @prodMoveInventory.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация'**
  String get prodMoveInventory;

  /// No description provided for @prodMoveTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Перемещение'**
  String get prodMoveTransfer;

  /// No description provided for @prodErrEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название товара'**
  String get prodErrEnterName;

  /// No description provided for @prodErrPriceNegative.
  ///
  /// In ru, this message translates to:
  /// **'Цена не может быть отрицательной'**
  String get prodErrPriceNegative;

  /// No description provided for @prodErrCostNegative.
  ///
  /// In ru, this message translates to:
  /// **'Себестоимость не может быть отрицательной'**
  String get prodErrCostNegative;

  /// No description provided for @prodErrWholesaleNegative.
  ///
  /// In ru, this message translates to:
  /// **'Оптовая цена не может быть отрицательной'**
  String get prodErrWholesaleNegative;

  /// No description provided for @prodErrVatRange.
  ///
  /// In ru, this message translates to:
  /// **'НДС должен быть от 0 до 100%'**
  String get prodErrVatRange;

  /// No description provided for @prodErrMinStockNegative.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный остаток не может быть отрицательным'**
  String get prodErrMinStockNegative;

  /// No description provided for @prodErrInitStockNegative.
  ///
  /// In ru, this message translates to:
  /// **'Начальный остаток не может быть отрицательным'**
  String get prodErrInitStockNegative;

  /// No description provided for @prodErrBarcodeUsedBy.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод {code} уже используется товаром «{name}»'**
  String prodErrBarcodeUsedBy(String code, String name);

  /// No description provided for @prodErrInitStockInteger.
  ///
  /// In ru, this message translates to:
  /// **'Начальный остаток для «{unit}» должен быть целым'**
  String prodErrInitStockInteger(String unit);

  /// No description provided for @prodNoPricePerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права менять цены'**
  String get prodNoPricePerm;

  /// No description provided for @prodErrBarcodeUsedOther.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод {code} уже используется другим товаром'**
  String prodErrBarcodeUsedOther(String code);

  /// No description provided for @prodErrAlreadyDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар уже удалён'**
  String get prodErrAlreadyDeleted;

  /// No description provided for @prodErrFractionalStock.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {qty} дробный — сначала исправьте его в разделе «Склад», затем меняйте единицу на «{unit}»'**
  String prodErrFractionalStock(String qty, String unit);

  /// No description provided for @prodErrHasHistory.
  ///
  /// In ru, this message translates to:
  /// **'По товару есть операции (продажи, движения). Его можно только архивировать.'**
  String get prodErrHasHistory;

  /// No description provided for @prodErrPriceNegativeFor.
  ///
  /// In ru, this message translates to:
  /// **'Цена не может быть отрицательной: {name}'**
  String prodErrPriceNegativeFor(String name);

  /// No description provided for @prodErrEnterCategoryName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название категории'**
  String get prodErrEnterCategoryName;

  /// No description provided for @prodErrCategoryNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Название длиннее 120 символов'**
  String get prodErrCategoryNameTooLong;

  /// No description provided for @prodErrCategoryExists.
  ///
  /// In ru, this message translates to:
  /// **'Категория «{name}» уже существует'**
  String prodErrCategoryExists(String name);

  /// No description provided for @prodErrCategoryInUse.
  ///
  /// In ru, this message translates to:
  /// **'В категории {count} товаров — выберите, куда их перенести'**
  String prodErrCategoryInUse(String count);

  /// No description provided for @prodErrPickOtherCategory.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другую категорию'**
  String get prodErrPickOtherCategory;

  /// No description provided for @prodImpNoteStockUnchanged.
  ///
  /// In ru, this message translates to:
  /// **'Остаток не меняется — используйте «Склад»'**
  String get prodImpNoteStockUnchanged;

  /// No description provided for @prodImpNoteBarcodeTaken.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод уже у товара «{name}»'**
  String prodImpNoteBarcodeTaken(String name);

  /// No description provided for @prodNotFoundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товар не найден'**
  String get prodNotFoundTitle;

  /// No description provided for @prodBarcodeNotInCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкода {code} нет в каталоге. Создать новый товар с этим штрихкодом?'**
  String prodBarcodeNotInCatalog(String code);

  /// No description provided for @prodCategories.
  ///
  /// In ru, this message translates to:
  /// **'Категории'**
  String get prodCategories;

  /// No description provided for @prodImportFromCsv.
  ///
  /// In ru, this message translates to:
  /// **'Импорт из CSV'**
  String get prodImportFromCsv;

  /// No description provided for @prodExportToCsv.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт в CSV'**
  String get prodExportToCsv;

  /// No description provided for @prodByCurrentFilter.
  ///
  /// In ru, this message translates to:
  /// **'по текущему фильтру'**
  String get prodByCurrentFilter;

  /// No description provided for @prodWholeCatalog.
  ///
  /// In ru, this message translates to:
  /// **'весь каталог'**
  String get prodWholeCatalog;

  /// No description provided for @prodNewProduct.
  ///
  /// In ru, this message translates to:
  /// **'Новый товар'**
  String get prodNewProduct;

  /// No description provided for @prodNoCategory.
  ///
  /// In ru, this message translates to:
  /// **'Без категории'**
  String get prodNoCategory;

  /// No description provided for @prodSearchHintShort.
  ///
  /// In ru, this message translates to:
  /// **'Название, артикул, штрихкод'**
  String get prodSearchHintShort;

  /// No description provided for @prodSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, артикул или штрихкод (Ctrl+F)'**
  String get prodSearchHint;

  /// No description provided for @prodAllCategories.
  ///
  /// In ru, this message translates to:
  /// **'Все категории'**
  String get prodAllCategories;

  /// No description provided for @prodFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранные'**
  String get prodFavorites;

  /// No description provided for @prodSortTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка (повторный выбор — обратный порядок)'**
  String get prodSortTooltip;

  /// No description provided for @prodCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Товаров: {count}'**
  String prodCountLabel(String count);

  /// No description provided for @prodSelect.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get prodSelect;

  /// No description provided for @prodNoEditPerm.
  ///
  /// In ru, this message translates to:
  /// **'Нет права редактировать товары'**
  String get prodNoEditPerm;

  /// No description provided for @prodPricesPercent.
  ///
  /// In ru, this message translates to:
  /// **'Цены, %'**
  String get prodPricesPercent;

  /// No description provided for @prodPriceLabels.
  ///
  /// In ru, this message translates to:
  /// **'Ценники'**
  String get prodPriceLabels;

  /// No description provided for @prodToArchive.
  ///
  /// In ru, this message translates to:
  /// **'В архив'**
  String get prodToArchive;

  /// No description provided for @prodRestore.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть'**
  String get prodRestore;

  /// No description provided for @prodCancelSelection.
  ///
  /// In ru, this message translates to:
  /// **'Отменить выбор (Esc)'**
  String get prodCancelSelection;

  /// No description provided for @prodSelectedCount.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано: {count}'**
  String prodSelectedCount(String count);

  /// No description provided for @prodTryOtherFilters.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить фильтры'**
  String get prodTryOtherFilters;

  /// No description provided for @prodNoResultsFor.
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» товаров нет'**
  String prodNoResultsFor(String query);

  /// No description provided for @prodResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get prodResetFilters;

  /// No description provided for @prodCatalogEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Каталог пуст'**
  String get prodCatalogEmpty;

  /// No description provided for @prodEmptyHintEditor.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первый товар или загрузите список из Excel (CSV).'**
  String get prodEmptyHintEditor;

  /// No description provided for @prodEmptyHintViewer.
  ///
  /// In ru, this message translates to:
  /// **'Товары добавляет менеджер или администратор.'**
  String get prodEmptyHintViewer;

  /// No description provided for @prodImportCsv.
  ///
  /// In ru, this message translates to:
  /// **'Импорт CSV'**
  String get prodImportCsv;

  /// No description provided for @prodStockUntracked.
  ///
  /// In ru, this message translates to:
  /// **'Остаток не учитывается'**
  String get prodStockUntracked;

  /// No description provided for @prodStockLowTip.
  ///
  /// In ru, this message translates to:
  /// **'Мало: минимум {qty}'**
  String prodStockLowTip(String qty);

  /// No description provided for @prodStockNegativeTip.
  ///
  /// In ru, this message translates to:
  /// **'Отрицательный остаток — проверьте приход/инвентаризацию'**
  String get prodStockNegativeTip;

  /// No description provided for @prodSkuShort.
  ///
  /// In ru, this message translates to:
  /// **'арт. {sku}'**
  String prodSkuShort(String sku);

  /// No description provided for @prodCostShort.
  ///
  /// In ru, this message translates to:
  /// **'Себест.'**
  String get prodCostShort;

  /// No description provided for @prodMargin.
  ///
  /// In ru, this message translates to:
  /// **'Маржа'**
  String get prodMargin;

  /// No description provided for @prodArchiveOneQ.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать товар?'**
  String get prodArchiveOneQ;

  /// No description provided for @prodArchiveManyQ.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать товары ({count})?'**
  String prodArchiveManyQ(String count);

  /// No description provided for @prodArchiveMessage.
  ///
  /// In ru, this message translates to:
  /// **'Архивные товары не продаются и не видны на кассе. История продаж сохраняется. Вернуть можно в любой момент (фильтр «Архив»).'**
  String get prodArchiveMessage;

  /// No description provided for @prodRestored.
  ///
  /// In ru, this message translates to:
  /// **'Товары возвращены в продажу'**
  String get prodRestored;

  /// No description provided for @prodArchived.
  ///
  /// In ru, this message translates to:
  /// **'Перемещено в архив'**
  String get prodArchived;

  /// No description provided for @prodCannotDeleteArchived.
  ///
  /// In ru, this message translates to:
  /// **'По товару есть операции — удалить нельзя, он уже в архиве'**
  String get prodCannotDeleteArchived;

  /// No description provided for @prodCannotDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить нельзя'**
  String get prodCannotDeleteTitle;

  /// No description provided for @prodCannotDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'По товару «{name}» есть продажи или движения по складу — для отчётов он должен остаться в базе. Переместить его в архив?'**
  String prodCannotDeleteMessage(String name);

  /// No description provided for @prodMovedToArchive.
  ///
  /// In ru, this message translates to:
  /// **'Товар перемещён в архив'**
  String get prodMovedToArchive;

  /// No description provided for @prodDeleteQ.
  ///
  /// In ru, this message translates to:
  /// **'Удалить «{name}»?'**
  String prodDeleteQ(String name);

  /// No description provided for @prodDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Товар без операций будет удалён из каталога.'**
  String get prodDeleteMessage;

  /// No description provided for @prodDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get prodDeleted;

  /// No description provided for @prodNotFoundOrDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар не найден или удалён'**
  String get prodNotFoundOrDeleted;

  /// No description provided for @prodPriceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ценник'**
  String get prodPriceLabel;

  /// No description provided for @prodDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Дублировать'**
  String get prodDuplicate;

  /// No description provided for @prodUnfavorited.
  ///
  /// In ru, this message translates to:
  /// **'Убрано из избранного'**
  String get prodUnfavorited;

  /// No description provided for @prodFavorited.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get prodFavorited;

  /// No description provided for @prodUnfavorite.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get prodUnfavorite;

  /// No description provided for @prodFavorite.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get prodFavorite;

  /// No description provided for @prodRestoreFromArchive.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть из архива'**
  String get prodRestoreFromArchive;

  /// No description provided for @prodFavoriteChip.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get prodFavoriteChip;

  /// No description provided for @prodNoStockTracking.
  ///
  /// In ru, this message translates to:
  /// **'Без учёта остатка'**
  String get prodNoStockTracking;

  /// No description provided for @prodNoReceiptsYet.
  ///
  /// In ru, this message translates to:
  /// **'приходов не было'**
  String get prodNoReceiptsYet;

  /// No description provided for @prodToday.
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get prodToday;

  /// No description provided for @prodDaysAgo.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн. назад'**
  String prodDaysAgo(String days);

  /// No description provided for @prodWholesaleShort.
  ///
  /// In ru, this message translates to:
  /// **'опт. {price}'**
  String prodWholesaleShort(String price);

  /// No description provided for @prodPerUnit.
  ///
  /// In ru, this message translates to:
  /// **'за 1 {unit}'**
  String prodPerUnit(String unit);

  /// No description provided for @prodMarginLower.
  ///
  /// In ru, this message translates to:
  /// **'маржа {pct}'**
  String prodMarginLower(String pct);

  /// No description provided for @prodUntrackedLower.
  ///
  /// In ru, this message translates to:
  /// **'без учёта'**
  String get prodUntrackedLower;

  /// No description provided for @prodMinShort.
  ///
  /// In ru, this message translates to:
  /// **'мин. {qty}'**
  String prodMinShort(String qty);

  /// No description provided for @prodMinNotSet.
  ///
  /// In ru, this message translates to:
  /// **'минимум не задан'**
  String get prodMinNotSet;

  /// No description provided for @prodSold.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get prodSold;

  /// No description provided for @prodLast30Days.
  ///
  /// In ru, this message translates to:
  /// **'за 30 дней'**
  String get prodLast30Days;

  /// No description provided for @prodLast30DaysReceipts.
  ///
  /// In ru, this message translates to:
  /// **'за 30 дней · чеков: {count}'**
  String prodLast30DaysReceipts(String count);

  /// No description provided for @prodRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get prodRevenue;

  /// No description provided for @prodLastReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Последний приход'**
  String get prodLastReceipt;

  /// No description provided for @prodSpecs.
  ///
  /// In ru, this message translates to:
  /// **'Характеристики'**
  String get prodSpecs;

  /// No description provided for @prodWholesalePrice.
  ///
  /// In ru, this message translates to:
  /// **'Оптовая цена'**
  String get prodWholesalePrice;

  /// No description provided for @prodNoVatLower.
  ///
  /// In ru, this message translates to:
  /// **'без НДС'**
  String get prodNoVatLower;

  /// No description provided for @prodNegativeSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажа в минус'**
  String get prodNegativeSale;

  /// No description provided for @prodAllowed.
  ///
  /// In ru, this message translates to:
  /// **'разрешена'**
  String get prodAllowed;

  /// No description provided for @prodForbidden.
  ///
  /// In ru, this message translates to:
  /// **'запрещена'**
  String get prodForbidden;

  /// No description provided for @prodWarranty.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия'**
  String get prodWarranty;

  /// No description provided for @prodNoneLower.
  ///
  /// In ru, this message translates to:
  /// **'нет'**
  String get prodNoneLower;

  /// No description provided for @prodMonthsShort.
  ///
  /// In ru, this message translates to:
  /// **'{count} мес.'**
  String prodMonthsShort(String count);

  /// No description provided for @prodUpdatedAt.
  ///
  /// In ru, this message translates to:
  /// **'Изменён'**
  String get prodUpdatedAt;

  /// No description provided for @prodMovements.
  ///
  /// In ru, this message translates to:
  /// **'Движение товара'**
  String get prodMovements;

  /// No description provided for @prodLast50.
  ///
  /// In ru, this message translates to:
  /// **'последние 50'**
  String get prodLast50;

  /// No description provided for @prodNoMovements.
  ///
  /// In ru, this message translates to:
  /// **'Движений пока не было. Приход оформляется в разделе «Склад» или «Закупки».'**
  String get prodNoMovements;

  /// No description provided for @prodStockAfterShort.
  ///
  /// In ru, this message translates to:
  /// **'ост. {qty}'**
  String prodStockAfterShort(String qty);

  /// No description provided for @prodCopySuffix.
  ///
  /// In ru, this message translates to:
  /// **'{name} (копия)'**
  String prodCopySuffix(String name);

  /// No description provided for @prodReplaceBarcodeQ.
  ///
  /// In ru, this message translates to:
  /// **'Заменить штрихкод?'**
  String get prodReplaceBarcodeQ;

  /// No description provided for @prodReplaceBarcodeMessage.
  ///
  /// In ru, this message translates to:
  /// **'Текущий штрихкод {code} будет заменён внутренним. Старые этикетки перестанут сканироваться.'**
  String prodReplaceBarcodeMessage(String code);

  /// No description provided for @prodReplace.
  ///
  /// In ru, this message translates to:
  /// **'Заменить'**
  String get prodReplace;

  /// No description provided for @prodCloseUnsavedQ.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть без сохранения?'**
  String get prodCloseUnsavedQ;

  /// No description provided for @prodUnsavedLost.
  ///
  /// In ru, this message translates to:
  /// **'Внесённые изменения будут потеряны.'**
  String get prodUnsavedLost;

  /// No description provided for @prodCheckFields.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте выделенные поля'**
  String get prodCheckFields;

  /// No description provided for @prodBarcodeInUseBy.
  ///
  /// In ru, this message translates to:
  /// **'Уже используется: «{name}»'**
  String prodBarcodeInUseBy(String name);

  /// No description provided for @prodBarcodeAssignedTo.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод {code} уже присвоен товару «{name}»'**
  String prodBarcodeAssignedTo(String code, String name);

  /// No description provided for @prodPriceBelowCostMessage.
  ///
  /// In ru, this message translates to:
  /// **'Цена {price} меньше себестоимости {cost}. Каждая продажа будет убыточной. Сохранить?'**
  String prodPriceBelowCostMessage(String price, String cost);

  /// No description provided for @prodZeroPrice.
  ///
  /// In ru, this message translates to:
  /// **'Нулевая цена'**
  String get prodZeroPrice;

  /// No description provided for @prodZeroPriceMessage.
  ///
  /// In ru, this message translates to:
  /// **'Товар будет продаваться бесплатно. Продолжить?'**
  String get prodZeroPriceMessage;

  /// No description provided for @prodCreated.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{name}» создан'**
  String prodCreated(String name);

  /// No description provided for @prodChangesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Изменения сохранены'**
  String get prodChangesSaved;

  /// No description provided for @prodCopyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Копия товара'**
  String get prodCopyTitle;

  /// No description provided for @prodEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование товара'**
  String get prodEditTitle;

  /// No description provided for @prodCreateProduct.
  ///
  /// In ru, this message translates to:
  /// **'Создать товар'**
  String get prodCreateProduct;

  /// No description provided for @prodCloseEsc.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть (Esc)'**
  String get prodCloseEsc;

  /// No description provided for @prodEditorShortcuts.
  ///
  /// In ru, this message translates to:
  /// **'Ctrl+S — сохранить, Esc — закрыть'**
  String get prodEditorShortcuts;

  /// No description provided for @prodSectionBasic.
  ///
  /// In ru, this message translates to:
  /// **'Основное'**
  String get prodSectionBasic;

  /// No description provided for @prodNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Название *'**
  String get prodNameRequired;

  /// No description provided for @prodNewCategory.
  ///
  /// In ru, this message translates to:
  /// **'Новая категория'**
  String get prodNewCategory;

  /// No description provided for @prodUnitLabel.
  ///
  /// In ru, this message translates to:
  /// **'Единица измерения'**
  String get prodUnitLabel;

  /// No description provided for @prodFractionalHint.
  ///
  /// In ru, this message translates to:
  /// **'Дробное количество (весовой товар)'**
  String get prodFractionalHint;

  /// No description provided for @prodDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get prodDescription;

  /// No description provided for @prodActiveSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Активен (продаётся)'**
  String get prodActiveSwitch;

  /// No description provided for @prodFavoriteSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Избранное на кассе'**
  String get prodFavoriteSwitch;

  /// No description provided for @prodSectionPrices.
  ///
  /// In ru, this message translates to:
  /// **'Цены'**
  String get prodSectionPrices;

  /// No description provided for @prodRetailPriceRequired.
  ///
  /// In ru, this message translates to:
  /// **'Розничная цена *'**
  String get prodRetailPriceRequired;

  /// No description provided for @prodRetailPrice.
  ///
  /// In ru, this message translates to:
  /// **'Розничная цена'**
  String get prodRetailPrice;

  /// No description provided for @prodCostHintNew.
  ///
  /// In ru, this message translates to:
  /// **'Для начального остатка'**
  String get prodCostHintNew;

  /// No description provided for @prodCostHintAvg.
  ///
  /// In ru, this message translates to:
  /// **'Средняя, по приходам'**
  String get prodCostHintAvg;

  /// No description provided for @prodMarginColon.
  ///
  /// In ru, this message translates to:
  /// **'Маржа: '**
  String get prodMarginColon;

  /// No description provided for @prodMarkupColon.
  ///
  /// In ru, this message translates to:
  /// **'Наценка: '**
  String get prodMarkupColon;

  /// No description provided for @prodProfitPerUnitColon.
  ///
  /// In ru, this message translates to:
  /// **'Прибыль с единицы: '**
  String get prodProfitPerUnitColon;

  /// No description provided for @prodVatIncluded.
  ///
  /// In ru, this message translates to:
  /// **'НДС (включён в цену)'**
  String get prodVatIncluded;

  /// No description provided for @prodNoVat.
  ///
  /// In ru, this message translates to:
  /// **'Без НДС'**
  String get prodNoVat;

  /// No description provided for @prodVatOther.
  ///
  /// In ru, this message translates to:
  /// **'Другой'**
  String get prodVatOther;

  /// No description provided for @prodInternalEan.
  ///
  /// In ru, this message translates to:
  /// **'Внутренний EAN-13'**
  String get prodInternalEan;

  /// No description provided for @prodSectionCodes.
  ///
  /// In ru, this message translates to:
  /// **'Коды'**
  String get prodSectionCodes;

  /// No description provided for @prodScanOrType.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте или введите'**
  String get prodScanOrType;

  /// No description provided for @prodGenerateBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Сгенерировать внутренний EAN-13 (префикс 200)'**
  String get prodGenerateBarcode;

  /// No description provided for @prodBarcodeTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Слишком длинный штрихкод'**
  String get prodBarcodeTooLong;

  /// No description provided for @prodBarcodeNoSpaces.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод не должен содержать пробелы'**
  String get prodBarcodeNoSpaces;

  /// No description provided for @prodSkuLabel.
  ///
  /// In ru, this message translates to:
  /// **'Артикул (SKU)'**
  String get prodSkuLabel;

  /// No description provided for @prodSkuFree.
  ///
  /// In ru, this message translates to:
  /// **'Свободный: {sku}'**
  String prodSkuFree(String sku);

  /// No description provided for @prodSkuUse.
  ///
  /// In ru, this message translates to:
  /// **'Подставить {sku}'**
  String prodSkuUse(String sku);

  /// No description provided for @prodSectionStock.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get prodSectionStock;

  /// No description provided for @prodTrackStock.
  ///
  /// In ru, this message translates to:
  /// **'Учитывать остаток'**
  String get prodTrackStock;

  /// No description provided for @prodAllowNegative.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить продажу в минус'**
  String get prodAllowNegative;

  /// No description provided for @prodMinStock.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный остаток'**
  String get prodMinStock;

  /// No description provided for @prodMinStockHint.
  ///
  /// In ru, this message translates to:
  /// **'Ниже — товар помечается «Мало»'**
  String get prodMinStockHint;

  /// No description provided for @prodEnterNonNegative.
  ///
  /// In ru, this message translates to:
  /// **'Введите число ≥ 0'**
  String get prodEnterNonNegative;

  /// No description provided for @prodInitialStock.
  ///
  /// In ru, this message translates to:
  /// **'Начальный остаток'**
  String get prodInitialStock;

  /// No description provided for @prodInitialStockHint.
  ///
  /// In ru, this message translates to:
  /// **'Оприходуется как «Начальный остаток»'**
  String get prodInitialStockHint;

  /// No description provided for @prodCurrentStock.
  ///
  /// In ru, this message translates to:
  /// **'Текущий остаток'**
  String get prodCurrentStock;

  /// No description provided for @prodCurrentStockHint.
  ///
  /// In ru, this message translates to:
  /// **'Изменяется в разделе «Склад»: приход, списание, инвентаризация'**
  String get prodCurrentStockHint;

  /// No description provided for @prodSectionWarranty.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия и поставщик'**
  String get prodSectionWarranty;

  /// No description provided for @prodMonthsSuffix.
  ///
  /// In ru, this message translates to:
  /// **'мес.'**
  String get prodMonthsSuffix;

  /// No description provided for @prodWarrantyHint.
  ///
  /// In ru, this message translates to:
  /// **'0 — без гарантии'**
  String get prodWarrantyHint;

  /// No description provided for @prodWarrantyRange.
  ///
  /// In ru, this message translates to:
  /// **'От 0 до 240 месяцев'**
  String get prodWarrantyRange;

  /// No description provided for @prodSuppliersHint.
  ///
  /// In ru, this message translates to:
  /// **'Поставщики добавляются в разделе «Закупки»'**
  String get prodSuppliersHint;

  /// No description provided for @prodNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указан'**
  String get prodNotSpecified;

  /// No description provided for @prodUnitNamePcs.
  ///
  /// In ru, this message translates to:
  /// **'Штука (шт)'**
  String get prodUnitNamePcs;

  /// No description provided for @prodUnitNameKg.
  ///
  /// In ru, this message translates to:
  /// **'Килограмм (кг)'**
  String get prodUnitNameKg;

  /// No description provided for @prodUnitNameG.
  ///
  /// In ru, this message translates to:
  /// **'Грамм (г)'**
  String get prodUnitNameG;

  /// No description provided for @prodUnitNameL.
  ///
  /// In ru, this message translates to:
  /// **'Литр (л)'**
  String get prodUnitNameL;

  /// No description provided for @prodUnitNameM.
  ///
  /// In ru, this message translates to:
  /// **'Метр (м)'**
  String get prodUnitNameM;

  /// No description provided for @prodUnitNamePack.
  ///
  /// In ru, this message translates to:
  /// **'Упаковка (уп)'**
  String get prodUnitNamePack;

  /// No description provided for @prodBulkCategoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Категория для {count} товаров'**
  String prodBulkCategoryTitle(String count);

  /// No description provided for @prodBulkCategoryDone.
  ///
  /// In ru, this message translates to:
  /// **'Категория изменена у {count} товаров'**
  String prodBulkCategoryDone(String count);

  /// No description provided for @prodBulkPriceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цены на %'**
  String get prodBulkPriceTitle;

  /// No description provided for @prodBulkPctError.
  ///
  /// In ru, this message translates to:
  /// **'Введите процент от −99 до 1000, например 10 или −5'**
  String get prodBulkPctError;

  /// No description provided for @prodBulkNoChange.
  ///
  /// In ru, this message translates to:
  /// **'Цены не изменятся — попробуйте другой процент или округление'**
  String get prodBulkNoChange;

  /// No description provided for @prodBulkPriceConfirmQ.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цены у {count} товаров?'**
  String prodBulkPriceConfirmQ(String count);

  /// No description provided for @prodBulkPriceConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Каждое изменение будет записано в журнал аудита. Ценники нужно будет перепечатать.'**
  String get prodBulkPriceConfirmMessage;

  /// No description provided for @prodChangePrices.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цены'**
  String get prodChangePrices;

  /// No description provided for @prodBulkPriceDone.
  ///
  /// In ru, this message translates to:
  /// **'Цены обновлены у {count} товаров'**
  String prodBulkPriceDone(String count);

  /// No description provided for @prodChangePct.
  ///
  /// In ru, this message translates to:
  /// **'Изменение, %'**
  String get prodChangePct;

  /// No description provided for @prodChangePctHint.
  ///
  /// In ru, this message translates to:
  /// **'например 10 или -5'**
  String get prodChangePctHint;

  /// No description provided for @prodChangePctHelper.
  ///
  /// In ru, this message translates to:
  /// **'Плюс — подорожание, минус — скидка'**
  String get prodChangePctHelper;

  /// No description provided for @prodChangePctRange.
  ///
  /// In ru, this message translates to:
  /// **'От −99 до 1000'**
  String get prodChangePctRange;

  /// No description provided for @prodRounding.
  ///
  /// In ru, this message translates to:
  /// **'Округление'**
  String get prodRounding;

  /// No description provided for @prodWillChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменится: {count}'**
  String prodWillChange(String count);

  /// No description provided for @prodBelowCostCount.
  ///
  /// In ru, this message translates to:
  /// **'Ниже себестоимости: {count}'**
  String prodBelowCostCount(String count);

  /// No description provided for @prodCostMarginLine.
  ///
  /// In ru, this message translates to:
  /// **'себест. {cost} · маржа {margin}'**
  String prodCostMarginLine(String cost, String margin);

  /// No description provided for @prodApplyTo.
  ///
  /// In ru, this message translates to:
  /// **'Применить к {count}'**
  String prodApplyTo(String count);

  /// No description provided for @prodErrEnterNameShort.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get prodErrEnterNameShort;

  /// No description provided for @prodColor.
  ///
  /// In ru, this message translates to:
  /// **'Цвет'**
  String get prodColor;

  /// No description provided for @prodDeleteCategoryQ.
  ///
  /// In ru, this message translates to:
  /// **'Удалить категорию «{name}»?'**
  String prodDeleteCategoryQ(String name);

  /// No description provided for @prodCategoryEmptyMsg.
  ///
  /// In ru, this message translates to:
  /// **'В категории нет товаров.'**
  String get prodCategoryEmptyMsg;

  /// No description provided for @prodCategoryDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Категория удалена'**
  String get prodCategoryDeleted;

  /// No description provided for @prodCategoryMoveQ.
  ///
  /// In ru, this message translates to:
  /// **'В категории {count} товаров. Куда их перенести?'**
  String prodCategoryMoveQ(String count);

  /// No description provided for @prodMoveTo.
  ///
  /// In ru, this message translates to:
  /// **'Перенести в'**
  String get prodMoveTo;

  /// No description provided for @prodMoveAndDelete.
  ///
  /// In ru, this message translates to:
  /// **'Перенести и удалить'**
  String get prodMoveAndDelete;

  /// No description provided for @prodCategoryDeletedMoved.
  ///
  /// In ru, this message translates to:
  /// **'Категория удалена, товары перенесены'**
  String get prodCategoryDeletedMoved;

  /// No description provided for @prodNoCategoriesYet.
  ///
  /// In ru, this message translates to:
  /// **'Категорий пока нет'**
  String get prodNoCategoriesYet;

  /// No description provided for @prodCategoriesHint.
  ///
  /// In ru, this message translates to:
  /// **'Категории помогают быстро находить товары на кассе и в отчётах.'**
  String get prodCategoriesHint;

  /// No description provided for @prodCategoriesFooter.
  ///
  /// In ru, this message translates to:
  /// **'Перетащите, чтобы изменить порядок на кассе. Без категории: {count} товаров.'**
  String prodCategoriesFooter(String count);

  /// No description provided for @prodImportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Импорт товаров из CSV'**
  String get prodImportTitle;

  /// No description provided for @prodImpEnterPath.
  ///
  /// In ru, this message translates to:
  /// **'Введите путь к файлу .csv'**
  String get prodImpEnterPath;

  /// No description provided for @prodImpFileNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Файл не найден: {path}'**
  String prodImpFileNotFound(String path);

  /// No description provided for @prodImpFileTooBig.
  ///
  /// In ru, this message translates to:
  /// **'Файл больше 20 МБ'**
  String get prodImpFileTooBig;

  /// No description provided for @prodImpFileLoaded.
  ///
  /// In ru, this message translates to:
  /// **'Файл загружен: {name}'**
  String prodImpFileLoaded(String name);

  /// No description provided for @prodImpPasteOrLoad.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте данные из Excel или загрузите файл'**
  String get prodImpPasteOrLoad;

  /// No description provided for @prodImpNoRows.
  ///
  /// In ru, this message translates to:
  /// **'Нет строк с данными'**
  String get prodImpNoRows;

  /// No description provided for @prodImpTooManyRows.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много строк ({count}). Разбейте файл на части до 20 000 строк.'**
  String prodImpTooManyRows(String count);

  /// No description provided for @prodImpNothing.
  ///
  /// In ru, this message translates to:
  /// **'Нечего импортировать — исправьте ошибки в данных'**
  String get prodImpNothing;

  /// No description provided for @prodImpDone.
  ///
  /// In ru, this message translates to:
  /// **'Создано {created}, обновлено {updated}'**
  String prodImpDone(String created, String updated);

  /// No description provided for @prodImpDoneSkipped.
  ///
  /// In ru, this message translates to:
  /// **', пропущено {count}'**
  String prodImpDoneSkipped(String count);

  /// No description provided for @prodImpDoneCategories.
  ///
  /// In ru, this message translates to:
  /// **', новых категорий {count}'**
  String prodImpDoneCategories(String count);

  /// No description provided for @prodImpIntro.
  ///
  /// In ru, this message translates to:
  /// **'Скопируйте строки из Excel / Google Таблиц и вставьте ниже, либо укажите путь к файлу .csv. Колонки: название; штрихкод; артикул; категория; цена; себестоимость; ед.; остаток. Заголовок и разделитель (; , табуляция) определяются автоматически.'**
  String get prodImpIntro;

  /// No description provided for @prodImpPasteHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте данные (Ctrl+V)…'**
  String get prodImpPasteHint;

  /// No description provided for @prodImpOrPath.
  ///
  /// In ru, this message translates to:
  /// **'Или путь к файлу'**
  String get prodImpOrPath;

  /// No description provided for @prodImpPathHint.
  ///
  /// In ru, this message translates to:
  /// **'C:\\Users\\...\\товары.csv'**
  String get prodImpPathHint;

  /// No description provided for @prodImpLoad.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get prodImpLoad;

  /// No description provided for @prodImpUpdateExisting.
  ///
  /// In ru, this message translates to:
  /// **'Обновлять существующие товары по штрихкоду'**
  String get prodImpUpdateExisting;

  /// No description provided for @prodImpUpdateExistingHint.
  ///
  /// In ru, this message translates to:
  /// **'Иначе строки с уже известным штрихкодом пропускаются. Остаток существующих товаров не меняется.'**
  String get prodImpUpdateExistingHint;

  /// No description provided for @prodImpSample.
  ///
  /// In ru, this message translates to:
  /// **'Пример'**
  String get prodImpSample;

  /// No description provided for @prodImpCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get prodImpCheck;

  /// No description provided for @prodImpRows.
  ///
  /// In ru, this message translates to:
  /// **'Строк: {count}'**
  String prodImpRows(String count);

  /// No description provided for @prodImpNew.
  ///
  /// In ru, this message translates to:
  /// **'Новых: {count}'**
  String prodImpNew(String count);

  /// No description provided for @prodImpUpdateCount.
  ///
  /// In ru, this message translates to:
  /// **'Обновить: {count}'**
  String prodImpUpdateCount(String count);

  /// No description provided for @prodImpSkipErrors.
  ///
  /// In ru, this message translates to:
  /// **'Пропуск/ошибки: {count}'**
  String prodImpSkipErrors(String count);

  /// No description provided for @prodImpNewCategories.
  ///
  /// In ru, this message translates to:
  /// **'Новых категорий: {count}'**
  String prodImpNewCategories(String count);

  /// No description provided for @prodImpDelimiterWithHeader.
  ///
  /// In ru, this message translates to:
  /// **'Разделитель: {delimiter}, с заголовком'**
  String prodImpDelimiterWithHeader(String delimiter);

  /// No description provided for @prodImpDelimiterNoHeader.
  ///
  /// In ru, this message translates to:
  /// **'Разделитель: {delimiter}, без заголовка'**
  String prodImpDelimiterNoHeader(String delimiter);

  /// No description provided for @prodImpNoPricePerm.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет права менять цены: цены существующих товаров не обновятся.'**
  String get prodImpNoPricePerm;

  /// No description provided for @prodImpUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get prodImpUpdate;

  /// No description provided for @prodImpSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропуск'**
  String get prodImpSkip;

  /// No description provided for @prodImpNoName.
  ///
  /// In ru, this message translates to:
  /// **'(без названия)'**
  String get prodImpNoName;

  /// No description provided for @prodImpBackToData.
  ///
  /// In ru, this message translates to:
  /// **'Назад к данным'**
  String get prodImpBackToData;

  /// No description provided for @prodImpImportN.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать {count}'**
  String prodImpImportN(String count);

  /// No description provided for @prodExpNothing.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров для экспорта по текущему фильтру'**
  String get prodExpNothing;

  /// No description provided for @prodExpFileStem.
  ///
  /// In ru, this message translates to:
  /// **'товары'**
  String get prodExpFileStem;

  /// No description provided for @prodExpDoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировано товаров: {count}'**
  String prodExpDoneTitle(String count);

  /// No description provided for @prodExpCopied.
  ///
  /// In ru, this message translates to:
  /// **'Данные скопированы в буфер обмена — вставьте их в Excel (Ctrl+V).'**
  String get prodExpCopied;

  /// No description provided for @prodExpSaved.
  ///
  /// In ru, this message translates to:
  /// **'Файл сохранён:'**
  String get prodExpSaved;

  /// No description provided for @prodExpSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Файл сохранить не удалось: {error}'**
  String prodExpSaveFailed(String error);

  /// No description provided for @prodExpCopyPath.
  ///
  /// In ru, this message translates to:
  /// **'Копировать путь'**
  String get prodExpCopyPath;

  /// No description provided for @prodLabelSmall.
  ///
  /// In ru, this message translates to:
  /// **'Маленькие 4×10 (52×29 мм)'**
  String get prodLabelSmall;

  /// No description provided for @prodLabelMedium.
  ///
  /// In ru, this message translates to:
  /// **'Средние 3×8 (70×37 мм)'**
  String get prodLabelMedium;

  /// No description provided for @prodLabelLarge.
  ///
  /// In ru, this message translates to:
  /// **'Крупные 2×5 (105×59 мм)'**
  String get prodLabelLarge;

  /// No description provided for @prodPrintLabelsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Печать ценников'**
  String get prodPrintLabelsTitle;

  /// No description provided for @prodCopiesRange.
  ///
  /// In ru, this message translates to:
  /// **'Количество копий — от 1 до 100'**
  String get prodCopiesRange;

  /// No description provided for @prodLabelsIntro.
  ///
  /// In ru, this message translates to:
  /// **'Товаров: {count}. Формат A4, линии реза пунктиром.'**
  String prodLabelsIntro(String count);

  /// No description provided for @prodLabelSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер ценника'**
  String get prodLabelSize;

  /// No description provided for @prodCopiesEach.
  ///
  /// In ru, this message translates to:
  /// **'Копий каждого'**
  String get prodCopiesEach;

  /// No description provided for @prodLabelsTotal.
  ///
  /// In ru, this message translates to:
  /// **'Всего ценников: {total}\nСтраниц A4: {pages}'**
  String prodLabelsTotal(String total, String pages);

  /// No description provided for @prodPrintBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Печатать штрихкод'**
  String get prodPrintBarcode;

  /// No description provided for @prodPreparingPdf.
  ///
  /// In ru, this message translates to:
  /// **'Готовим PDF…'**
  String get prodPreparingPdf;

  /// No description provided for @purActCopied.
  ///
  /// In ru, this message translates to:
  /// **'Акт сверки скопирован — вставьте в Excel'**
  String get purActCopied;

  /// No description provided for @purActCopyCsv.
  ///
  /// In ru, this message translates to:
  /// **'Копировать CSV'**
  String get purActCopyCsv;

  /// No description provided for @purActFilePrefix.
  ///
  /// In ru, this message translates to:
  /// **'Акт_сверки'**
  String get purActFilePrefix;

  /// No description provided for @purActFileSupplier.
  ///
  /// In ru, this message translates to:
  /// **'поставщик'**
  String get purActFileSupplier;

  /// No description provided for @purActLegend.
  ///
  /// In ru, this message translates to:
  /// **'Приход (+) увеличивает долг магазина перед поставщиком, расход (−) уменьшает его. Положительный баланс — долг магазина, отрицательный — аванс у поставщика.'**
  String get purActLegend;

  /// No description provided for @purActPrint.
  ///
  /// In ru, this message translates to:
  /// **'Печать / PDF'**
  String get purActPrint;

  /// No description provided for @purActSaveCsv.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить CSV (Excel)'**
  String get purActSaveCsv;

  /// No description provided for @purActShare.
  ///
  /// In ru, this message translates to:
  /// **'Отправить PDF'**
  String get purActShare;

  /// No description provided for @purActShort.
  ///
  /// In ru, this message translates to:
  /// **'Акт сверки'**
  String get purActShort;

  /// No description provided for @purActTitle.
  ///
  /// In ru, this message translates to:
  /// **'Акт сверки взаиморасчётов'**
  String get purActTitle;

  /// No description provided for @purActive.
  ///
  /// In ru, this message translates to:
  /// **'Активные'**
  String get purActive;

  /// No description provided for @purAddOneProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы один товар'**
  String get purAddOneProduct;

  /// No description provided for @purAddSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Добавить поставщика'**
  String get purAddSupplier;

  /// No description provided for @purAddToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в заказ'**
  String get purAddToOrder;

  /// No description provided for @purAdjustDone.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка {amount} проведена'**
  String purAdjustDone(String amount);

  /// No description provided for @purAdjustReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: по акту сверки от …'**
  String get purAdjustReasonHint;

  /// No description provided for @purAdjustTitle.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка баланса'**
  String get purAdjustTitle;

  /// No description provided for @purAdvanceLower.
  ///
  /// In ru, this message translates to:
  /// **'аванс'**
  String get purAdvanceLower;

  /// No description provided for @purAdvanceLowerValue.
  ///
  /// In ru, this message translates to:
  /// **'аванс {amount}'**
  String purAdvanceLowerValue(String amount);

  /// No description provided for @purAdvanceSuffix.
  ///
  /// In ru, this message translates to:
  /// **'{amount} аванс'**
  String purAdvanceSuffix(String amount);

  /// No description provided for @purAdvanceValue.
  ///
  /// In ru, this message translates to:
  /// **'Аванс у поставщика: {amount}'**
  String purAdvanceValue(String amount);

  /// No description provided for @purAdvanceWithSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Аванс у поставщика'**
  String get purAdvanceWithSupplier;

  /// No description provided for @purAfterAdjust.
  ///
  /// In ru, this message translates to:
  /// **'После корректировки: {value}'**
  String purAfterAdjust(String value);

  /// No description provided for @purAllAsOrdered.
  ///
  /// In ru, this message translates to:
  /// **'Всё по заказу'**
  String get purAllAsOrdered;

  /// No description provided for @purAllReceived.
  ///
  /// In ru, this message translates to:
  /// **'Все позиции заказа уже приняты'**
  String get purAllReceived;

  /// No description provided for @purAllTimeLower.
  ///
  /// In ru, this message translates to:
  /// **'всё время'**
  String get purAllTimeLower;

  /// No description provided for @purAmountRequired.
  ///
  /// In ru, this message translates to:
  /// **'Сумма *'**
  String get purAmountRequired;

  /// No description provided for @purBalanceLower.
  ///
  /// In ru, this message translates to:
  /// **'баланс {value}'**
  String purBalanceLower(String value);

  /// No description provided for @purBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get purBuyer;

  /// No description provided for @purCancelCashHint.
  ///
  /// In ru, this message translates to:
  /// **'Наличную оплату можно отменить только пока открыта её смена.'**
  String get purCancelCashHint;

  /// No description provided for @purCancelOrder.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ'**
  String get purCancelOrder;

  /// No description provided for @purCancelOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ №{number}?'**
  String purCancelOrderTitle(String number);

  /// No description provided for @purCancelPayment.
  ///
  /// In ru, this message translates to:
  /// **'Отменить оплату'**
  String get purCancelPayment;

  /// No description provided for @purCancelPaymentMessage.
  ///
  /// In ru, this message translates to:
  /// **'Оплата от {date} ({method}) останется в истории с отметкой «Отменена», долг поставщику увеличится на эту сумму.'**
  String purCancelPaymentMessage(String date, String method);

  /// No description provided for @purCancelPaymentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить оплату {amount}?'**
  String purCancelPaymentTitle(String amount);

  /// No description provided for @purCancelReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина отмены *'**
  String get purCancelReasonLabel;

  /// No description provided for @purCancelledAt.
  ///
  /// In ru, this message translates to:
  /// **'Отменена {date}'**
  String purCancelledAt(String date);

  /// No description provided for @purCancelledFem.
  ///
  /// In ru, this message translates to:
  /// **'Отменена'**
  String get purCancelledFem;

  /// No description provided for @purCashNeedsShift.
  ///
  /// In ru, this message translates to:
  /// **'Оплата наличными из кассы требует открытой смены. Откройте смену или выберите другой способ.'**
  String get purCashNeedsShift;

  /// No description provided for @purCashOutFromShift.
  ///
  /// In ru, this message translates to:
  /// **'Будет учтено как выплата из кассы смены №{number}'**
  String purCashOutFromShift(String number);

  /// No description provided for @purChangesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Изменения сохранены'**
  String get purChangesSaved;

  /// No description provided for @purCheckPhone.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте номер телефона'**
  String get purCheckPhone;

  /// No description provided for @purChooseAnotherPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой период'**
  String get purChooseAnotherPeriod;

  /// No description provided for @purCloseOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть заказ №{number} без остатка?'**
  String purCloseOrderTitle(String number);

  /// No description provided for @purCloseWithoutRest.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть без остатка'**
  String get purCloseWithoutRest;

  /// No description provided for @purClosingBalance.
  ///
  /// In ru, this message translates to:
  /// **'Сальдо на конец периода'**
  String get purClosingBalance;

  /// No description provided for @purClosingShort.
  ///
  /// In ru, this message translates to:
  /// **'Сальдо на конец'**
  String get purClosingShort;

  /// No description provided for @purConclusionNone.
  ///
  /// In ru, this message translates to:
  /// **'На {at} задолженность между сторонами отсутствует.'**
  String purConclusionNone(String at);

  /// No description provided for @purConclusionStoreOwes.
  ///
  /// In ru, this message translates to:
  /// **'На {at} задолженность «{store}» перед «{supplier}» составляет {amount}.'**
  String purConclusionStoreOwes(
    String at,
    String store,
    String supplier,
    String amount,
  );

  /// No description provided for @purConclusionSupplierOwes.
  ///
  /// In ru, this message translates to:
  /// **'На {at} задолженность «{supplier}» перед «{store}» (аванс) составляет {amount}.'**
  String purConclusionSupplierOwes(
    String at,
    String supplier,
    String store,
    String amount,
  );

  /// No description provided for @purContactPerson.
  ///
  /// In ru, this message translates to:
  /// **'Контактное лицо'**
  String get purContactPerson;

  /// No description provided for @purCoverDays.
  ///
  /// In ru, this message translates to:
  /// **'хватит на {days} дн.'**
  String purCoverDays(String days);

  /// No description provided for @purCreateOrder.
  ///
  /// In ru, this message translates to:
  /// **'Создать заказ'**
  String get purCreateOrder;

  /// No description provided for @purCreateOrders.
  ///
  /// In ru, this message translates to:
  /// **'Создать заказы'**
  String get purCreateOrders;

  /// No description provided for @purCreatedOn.
  ///
  /// In ru, this message translates to:
  /// **'создан {date}'**
  String purCreatedOn(String date);

  /// No description provided for @purDaysShort.
  ///
  /// In ru, this message translates to:
  /// **'{n} дн.'**
  String purDaysShort(String n);

  /// No description provided for @purDaysSuffix.
  ///
  /// In ru, this message translates to:
  /// **'дн.'**
  String get purDaysSuffix;

  /// No description provided for @purDebtOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только с долгом'**
  String get purDebtOnly;

  /// No description provided for @purDecrease.
  ///
  /// In ru, this message translates to:
  /// **'Расход (−)'**
  String get purDecrease;

  /// No description provided for @purDecreaseDebt.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить долг'**
  String get purDecreaseDebt;

  /// No description provided for @purDeleteLine.
  ///
  /// In ru, this message translates to:
  /// **'Удалить строку'**
  String get purDeleteLine;

  /// No description provided for @purDeleteSupplierMessage.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик будет скрыт из списков. История заказов и оплат сохранится.'**
  String get purDeleteSupplierMessage;

  /// No description provided for @purDeleteSupplierTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить поставщика «{name}»?'**
  String purDeleteSupplierTitle(String name);

  /// No description provided for @purDeletedProduct.
  ///
  /// In ru, this message translates to:
  /// **'Удалённый товар'**
  String get purDeletedProduct;

  /// No description provided for @purDeliveryDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата поставки'**
  String get purDeliveryDate;

  /// No description provided for @purDeliveryOn.
  ///
  /// In ru, this message translates to:
  /// **'Поставка {date}'**
  String purDeliveryOn(String date);

  /// No description provided for @purDraftSaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик заказа сохранён'**
  String get purDraftSaved;

  /// No description provided for @purEditorEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары: сканером, кнопкой «Товар» или из вкладки «Автозаказ»'**
  String get purEditorEmptyHint;

  /// No description provided for @purEditorTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого: {amount} · позиций {count}'**
  String purEditorTotal(String amount, String count);

  /// No description provided for @purEnterAdjustReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину корректировки'**
  String get purEnterAdjustReason;

  /// No description provided for @purEnterPrice.
  ///
  /// In ru, this message translates to:
  /// **'Укажите цену'**
  String get purEnterPrice;

  /// No description provided for @purEnterReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину'**
  String get purEnterReason;

  /// No description provided for @purEnterSupplierName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название поставщика'**
  String get purEnterSupplierName;

  /// No description provided for @purErrAddOneProduct.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте в заказ хотя бы один товар'**
  String get purErrAddOneProduct;

  /// No description provided for @purErrAlreadyClosed.
  ///
  /// In ru, this message translates to:
  /// **'Заказ уже закрыт'**
  String get purErrAlreadyClosed;

  /// No description provided for @purErrAlreadySent.
  ///
  /// In ru, this message translates to:
  /// **'Заказ уже отправлен'**
  String get purErrAlreadySent;

  /// No description provided for @purErrDeleteNonZeroBalance.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя удалить поставщика с ненулевым балансом ({balance})'**
  String purErrDeleteNonZeroBalance(String balance);

  /// No description provided for @purErrDuplicateProduct.
  ///
  /// In ru, this message translates to:
  /// **'Товар повторяется в заказе — объедините строки'**
  String get purErrDuplicateProduct;

  /// No description provided for @purErrEnterQtyOneLine.
  ///
  /// In ru, this message translates to:
  /// **'Укажите количество хотя бы по одной позиции'**
  String get purErrEnterQtyOneLine;

  /// No description provided for @purErrLineNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Позиция не найдена в заказе'**
  String get purErrLineNotFound;

  /// No description provided for @purErrLinePriceNegative.
  ///
  /// In ru, this message translates to:
  /// **'«{name}»: цена не может быть отрицательной'**
  String purErrLinePriceNegative(String name);

  /// No description provided for @purErrLineTwice.
  ///
  /// In ru, this message translates to:
  /// **'Позиция заказа указана дважды'**
  String get purErrLineTwice;

  /// No description provided for @purErrNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Название слишком длинное'**
  String get purErrNameTooLong;

  /// No description provided for @purErrNoLines.
  ///
  /// In ru, this message translates to:
  /// **'В заказе нет позиций'**
  String get purErrNoLines;

  /// No description provided for @purErrNothingToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Нет позиций для заказа'**
  String get purErrNothingToOrder;

  /// No description provided for @purErrOnlyDraftEditable.
  ///
  /// In ru, this message translates to:
  /// **'Изменять можно только черновик заказа'**
  String get purErrOnlyDraftEditable;

  /// No description provided for @purErrOrderAlreadyStatus.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number} уже {status}'**
  String purErrOrderAlreadyStatus(String number, String status);

  /// No description provided for @purErrReceiveAtMost.
  ///
  /// In ru, this message translates to:
  /// **'«{name}»: можно принять не больше {qty}'**
  String purErrReceiveAtMost(String name, String qty);

  /// No description provided for @purErrSupplierExists.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик «{name}» уже есть'**
  String purErrSupplierExists(String name);

  /// No description provided for @purErrSupplierHasOpenOrders.
  ///
  /// In ru, this message translates to:
  /// **'У поставщика есть незакрытые заказы ({n})'**
  String purErrSupplierHasOpenOrders(String n);

  /// No description provided for @purErrSupplierNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите название поставщика'**
  String get purErrSupplierNameRequired;

  /// No description provided for @purErrWholeQty.
  ///
  /// In ru, this message translates to:
  /// **'«{name}»: только целое количество'**
  String purErrWholeQty(String name);

  /// No description provided for @purExpectedOn.
  ///
  /// In ru, this message translates to:
  /// **'ожидается {date}'**
  String purExpectedOn(String date);

  /// No description provided for @purFromBuyer.
  ///
  /// In ru, this message translates to:
  /// **'От покупателя'**
  String get purFromBuyer;

  /// No description provided for @purFromSupplier.
  ///
  /// In ru, this message translates to:
  /// **'От поставщика'**
  String get purFromSupplier;

  /// No description provided for @purFullyReceivedSuffix.
  ///
  /// In ru, this message translates to:
  /// **' — заказ получен полностью'**
  String get purFullyReceivedSuffix;

  /// No description provided for @purHeadingAllTime.
  ///
  /// In ru, this message translates to:
  /// **'за {period}'**
  String purHeadingAllTime(String period);

  /// No description provided for @purHeadingPeriod.
  ///
  /// In ru, this message translates to:
  /// **'за период {period}'**
  String purHeadingPeriod(String period);

  /// No description provided for @purIncrease.
  ///
  /// In ru, this message translates to:
  /// **'Приход (+)'**
  String get purIncrease;

  /// No description provided for @purIncreaseDebt.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить долг'**
  String get purIncreaseDebt;

  /// No description provided for @purInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Неверно'**
  String get purInvalid;

  /// No description provided for @purInvoiceShort.
  ///
  /// In ru, this message translates to:
  /// **'накл. {number}'**
  String purInvoiceShort(String number);

  /// No description provided for @purItemProgress.
  ///
  /// In ru, this message translates to:
  /// **'заказано {ordered} · принято {received}'**
  String purItemProgress(String ordered, String received);

  /// No description provided for @purItemRestSuffix.
  ///
  /// In ru, this message translates to:
  /// **' · осталось {qty}'**
  String purItemRestSuffix(String qty);

  /// No description provided for @purLastReceipt.
  ///
  /// In ru, this message translates to:
  /// **'последний приход {date} · приходов {count}'**
  String purLastReceipt(String date, String count);

  /// No description provided for @purLedgerAdjustment.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка'**
  String get purLedgerAdjustment;

  /// No description provided for @purLedgerEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Взаиморасчётов ещё не было'**
  String get purLedgerEmpty;

  /// No description provided for @purLedgerEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся приходы, оплаты и корректировки с текущим балансом'**
  String get purLedgerEmptyMessage;

  /// No description provided for @purLedgerEmptyPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Операций за период нет'**
  String get purLedgerEmptyPeriod;

  /// No description provided for @purLedgerOpNumbered.
  ///
  /// In ru, this message translates to:
  /// **'{op} №{number}'**
  String purLedgerOpNumbered(String op, String number);

  /// No description provided for @purLedgerOpening.
  ///
  /// In ru, this message translates to:
  /// **'Начальный остаток'**
  String get purLedgerOpening;

  /// No description provided for @purLedgerPaymentCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена оплаты'**
  String get purLedgerPaymentCancel;

  /// No description provided for @purLedgerPeriodHelp.
  ///
  /// In ru, this message translates to:
  /// **'Период взаиморасчётов'**
  String get purLedgerPeriodHelp;

  /// No description provided for @purLedgerReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get purLedgerReceipt;

  /// No description provided for @purLedgerReceiptReversal.
  ///
  /// In ru, this message translates to:
  /// **'Сторно прихода'**
  String get purLedgerReceiptReversal;

  /// No description provided for @purMarkOrdered.
  ///
  /// In ru, this message translates to:
  /// **'Отметить заказанным'**
  String get purMarkOrdered;

  /// No description provided for @purMax160Chars.
  ///
  /// In ru, this message translates to:
  /// **'Не длиннее 160 символов'**
  String get purMax160Chars;

  /// No description provided for @purMaxQty.
  ///
  /// In ru, this message translates to:
  /// **'Макс. {qty}'**
  String purMaxQty(String qty);

  /// No description provided for @purMethodTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Перечисление'**
  String get purMethodTransfer;

  /// No description provided for @purMinValue.
  ///
  /// In ru, this message translates to:
  /// **'мин. {qty}'**
  String purMinValue(String qty);

  /// No description provided for @purNameRequiredLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название *'**
  String get purNameRequiredLabel;

  /// No description provided for @purNewOrder.
  ///
  /// In ru, this message translates to:
  /// **'Новый заказ'**
  String get purNewOrder;

  /// No description provided for @purNewPo.
  ///
  /// In ru, this message translates to:
  /// **'Новый заказ поставщику'**
  String get purNewPo;

  /// No description provided for @purNewSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Новый поставщик'**
  String get purNewSupplier;

  /// No description provided for @purNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа'**
  String get purNoAccess;

  /// No description provided for @purNoAccessMessage.
  ///
  /// In ru, this message translates to:
  /// **'Закупки доступны кладовщику, менеджеру и владельцу'**
  String get purNoAccessMessage;

  /// No description provided for @purNoCashOutPermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет права на выдачу наличных из кассы'**
  String get purNoCashOutPermission;

  /// No description provided for @purNoCashPermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет права на операции с наличными'**
  String get purNoCashPermission;

  /// No description provided for @purNoChange.
  ///
  /// In ru, this message translates to:
  /// **'без изменений'**
  String get purNoChange;

  /// No description provided for @purNoDebt.
  ///
  /// In ru, this message translates to:
  /// **'нет долга'**
  String get purNoDebt;

  /// No description provided for @purNoLinesAdded.
  ///
  /// In ru, this message translates to:
  /// **'Позиции не добавлены'**
  String get purNoLinesAdded;

  /// No description provided for @purNoOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказов поставщикам пока нет'**
  String get purNoOrders;

  /// No description provided for @purNoOrdersForFilter.
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов по фильтру'**
  String get purNoOrdersForFilter;

  /// No description provided for @purNoOrdersMessage.
  ///
  /// In ru, this message translates to:
  /// **'Создайте заказ вручную или воспользуйтесь вкладкой «Автозаказ»'**
  String get purNoOrdersMessage;

  /// No description provided for @purNoOrdersYet.
  ///
  /// In ru, this message translates to:
  /// **'Заказов ещё не было'**
  String get purNoOrdersYet;

  /// No description provided for @purNoPaymentsYet.
  ///
  /// In ru, this message translates to:
  /// **'Оплат ещё не было'**
  String get purNoPaymentsYet;

  /// No description provided for @purNoProductsForFilter.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров по фильтру'**
  String get purNoProductsForFilter;

  /// No description provided for @purNoReceiptsYet.
  ///
  /// In ru, this message translates to:
  /// **'Товар по заказу ещё не принимали'**
  String get purNoReceiptsYet;

  /// No description provided for @purNoSales.
  ///
  /// In ru, this message translates to:
  /// **'продаж не было'**
  String get purNoSales;

  /// No description provided for @purNoSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Без поставщика'**
  String get purNoSupplier;

  /// No description provided for @purNoSupplierHelper.
  ///
  /// In ru, this message translates to:
  /// **'У этих товаров поставщик не указан в карточке'**
  String get purNoSupplierHelper;

  /// No description provided for @purNoSuppliers.
  ///
  /// In ru, this message translates to:
  /// **'Поставщиков пока нет'**
  String get purNoSuppliers;

  /// No description provided for @purNoSuppliersMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте поставщиков, чтобы вести заказы и учитывать долги'**
  String get purNoSuppliersMessage;

  /// No description provided for @purNowValue.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас: {value}'**
  String purNowValue(String value);

  /// No description provided for @purNumberGeZero.
  ///
  /// In ru, this message translates to:
  /// **'Число ≥ 0'**
  String get purNumberGeZero;

  /// No description provided for @purOnOrderValue.
  ///
  /// In ru, this message translates to:
  /// **'уже в заказах {qty}'**
  String purOnOrderValue(String qty);

  /// No description provided for @purOpeningBalance.
  ///
  /// In ru, this message translates to:
  /// **'Сальдо на начало периода'**
  String get purOpeningBalance;

  /// No description provided for @purOpeningShort.
  ///
  /// In ru, this message translates to:
  /// **'Сальдо на начало'**
  String get purOpeningShort;

  /// No description provided for @purOperation.
  ///
  /// In ru, this message translates to:
  /// **'Операция'**
  String get purOperation;

  /// No description provided for @purOrderAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа {amount}'**
  String purOrderAmount(String amount);

  /// No description provided for @purOrderButton.
  ///
  /// In ru, this message translates to:
  /// **'Заказ'**
  String get purOrderButton;

  /// No description provided for @purOrderCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Заказ отменён'**
  String get purOrderCancelled;

  /// No description provided for @purOrderClosed.
  ///
  /// In ru, this message translates to:
  /// **'Заказ закрыт'**
  String get purOrderClosed;

  /// No description provided for @purOrderFromSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Заказать у поставщика'**
  String get purOrderFromSupplier;

  /// No description provided for @purOrderListTitle.
  ///
  /// In ru, this message translates to:
  /// **'№{number} · {supplier}'**
  String purOrderListTitle(String number, String supplier);

  /// No description provided for @purOrderNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Заказ не найден'**
  String get purOrderNotFound;

  /// No description provided for @purOrderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number}'**
  String purOrderNumber(String number);

  /// No description provided for @purOrderReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Приходы по заказу'**
  String get purOrderReceipts;

  /// No description provided for @purOrderSavedSent.
  ///
  /// In ru, this message translates to:
  /// **'Заказ сохранён и отмечен как отправленный'**
  String get purOrderSavedSent;

  /// No description provided for @purOrderSent.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number} отправлен поставщику'**
  String purOrderSent(String number);

  /// No description provided for @purOrderedRest.
  ///
  /// In ru, this message translates to:
  /// **'заказано {ordered} · осталось {rest}'**
  String purOrderedRest(String ordered, String rest);

  /// No description provided for @purOurDebtLower.
  ///
  /// In ru, this message translates to:
  /// **'наш долг'**
  String get purOurDebtLower;

  /// No description provided for @purOurDebtLowerValue.
  ///
  /// In ru, this message translates to:
  /// **'наш долг {amount}'**
  String purOurDebtLowerValue(String amount);

  /// No description provided for @purOurDebtToSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Наш долг поставщику'**
  String get purOurDebtToSupplier;

  /// No description provided for @purOurDebtValue.
  ///
  /// In ru, this message translates to:
  /// **'Наш долг: {amount}'**
  String purOurDebtValue(String amount);

  /// No description provided for @purOverpayMessage.
  ///
  /// In ru, this message translates to:
  /// **'Долг поставщику: {debt}.\nПосле оплаты {amount} образуется аванс {advance}. Продолжить?'**
  String purOverpayMessage(String debt, String amount, String advance);

  /// No description provided for @purOverpayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сумма больше долга'**
  String get purOverpayTitle;

  /// No description provided for @purPaidAmount.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено {amount}'**
  String purPaidAmount(String amount);

  /// No description provided for @purPay.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get purPay;

  /// No description provided for @purPayWithAdvance.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить с авансом'**
  String get purPayWithAdvance;

  /// No description provided for @purPaymentCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Оплата {amount} отменена'**
  String purPaymentCancelled(String amount);

  /// No description provided for @purPaymentCommentLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (№ платёжки…)'**
  String get purPaymentCommentLabel;

  /// No description provided for @purPaymentDone.
  ///
  /// In ru, this message translates to:
  /// **'Оплата {amount} проведена'**
  String purPaymentDone(String amount);

  /// No description provided for @purPaymentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оплата поставщику'**
  String get purPaymentTitle;

  /// No description provided for @purPeriodAll.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get purPeriodAll;

  /// No description provided for @purPeriodCustom.
  ///
  /// In ru, this message translates to:
  /// **'Период…'**
  String get purPeriodCustom;

  /// No description provided for @purPeriodLastMonth.
  ///
  /// In ru, this message translates to:
  /// **'Прошлый месяц'**
  String get purPeriodLastMonth;

  /// No description provided for @purPeriodQuarter.
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get purPeriodQuarter;

  /// No description provided for @purPeriodThisMonth.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get purPeriodThisMonth;

  /// No description provided for @purPeriodUntil.
  ///
  /// In ru, this message translates to:
  /// **'по {date}'**
  String purPeriodUntil(String date);

  /// No description provided for @purPoColBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод / арт.'**
  String get purPoColBarcode;

  /// No description provided for @purPoColNo.
  ///
  /// In ru, this message translates to:
  /// **'№'**
  String get purPoColNo;

  /// No description provided for @purPoColQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get purPoColQty;

  /// No description provided for @purPoColReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get purPoColReceived;

  /// No description provided for @purPoDated.
  ///
  /// In ru, this message translates to:
  /// **'от {date} · {status}'**
  String purPoDated(String date, String status);

  /// No description provided for @purPoExpected.
  ///
  /// In ru, this message translates to:
  /// **'Ожидаемая дата поставки: {date}'**
  String purPoExpected(String date);

  /// No description provided for @purPoNote.
  ///
  /// In ru, this message translates to:
  /// **'Примечание: {note}'**
  String purPoNote(String note);

  /// No description provided for @purPoOrderedBy.
  ///
  /// In ru, this message translates to:
  /// **'Заказал: {line}'**
  String purPoOrderedBy(String line);

  /// No description provided for @purPoPrintName.
  ///
  /// In ru, this message translates to:
  /// **'Заказ поставщику {number}'**
  String purPoPrintName(String number);

  /// No description provided for @purPoShort.
  ///
  /// In ru, this message translates to:
  /// **'Заказ поставщику'**
  String get purPoShort;

  /// No description provided for @purPoSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик: {name}'**
  String purPoSupplier(String name);

  /// No description provided for @purPoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ поставщику №{number}'**
  String purPoTitle(String number);

  /// No description provided for @purPoTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого: {amount}'**
  String purPoTotal(String amount);

  /// No description provided for @purPostAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Провести корректировку'**
  String get purPostAdjust;

  /// No description provided for @purPriceRiseChip.
  ///
  /// In ru, this message translates to:
  /// **'Рост > 10%'**
  String get purPriceRiseChip;

  /// No description provided for @purPriceRiseFilter.
  ///
  /// In ru, this message translates to:
  /// **'Рост цены > 10%'**
  String get purPriceRiseFilter;

  /// No description provided for @purPricesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Приходов за период нет'**
  String get purPricesEmpty;

  /// No description provided for @purPricesEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'История закупочных цен строится по приходам товара'**
  String get purPricesEmptyMessage;

  /// No description provided for @purPricesSummary.
  ///
  /// In ru, this message translates to:
  /// **'Товаров с приходами: {count} · подорожали более чем на 10%: {spikes}'**
  String purPricesSummary(String count, String spikes);

  /// No description provided for @purProductNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Товар «{code}» не найден'**
  String purProductNotFound(String code);

  /// No description provided for @purPurchasePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена закупки'**
  String get purPurchasePrice;

  /// No description provided for @purQtyMoreThanZero.
  ///
  /// In ru, this message translates to:
  /// **'больше 0'**
  String get purQtyMoreThanZero;

  /// No description provided for @purQtyMoreThanZeroCap.
  ///
  /// In ru, this message translates to:
  /// **'Больше 0'**
  String get purQtyMoreThanZeroCap;

  /// No description provided for @purQtyWhole.
  ///
  /// In ru, this message translates to:
  /// **'целое'**
  String get purQtyWhole;

  /// No description provided for @purQtyWholeCap.
  ///
  /// In ru, this message translates to:
  /// **'Целое'**
  String get purQtyWholeCap;

  /// No description provided for @purReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Причина *'**
  String get purReasonRequired;

  /// No description provided for @purRecalculate.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитать'**
  String get purRecalculate;

  /// No description provided for @purReceiptNumber.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number}'**
  String purReceiptNumber(String number);

  /// No description provided for @purReceiptPosted.
  ///
  /// In ru, this message translates to:
  /// **'Приход №{number} проведён на {amount}'**
  String purReceiptPosted(String number, String amount);

  /// No description provided for @purReceiveConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Позиций: {count} на сумму {amount}.\nОстатки увеличатся, долг поставщику вырастет на эту сумму.'**
  String purReceiveConfirmMessage(String count, String amount);

  /// No description provided for @purReceiveConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Принять товар?'**
  String get purReceiveConfirmTitle;

  /// No description provided for @purReceiveEnterQty.
  ///
  /// In ru, this message translates to:
  /// **'Укажите принятое количество хотя бы по одной позиции'**
  String get purReceiveEnterQty;

  /// No description provided for @purReceiveGoods.
  ///
  /// In ru, this message translates to:
  /// **'Принять товар'**
  String get purReceiveGoods;

  /// No description provided for @purReceiveShort.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get purReceiveShort;

  /// No description provided for @purReceiveStaysOpen.
  ///
  /// In ru, this message translates to:
  /// **'Заказ останется открытым — недопоставку можно принять позже.'**
  String get purReceiveStaysOpen;

  /// No description provided for @purReceiveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Приёмка по заказу №{number}'**
  String purReceiveTitle(String number);

  /// No description provided for @purReceiveWillClose.
  ///
  /// In ru, this message translates to:
  /// **'Заказ будет закрыт как полученный.'**
  String get purReceiveWillClose;

  /// No description provided for @purReceivedAmount.
  ///
  /// In ru, this message translates to:
  /// **'Получено на сумму {amount}'**
  String purReceivedAmount(String amount);

  /// No description provided for @purReceivedField.
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get purReceivedField;

  /// No description provided for @purReceivedOn.
  ///
  /// In ru, this message translates to:
  /// **'получен {date}'**
  String purReceivedOn(String date);

  /// No description provided for @purReorderAssignSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Выберите поставщика для товаров без поставщика'**
  String get purReorderAssignSupplier;

  /// No description provided for @purReorderConfirmHead.
  ///
  /// In ru, this message translates to:
  /// **'Будет создано черновиков: {count}'**
  String purReorderConfirmHead(String count);

  /// No description provided for @purReorderConfirmLine.
  ///
  /// In ru, this message translates to:
  /// **'• {name}: {count} поз.'**
  String purReorderConfirmLine(String name, String count);

  /// No description provided for @purReorderConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создать заказы?'**
  String get purReorderConfirmTitle;

  /// No description provided for @purReorderCreated.
  ///
  /// In ru, this message translates to:
  /// **'Создано черновиков заказов: {count}. Проверьте их во вкладке «Заказы»'**
  String purReorderCreated(String count);

  /// No description provided for @purReorderDaysInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Укажите запас от 1 до 365 дней'**
  String get purReorderDaysInvalid;

  /// No description provided for @purReorderDaysLabel.
  ///
  /// In ru, this message translates to:
  /// **'Запас на, дней'**
  String get purReorderDaysLabel;

  /// No description provided for @purReorderEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заказывать нечего'**
  String get purReorderEmpty;

  /// No description provided for @purReorderEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Запасов хватает на выбранный период. Задайте минимальные остатки в карточках товаров.'**
  String get purReorderEmptyMessage;

  /// No description provided for @purReorderHint.
  ///
  /// In ru, this message translates to:
  /// **'Средний расход считается по продажам за 30 дней; учтены остатки, минимум и уже заказанное.'**
  String get purReorderHint;

  /// No description provided for @purReorderNothingSelected.
  ///
  /// In ru, this message translates to:
  /// **'Не выбрано ни одной позиции'**
  String get purReorderNothingSelected;

  /// No description provided for @purReorderSkipped.
  ///
  /// In ru, this message translates to:
  /// **'{count} поз. без поставщика пропущены'**
  String purReorderSkipped(String count);

  /// No description provided for @purRetailSuffix.
  ///
  /// In ru, this message translates to:
  /// **' · розница {price}'**
  String purRetailSuffix(String price);

  /// No description provided for @purSalesPerDay.
  ///
  /// In ru, this message translates to:
  /// **'продаж/день {value}'**
  String purSalesPerDay(String value);

  /// No description provided for @purSaveAndSend.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и отправить'**
  String get purSaveAndSend;

  /// No description provided for @purSaveDraft.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить черновик'**
  String get purSaveDraft;

  /// No description provided for @purSearchOrder.
  ///
  /// In ru, this message translates to:
  /// **'Поиск заказа'**
  String get purSearchOrder;

  /// No description provided for @purSelectOrder.
  ///
  /// In ru, this message translates to:
  /// **'Выберите заказ'**
  String get purSelectOrder;

  /// No description provided for @purSelectOrderMessage.
  ///
  /// In ru, this message translates to:
  /// **'Откройте заказ из списка слева или создайте новый'**
  String get purSelectOrderMessage;

  /// No description provided for @purSelectSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Выберите поставщика'**
  String get purSelectSupplier;

  /// No description provided for @purSelectedCount.
  ///
  /// In ru, this message translates to:
  /// **'Выбрано позиций: {count}'**
  String purSelectedCount(String count);

  /// No description provided for @purShiftClosedNoCash.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта — наличные из кассы выдать нельзя'**
  String get purShiftClosedNoCash;

  /// No description provided for @purSignatureCaption.
  ///
  /// In ru, this message translates to:
  /// **'подпись                         ФИО'**
  String get purSignatureCaption;

  /// No description provided for @purStampPlace.
  ///
  /// In ru, this message translates to:
  /// **'М.П.'**
  String get purStampPlace;

  /// No description provided for @purStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get purStatusCancelled;

  /// No description provided for @purStatusDraft.
  ///
  /// In ru, this message translates to:
  /// **'Черновик'**
  String get purStatusDraft;

  /// No description provided for @purStatusOrdered.
  ///
  /// In ru, this message translates to:
  /// **'Заказан'**
  String get purStatusOrdered;

  /// No description provided for @purStatusPartial.
  ///
  /// In ru, this message translates to:
  /// **'Частично получен'**
  String get purStatusPartial;

  /// No description provided for @purStatusReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получен'**
  String get purStatusReceived;

  /// No description provided for @purStockValue.
  ///
  /// In ru, this message translates to:
  /// **'остаток {qty}'**
  String purStockValue(String qty);

  /// No description provided for @purStore.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get purStore;

  /// No description provided for @purSupplierAdded.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик добавлен'**
  String get purSupplierAdded;

  /// No description provided for @purSupplierDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик удалён'**
  String get purSupplierDeleted;

  /// No description provided for @purSupplierInvoiceNo.
  ///
  /// In ru, this message translates to:
  /// **'№ накладной поставщика'**
  String get purSupplierInvoiceNo;

  /// No description provided for @purSupplierNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик не найден или удалён'**
  String get purSupplierNotFound;

  /// No description provided for @purSupplierRequired.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик *'**
  String get purSupplierRequired;

  /// No description provided for @purTabLedger.
  ///
  /// In ru, this message translates to:
  /// **'Взаиморасчёты'**
  String get purTabLedger;

  /// No description provided for @purTabOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get purTabOrders;

  /// No description provided for @purTabPayments.
  ///
  /// In ru, this message translates to:
  /// **'Оплаты'**
  String get purTabPayments;

  /// No description provided for @purTabPrices.
  ///
  /// In ru, this message translates to:
  /// **'Закупочные цены'**
  String get purTabPrices;

  /// No description provided for @purTabReorder.
  ///
  /// In ru, this message translates to:
  /// **'Автозаказ'**
  String get purTabReorder;

  /// No description provided for @purTabSuppliers.
  ///
  /// In ru, this message translates to:
  /// **'Поставщики'**
  String get purTabSuppliers;

  /// No description provided for @purTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН'**
  String get purTaxId;

  /// No description provided for @purTaxIdInvalid.
  ///
  /// In ru, this message translates to:
  /// **'ИНН — от 9 до 14 цифр'**
  String get purTaxIdInvalid;

  /// No description provided for @purTaxIdValue.
  ///
  /// In ru, this message translates to:
  /// **'ИНН {taxId}'**
  String purTaxIdValue(String taxId);

  /// No description provided for @purTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закупки'**
  String get purTitle;

  /// No description provided for @purToPost.
  ///
  /// In ru, this message translates to:
  /// **'К оприходованию: {amount}'**
  String purToPost(String amount);

  /// No description provided for @purTurnover.
  ///
  /// In ru, this message translates to:
  /// **'Обороты за период'**
  String get purTurnover;

  /// No description provided for @purUrgent.
  ///
  /// In ru, this message translates to:
  /// **'Срочно'**
  String get purUrgent;

  /// No description provided for @purWeOwe.
  ///
  /// In ru, this message translates to:
  /// **'Мы должны: {amount}'**
  String purWeOwe(String amount);

  /// No description provided for @purZeroAll.
  ///
  /// In ru, this message translates to:
  /// **'Обнулить'**
  String get purZeroAll;

  /// No description provided for @repAbcHintA.
  ///
  /// In ru, this message translates to:
  /// **'Основная выручка (первые 80%)'**
  String get repAbcHintA;

  /// No description provided for @repAbcHintB.
  ///
  /// In ru, this message translates to:
  /// **'Средний вклад (следующие 15%)'**
  String get repAbcHintB;

  /// No description provided for @repAbcHintC.
  ///
  /// In ru, this message translates to:
  /// **'Малый вклад (последние 5%)'**
  String get repAbcHintC;

  /// No description provided for @repGiftSalesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификатов (аванс, не выручка)'**
  String get repGiftSalesTitle;

  /// No description provided for @repGiftSalesHint.
  ///
  /// In ru, this message translates to:
  /// **'Деньги за проданные сертификаты — аванс. В выручку они попадают при оплате товара сертификатом.'**
  String get repGiftSalesHint;

  /// No description provided for @repGiftSalesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'{period} · продано {sold}, аннулировано {voided}'**
  String repGiftSalesSubtitle(String period, String sold, String voided);

  /// No description provided for @repColSold.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get repColSold;

  /// No description provided for @repColVoided.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировано'**
  String get repColVoided;

  /// No description provided for @repGiftVoidedTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено покупателям при аннулировании продажи'**
  String get repGiftVoidedTooltip;

  /// No description provided for @repPeriodLastMonth.
  ///
  /// In ru, this message translates to:
  /// **'Прошлый месяц'**
  String get repPeriodLastMonth;

  /// No description provided for @repPeriodQuarter.
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get repPeriodQuarter;

  /// No description provided for @repPeriodCustom.
  ///
  /// In ru, this message translates to:
  /// **'Произвольный'**
  String get repPeriodCustom;

  /// No description provided for @repNoCategory.
  ///
  /// In ru, this message translates to:
  /// **'Без категории'**
  String get repNoCategory;

  /// No description provided for @repNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указан'**
  String get repNotSpecified;

  /// No description provided for @repNoReason.
  ///
  /// In ru, this message translates to:
  /// **'Без причины'**
  String get repNoReason;

  /// No description provided for @repExportFolder.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get repExportFolder;

  /// No description provided for @repForecastTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прогноз спроса и заказ на {days} дн.'**
  String repForecastTitle(String days);

  /// No description provided for @repAsOf.
  ///
  /// In ru, this message translates to:
  /// **'на {date}'**
  String repAsOf(String date);

  /// No description provided for @repColSalesPerDay.
  ///
  /// In ru, this message translates to:
  /// **'Продаж в день'**
  String get repColSalesPerDay;

  /// No description provided for @repColSalesPerDayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Среднее за 28 дней (для новых — за дни с момента создания, не меньше 7)'**
  String get repColSalesPerDayTooltip;

  /// No description provided for @repColTrend7.
  ///
  /// In ru, this message translates to:
  /// **'Тренд 7 дн.'**
  String get repColTrend7;

  /// No description provided for @repColTrend7Tooltip.
  ///
  /// In ru, this message translates to:
  /// **'Темп продаж последних 7 дней относительно среднего'**
  String get repColTrend7Tooltip;

  /// No description provided for @repColCover.
  ///
  /// In ru, this message translates to:
  /// **'Хватит на'**
  String get repColCover;

  /// No description provided for @repColRunsOut.
  ///
  /// In ru, this message translates to:
  /// **'Закончится'**
  String get repColRunsOut;

  /// No description provided for @repColToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Заказать'**
  String get repColToOrder;

  /// No description provided for @repColOrderSum.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа'**
  String get repColOrderSum;

  /// No description provided for @repDaysShort.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String repDaysShort(String days);

  /// No description provided for @repAlreadyOut.
  ///
  /// In ru, this message translates to:
  /// **'уже нет'**
  String get repAlreadyOut;

  /// No description provided for @repOutOfStock.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии'**
  String get repOutOfStock;

  /// No description provided for @repRisk.
  ///
  /// In ru, this message translates to:
  /// **'Риск'**
  String get repRisk;

  /// No description provided for @repNormal.
  ///
  /// In ru, this message translates to:
  /// **'Норма'**
  String get repNormal;

  /// No description provided for @repNoSalesShort.
  ///
  /// In ru, this message translates to:
  /// **'Нет продаж'**
  String get repNoSalesShort;

  /// No description provided for @repRunOutIn7.
  ///
  /// In ru, this message translates to:
  /// **'Закончатся за 7 дней'**
  String get repRunOutIn7;

  /// No description provided for @repOutButWanted.
  ///
  /// In ru, this message translates to:
  /// **'Нет в наличии, но покупают'**
  String get repOutButWanted;

  /// No description provided for @repItemsToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Позиций к заказу'**
  String get repItemsToOrder;

  /// No description provided for @repOrderSumAtCost.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа (по себестоимости)'**
  String get repOrderSumAtCost;

  /// No description provided for @repForecastHow.
  ///
  /// In ru, this message translates to:
  /// **'Как считается прогноз'**
  String get repForecastHow;

  /// No description provided for @repForecastHelp.
  ///
  /// In ru, this message translates to:
  /// **'• Продаж в день = продано за последние 28 дней (за вычетом возвратов) ÷ 28. Для новых товаров — за дни с момента добавления, но не меньше 7.\n• Хватит на = остаток ÷ продаж в день.\n• Заказать = продаж в день × {horizon} дн. + минимальный остаток − текущий остаток.\n• «Риск» — товар закончится в ближайшие {riskDays} дней.'**
  String repForecastHelp(String horizon, String riskDays);

  /// No description provided for @repNothingToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Нечего заказывать — запасов хватает на {days} дн.'**
  String repNothingToOrder(String days);

  /// No description provided for @repNoTrackedProducts.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров с учётом остатков'**
  String get repNoTrackedProducts;

  /// No description provided for @repOnlyToOrder.
  ///
  /// In ru, this message translates to:
  /// **'Только требующие заказа'**
  String get repOnlyToOrder;

  /// No description provided for @repGoToPurchasing.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к закупкам'**
  String get repGoToPurchasing;

  /// No description provided for @repInsQuoted.
  ///
  /// In ru, this message translates to:
  /// **'«{name}»'**
  String repInsQuoted(String name);

  /// No description provided for @repInsWeekExpl.
  ///
  /// In ru, this message translates to:
  /// **'За последние 7 дней: {week}, за 7 дней до этого: {prev} (чистая выручка с учётом возвратов).'**
  String repInsWeekExpl(String week, String prev);

  /// No description provided for @repInsRevenueUpTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выручка за неделю выросла на {pct}'**
  String repInsRevenueUpTitle(String pct);

  /// No description provided for @repInsRevenueUpExpl.
  ///
  /// In ru, this message translates to:
  /// **'{base} Отличный результат — проверьте, хватит ли остатков ходовых товаров.'**
  String repInsRevenueUpExpl(String base);

  /// No description provided for @repInsRevenueDownTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выручка за неделю упала на {pct}'**
  String repInsRevenueDownTitle(String pct);

  /// No description provided for @repInsRevenueDownExpl.
  ///
  /// In ru, this message translates to:
  /// **'{base} Проверьте наличие ходовых товаров и запустите акцию.'**
  String repInsRevenueDownExpl(String base);

  /// No description provided for @repInsActLaunchPromo.
  ///
  /// In ru, this message translates to:
  /// **'Запустить акцию'**
  String get repInsActLaunchPromo;

  /// No description provided for @repInsOutOfStockOne.
  ///
  /// In ru, this message translates to:
  /// **'Закончился ходовой товар {name}'**
  String repInsOutOfStockOne(String name);

  /// No description provided for @repInsOutOfStockMany.
  ///
  /// In ru, this message translates to:
  /// **'{items} с продажами закончились'**
  String repInsOutOfStockMany(String items);

  /// No description provided for @repInsOutOfStockExpl.
  ///
  /// In ru, this message translates to:
  /// **'{names} — остаток 0, а за последние 4 недели их покупали. Каждый день без товара — потерянная выручка.'**
  String repInsOutOfStockExpl(String names);

  /// No description provided for @repInsActOrderSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Заказать у поставщика'**
  String get repInsActOrderSupplier;

  /// No description provided for @repInsStockoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товар {name} закончится через {days}'**
  String repInsStockoutTitle(String name, String days);

  /// No description provided for @repInsStockoutExpl.
  ///
  /// In ru, this message translates to:
  /// **'Остаток {stock}, продаётся в среднем {avg} в день (за {window}). Рекомендуем заказать {reorder} на {horizon}.'**
  String repInsStockoutExpl(
    String stock,
    String avg,
    String window,
    String reorder,
    String horizon,
  );

  /// No description provided for @repInsActPurchase.
  ///
  /// In ru, this message translates to:
  /// **'Оформить закупку'**
  String get repInsActPurchase;

  /// No description provided for @repInsStockoutMoreOne.
  ///
  /// In ru, this message translates to:
  /// **'Ещё 1 товар закончится в течение недели'**
  String get repInsStockoutMoreOne;

  /// No description provided for @repInsStockoutMoreMany.
  ///
  /// In ru, this message translates to:
  /// **'Ещё {items} закончатся в течение недели'**
  String repInsStockoutMoreMany(String items);

  /// No description provided for @repInsStockoutMoreExpl.
  ///
  /// In ru, this message translates to:
  /// **'См. вкладку «Прогноз спроса» — там рекомендуемое количество к заказу.'**
  String get repInsStockoutMoreExpl;

  /// No description provided for @repInsCategoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Категория «{name}» даёт {pct} прибыли'**
  String repInsCategoryTitle(String name, String pct);

  /// No description provided for @repInsCategoryExpl.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней: {profit} из {total} валовой прибыли. Держите эту категорию в наличии и на видном месте.'**
  String repInsCategoryExpl(String profit, String total);

  /// No description provided for @repInsActOpenProducts.
  ///
  /// In ru, this message translates to:
  /// **'Открыть товары'**
  String get repInsActOpenProducts;

  /// No description provided for @repInsLossTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товар {name} продаётся в убыток'**
  String repInsLossTitle(String name);

  /// No description provided for @repInsLowMarginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Маржа товара {name} ниже 5%'**
  String repInsLowMarginTitle(String name);

  /// No description provided for @repInsMarginExpl.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней: выручка {revenue}, себестоимость {cost}, маржа {margin}%. Поднимите цену или пересмотрите закупочную цену и скидки.'**
  String repInsMarginExpl(String revenue, String cost, String margin);

  /// No description provided for @repInsActChangePrice.
  ///
  /// In ru, this message translates to:
  /// **'Изменить цену'**
  String get repInsActChangePrice;

  /// No description provided for @repInsInactiveTitle.
  ///
  /// In ru, this message translates to:
  /// **'{customers} не приходили 60 дней — запустите акцию'**
  String repInsInactiveTitle(String customers);

  /// No description provided for @repInsInactiveExpl.
  ///
  /// In ru, this message translates to:
  /// **'Эти клиенты раньше покупали, но не возвращались больше 60 дней. Персональная скидка или бонусы часто возвращают 10–20% из них.'**
  String get repInsInactiveExpl;

  /// No description provided for @repInsActCreatePromo.
  ///
  /// In ru, this message translates to:
  /// **'Создать акцию'**
  String get repInsActCreatePromo;

  /// No description provided for @repInsDiscountsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скидки съели {pct} выручки'**
  String repInsDiscountsTitle(String pct);

  /// No description provided for @repInsDiscountsExpl.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней скидки составили {discounts} от {subtotal} до скидок. Проверьте акции и ручные скидки кассиров (вкладка «Сотрудники»).'**
  String repInsDiscountsExpl(String discounts, String subtotal);

  /// No description provided for @repInsActCheckPromos.
  ///
  /// In ru, this message translates to:
  /// **'Проверить акции'**
  String get repInsActCheckPromos;

  /// No description provided for @repInsReturnsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты — {pct} от продаж'**
  String repInsReturnsTitle(String pct);

  /// No description provided for @repInsReturnsExpl.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней {returns} на {amount}. Норма для розницы — до 3–5%. Проверьте качество товара и причины возвратов.'**
  String repInsReturnsExpl(String returns, String amount);

  /// No description provided for @repInsActOpenReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чеки'**
  String get repInsActOpenReceipts;

  /// No description provided for @repInsPeakTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пиковые часы {from}–{to} — поставьте второго кассира'**
  String repInsPeakTitle(String from, String to);

  /// No description provided for @repInsPeakExpl.
  ///
  /// In ru, this message translates to:
  /// **'С {from}:00 до {to}:00 приходится {pct} всех чеков за 30 дней. Второй кассир в это время сократит очереди и потерянные продажи.'**
  String repInsPeakExpl(String from, String to, String pct);

  /// No description provided for @repInsActStaff.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get repInsActStaff;

  /// No description provided for @repInsDeadTitle.
  ///
  /// In ru, this message translates to:
  /// **'{items} не продавались 60 дней'**
  String repInsDeadTitle(String items);

  /// No description provided for @repInsDeadExplCost.
  ///
  /// In ru, this message translates to:
  /// **'В них заморожено {amount} по себестоимости. Сделайте уценку или акцию, чтобы освободить деньги.'**
  String repInsDeadExplCost(String amount);

  /// No description provided for @repInsDeadExpl.
  ///
  /// In ru, this message translates to:
  /// **'Сделайте уценку или акцию, чтобы освободить деньги и место на полке.'**
  String get repInsDeadExpl;

  /// No description provided for @repInsActOpenInventory.
  ///
  /// In ru, this message translates to:
  /// **'Открыть склад'**
  String get repInsActOpenInventory;

  /// No description provided for @repInsOverdueTitle.
  ///
  /// In ru, this message translates to:
  /// **'Просроченные долги: {customers}'**
  String repInsOverdueTitle(String customers);

  /// No description provided for @repInsOverdueExpl.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено {amount} — срок оплаты этих долгов прошёл. Напомните клиентам и не продавайте им в долг до погашения.'**
  String repInsOverdueExpl(String amount);

  /// No description provided for @repInsActOpenCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Открыть клиентов'**
  String get repInsActOpenCustomers;

  /// No description provided for @repInsTopTitle.
  ///
  /// In ru, this message translates to:
  /// **'Хит недели — {name}'**
  String repInsTopTitle(String name);

  /// No description provided for @repInsTopExpl.
  ///
  /// In ru, this message translates to:
  /// **'Выручка {amount} за 7 дней ({pct} всех продаж). Следите, чтобы он не заканчивался.'**
  String repInsTopExpl(String amount, String pct);

  /// No description provided for @repInsActCheckStock.
  ///
  /// In ru, this message translates to:
  /// **'Проверить остатки'**
  String get repInsActCheckStock;

  /// No description provided for @repSevCritical.
  ///
  /// In ru, this message translates to:
  /// **'Срочно'**
  String get repSevCritical;

  /// No description provided for @repSevWarning.
  ///
  /// In ru, this message translates to:
  /// **'Внимание'**
  String get repSevWarning;

  /// No description provided for @repSevInfo.
  ///
  /// In ru, this message translates to:
  /// **'Совет'**
  String get repSevInfo;

  /// No description provided for @repSevPositive.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get repSevPositive;

  /// No description provided for @repInsightsIntro.
  ///
  /// In ru, this message translates to:
  /// **'Подсказки по вашим данным за последние 30 дней. Считаются на этом устройстве, без интернета; каждая объясняет, откуда взялись цифры.'**
  String get repInsightsIntro;

  /// No description provided for @repRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get repRefresh;

  /// No description provided for @repInsightsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пока нечего подсказать'**
  String get repInsightsEmptyTitle;

  /// No description provided for @repInsightsEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Подсказки появятся, когда накопятся продажи хотя бы за неделю. Проблем с остатками, долгами и маржой не найдено.'**
  String get repInsightsEmptyMessage;

  /// No description provided for @repByProducts.
  ///
  /// In ru, this message translates to:
  /// **'По товарам'**
  String get repByProducts;

  /// No description provided for @repByCategories.
  ///
  /// In ru, this message translates to:
  /// **'По категориям'**
  String get repByCategories;

  /// No description provided for @repSalesByCategory.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по категориям'**
  String get repSalesByCategory;

  /// No description provided for @repColProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товаров'**
  String get repColProducts;

  /// No description provided for @repColQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get repColQty;

  /// No description provided for @repColRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get repColRevenue;

  /// No description provided for @repColRevenueShare.
  ///
  /// In ru, this message translates to:
  /// **'Доля выручки'**
  String get repColRevenueShare;

  /// No description provided for @repProfitByCategory.
  ///
  /// In ru, this message translates to:
  /// **'Прибыль по категориям'**
  String get repProfitByCategory;

  /// No description provided for @repRevenueByCategory.
  ///
  /// In ru, this message translates to:
  /// **'Выручка по категориям'**
  String get repRevenueByCategory;

  /// No description provided for @repSalesByProduct.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по товарам'**
  String get repSalesByProduct;

  /// No description provided for @repColShare.
  ///
  /// In ru, this message translates to:
  /// **'Доля'**
  String get repColShare;

  /// No description provided for @repAbcTooltip.
  ///
  /// In ru, this message translates to:
  /// **'A — 80% выручки, B — следующие 15%, C — последние 5%'**
  String get repAbcTooltip;

  /// No description provided for @repAbcClass.
  ///
  /// In ru, this message translates to:
  /// **'Класс {cls} — {hint}'**
  String repAbcClass(String cls, String hint);

  /// No description provided for @repProductsShort.
  ///
  /// In ru, this message translates to:
  /// **'{count} тов.'**
  String repProductsShort(String count);

  /// No description provided for @repRevenueSharePct.
  ///
  /// In ru, this message translates to:
  /// **'{pct}% выручки'**
  String repRevenueSharePct(String pct);

  /// No description provided for @repNoSales.
  ///
  /// In ru, this message translates to:
  /// **'Нет продаж за период'**
  String get repNoSales;

  /// No description provided for @repSearchProduct.
  ///
  /// In ru, this message translates to:
  /// **'Поиск товара'**
  String get repSearchProduct;

  /// No description provided for @repNoDataForPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных за период'**
  String get repNoDataForPeriod;

  /// No description provided for @repShowMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё (показано {shown} из {total})'**
  String repShowMore(String shown, String total);

  /// No description provided for @repNoSort.
  ///
  /// In ru, this message translates to:
  /// **'Без сортировки'**
  String get repNoSort;

  /// No description provided for @repSortBy.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка: {column}'**
  String repSortBy(String column);

  /// No description provided for @repCopyCsv.
  ///
  /// In ru, this message translates to:
  /// **'Копировать CSV'**
  String get repCopyCsv;

  /// No description provided for @repSaveCsv.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить CSV (Excel)'**
  String get repSaveCsv;

  /// No description provided for @repSavePdf.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить PDF'**
  String get repSavePdf;

  /// No description provided for @repTableCopied.
  ///
  /// In ru, this message translates to:
  /// **'Таблица скопирована — вставьте в Excel или сообщение'**
  String get repTableCopied;

  /// No description provided for @repFileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Файл сохранён'**
  String get repFileSaved;

  /// No description provided for @repCopyPath.
  ///
  /// In ru, this message translates to:
  /// **'Копировать путь'**
  String get repCopyPath;

  /// No description provided for @repNoSalesInPeriod.
  ///
  /// In ru, this message translates to:
  /// **'За выбранный период продаж нет'**
  String get repNoSalesInPeriod;

  /// No description provided for @repPickAnotherPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой период вверху экрана.'**
  String get repPickAnotherPeriod;

  /// No description provided for @repPrevPeriod.
  ///
  /// In ru, this message translates to:
  /// **'пред. период: {amount}'**
  String repPrevPeriod(String amount);

  /// No description provided for @repNetRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка'**
  String get repNetRevenue;

  /// No description provided for @repNetRevenueTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Продажи минус возвраты за период (аннулированные чеки не учитываются)'**
  String get repNetRevenueTooltip;

  /// No description provided for @repReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get repReturns;

  /// No description provided for @repReturnsHint.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт. · {pct} от продаж'**
  String repReturnsHint(String count, String pct);

  /// No description provided for @repDiscounts.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get repDiscounts;

  /// No description provided for @repDiscountsHint.
  ///
  /// In ru, this message translates to:
  /// **'{pct} от суммы до скидок'**
  String repDiscountsHint(String pct);

  /// No description provided for @repReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get repReceipts;

  /// No description provided for @repVoidedCount.
  ///
  /// In ru, this message translates to:
  /// **'аннулировано: {count}'**
  String repVoidedCount(String count);

  /// No description provided for @repNoVoids.
  ///
  /// In ru, this message translates to:
  /// **'аннулирований нет'**
  String get repNoVoids;

  /// No description provided for @repAvgCheck.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get repAvgCheck;

  /// No description provided for @repGrossProfit.
  ///
  /// In ru, this message translates to:
  /// **'Валовая прибыль'**
  String get repGrossProfit;

  /// No description provided for @repGrossProfitTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка минус себестоимость проданного (с учётом возвратов на склад)'**
  String get repGrossProfitTooltip;

  /// No description provided for @repMargin.
  ///
  /// In ru, this message translates to:
  /// **'Маржа'**
  String get repMargin;

  /// No description provided for @repCostHint.
  ///
  /// In ru, this message translates to:
  /// **'себестоимость: {amount}'**
  String repCostHint(String amount);

  /// No description provided for @repSalesByDay.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по дням'**
  String get repSalesByDay;

  /// No description provided for @repProfit.
  ///
  /// In ru, this message translates to:
  /// **'Прибыль'**
  String get repProfit;

  /// No description provided for @repNetRevenueByDay.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка по дням'**
  String get repNetRevenueByDay;

  /// No description provided for @repTipNetRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка: {amount}'**
  String repTipNetRevenue(String amount);

  /// No description provided for @repTipReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков: {count}'**
  String repTipReceipts(String count);

  /// No description provided for @repTipReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты: {amount}'**
  String repTipReturns(String amount);

  /// No description provided for @repSalesByHour.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по часам'**
  String get repSalesByHour;

  /// No description provided for @repHour.
  ///
  /// In ru, this message translates to:
  /// **'Час'**
  String get repHour;

  /// No description provided for @repReceiptsPerDay.
  ///
  /// In ru, this message translates to:
  /// **'Чеков в день'**
  String get repReceiptsPerDay;

  /// No description provided for @repReceiptsPerDayTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Среднее количество чеков в этот час за день'**
  String get repReceiptsPerDayTooltip;

  /// No description provided for @repReceiptsShare.
  ///
  /// In ru, this message translates to:
  /// **'Доля чеков'**
  String get repReceiptsShare;

  /// No description provided for @repLoadByHour.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка по часам'**
  String get repLoadByHour;

  /// No description provided for @repPeak.
  ///
  /// In ru, this message translates to:
  /// **'Пик: {from}:00–{to}:00'**
  String repPeak(String from, String to);

  /// No description provided for @repLoadByHourHint.
  ///
  /// In ru, this message translates to:
  /// **'Сколько чеков пробивается в каждый час — помогает планировать смены и второго кассира.'**
  String get repLoadByHourHint;

  /// No description provided for @repTipReceiptsPerDay.
  ///
  /// In ru, this message translates to:
  /// **'Чеков: {count} (≈{perDay} в день)'**
  String repTipReceiptsPerDay(String count, String perDay);

  /// No description provided for @repTipSales.
  ///
  /// In ru, this message translates to:
  /// **'Продажи: {amount}'**
  String repTipSales(String amount);

  /// No description provided for @repByWeekday.
  ///
  /// In ru, this message translates to:
  /// **'По дням недели'**
  String get repByWeekday;

  /// No description provided for @repTipReceiptsLower.
  ///
  /// In ru, this message translates to:
  /// **'чеков: {count}'**
  String repTipReceiptsLower(String count);

  /// No description provided for @repTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get repTitle;

  /// No description provided for @repTabSales.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get repTabSales;

  /// No description provided for @repTabStaff.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get repTabStaff;

  /// No description provided for @repTabPayments.
  ///
  /// In ru, this message translates to:
  /// **'Оплаты'**
  String get repTabPayments;

  /// No description provided for @repTabStock.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get repTabStock;

  /// No description provided for @repTabForecast.
  ///
  /// In ru, this message translates to:
  /// **'Прогноз спроса'**
  String get repTabForecast;

  /// No description provided for @repTabInsights.
  ///
  /// In ru, this message translates to:
  /// **'AI-аналитика'**
  String get repTabInsights;

  /// No description provided for @repForecastSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'По продажам за последние 28 дней'**
  String get repForecastSubtitle;

  /// No description provided for @repLast30Days.
  ///
  /// In ru, this message translates to:
  /// **'Последние 30 дней'**
  String get repLast30Days;

  /// No description provided for @repPeriodTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Период: {period}'**
  String repPeriodTooltip(String period);

  /// No description provided for @repPeriodCustomMenu.
  ///
  /// In ru, this message translates to:
  /// **'Произвольный…'**
  String get repPeriodCustomMenu;

  /// No description provided for @repPickPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выберите период'**
  String get repPickPeriod;

  /// No description provided for @repFrom.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get repFrom;

  /// No description provided for @repTo.
  ///
  /// In ru, this message translates to:
  /// **'По'**
  String get repTo;

  /// No description provided for @repWdMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get repWdMon;

  /// No description provided for @repWdTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get repWdTue;

  /// No description provided for @repWdWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get repWdWed;

  /// No description provided for @repWdThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get repWdThu;

  /// No description provided for @repWdFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get repWdFri;

  /// No description provided for @repWdSat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get repWdSat;

  /// No description provided for @repWdSun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get repWdSun;

  /// No description provided for @repDeltaNew.
  ///
  /// In ru, this message translates to:
  /// **'новое'**
  String get repDeltaNew;

  /// No description provided for @repSalesByCashier.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по кассирам'**
  String get repSalesByCashier;

  /// No description provided for @repSalesBySeller.
  ///
  /// In ru, this message translates to:
  /// **'Продажи по продавцам'**
  String get repSalesBySeller;

  /// No description provided for @repStaffDiscountsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сумма скидок в чеках сотрудника и доля от суммы до скидок'**
  String get repStaffDiscountsTooltip;

  /// No description provided for @repStaffReturnsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты по чекам этого сотрудника, оформленные в периоде'**
  String get repStaffReturnsTooltip;

  /// No description provided for @repColVoidedShort.
  ///
  /// In ru, this message translates to:
  /// **'Аннулир.'**
  String get repColVoidedShort;

  /// No description provided for @repVoidedReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Аннулированные чеки'**
  String get repVoidedReceipts;

  /// No description provided for @repCashiers.
  ///
  /// In ru, this message translates to:
  /// **'Кассиры'**
  String get repCashiers;

  /// No description provided for @repSellers.
  ///
  /// In ru, this message translates to:
  /// **'Продавцы'**
  String get repSellers;

  /// No description provided for @repNetRevenueByStaff.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка по сотрудникам'**
  String get repNetRevenueByStaff;

  /// No description provided for @repPaymentsByMethod.
  ///
  /// In ru, this message translates to:
  /// **'Оплаты по способам'**
  String get repPaymentsByMethod;

  /// No description provided for @repColReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получено'**
  String get repColReceived;

  /// No description provided for @repColRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено'**
  String get repColRefunded;

  /// No description provided for @repPaymentsStructure.
  ///
  /// In ru, this message translates to:
  /// **'Структура оплат'**
  String get repPaymentsStructure;

  /// No description provided for @repNoPayments.
  ///
  /// In ru, this message translates to:
  /// **'Нет оплат за период'**
  String get repNoPayments;

  /// No description provided for @repCustomerDebts.
  ///
  /// In ru, this message translates to:
  /// **'Долги клиентов'**
  String get repCustomerDebts;

  /// No description provided for @repDebtIssued.
  ///
  /// In ru, this message translates to:
  /// **'Выдано в долг'**
  String get repDebtIssued;

  /// No description provided for @repDebtCollected.
  ///
  /// In ru, this message translates to:
  /// **'Погашено'**
  String get repDebtCollected;

  /// No description provided for @repDebtAdjusted.
  ///
  /// In ru, this message translates to:
  /// **'Корректировки (возвраты, аннулирования)'**
  String get repDebtAdjusted;

  /// No description provided for @repDebtChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменение долга за период'**
  String get repDebtChange;

  /// No description provided for @repDebtOutstanding.
  ///
  /// In ru, this message translates to:
  /// **'Текущий долг клиентов ({count})'**
  String repDebtOutstanding(String count);

  /// No description provided for @repStockByCategory.
  ///
  /// In ru, this message translates to:
  /// **'Остатки по категориям (на сейчас)'**
  String get repStockByCategory;

  /// No description provided for @repColPositions.
  ///
  /// In ru, this message translates to:
  /// **'Позиций'**
  String get repColPositions;

  /// No description provided for @repColAtCost.
  ///
  /// In ru, this message translates to:
  /// **'По себестоимости'**
  String get repColAtCost;

  /// No description provided for @repColAtRetail.
  ///
  /// In ru, this message translates to:
  /// **'По рознице'**
  String get repColAtRetail;

  /// No description provided for @repColPotentialProfit.
  ///
  /// In ru, this message translates to:
  /// **'Потенц. прибыль'**
  String get repColPotentialProfit;

  /// No description provided for @repPositionsInStock.
  ///
  /// In ru, this message translates to:
  /// **'Позиций в наличии'**
  String get repPositionsInStock;

  /// No description provided for @repCategoriesCount.
  ///
  /// In ru, this message translates to:
  /// **'категорий: {count}'**
  String repCategoriesCount(String count);

  /// No description provided for @repStockAtCost.
  ///
  /// In ru, this message translates to:
  /// **'Склад по себестоимости'**
  String get repStockAtCost;

  /// No description provided for @repStockAtCostTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сколько денег вложено в товар на складе'**
  String get repStockAtCostTooltip;

  /// No description provided for @repStockAtCostHint.
  ///
  /// In ru, this message translates to:
  /// **'вложено в товар'**
  String get repStockAtCostHint;

  /// No description provided for @repStockAtRetail.
  ///
  /// In ru, this message translates to:
  /// **'Склад по розничным ценам'**
  String get repStockAtRetail;

  /// No description provided for @repStockAtRetailHint.
  ///
  /// In ru, this message translates to:
  /// **'если продать всё по текущим ценам'**
  String get repStockAtRetailHint;

  /// No description provided for @repPotentialProfit.
  ///
  /// In ru, this message translates to:
  /// **'Потенциальная прибыль'**
  String get repPotentialProfit;

  /// No description provided for @repAvgMarkup.
  ///
  /// In ru, this message translates to:
  /// **'наценка в среднем {pct}'**
  String repAvgMarkup(String pct);

  /// No description provided for @repNoStock.
  ///
  /// In ru, this message translates to:
  /// **'На складе нет товаров с положительным остатком'**
  String get repNoStock;

  /// No description provided for @repDeadStockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Неликвид: нет продаж {days} дней'**
  String repDeadStockTitle(String days);

  /// No description provided for @repColFrozen.
  ///
  /// In ru, this message translates to:
  /// **'Заморожено'**
  String get repColFrozen;

  /// No description provided for @repColLastSale.
  ///
  /// In ru, this message translates to:
  /// **'Последняя продажа'**
  String get repColLastSale;

  /// No description provided for @repNeverSold.
  ///
  /// In ru, this message translates to:
  /// **'не продавался'**
  String get repNeverSold;

  /// No description provided for @repNoDeadStock.
  ///
  /// In ru, this message translates to:
  /// **'Отлично — неликвидных товаров нет'**
  String get repNoDeadStock;

  /// No description provided for @repDeadStockHint.
  ///
  /// In ru, this message translates to:
  /// **'Товары с остатком, которые не продавались {days} дней. Сделайте уценку, акцию или верните поставщику.'**
  String repDeadStockHint(String days);

  /// No description provided for @repWriteOffsByReason.
  ///
  /// In ru, this message translates to:
  /// **'Списания по причинам'**
  String get repWriteOffsByReason;

  /// No description provided for @repColOperations.
  ///
  /// In ru, this message translates to:
  /// **'Операций'**
  String get repColOperations;

  /// No description provided for @repNoWriteOffs.
  ///
  /// In ru, this message translates to:
  /// **'Списаний за период нет'**
  String get repNoWriteOffs;

  /// No description provided for @salesStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Проведён'**
  String get salesStatusCompleted;

  /// No description provided for @salesStatusPartial.
  ///
  /// In ru, this message translates to:
  /// **'Частичный возврат'**
  String get salesStatusPartial;

  /// No description provided for @salesStatusReturned.
  ///
  /// In ru, this message translates to:
  /// **'Возвращён'**
  String get salesStatusReturned;

  /// No description provided for @salesStatusHeld.
  ///
  /// In ru, this message translates to:
  /// **'Отложен'**
  String get salesStatusHeld;

  /// No description provided for @salesPeriodWeek.
  ///
  /// In ru, this message translates to:
  /// **'7 дней'**
  String get salesPeriodWeek;

  /// No description provided for @salesPeriodAll.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get salesPeriodAll;

  /// No description provided for @salesPeriodCustom.
  ///
  /// In ru, this message translates to:
  /// **'Период…'**
  String get salesPeriodCustom;

  /// No description provided for @salesRefundHintCash.
  ///
  /// In ru, this message translates to:
  /// **'Выдать деньги из кассы'**
  String get salesRefundHintCash;

  /// No description provided for @salesRefundHintCard.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть на карту через терминал'**
  String get salesRefundHintCard;

  /// No description provided for @salesRefundHintTransfer.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть переводом'**
  String get salesRefundHintTransfer;

  /// No description provided for @salesRefundHintDebt.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить долг клиента'**
  String get salesRefundHintDebt;

  /// No description provided for @salesRefundHintBonus.
  ///
  /// In ru, this message translates to:
  /// **'Начислить на бонусный счёт клиента'**
  String get salesRefundHintBonus;

  /// No description provided for @salesReturnPeriodExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок возврата ({days} дн.) истёк'**
  String salesReturnPeriodExpired(String days);

  /// No description provided for @salesVoidAlready.
  ///
  /// In ru, this message translates to:
  /// **'Чек уже аннулирован'**
  String get salesVoidAlready;

  /// No description provided for @salesVoidOnlyNoReturns.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать можно только чек без возвратов'**
  String get salesVoidOnlyNoReturns;

  /// No description provided for @salesVoidShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена чека закрыта — оформите возврат'**
  String get salesVoidShiftClosed;

  /// No description provided for @salesVoidOtherShift.
  ///
  /// In ru, this message translates to:
  /// **'Чек из другой смены — оформите возврат'**
  String get salesVoidOtherShift;

  /// No description provided for @salesReasonDefect.
  ///
  /// In ru, this message translates to:
  /// **'Брак'**
  String get salesReasonDefect;

  /// No description provided for @salesReasonNotFit.
  ///
  /// In ru, this message translates to:
  /// **'Не подошёл'**
  String get salesReasonNotFit;

  /// No description provided for @salesReasonCashierError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка кассира'**
  String get salesReasonCashierError;

  /// No description provided for @salesReasonOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get salesReasonOther;

  /// No description provided for @salesPickPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выберите период'**
  String get salesPickPeriod;

  /// No description provided for @salesSlipTitle.
  ///
  /// In ru, this message translates to:
  /// **'АКТ ВОЗВРАТА ТОВАРА №{number}'**
  String salesSlipTitle(String number);

  /// No description provided for @salesSlipBySale.
  ///
  /// In ru, this message translates to:
  /// **'По чеку'**
  String get salesSlipBySale;

  /// No description provided for @salesSlipSaleRef.
  ///
  /// In ru, this message translates to:
  /// **'№{number} от {date}'**
  String salesSlipSaleRef(String number, String date);

  /// No description provided for @salesSlipBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get salesSlipBuyer;

  /// No description provided for @salesSlipMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ возврата'**
  String get salesSlipMethod;

  /// No description provided for @salesSlipRestock.
  ///
  /// In ru, this message translates to:
  /// **'На склад'**
  String get salesSlipRestock;

  /// No description provided for @salesSlipYes.
  ///
  /// In ru, this message translates to:
  /// **'да'**
  String get salesSlipYes;

  /// No description provided for @salesSlipNoRestock.
  ///
  /// In ru, this message translates to:
  /// **'нет (брак / не подлежит продаже)'**
  String get salesSlipNoRestock;

  /// No description provided for @salesSlipQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get salesSlipQty;

  /// No description provided for @salesSlipTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого к возврату: {amount}'**
  String salesSlipTotal(String amount);

  /// No description provided for @salesSlipIssued.
  ///
  /// In ru, this message translates to:
  /// **'Выдал: {name} ____________'**
  String salesSlipIssued(String name);

  /// No description provided for @salesSlipReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получил: ____________'**
  String get salesSlipReceived;

  /// No description provided for @salesSlipJobName.
  ///
  /// In ru, this message translates to:
  /// **'Возврат {number}'**
  String salesSlipJobName(String number);

  /// No description provided for @salesReturnWizardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возврат по чеку №{number}'**
  String salesReturnWizardTitle(String number);

  /// No description provided for @salesNotMore.
  ///
  /// In ru, this message translates to:
  /// **'Не больше {qty}'**
  String salesNotMore(String qty);

  /// No description provided for @salesIntegerOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только целое'**
  String get salesIntegerOnly;

  /// No description provided for @salesCheckQty.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте количество в отмеченных строках'**
  String get salesCheckQty;

  /// No description provided for @salesSelectItems.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товары и количество для возврата'**
  String get salesSelectItems;

  /// No description provided for @salesEnterReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину возврата'**
  String get salesEnterReason;

  /// No description provided for @salesOpenShiftForCash.
  ///
  /// In ru, this message translates to:
  /// **'Для возврата наличными откройте смену'**
  String get salesOpenShiftForCash;

  /// No description provided for @salesConfirmReturnTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформить возврат?'**
  String get salesConfirmReturnTitle;

  /// No description provided for @salesConfirmReturnMessage.
  ///
  /// In ru, this message translates to:
  /// **'{method}: {amount}\nПозиций: {count}. {restock}'**
  String salesConfirmReturnMessage(
    String method,
    String amount,
    String count,
    String restock,
  );

  /// No description provided for @salesRestockYes.
  ///
  /// In ru, this message translates to:
  /// **'Товар вернётся на склад.'**
  String get salesRestockYes;

  /// No description provided for @salesRestockNo.
  ///
  /// In ru, this message translates to:
  /// **'Товар НЕ вернётся на склад.'**
  String get salesRestockNo;

  /// No description provided for @salesDoReturn.
  ///
  /// In ru, this message translates to:
  /// **'Оформить возврат'**
  String get salesDoReturn;

  /// No description provided for @salesAllReturned.
  ///
  /// In ru, this message translates to:
  /// **'Все товары уже возвращены'**
  String get salesAllReturned;

  /// No description provided for @salesReturnExpiredBanner.
  ///
  /// In ru, this message translates to:
  /// **'{reason}. Возврат по чеку от {date} невозможен — для брака оформите гарантийную заявку.'**
  String salesReturnExpiredBanner(String reason, String date);

  /// No description provided for @salesWhatToReturn.
  ///
  /// In ru, this message translates to:
  /// **'Что возвращаем'**
  String get salesWhatToReturn;

  /// No description provided for @salesReturnAll.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть всё'**
  String get salesReturnAll;

  /// No description provided for @salesHowToRefund.
  ///
  /// In ru, this message translates to:
  /// **'Как вернуть деньги'**
  String get salesHowToRefund;

  /// No description provided for @salesNoShiftNoCash.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта — возврат наличными невозможен'**
  String get salesNoShiftNoCash;

  /// No description provided for @salesDebtExcess.
  ///
  /// In ru, this message translates to:
  /// **'Долг клиента {debt} — излишек {excess} станет авансом клиента'**
  String salesDebtExcess(String debt, String excess);

  /// No description provided for @salesPaidList.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено: {list}'**
  String salesPaidList(String list);

  /// No description provided for @salesRestockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть товар на склад'**
  String get salesRestockTitle;

  /// No description provided for @salesRestockOn.
  ///
  /// In ru, this message translates to:
  /// **'Остаток увеличится на возвращаемое количество'**
  String get salesRestockOn;

  /// No description provided for @salesRestockOff.
  ///
  /// In ru, this message translates to:
  /// **'Товар не вернётся в остаток (брак). После возврата можно оформить гарантийную заявку'**
  String get salesRestockOff;

  /// No description provided for @salesReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина возврата *'**
  String get salesReasonLabel;

  /// No description provided for @salesReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину'**
  String get salesReasonRequired;

  /// No description provided for @salesBonusClawback.
  ///
  /// In ru, this message translates to:
  /// **'С клиента будет списано до {amount} начисленных бонусов'**
  String salesBonusClawback(String amount);

  /// No description provided for @salesToRefund.
  ///
  /// In ru, this message translates to:
  /// **'К возврату'**
  String get salesToRefund;

  /// No description provided for @salesBought.
  ///
  /// In ru, this message translates to:
  /// **'куплено {qty}'**
  String salesBought(String qty);

  /// No description provided for @salesReturnedQty.
  ///
  /// In ru, this message translates to:
  /// **'возвращено {qty}'**
  String salesReturnedQty(String qty);

  /// No description provided for @salesPaidAmount.
  ///
  /// In ru, this message translates to:
  /// **'оплачено {amount}'**
  String salesPaidAmount(String amount);

  /// No description provided for @salesLess.
  ///
  /// In ru, this message translates to:
  /// **'Меньше'**
  String get salesLess;

  /// No description provided for @salesMore.
  ///
  /// In ru, this message translates to:
  /// **'Больше'**
  String get salesMore;

  /// No description provided for @salesOfQty.
  ///
  /// In ru, this message translates to:
  /// **'из {qty}'**
  String salesOfQty(String qty);

  /// No description provided for @salesReceiptNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Чек не найден'**
  String get salesReceiptNotFound;

  /// No description provided for @salesReceiptVoided.
  ///
  /// In ru, this message translates to:
  /// **'Чек аннулирован'**
  String get salesReceiptVoided;

  /// No description provided for @salesReceiptCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копия чека'**
  String get salesReceiptCopy;

  /// No description provided for @salesReceiptText.
  ///
  /// In ru, this message translates to:
  /// **'Текст чека'**
  String get salesReceiptText;

  /// No description provided for @salesVoid.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать'**
  String get salesVoid;

  /// No description provided for @salesReturnsSection.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты ({count})'**
  String salesReturnsSection(String count);

  /// No description provided for @salesReceiptNo.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number}'**
  String salesReceiptNo(String number);

  /// No description provided for @salesShiftNo.
  ///
  /// In ru, this message translates to:
  /// **'смена №{number}'**
  String salesShiftNo(String number);

  /// No description provided for @salesVoidedReason.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирован: {reason}'**
  String salesVoidedReason(String reason);

  /// No description provided for @salesParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get salesParticipants;

  /// No description provided for @salesSeller.
  ///
  /// In ru, this message translates to:
  /// **'Продавец'**
  String get salesSeller;

  /// No description provided for @salesNoCustomer.
  ///
  /// In ru, this message translates to:
  /// **'без клиента'**
  String get salesNoCustomer;

  /// No description provided for @salesPromoCode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get salesPromoCode;

  /// No description provided for @salesItemsSection.
  ///
  /// In ru, this message translates to:
  /// **'Товары ({count})'**
  String salesItemsSection(String count);

  /// No description provided for @salesSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма без скидки'**
  String get salesSubtotal;

  /// No description provided for @salesVatIncluded.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. НДС'**
  String get salesVatIncluded;

  /// No description provided for @salesBonusEarned.
  ///
  /// In ru, this message translates to:
  /// **'Начислено бонусов'**
  String get salesBonusEarned;

  /// No description provided for @salesRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено'**
  String get salesRefunded;

  /// No description provided for @salesReceiptTextCopied.
  ///
  /// In ru, this message translates to:
  /// **'Текст чека скопирован'**
  String get salesReceiptTextCopied;

  /// No description provided for @salesCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get salesCopy;

  /// No description provided for @salesVoidPromptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать чек №{number}'**
  String salesVoidPromptTitle(String number);

  /// No description provided for @salesReasonRequiredLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина *'**
  String get salesReasonRequiredLabel;

  /// No description provided for @salesVoidConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировать чек?'**
  String get salesVoidConfirmTitle;

  /// No description provided for @salesVoidConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} на {amount} будет отменён целиком: товар вернётся на склад, оплата — по исходным способам. Действие необратимо.'**
  String salesVoidConfirmMessage(String number, String amount);

  /// No description provided for @salesVoidDone.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} аннулирован'**
  String salesVoidDone(String number);

  /// No description provided for @salesReturnDoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возврат №{number} оформлен'**
  String salesReturnDoneTitle(String number);

  /// No description provided for @salesNotRestockedHint.
  ///
  /// In ru, this message translates to:
  /// **'Товар не возвращён на склад. Если это брак по гарантии — оформите гарантийную заявку.'**
  String get salesNotRestockedHint;

  /// No description provided for @salesWarrantyClaim.
  ///
  /// In ru, this message translates to:
  /// **'Гарантийная заявка'**
  String get salesWarrantyClaim;

  /// No description provided for @salesReturnSlip.
  ///
  /// In ru, this message translates to:
  /// **'Акт возврата'**
  String get salesReturnSlip;

  /// No description provided for @salesItemDiscount.
  ///
  /// In ru, this message translates to:
  /// **'скидка {amount}'**
  String salesItemDiscount(String amount);

  /// No description provided for @salesItemWarranty.
  ///
  /// In ru, this message translates to:
  /// **'гарантия до {date}'**
  String salesItemWarranty(String date);

  /// No description provided for @salesReturnHeader.
  ///
  /// In ru, this message translates to:
  /// **'Возврат №{number} · {date}'**
  String salesReturnHeader(String number, String date);

  /// No description provided for @salesToStock.
  ///
  /// In ru, this message translates to:
  /// **'на склад'**
  String get salesToStock;

  /// No description provided for @salesNoRestock.
  ///
  /// In ru, this message translates to:
  /// **'без возврата на склад'**
  String get salesNoRestock;

  /// No description provided for @salesReasonValue.
  ///
  /// In ru, this message translates to:
  /// **'Причина: {reason}'**
  String salesReasonValue(String reason);

  /// No description provided for @salesReceiptNoNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} не найден'**
  String salesReceiptNoNotFound(String number);

  /// No description provided for @salesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чеки'**
  String get salesTitle;

  /// No description provided for @salesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'История продаж и возвраты'**
  String get salesSubtitle;

  /// No description provided for @salesTabReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get salesTabReturns;

  /// No description provided for @salesNoShiftReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта. Вы видите только чеки текущей смены.'**
  String get salesNoShiftReceipts;

  /// No description provided for @salesShiftReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Показаны чеки текущей смены №{number}'**
  String salesShiftReceipts(String number);

  /// No description provided for @salesSelectReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Выберите чек'**
  String get salesSelectReceipt;

  /// No description provided for @salesSelectReceiptHint.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся состав чека, оплаты, возвраты и действия'**
  String get salesSelectReceiptHint;

  /// No description provided for @salesNoReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков не найдено'**
  String get salesNoReceipts;

  /// No description provided for @salesNoReceiptsFiltered.
  ///
  /// In ru, this message translates to:
  /// **'Измените условия поиска или сбросьте фильтры'**
  String get salesNoReceiptsFiltered;

  /// No description provided for @salesNoSalesInShift.
  ///
  /// In ru, this message translates to:
  /// **'В текущей смене продаж пока нет'**
  String get salesNoSalesInShift;

  /// No description provided for @salesNoSalesInPeriod.
  ///
  /// In ru, this message translates to:
  /// **'За выбранный период продаж нет'**
  String get salesNoSalesInPeriod;

  /// No description provided for @salesResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get salesResetFilters;

  /// No description provided for @salesShowAllTime.
  ///
  /// In ru, this message translates to:
  /// **'Показать за всё время'**
  String get salesShowAllTime;

  /// No description provided for @salesShowMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get salesShowMore;

  /// No description provided for @salesSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Номер чека, клиент или товар'**
  String get salesSearchHint;

  /// No description provided for @salesAnyFem.
  ///
  /// In ru, this message translates to:
  /// **'Любая'**
  String get salesAnyFem;

  /// No description provided for @salesReceiptsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get salesReceiptsLabel;

  /// No description provided for @salesSalesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get salesSalesLabel;

  /// No description provided for @salesVoidedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировано'**
  String get salesVoidedLabel;

  /// No description provided for @salesPositionsShort.
  ///
  /// In ru, this message translates to:
  /// **'{n} поз.'**
  String salesPositionsShort(String n);

  /// No description provided for @salesNoReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвратов нет'**
  String get salesNoReturns;

  /// No description provided for @salesChangeSearch.
  ///
  /// In ru, this message translates to:
  /// **'Измените условия поиска'**
  String get salesChangeSearch;

  /// No description provided for @salesNoReturnsHint.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты оформляются из карточки чека во вкладке «Чеки»'**
  String get salesNoReturnsHint;

  /// No description provided for @salesReturnTitle.
  ///
  /// In ru, this message translates to:
  /// **'Возврат №{number} · чек №{sale}'**
  String salesReturnTitle(String number, String sale);

  /// No description provided for @salesReturnsSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Номер, клиент или причина'**
  String get salesReturnsSearchHint;

  /// No description provided for @salesMethodLabel.
  ///
  /// In ru, this message translates to:
  /// **'Способ'**
  String get salesMethodLabel;

  /// No description provided for @salesAnyMasc.
  ///
  /// In ru, this message translates to:
  /// **'Любой'**
  String get salesAnyMasc;

  /// No description provided for @salesNoShiftReturns.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта. Вы видите только возвраты текущей смены.'**
  String get salesNoShiftReturns;

  /// No description provided for @salesShiftReturns.
  ///
  /// In ru, this message translates to:
  /// **'Показаны возвраты текущей смены №{number}'**
  String salesShiftReturns(String number);

  /// No description provided for @salesReturnsCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Возвратов'**
  String get salesReturnsCountLabel;

  /// No description provided for @salesSumLabel.
  ///
  /// In ru, this message translates to:
  /// **'На сумму'**
  String get salesSumLabel;

  /// No description provided for @salesSelectReturn.
  ///
  /// In ru, this message translates to:
  /// **'Выберите возврат'**
  String get salesSelectReturn;

  /// No description provided for @salesSelectReturnHint.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся чек, состав возврата и акт для печати'**
  String get salesSelectReturnHint;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа'**
  String get settingsNoAccess;

  /// No description provided for @settingsNoAccessMessage.
  ///
  /// In ru, this message translates to:
  /// **'Настройки может менять только владелец или администратор.'**
  String get settingsNoAccessMessage;

  /// No description provided for @settingsSecStore.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get settingsSecStore;

  /// No description provided for @settingsSecStoreHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, реквизиты, чек'**
  String get settingsSecStoreHint;

  /// No description provided for @settingsSecCurrency.
  ///
  /// In ru, this message translates to:
  /// **'Валюта и налоги'**
  String get settingsSecCurrency;

  /// No description provided for @settingsSecCurrencyHint.
  ///
  /// In ru, this message translates to:
  /// **'Валюта учёта, НДС'**
  String get settingsSecCurrencyHint;

  /// No description provided for @settingsSecSales.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get settingsSecSales;

  /// No description provided for @settingsSecSalesHint.
  ///
  /// In ru, this message translates to:
  /// **'Смены, возвраты, оплата'**
  String get settingsSecSalesHint;

  /// No description provided for @settingsSecLoyalty.
  ///
  /// In ru, this message translates to:
  /// **'Лояльность'**
  String get settingsSecLoyalty;

  /// No description provided for @settingsSecLoyaltyHint.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа'**
  String get settingsSecLoyaltyHint;

  /// No description provided for @settingsSecDevices.
  ///
  /// In ru, this message translates to:
  /// **'Кассы и устройства'**
  String get settingsSecDevices;

  /// No description provided for @settingsSecDevicesHint.
  ///
  /// In ru, this message translates to:
  /// **'Кассы, принтер, сканер'**
  String get settingsSecDevicesHint;

  /// No description provided for @settingsSecAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Внешний вид'**
  String get settingsSecAppearance;

  /// No description provided for @settingsSecAppearanceHint.
  ///
  /// In ru, this message translates to:
  /// **'Светлая и тёмная тема'**
  String get settingsSecAppearanceHint;

  /// No description provided for @settingsSecBackup.
  ///
  /// In ru, this message translates to:
  /// **'Резервное копирование'**
  String get settingsSecBackup;

  /// No description provided for @settingsSecBackupHint.
  ///
  /// In ru, this message translates to:
  /// **'Копии и восстановление'**
  String get settingsSecBackupHint;

  /// No description provided for @settingsSecData.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get settingsSecData;

  /// No description provided for @settingsSecDataHint.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим, экспорт'**
  String get settingsSecDataHint;

  /// No description provided for @settingsSecAbout.
  ///
  /// In ru, this message translates to:
  /// **'О программе'**
  String get settingsSecAbout;

  /// No description provided for @settingsSecAboutHint.
  ///
  /// In ru, this message translates to:
  /// **'Версия, лицензия, помощь'**
  String get settingsSecAboutHint;

  /// No description provided for @settingsDiscardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить изменения?'**
  String get settingsDiscardTitle;

  /// No description provided for @settingsDiscardMessage.
  ///
  /// In ru, this message translates to:
  /// **'В разделе есть несохранённые изменения. Если уйти, они будут потеряны.'**
  String get settingsDiscardMessage;

  /// No description provided for @settingsDiscardOk.
  ///
  /// In ru, this message translates to:
  /// **'Не сохранять'**
  String get settingsDiscardOk;

  /// No description provided for @settingsUnsavedBar.
  ///
  /// In ru, this message translates to:
  /// **'Есть несохранённые изменения (Ctrl+S — сохранить)'**
  String get settingsUnsavedBar;

  /// No description provided for @settingsCancelVerb.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get settingsCancelVerb;

  /// No description provided for @settingsSaved.
  ///
  /// In ru, this message translates to:
  /// **'Настройки сохранены'**
  String get settingsSaved;

  /// No description provided for @settingsSwitchOn.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» — включено'**
  String settingsSwitchOn(String title);

  /// No description provided for @settingsSwitchOff.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» — выключено'**
  String settingsSwitchOff(String title);

  /// No description provided for @settingsCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get settingsCopied;

  /// No description provided for @settingsErrPercentRange.
  ///
  /// In ru, this message translates to:
  /// **'Укажите значение от {min} до {max}'**
  String settingsErrPercentRange(String min, String max);

  /// No description provided for @settingsErrPercentNumber.
  ///
  /// In ru, this message translates to:
  /// **'Введите число, например 2 или 2,5'**
  String get settingsErrPercentNumber;

  /// No description provided for @settingsErrPercentAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Допустимо от {min} до {max} %'**
  String settingsErrPercentAllowed(String min, String max);

  /// No description provided for @settingsErrTwoDecimals.
  ///
  /// In ru, this message translates to:
  /// **'Не больше двух знаков после запятой'**
  String get settingsErrTwoDecimals;

  /// No description provided for @settingsErrReturnDaysEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Укажите количество дней (0 — без ограничения)'**
  String get settingsErrReturnDaysEmpty;

  /// No description provided for @settingsErrReturnDaysInt.
  ///
  /// In ru, this message translates to:
  /// **'Введите целое число дней'**
  String get settingsErrReturnDaysInt;

  /// No description provided for @settingsErrNotNegative.
  ///
  /// In ru, this message translates to:
  /// **'Не может быть отрицательным'**
  String get settingsErrNotNegative;

  /// No description provided for @settingsErrReturnDaysMax.
  ///
  /// In ru, this message translates to:
  /// **'Не больше 3650 дней (10 лет)'**
  String get settingsErrReturnDaysMax;

  /// No description provided for @settingsErrStoreNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Название магазина обязательно — оно печатается в чеке'**
  String get settingsErrStoreNameRequired;

  /// No description provided for @settingsErrMaxLength.
  ///
  /// In ru, this message translates to:
  /// **'Не длиннее {max} символов'**
  String settingsErrMaxLength(String max);

  /// No description provided for @settingsErrPhoneChars.
  ///
  /// In ru, this message translates to:
  /// **'Только цифры, пробел, +, - и скобки'**
  String get settingsErrPhoneChars;

  /// No description provided for @settingsErrPhoneDigits.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте номер: от 5 до 15 цифр'**
  String get settingsErrPhoneDigits;

  /// No description provided for @settingsErrTaxIdDigits.
  ///
  /// In ru, this message translates to:
  /// **'ИНН состоит только из цифр'**
  String get settingsErrTaxIdDigits;

  /// No description provided for @settingsErrTaxIdLength.
  ///
  /// In ru, this message translates to:
  /// **'ИНН должен содержать от 9 до 14 цифр'**
  String get settingsErrTaxIdLength;

  /// No description provided for @settingsErrFooterLines.
  ///
  /// In ru, this message translates to:
  /// **'Не больше 6 строк'**
  String get settingsErrFooterLines;

  /// No description provided for @settingsErrBanknoteNotNumber.
  ///
  /// In ru, this message translates to:
  /// **'«{value}» — не число. Дробную часть пишите через точку'**
  String settingsErrBanknoteNotNumber(String value);

  /// No description provided for @settingsErrBanknoteNoFraction.
  ///
  /// In ru, this message translates to:
  /// **'«{value}»: у {code} нет дробных единиц'**
  String settingsErrBanknoteNoFraction(String value, String code);

  /// No description provided for @settingsErrBanknoteTooManyDecimals.
  ///
  /// In ru, this message translates to:
  /// **'«{value}»: слишком много знаков после точки'**
  String settingsErrBanknoteTooManyDecimals(String value);

  /// No description provided for @settingsErrBanknotePositive.
  ///
  /// In ru, this message translates to:
  /// **'«{value}» — номинал должен быть больше нуля'**
  String settingsErrBanknotePositive(String value);

  /// No description provided for @settingsErrBanknoteTooBig.
  ///
  /// In ru, this message translates to:
  /// **'«{value}» — слишком большой номинал'**
  String settingsErrBanknoteTooBig(String value);

  /// No description provided for @settingsErrBanknoteDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Номинал «{value}» указан дважды'**
  String settingsErrBanknoteDuplicate(String value);

  /// No description provided for @settingsErrBanknotesMax.
  ///
  /// In ru, this message translates to:
  /// **'Не больше {max} номиналов — кнопки должны помещаться на экране'**
  String settingsErrBanknotesMax(String max);

  /// No description provided for @settingsErrRegisterNameEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Введите название кассы'**
  String get settingsErrRegisterNameEmpty;

  /// No description provided for @settingsErrRegisterDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Касса с таким названием уже есть'**
  String get settingsErrRegisterDuplicate;

  /// No description provided for @settingsCurrencyLocked.
  ///
  /// In ru, this message translates to:
  /// **'Валюту нельзя менять: в базе уже есть продажи'**
  String get settingsCurrencyLocked;

  /// No description provided for @settingsRegisterBusy.
  ///
  /// In ru, this message translates to:
  /// **'На этой кассе открыта смена. Сначала закройте смену, затем отключайте или удаляйте кассу.'**
  String get settingsRegisterBusy;

  /// No description provided for @settingsRoundingNone.
  ///
  /// In ru, this message translates to:
  /// **'Без округления'**
  String get settingsRoundingNone;

  /// No description provided for @settingsRoundingStep.
  ///
  /// In ru, this message translates to:
  /// **'Кратно {amount}'**
  String settingsRoundingStep(String amount);

  /// No description provided for @settingsLoyaltyExample.
  ///
  /// In ru, this message translates to:
  /// **'С покупки {purchase} начислится {earned} бонусов (1 бонус = 1 {symbol}). Бонусами можно оплатить до {percent}% чека — до {redeem}.'**
  String settingsLoyaltyExample(
    String purchase,
    String earned,
    String symbol,
    String percent,
    String redeem,
  );

  /// No description provided for @settingsBytes.
  ///
  /// In ru, this message translates to:
  /// **'{n} Б'**
  String settingsBytes(String n);

  /// No description provided for @settingsKilobytes.
  ///
  /// In ru, this message translates to:
  /// **'{n} КБ'**
  String settingsKilobytes(String n);

  /// No description provided for @settingsMegabytes.
  ///
  /// In ru, this message translates to:
  /// **'{n} МБ'**
  String settingsMegabytes(String n);

  /// No description provided for @settingsGigabytes.
  ///
  /// In ru, this message translates to:
  /// **'{n} ГБ'**
  String settingsGigabytes(String n);

  /// No description provided for @settingsSampleCashier.
  ///
  /// In ru, this message translates to:
  /// **'Образец'**
  String get settingsSampleCashier;

  /// No description provided for @settingsSampleItemMilk.
  ///
  /// In ru, this message translates to:
  /// **'Молоко 2,5% 1 л'**
  String get settingsSampleItemMilk;

  /// No description provided for @settingsSampleItemBread.
  ///
  /// In ru, this message translates to:
  /// **'Хлеб белый'**
  String get settingsSampleItemBread;

  /// No description provided for @settingsSampleItemTea.
  ///
  /// In ru, this message translates to:
  /// **'Чай чёрный 100 г'**
  String get settingsSampleItemTea;

  /// No description provided for @settingsDiagPlatform.
  ///
  /// In ru, this message translates to:
  /// **'Платформа: {value}'**
  String settingsDiagPlatform(String value);

  /// No description provided for @settingsDiagStore.
  ///
  /// In ru, this message translates to:
  /// **'Магазин: {value}'**
  String settingsDiagStore(String value);

  /// No description provided for @settingsCurrencyValue.
  ///
  /// In ru, this message translates to:
  /// **'Валюта: {value}'**
  String settingsCurrencyValue(String value);

  /// No description provided for @settingsDiagDemo.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим: {value}'**
  String settingsDiagDemo(String value);

  /// No description provided for @settingsYesLower.
  ///
  /// In ru, this message translates to:
  /// **'да'**
  String get settingsYesLower;

  /// No description provided for @settingsNoLower.
  ///
  /// In ru, this message translates to:
  /// **'нет'**
  String get settingsNoLower;

  /// No description provided for @settingsDiagDbSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер базы: {value}'**
  String settingsDiagDbSize(String value);

  /// No description provided for @settingsDiagProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товаров: {value}'**
  String settingsDiagProducts(String value);

  /// No description provided for @settingsDiagSales.
  ///
  /// In ru, this message translates to:
  /// **'Продаж: {value}'**
  String settingsDiagSales(String value);

  /// No description provided for @settingsDiagCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Клиентов: {value}'**
  String settingsDiagCustomers(String value);

  /// No description provided for @settingsDiagUsers.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудников: {value}'**
  String settingsDiagUsers(String value);

  /// No description provided for @settingsDiagLastBackup.
  ///
  /// In ru, this message translates to:
  /// **'Последняя резервная копия: {value}'**
  String settingsDiagLastBackup(String value);

  /// No description provided for @settingsDiagGenerated.
  ///
  /// In ru, this message translates to:
  /// **'Сформировано: {value}'**
  String settingsDiagGenerated(String value);

  /// No description provided for @settingsErrBackupFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать резервную копию'**
  String get settingsErrBackupFailed;

  /// No description provided for @settingsErrNotBackup.
  ///
  /// In ru, this message translates to:
  /// **'Файл «{name}» не является резервной копией DreamPOS'**
  String settingsErrNotBackup(String name);

  /// No description provided for @settingsCsvName.
  ///
  /// In ru, this message translates to:
  /// **'Наименование'**
  String get settingsCsvName;

  /// No description provided for @settingsCsvMinStock.
  ///
  /// In ru, this message translates to:
  /// **'Мин. остаток'**
  String get settingsCsvMinStock;

  /// No description provided for @settingsCsvVatPercent.
  ///
  /// In ru, this message translates to:
  /// **'НДС %'**
  String get settingsCsvVatPercent;

  /// No description provided for @settingsCsvActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get settingsCsvActive;

  /// No description provided for @settingsCsvCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get settingsCsvCard;

  /// No description provided for @settingsCsvDiscountPercent.
  ///
  /// In ru, this message translates to:
  /// **'Скидка %'**
  String get settingsCsvDiscountPercent;

  /// No description provided for @settingsCsvDebtLimit.
  ///
  /// In ru, this message translates to:
  /// **'Лимит долга'**
  String get settingsCsvDebtLimit;

  /// No description provided for @settingsCsvTotalSpent.
  ///
  /// In ru, this message translates to:
  /// **'Покупок на сумму'**
  String get settingsCsvTotalSpent;

  /// No description provided for @settingsCsvVisits.
  ///
  /// In ru, this message translates to:
  /// **'Визитов'**
  String get settingsCsvVisits;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsAboutTagline.
  ///
  /// In ru, this message translates to:
  /// **'Касса и учёт для розничных магазинов. Работает без интернета.'**
  String get settingsAboutTagline;

  /// No description provided for @settingsLicense.
  ///
  /// In ru, this message translates to:
  /// **'Лицензия'**
  String get settingsLicense;

  /// No description provided for @settingsPlan.
  ///
  /// In ru, this message translates to:
  /// **'Тариф: «Магазин» (1 точка)'**
  String get settingsPlan;

  /// No description provided for @settingsTrialExpired.
  ///
  /// In ru, this message translates to:
  /// **'Пробный период истёк'**
  String get settingsTrialExpired;

  /// No description provided for @settingsTrial.
  ///
  /// In ru, this message translates to:
  /// **'Пробный период'**
  String get settingsTrial;

  /// No description provided for @settingsTrialEnded.
  ///
  /// In ru, this message translates to:
  /// **'Пробный период закончился. Свяжитесь с поддержкой для продления — данные сохранены.'**
  String get settingsTrialEnded;

  /// No description provided for @settingsTrialLeft.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Осталось {count} день из {total} · установлено {date}} few{Осталось {count} дня из {total} · установлено {date}} many{Осталось {count} дней из {total} · установлено {date}} other{Осталось {count} дня из {total} · установлено {date}}}'**
  String settingsTrialLeft(int count, String total, String date);

  /// No description provided for @settingsSupport.
  ///
  /// In ru, this message translates to:
  /// **'Связаться с поддержкой'**
  String get settingsSupport;

  /// No description provided for @settingsSupportHint.
  ///
  /// In ru, this message translates to:
  /// **'При обращении в поддержку приложите сведения ниже — они помогут быстрее разобраться. Личные данные клиентов в них не входят.'**
  String get settingsSupportHint;

  /// No description provided for @settingsInfoCopied.
  ///
  /// In ru, this message translates to:
  /// **'Сведения скопированы'**
  String get settingsInfoCopied;

  /// No description provided for @settingsCopyInfo.
  ///
  /// In ru, this message translates to:
  /// **'Копировать сведения'**
  String get settingsCopyInfo;

  /// No description provided for @settingsRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get settingsRefresh;

  /// No description provided for @settingsAppearanceDesc.
  ///
  /// In ru, this message translates to:
  /// **'Тема оформления применяется сразу на всех экранах этой программы.'**
  String get settingsAppearanceDesc;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeHint.
  ///
  /// In ru, this message translates to:
  /// **'«Авто» — как в настройках Windows/Android. Тёмная тема снижает нагрузку на глаза в вечернюю смену и экономит заряд на телефонах с OLED-экраном. Светлая лучше читается при ярком освещении торгового зала.'**
  String get settingsThemeHint;

  /// No description provided for @settingsBackupCreated.
  ///
  /// In ru, this message translates to:
  /// **'Копия создана: {name} ({size})'**
  String settingsBackupCreated(String name, String size);

  /// No description provided for @settingsBackupDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить копию?'**
  String get settingsBackupDeleteTitle;

  /// No description provided for @settingsBackupDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'{name}\n{date} · {size}\n\nФайл будет удалён с диска без возможности восстановления.'**
  String settingsBackupDeleteMessage(String name, String date, String size);

  /// No description provided for @settingsBackupDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Копия удалена'**
  String get settingsBackupDeleted;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить данные из копии?'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreMessage.
  ///
  /// In ru, this message translates to:
  /// **'Копия от {date} заменит ВСЕ текущие данные: товары, продажи, клиентов, смены и настройки. Всё, что сделано после этой даты, пропадёт.\n\nПеред восстановлением будет автоматически создана копия текущих данных.\n\nДанные заменятся при следующем запуске программы.'**
  String settingsRestoreMessage(String date);

  /// No description provided for @settingsRestore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get settingsRestore;

  /// No description provided for @settingsRestartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перезапустите программу'**
  String get settingsRestartTitle;

  /// No description provided for @settingsRestartMessage.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление подготовлено.\n\n1. Закройте DreamPOS на этом компьютере.\n2. Запустите программу снова — данные будут заменены копией.\n3. Войдите и проверьте товары и последние продажи.\n\nДо перезапуска не проводите продажи: они будут потеряны.'**
  String get settingsRestartMessage;

  /// No description provided for @settingsGotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get settingsGotIt;

  /// No description provided for @settingsRestoreCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление отменено'**
  String get settingsRestoreCancelled;

  /// No description provided for @settingsBackupDesc.
  ///
  /// In ru, this message translates to:
  /// **'Копия базы данных защищает от потери данных при поломке компьютера, вирусе или ошибке. Храните копии также на флешке или в облаке.'**
  String get settingsBackupDesc;

  /// No description provided for @settingsRestorePending.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление из копии подготовлено. Перезапустите программу, чтобы заменить данные.'**
  String get settingsRestorePending;

  /// No description provided for @settingsLastBackup.
  ///
  /// In ru, this message translates to:
  /// **'Последняя копия'**
  String get settingsLastBackup;

  /// No description provided for @settingsNeverBackedUp.
  ///
  /// In ru, this message translates to:
  /// **'ещё не создавалась'**
  String get settingsNeverBackedUp;

  /// No description provided for @settingsBackupWeekly.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуем делать копию хотя бы раз в неделю'**
  String get settingsBackupWeekly;

  /// No description provided for @settingsBackupCreateNow.
  ///
  /// In ru, this message translates to:
  /// **'Создать копию сейчас'**
  String get settingsBackupCreateNow;

  /// No description provided for @settingsAutoBackup.
  ///
  /// In ru, this message translates to:
  /// **'Ежедневная автоматическая копия'**
  String get settingsAutoBackup;

  /// No description provided for @settingsAutoBackupHint.
  ///
  /// In ru, this message translates to:
  /// **'Создаётся раз в сутки при запуске программы'**
  String get settingsAutoBackupHint;

  /// No description provided for @settingsBackupFolder.
  ///
  /// In ru, this message translates to:
  /// **'Папка с копиями'**
  String get settingsBackupFolder;

  /// No description provided for @settingsCopyPath.
  ///
  /// In ru, this message translates to:
  /// **'Копировать путь'**
  String get settingsCopyPath;

  /// No description provided for @settingsPathCopied.
  ///
  /// In ru, this message translates to:
  /// **'Путь скопирован'**
  String get settingsPathCopied;

  /// No description provided for @settingsBackups.
  ///
  /// In ru, this message translates to:
  /// **'Копии'**
  String get settingsBackups;

  /// No description provided for @settingsNoBackups.
  ///
  /// In ru, this message translates to:
  /// **'Копий пока нет. Нажмите «Создать копию сейчас».'**
  String get settingsNoBackups;

  /// No description provided for @settingsRestoreInfo.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление заменяет все данные программы содержимым копии и требует перезапуска. Перед восстановлением автоматически создаётся копия текущих данных.'**
  String get settingsRestoreInfo;

  /// No description provided for @settingsCurUzs.
  ///
  /// In ru, this message translates to:
  /// **'Узбекский сум'**
  String get settingsCurUzs;

  /// No description provided for @settingsCurTjs.
  ///
  /// In ru, this message translates to:
  /// **'Таджикский сомони'**
  String get settingsCurTjs;

  /// No description provided for @settingsCurKzt.
  ///
  /// In ru, this message translates to:
  /// **'Казахстанский тенге'**
  String get settingsCurKzt;

  /// No description provided for @settingsCurKgs.
  ///
  /// In ru, this message translates to:
  /// **'Киргизский сом'**
  String get settingsCurKgs;

  /// No description provided for @settingsCurRub.
  ///
  /// In ru, this message translates to:
  /// **'Российский рубль'**
  String get settingsCurRub;

  /// No description provided for @settingsCurUsd.
  ///
  /// In ru, this message translates to:
  /// **'Доллар США'**
  String get settingsCurUsd;

  /// No description provided for @settingsCurChangeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сменить валюту на {code}?'**
  String settingsCurChangeTitle(String code);

  /// No description provided for @settingsCurChangeSymbol.
  ///
  /// In ru, this message translates to:
  /// **'Все суммы будут показываться в «{symbol}».'**
  String settingsCurChangeSymbol(String symbol);

  /// No description provided for @settingsCurChangeRescale.
  ///
  /// In ru, this message translates to:
  /// **'Внимание: у вас уже заведено товаров: {products}. Цены хранятся в минимальных единицах, поэтому цена {from} станет {to}. Проверьте и исправьте цены после смены валюты.'**
  String settingsCurChangeRescale(String products, String from, String to);

  /// No description provided for @settingsCurChangeResetsCash.
  ///
  /// In ru, this message translates to:
  /// **'Номиналы купюр быстрой оплаты и округление наличных будут сброшены на стандартные для новой валюты (раздел «Продажи»).'**
  String get settingsCurChangeResetsCash;

  /// No description provided for @settingsCurChangeFinal.
  ///
  /// In ru, this message translates to:
  /// **'После первой продажи валюту изменить будет нельзя.'**
  String get settingsCurChangeFinal;

  /// No description provided for @settingsCurChangeOk.
  ///
  /// In ru, this message translates to:
  /// **'Сменить валюту'**
  String get settingsCurChangeOk;

  /// No description provided for @settingsCurrencyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Валюта, в которой ведётся учёт, и ставка НДС по умолчанию для новых товаров.'**
  String get settingsCurrencyDesc;

  /// No description provided for @settingsCurBase.
  ///
  /// In ru, this message translates to:
  /// **'Валюта учёта'**
  String get settingsCurBase;

  /// No description provided for @settingsCurLockedTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Валюта зафиксирована после первой продажи'**
  String get settingsCurLockedTooltip;

  /// No description provided for @settingsCurLockedBanner.
  ///
  /// In ru, this message translates to:
  /// **'Валюта зафиксирована: в базе уже есть продажи. Все суммы в чеках, отчётах, долгах и бонусах хранятся в этой валюте — её смена исказила бы всю историю.'**
  String get settingsCurLockedBanner;

  /// No description provided for @settingsCurCheckFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить наличие продаж: {error}'**
  String settingsCurCheckFailed(String error);

  /// No description provided for @settingsCurExampleCents.
  ///
  /// In ru, this message translates to:
  /// **'Пример: {amount} · с копейками'**
  String settingsCurExampleCents(String amount);

  /// No description provided for @settingsCurExampleNoCents.
  ///
  /// In ru, this message translates to:
  /// **'Пример: {amount} · без копеек'**
  String settingsCurExampleNoCents(String amount);

  /// No description provided for @settingsVatDefault.
  ///
  /// In ru, this message translates to:
  /// **'НДС по умолчанию для новых товаров'**
  String get settingsVatDefault;

  /// No description provided for @settingsVatHelper.
  ///
  /// In ru, this message translates to:
  /// **'0 — если магазин не плательщик НДС'**
  String get settingsVatHelper;

  /// No description provided for @settingsVatInfo.
  ///
  /// In ru, this message translates to:
  /// **'Цены товаров указываются с НДС. Сумма НДС выделяется из цены по ставке товара и печатается в чеке строкой «в т.ч. НДС». Ставку можно изменить в карточке товара.'**
  String get settingsVatInfo;

  /// No description provided for @settingsFileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Файл сохранён: {path}'**
  String settingsFileSaved(String path);

  /// No description provided for @settingsDataDesc.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим и выгрузка справочников в файлы для Excel.'**
  String get settingsDataDesc;

  /// No description provided for @settingsMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим работы'**
  String get settingsMode;

  /// No description provided for @settingsDemoMode.
  ///
  /// In ru, this message translates to:
  /// **'Демо-режим'**
  String get settingsDemoMode;

  /// No description provided for @settingsLiveDb.
  ///
  /// In ru, this message translates to:
  /// **'Рабочая база'**
  String get settingsLiveDb;

  /// No description provided for @settingsDemoText.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас в базе демонстрационные товары, клиенты и продажи. Они нужны, чтобы познакомиться с программой. Не смешивайте их с реальной торговлей.'**
  String get settingsDemoText;

  /// No description provided for @settingsLiveText.
  ///
  /// In ru, this message translates to:
  /// **'Программа работает с реальными данными магазина.'**
  String get settingsLiveText;

  /// No description provided for @settingsDemoWarning.
  ///
  /// In ru, this message translates to:
  /// **'Удалить демо-данные кнопкой нельзя: это необратимо и затронуло бы отчёты, остатки и журнал. Чтобы начать работу с чистой базой:'**
  String get settingsDemoWarning;

  /// No description provided for @settingsDemoStep1.
  ///
  /// In ru, this message translates to:
  /// **'Создайте резервную копию (раздел «Резервное копирование») — на случай, если демо-данные ещё понадобятся.'**
  String get settingsDemoStep1;

  /// No description provided for @settingsDemoStep2.
  ///
  /// In ru, this message translates to:
  /// **'Закройте программу.'**
  String get settingsDemoStep2;

  /// No description provided for @settingsDemoStep3.
  ///
  /// In ru, this message translates to:
  /// **'Удалите файл базы данных и, если есть, файлы рядом с ним, имя которых оканчивается на «wal» или «shm».'**
  String get settingsDemoStep3;

  /// No description provided for @settingsDbFile.
  ///
  /// In ru, this message translates to:
  /// **'Файл базы: {path}'**
  String settingsDbFile(String path);

  /// No description provided for @settingsDemoStep4.
  ///
  /// In ru, this message translates to:
  /// **'Запустите DreamPOS — откроется мастер первоначальной настройки. Не отмечайте «Демо-данные».'**
  String get settingsDemoStep4;

  /// No description provided for @settingsCopyDbPath.
  ///
  /// In ru, this message translates to:
  /// **'Копировать путь к базе'**
  String get settingsCopyDbPath;

  /// No description provided for @settingsExportProductsHint.
  ///
  /// In ru, this message translates to:
  /// **'Наименование, штрихкод, цены, остатки'**
  String get settingsExportProductsHint;

  /// No description provided for @settingsExportCustomersHint.
  ///
  /// In ru, this message translates to:
  /// **'Контакты, скидки, бонусы и долги'**
  String get settingsExportCustomersHint;

  /// No description provided for @settingsExportInfo.
  ///
  /// In ru, this message translates to:
  /// **'Файлы сохраняются в папку «Документы/DreamPOS/exports» в формате CSV (разделитель «;», кодировка UTF-8) — открываются в Excel и Google Таблицах. Файл клиентов содержит телефоны и долги — не пересылайте его посторонним.'**
  String get settingsExportInfo;

  /// No description provided for @settingsLastFile.
  ///
  /// In ru, this message translates to:
  /// **'Последний файл'**
  String get settingsLastFile;

  /// No description provided for @settingsDevicesDesc.
  ///
  /// In ru, this message translates to:
  /// **'Кассовые места магазина, привязка этого компьютера к кассе, сканер и принтер чеков.'**
  String get settingsDevicesDesc;

  /// No description provided for @settingsRegisterAdded.
  ///
  /// In ru, this message translates to:
  /// **'Касса «{name}» добавлена'**
  String settingsRegisterAdded(String name);

  /// No description provided for @settingsRegisterSaved.
  ///
  /// In ru, this message translates to:
  /// **'Касса сохранена'**
  String get settingsRegisterSaved;

  /// No description provided for @settingsRegisterDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить кассу «{name}»?'**
  String settingsRegisterDeleteTitle(String name);

  /// No description provided for @settingsRegisterDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Касса исчезнет из списка. Проданные на ней чеки и отчёты сохранятся.'**
  String get settingsRegisterDeleteMessage;

  /// No description provided for @settingsRegisterDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Касса удалена'**
  String get settingsRegisterDeleted;

  /// No description provided for @settingsRegisters.
  ///
  /// In ru, this message translates to:
  /// **'Кассы'**
  String get settingsRegisters;

  /// No description provided for @settingsNoRegisters.
  ///
  /// In ru, this message translates to:
  /// **'Касс пока нет. Добавьте кассу, если в магазине несколько кассовых мест — тогда в отчётах будет видно, где пробит чек.'**
  String get settingsNoRegisters;

  /// No description provided for @settingsRegisterDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Отключена'**
  String get settingsRegisterDisabled;

  /// No description provided for @settingsThisDevice.
  ///
  /// In ru, this message translates to:
  /// **'Этот компьютер'**
  String get settingsThisDevice;

  /// No description provided for @settingsRegisterDefaultName.
  ///
  /// In ru, this message translates to:
  /// **'Касса {number}'**
  String settingsRegisterDefaultName(String number);

  /// No description provided for @settingsNewRegister.
  ///
  /// In ru, this message translates to:
  /// **'Новая касса'**
  String get settingsNewRegister;

  /// No description provided for @settingsRegister.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get settingsRegister;

  /// No description provided for @settingsRegisterNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Касса 1, Склад, Отдел №2'**
  String get settingsRegisterNameHint;

  /// No description provided for @settingsRegisterActive.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get settingsRegisterActive;

  /// No description provided for @settingsRegisterActiveHint.
  ///
  /// In ru, this message translates to:
  /// **'Отключённую кассу нельзя выбрать для работы'**
  String get settingsRegisterActiveHint;

  /// No description provided for @settingsThisDeviceHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите, какой кассой работает это устройство. Настройка хранится только на этом компьютере и не переносится на другие.'**
  String get settingsThisDeviceHint;

  /// No description provided for @settingsAddRegisterFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте хотя бы одну активную кассу.'**
  String get settingsAddRegisterFirst;

  /// No description provided for @settingsDeviceRegister.
  ///
  /// In ru, this message translates to:
  /// **'Касса этого устройства'**
  String get settingsDeviceRegister;

  /// No description provided for @settingsNotSelected.
  ///
  /// In ru, this message translates to:
  /// **'Не выбрана'**
  String get settingsNotSelected;

  /// No description provided for @settingsDeviceRegisterSet.
  ///
  /// In ru, this message translates to:
  /// **'Касса для этого устройства выбрана'**
  String get settingsDeviceRegisterSet;

  /// No description provided for @settingsDeviceRegisterGone.
  ///
  /// In ru, this message translates to:
  /// **'Ранее выбранная касса удалена или отключена — выберите другую.'**
  String get settingsDeviceRegisterGone;

  /// No description provided for @settingsTestPrintTitle.
  ///
  /// In ru, this message translates to:
  /// **'ТЕСТОВАЯ ПЕЧАТЬ'**
  String get settingsTestPrintTitle;

  /// No description provided for @settingsNotFiscal.
  ///
  /// In ru, this message translates to:
  /// **'Не является фискальным документом'**
  String get settingsNotFiscal;

  /// No description provided for @settingsTestReceiptJob.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый чек'**
  String get settingsTestReceiptJob;

  /// No description provided for @settingsPrinter.
  ///
  /// In ru, this message translates to:
  /// **'Принтер чеков'**
  String get settingsPrinter;

  /// No description provided for @settingsPrinterHint.
  ///
  /// In ru, this message translates to:
  /// **'Чек печатается через системный диалог печати. Установите драйвер принтера и выберите его принтером по умолчанию. Ширина ленты сейчас: {width} мм (меняется в разделе «Магазин»).'**
  String settingsPrinterHint(String width);

  /// No description provided for @settingsPrintTest.
  ///
  /// In ru, this message translates to:
  /// **'Напечатать тестовый чек'**
  String get settingsPrintTest;

  /// No description provided for @settingsScanner.
  ///
  /// In ru, this message translates to:
  /// **'Сканер штрихкодов'**
  String get settingsScanner;

  /// No description provided for @settingsScannerTip1.
  ///
  /// In ru, this message translates to:
  /// **'Подключите USB‑сканер — он работает как клавиатура, драйвер обычно не нужен.'**
  String get settingsScannerTip1;

  /// No description provided for @settingsScannerTip2.
  ///
  /// In ru, this message translates to:
  /// **'Сканер должен отправлять Enter после кода (суффикс CR). Так настроено у большинства моделей.'**
  String get settingsScannerTip2;

  /// No description provided for @settingsScannerTip3.
  ///
  /// In ru, this message translates to:
  /// **'Раскладка клавиатуры: если вместо цифр печатаются другие символы, переключите раскладку на EN или настройте сканер на «цифровой» режим.'**
  String get settingsScannerTip3;

  /// No description provided for @settingsScannerTip4.
  ///
  /// In ru, this message translates to:
  /// **'Проверка: откройте поиск товара и отсканируйте штрихкод — код должен появиться целиком.'**
  String get settingsScannerTip4;

  /// No description provided for @settingsScannerTip5.
  ///
  /// In ru, this message translates to:
  /// **'Беспроводные сканеры работают так же; держите базу в пределах 10 м от кассы.'**
  String get settingsScannerTip5;

  /// No description provided for @settingsLoyaltyDesc.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа: клиент получает бонусы с покупок и оплачивает ими часть следующих покупок. 1 бонус = 1 единица валюты.'**
  String get settingsLoyaltyDesc;

  /// No description provided for @settingsLoyaltyEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Бонусная программа включена'**
  String get settingsLoyaltyEnabled;

  /// No description provided for @settingsLoyaltyEnabledHint.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы начисляются только покупателям, выбранным в чеке'**
  String get settingsLoyaltyEnabledHint;

  /// No description provided for @settingsRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила'**
  String get settingsRules;

  /// No description provided for @settingsLoyaltyOff.
  ///
  /// In ru, this message translates to:
  /// **'Программа выключена: бонусы не начисляются и не списываются. Накопленные балансы клиентов сохраняются.'**
  String get settingsLoyaltyOff;

  /// No description provided for @settingsEarnLabel.
  ///
  /// In ru, this message translates to:
  /// **'Начислять с покупки'**
  String get settingsEarnLabel;

  /// No description provided for @settingsPercentRangeHelper.
  ///
  /// In ru, this message translates to:
  /// **'От 0 до 100'**
  String get settingsPercentRangeHelper;

  /// No description provided for @settingsRedeemLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оплата бонусами, не больше'**
  String get settingsRedeemLabel;

  /// No description provided for @settingsRedeemSuffix.
  ///
  /// In ru, this message translates to:
  /// **'% чека'**
  String get settingsRedeemSuffix;

  /// No description provided for @settingsLoyaltyEnterPercents.
  ///
  /// In ru, this message translates to:
  /// **'Введите проценты от 0 до 100, чтобы увидеть пример.'**
  String get settingsLoyaltyEnterPercents;

  /// No description provided for @settingsLoyaltyReturnInfo.
  ///
  /// In ru, this message translates to:
  /// **'При возврате товара начисленные за него бонусы списываются пропорционально. Новые проценты действуют для следующих продаж; прошлые чеки не пересчитываются.'**
  String get settingsLoyaltyReturnInfo;

  /// No description provided for @settingsShiftOffTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить продажи без смены?'**
  String get settingsShiftOffTitle;

  /// No description provided for @settingsShiftOffMessage.
  ///
  /// In ru, this message translates to:
  /// **'Не рекомендуется. Без открытой смены:\n• не будет контроля наличных в кассе и Z-отчёта;\n• продажи не попадут ни в одну смену, расхождения не найти;\n• кассиры смогут продавать, не пересчитав размен.\n\nОтключайте, только если касса не принимает наличные.'**
  String get settingsShiftOffMessage;

  /// No description provided for @settingsShiftOffOk.
  ///
  /// In ru, this message translates to:
  /// **'Всё равно отключить'**
  String get settingsShiftOffOk;

  /// No description provided for @settingsNegativeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить продажу при нулевом остатке?'**
  String get settingsNegativeTitle;

  /// No description provided for @settingsNegativeMessage.
  ///
  /// In ru, this message translates to:
  /// **'Остаток сможет уйти в минус. Это удобно, если приход оформляют позже продажи, но скрывает пересорт и недостачи. Отрицательные остатки нужно регулярно исправлять приходом или инвентаризацией.'**
  String get settingsNegativeMessage;

  /// No description provided for @settingsAllow.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get settingsAllow;

  /// No description provided for @settingsSalesDesc.
  ///
  /// In ru, this message translates to:
  /// **'Правила, которые касса проверяет при каждой продаже и возврате.'**
  String get settingsSalesDesc;

  /// No description provided for @settingsControl.
  ///
  /// In ru, this message translates to:
  /// **'Контроль'**
  String get settingsControl;

  /// No description provided for @settingsRequireShift.
  ///
  /// In ru, this message translates to:
  /// **'Продавать только при открытой смене'**
  String get settingsRequireShift;

  /// No description provided for @settingsRequireShiftHint.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуется: контроль наличных и Z-отчёт по каждой смене'**
  String get settingsRequireShiftHint;

  /// No description provided for @settingsAllowNegative.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить продажу при нулевом остатке'**
  String get settingsAllowNegative;

  /// No description provided for @settingsAllowNegativeHint.
  ///
  /// In ru, this message translates to:
  /// **'Остаток может уйти в минус (для всех товаров)'**
  String get settingsAllowNegativeHint;

  /// No description provided for @settingsDebtLimit.
  ///
  /// In ru, this message translates to:
  /// **'В долг — только клиентам с лимитом'**
  String get settingsDebtLimit;

  /// No description provided for @settingsDebtLimitHint.
  ///
  /// In ru, this message translates to:
  /// **'Продажа в долг клиенту без установленного лимита будет запрещена'**
  String get settingsDebtLimitHint;

  /// No description provided for @settingsReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get settingsReturns;

  /// No description provided for @settingsReturnDays.
  ///
  /// In ru, this message translates to:
  /// **'Срок возврата, дней'**
  String get settingsReturnDays;

  /// No description provided for @settingsDaysSuffix.
  ///
  /// In ru, this message translates to:
  /// **'дн.'**
  String get settingsDaysSuffix;

  /// No description provided for @settingsReturnNoLimit.
  ///
  /// In ru, this message translates to:
  /// **'Без ограничения срока'**
  String get settingsReturnNoLimit;

  /// No description provided for @settingsReturnWithin.
  ///
  /// In ru, this message translates to:
  /// **'Возврат по чеку возможен в течение {days} дней. 0 — без ограничения'**
  String settingsReturnWithin(String days);

  /// No description provided for @settingsQuickCash.
  ///
  /// In ru, this message translates to:
  /// **'Быстрая оплата наличными'**
  String get settingsQuickCash;

  /// No description provided for @settingsBanknotesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Номиналы купюр на экране оплаты'**
  String get settingsBanknotesLabel;

  /// No description provided for @settingsBanknotesHelper.
  ///
  /// In ru, this message translates to:
  /// **'Через запятую, до {max} штук. Пусто — стандартный набор'**
  String settingsBanknotesHelper(String max);

  /// No description provided for @settingsPosButtons.
  ///
  /// In ru, this message translates to:
  /// **'Кнопки на кассе:'**
  String get settingsPosButtons;

  /// No description provided for @settingsCashRounding.
  ///
  /// In ru, this message translates to:
  /// **'Округление наличных'**
  String get settingsCashRounding;

  /// No description provided for @settingsRoundingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Округлять итог при оплате наличными'**
  String get settingsRoundingLabel;

  /// No description provided for @settingsRoundingChanged.
  ///
  /// In ru, this message translates to:
  /// **'Округление: {value}'**
  String settingsRoundingChanged(String value);

  /// No description provided for @settingsRoundingOff.
  ///
  /// In ru, this message translates to:
  /// **'Итог к оплате наличными не округляется.'**
  String get settingsRoundingOff;

  /// No description provided for @settingsRoundingExample.
  ///
  /// In ru, this message translates to:
  /// **'Пример: {from} → {to}. Округляется вниз, в пользу покупателя, только при оплате наличными.'**
  String settingsRoundingExample(String from, String to);

  /// No description provided for @settingsStoreName.
  ///
  /// In ru, this message translates to:
  /// **'Название магазина *'**
  String get settingsStoreName;

  /// No description provided for @settingsStoreNameHelper.
  ///
  /// In ru, this message translates to:
  /// **'Печатается в шапке чека и на экране входа'**
  String get settingsStoreNameHelper;

  /// No description provided for @settingsAddressHint.
  ///
  /// In ru, this message translates to:
  /// **'г. Ташкент, ул. Навои, 12'**
  String get settingsAddressHint;

  /// No description provided for @settingsTaxId.
  ///
  /// In ru, this message translates to:
  /// **'ИНН / БИН'**
  String get settingsTaxId;

  /// No description provided for @settingsTaxIdHelper.
  ///
  /// In ru, this message translates to:
  /// **'Только цифры, 9–14 знаков'**
  String get settingsTaxIdHelper;

  /// No description provided for @settingsFooter.
  ///
  /// In ru, this message translates to:
  /// **'Текст внизу чека'**
  String get settingsFooter;

  /// No description provided for @settingsFooterHint.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за покупку!\nОбмен и возврат в течение 14 дней'**
  String get settingsFooterHint;

  /// No description provided for @settingsPaperWidth.
  ///
  /// In ru, this message translates to:
  /// **'Ширина ленты'**
  String get settingsPaperWidth;

  /// No description provided for @settingsPaperWidthHint.
  ///
  /// In ru, this message translates to:
  /// **'Смотрите в инструкции принтера: 58 мм — компактные, 80 мм — стандартные'**
  String get settingsPaperWidthHint;

  /// No description provided for @settingsMm.
  ///
  /// In ru, this message translates to:
  /// **'{width} мм'**
  String settingsMm(String width);

  /// No description provided for @settingsAutoPrint.
  ///
  /// In ru, this message translates to:
  /// **'Печатать чек автоматически'**
  String get settingsAutoPrint;

  /// No description provided for @settingsAutoPrintHint.
  ///
  /// In ru, this message translates to:
  /// **'Сразу после оплаты, без вопроса кассиру'**
  String get settingsAutoPrintHint;

  /// No description provided for @settingsStoreDesc.
  ///
  /// In ru, this message translates to:
  /// **'Реквизиты магазина и оформление чека. Изменения сразу видны в образце чека.'**
  String get settingsStoreDesc;

  /// No description provided for @settingsReceiptSample.
  ///
  /// In ru, this message translates to:
  /// **'Образец чека'**
  String get settingsReceiptSample;

  /// No description provided for @settingsSecSync.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация'**
  String get settingsSecSync;

  /// No description provided for @settingsSecSyncHint.
  ///
  /// In ru, this message translates to:
  /// **'Несколько касс, облако'**
  String get settingsSecSyncHint;

  /// No description provided for @shiftClosingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрытие смены'**
  String get shiftClosingTitle;

  /// No description provided for @shiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get shiftClosed;

  /// No description provided for @shiftCloseConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть смену?'**
  String get shiftCloseConfirmTitle;

  /// No description provided for @shiftCountedValue.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитано: {amount}'**
  String shiftCountedValue(String amount);

  /// No description provided for @shiftExpectedValue.
  ///
  /// In ru, this message translates to:
  /// **'Ожидалось: {amount}'**
  String shiftExpectedValue(String amount);

  /// No description provided for @shiftShortage.
  ///
  /// In ru, this message translates to:
  /// **'Недостача'**
  String get shiftShortage;

  /// No description provided for @shiftSurplus.
  ///
  /// In ru, this message translates to:
  /// **'Излишек'**
  String get shiftSurplus;

  /// No description provided for @shiftCollectionAtCloseValue.
  ///
  /// In ru, this message translates to:
  /// **'Инкассация при закрытии: {amount}'**
  String shiftCollectionAtCloseValue(String amount);

  /// No description provided for @shiftCloseConfirmMessage.
  ///
  /// In ru, this message translates to:
  /// **'После закрытия продажи будут недоступны до открытия новой смены.'**
  String get shiftCloseConfirmMessage;

  /// No description provided for @shiftCloseAction.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть смену'**
  String get shiftCloseAction;

  /// No description provided for @shiftCountCashHint.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитайте наличные в денежном ящике.'**
  String get shiftCountCashHint;

  /// No description provided for @shiftByDenomination.
  ///
  /// In ru, this message translates to:
  /// **'По купюрам'**
  String get shiftByDenomination;

  /// No description provided for @shiftByTotal.
  ///
  /// In ru, this message translates to:
  /// **'Общей суммой'**
  String get shiftByTotal;

  /// No description provided for @shiftCashInDrawer.
  ///
  /// In ru, this message translates to:
  /// **'Наличные в кассе'**
  String get shiftCashInDrawer;

  /// No description provided for @shiftExpectedInDrawer.
  ///
  /// In ru, this message translates to:
  /// **'Ожидается в кассе'**
  String get shiftExpectedInDrawer;

  /// No description provided for @shiftInclGiftCash.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. сертификаты (нал.)'**
  String get shiftInclGiftCash;

  /// No description provided for @shiftCounted.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитано'**
  String get shiftCounted;

  /// No description provided for @shiftDifference.
  ///
  /// In ru, this message translates to:
  /// **'Расхождение'**
  String get shiftDifference;

  /// No description provided for @shiftDiffReasonLabel.
  ///
  /// In ru, this message translates to:
  /// **'Причина расхождения *'**
  String get shiftDiffReasonLabel;

  /// No description provided for @shiftNoteOptional.
  ///
  /// In ru, this message translates to:
  /// **'Примечание (необязательно)'**
  String get shiftNoteOptional;

  /// No description provided for @shiftCollectionAtClose.
  ///
  /// In ru, this message translates to:
  /// **'Инкассация при закрытии'**
  String get shiftCollectionAtClose;

  /// No description provided for @shiftCollectionSummary.
  ///
  /// In ru, this message translates to:
  /// **'Сдать {collect}, оставить {leave} на размен'**
  String shiftCollectionSummary(String collect, String leave);

  /// No description provided for @shiftCollectionHint.
  ///
  /// In ru, this message translates to:
  /// **'Сдать часть выручки и оставить размен на следующую смену'**
  String get shiftCollectionHint;

  /// No description provided for @shiftCollectionAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма инкассации'**
  String get shiftCollectionAmount;

  /// No description provided for @shiftCollectAll.
  ///
  /// In ru, this message translates to:
  /// **'Сдать всё'**
  String get shiftCollectAll;

  /// No description provided for @shiftNoDifference.
  ///
  /// In ru, this message translates to:
  /// **'без расхождений'**
  String get shiftNoDifference;

  /// No description provided for @shiftShortageLower.
  ///
  /// In ru, this message translates to:
  /// **'недостача'**
  String get shiftShortageLower;

  /// No description provided for @shiftSurplusLower.
  ///
  /// In ru, this message translates to:
  /// **'излишек'**
  String get shiftSurplusLower;

  /// No description provided for @shiftOpenedToast.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта. Размен: {amount}'**
  String shiftOpenedToast(String amount);

  /// No description provided for @shiftOpenHint.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы начать продавать, откройте смену и укажите сумму размена в кассе.'**
  String get shiftOpenHint;

  /// No description provided for @shiftOpeningCash.
  ///
  /// In ru, this message translates to:
  /// **'Размен на начало смены'**
  String get shiftOpeningCash;

  /// No description provided for @shiftOpeningSuggested.
  ///
  /// In ru, this message translates to:
  /// **'Предложено: остаток после прошлой смены'**
  String get shiftOpeningSuggested;

  /// No description provided for @shiftOpeningCashNow.
  ///
  /// In ru, this message translates to:
  /// **'Наличные в денежном ящике сейчас'**
  String get shiftOpeningCashNow;

  /// No description provided for @shiftNoRightOpen.
  ///
  /// In ru, this message translates to:
  /// **'Нет права открывать смену'**
  String get shiftNoRightOpen;

  /// No description provided for @shiftOpenAction.
  ///
  /// In ru, this message translates to:
  /// **'Открыть смену'**
  String get shiftOpenAction;

  /// No description provided for @shiftSales.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get shiftSales;

  /// No description provided for @shiftSalesHint.
  ///
  /// In ru, this message translates to:
  /// **'{receipts} · средний {avg}'**
  String shiftSalesHint(String receipts, String avg);

  /// No description provided for @shiftReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get shiftReturns;

  /// No description provided for @shiftNoReturns.
  ///
  /// In ru, this message translates to:
  /// **'Возвратов не было'**
  String get shiftNoReturns;

  /// No description provided for @shiftGrossProfit.
  ///
  /// In ru, this message translates to:
  /// **'Валовая прибыль'**
  String get shiftGrossProfit;

  /// No description provided for @shiftNetRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка без возвратов'**
  String get shiftNetRevenue;

  /// No description provided for @shiftRevenueValue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка {amount}'**
  String shiftRevenueValue(String amount);

  /// No description provided for @shiftExpectedHint.
  ///
  /// In ru, this message translates to:
  /// **'Наличные · размен {amount}'**
  String shiftExpectedHint(String amount);

  /// No description provided for @shiftXReport.
  ///
  /// In ru, this message translates to:
  /// **'X-отчёт'**
  String get shiftXReport;

  /// No description provided for @shiftZReport.
  ///
  /// In ru, this message translates to:
  /// **'Z-отчёт'**
  String get shiftZReport;

  /// No description provided for @shiftNumber.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number}'**
  String shiftNumber(String number);

  /// No description provided for @shiftStatusOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыта'**
  String get shiftStatusOpen;

  /// No description provided for @shiftOpenedAt.
  ///
  /// In ru, this message translates to:
  /// **'Открыта {date}'**
  String shiftOpenedAt(String date);

  /// No description provided for @shiftJustNow.
  ///
  /// In ru, this message translates to:
  /// **'только что'**
  String get shiftJustNow;

  /// No description provided for @shiftRunning.
  ///
  /// In ru, this message translates to:
  /// **'идёт {duration}'**
  String shiftRunning(String duration);

  /// No description provided for @shiftHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String shiftHoursMinutes(String hours, String minutes);

  /// No description provided for @shiftMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String shiftMinutes(String minutes);

  /// No description provided for @shiftCloseTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Пересчитать кассу и закрыть смену (Z-отчёт)'**
  String get shiftCloseTooltip;

  /// No description provided for @shiftNoRightClose.
  ///
  /// In ru, this message translates to:
  /// **'Нет права закрывать смену'**
  String get shiftNoRightClose;

  /// No description provided for @shiftCashOperations.
  ///
  /// In ru, this message translates to:
  /// **'Кассовые операции'**
  String get shiftCashOperations;

  /// No description provided for @shiftNoRightCash.
  ///
  /// In ru, this message translates to:
  /// **'Нет права на кассовые операции'**
  String get shiftNoRightCash;

  /// No description provided for @shiftOperationsList.
  ///
  /// In ru, this message translates to:
  /// **'Операции за смену'**
  String get shiftOperationsList;

  /// No description provided for @shiftNoOperations.
  ///
  /// In ru, this message translates to:
  /// **'Внесений и выплат ещё не было'**
  String get shiftNoOperations;

  /// No description provided for @shiftNumberOpen.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} открыта'**
  String shiftNumberOpen(String number);

  /// No description provided for @shiftTabCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Текущая смена'**
  String get shiftTabCurrent;

  /// No description provided for @shiftTabHistory.
  ///
  /// In ru, this message translates to:
  /// **'История смен'**
  String get shiftTabHistory;

  /// No description provided for @shiftOnlyMine.
  ///
  /// In ru, this message translates to:
  /// **'Только мои смены'**
  String get shiftOnlyMine;

  /// No description provided for @shiftHistoryEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Смен пока нет'**
  String get shiftHistoryEmptyTitle;

  /// No description provided for @shiftHistoryEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Закрытые смены и их Z-отчёты появятся здесь'**
  String get shiftHistoryEmptyMessage;

  /// No description provided for @shiftPickShift.
  ///
  /// In ru, this message translates to:
  /// **'Выберите смену'**
  String get shiftPickShift;

  /// No description provided for @shiftPickShiftMessage.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будет её отчёт с возможностью печати'**
  String get shiftPickShiftMessage;

  /// No description provided for @shiftNow.
  ///
  /// In ru, this message translates to:
  /// **'сейчас'**
  String get shiftNow;

  /// No description provided for @shiftEnterCountedCash.
  ///
  /// In ru, this message translates to:
  /// **'Введите сумму наличных в кассе'**
  String get shiftEnterCountedCash;

  /// No description provided for @shiftAmountNegative.
  ///
  /// In ru, this message translates to:
  /// **'Сумма не может быть отрицательной'**
  String get shiftAmountNegative;

  /// No description provided for @shiftCollectionNegative.
  ///
  /// In ru, this message translates to:
  /// **'Сумма инкассации не может быть отрицательной'**
  String get shiftCollectionNegative;

  /// No description provided for @shiftCollectionTooBig.
  ///
  /// In ru, this message translates to:
  /// **'Инкассация не может превышать пересчитанную сумму'**
  String get shiftCollectionTooBig;

  /// No description provided for @shiftEnterDiffReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину расхождения'**
  String get shiftEnterDiffReason;

  /// No description provided for @shiftKindPayIn.
  ///
  /// In ru, this message translates to:
  /// **'Внесение'**
  String get shiftKindPayIn;

  /// No description provided for @shiftKindPayOut.
  ///
  /// In ru, this message translates to:
  /// **'Выплата'**
  String get shiftKindPayOut;

  /// No description provided for @shiftKindExpense.
  ///
  /// In ru, this message translates to:
  /// **'Расход'**
  String get shiftKindExpense;

  /// No description provided for @shiftKindCollection.
  ///
  /// In ru, this message translates to:
  /// **'Инкассация'**
  String get shiftKindCollection;

  /// No description provided for @shiftExpRent.
  ///
  /// In ru, this message translates to:
  /// **'Аренда'**
  String get shiftExpRent;

  /// No description provided for @shiftExpSalary.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата'**
  String get shiftExpSalary;

  /// No description provided for @shiftExpSupplies.
  ///
  /// In ru, this message translates to:
  /// **'Хозтовары'**
  String get shiftExpSupplies;

  /// No description provided for @shiftExpTransport.
  ///
  /// In ru, this message translates to:
  /// **'Транспорт'**
  String get shiftExpTransport;

  /// No description provided for @shiftExpUtilities.
  ///
  /// In ru, this message translates to:
  /// **'Коммунальные'**
  String get shiftExpUtilities;

  /// No description provided for @shiftExpOther.
  ///
  /// In ru, this message translates to:
  /// **'Прочее'**
  String get shiftExpOther;

  /// No description provided for @shiftKindPayInHint.
  ///
  /// In ru, this message translates to:
  /// **'Размен, возврат подотчёта и т.п.'**
  String get shiftKindPayInHint;

  /// No description provided for @shiftKindPayOutHint.
  ///
  /// In ru, this message translates to:
  /// **'Выдача наличных из кассы (подотчёт, аванс)'**
  String get shiftKindPayOutHint;

  /// No description provided for @shiftKindExpenseHint.
  ///
  /// In ru, this message translates to:
  /// **'Оплата расходов магазина из кассы'**
  String get shiftKindExpenseHint;

  /// No description provided for @shiftKindCollectionHint.
  ///
  /// In ru, this message translates to:
  /// **'Сдача выручки владельцу / в банк'**
  String get shiftKindCollectionHint;

  /// No description provided for @shiftPickExpenseCategory.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию расхода'**
  String get shiftPickExpenseCategory;

  /// No description provided for @shiftCashInDrawerNow.
  ///
  /// In ru, this message translates to:
  /// **'В кассе сейчас: {amount}'**
  String shiftCashInDrawerNow(String amount);

  /// No description provided for @shiftEnterAmount.
  ///
  /// In ru, this message translates to:
  /// **'Введите сумму'**
  String get shiftEnterAmount;

  /// No description provided for @shiftOnlyInDrawer.
  ///
  /// In ru, this message translates to:
  /// **'В кассе только {amount}'**
  String shiftOnlyInDrawer(String amount);

  /// No description provided for @shiftExpenseCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория расхода'**
  String get shiftExpenseCategory;

  /// No description provided for @shiftReasonRequired.
  ///
  /// In ru, this message translates to:
  /// **'Основание / комментарий *'**
  String get shiftReasonRequired;

  /// No description provided for @shiftPayOutHint.
  ///
  /// In ru, this message translates to:
  /// **'Кому и зачем выданы деньги'**
  String get shiftPayOutHint;

  /// No description provided for @shiftEnterReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите основание'**
  String get shiftEnterReason;

  /// No description provided for @shiftSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get shiftSaving;

  /// No description provided for @shiftPost.
  ///
  /// In ru, this message translates to:
  /// **'Провести'**
  String get shiftPost;

  /// No description provided for @shiftZShiftNo.
  ///
  /// In ru, this message translates to:
  /// **'Смена №'**
  String get shiftZShiftNo;

  /// No description provided for @shiftZOpened.
  ///
  /// In ru, this message translates to:
  /// **'Открыта'**
  String get shiftZOpened;

  /// No description provided for @shiftZClosed.
  ///
  /// In ru, this message translates to:
  /// **'Закрыта'**
  String get shiftZClosed;

  /// No description provided for @shiftZReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get shiftZReceipts;

  /// No description provided for @shiftZSalesTotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма продаж'**
  String get shiftZSalesTotal;

  /// No description provided for @shiftZIncl.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. {method}'**
  String shiftZIncl(String method);

  /// No description provided for @shiftZDiscounts.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get shiftZDiscounts;

  /// No description provided for @shiftZAvgCheck.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get shiftZAvgCheck;

  /// No description provided for @shiftZVoidedReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировано чеков'**
  String get shiftZVoidedReceipts;

  /// No description provided for @shiftZReturnsCount.
  ///
  /// In ru, this message translates to:
  /// **'Возвратов'**
  String get shiftZReturnsCount;

  /// No description provided for @shiftZReturnsTotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма возвратов'**
  String get shiftZReturnsTotal;

  /// No description provided for @shiftZGiftCards.
  ///
  /// In ru, this message translates to:
  /// **'Сертификаты'**
  String get shiftZGiftCards;

  /// No description provided for @shiftZSold.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get shiftZSold;

  /// No description provided for @shiftZGiftSalesTotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма продаж (аванс)'**
  String get shiftZGiftSalesTotal;

  /// No description provided for @shiftZVoided.
  ///
  /// In ru, this message translates to:
  /// **'Аннулировано'**
  String get shiftZVoided;

  /// No description provided for @shiftZRefundedToBuyers.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено покупателям'**
  String get shiftZRefundedToBuyers;

  /// No description provided for @shiftZCashImpact.
  ///
  /// In ru, this message translates to:
  /// **'Влияние на кассу (нал.)'**
  String get shiftZCashImpact;

  /// No description provided for @shiftZAdvanceNote.
  ///
  /// In ru, this message translates to:
  /// **'аванс, не входит в выручку'**
  String get shiftZAdvanceNote;

  /// No description provided for @shiftZSummary.
  ///
  /// In ru, this message translates to:
  /// **'Итог'**
  String get shiftZSummary;

  /// No description provided for @shiftZNetRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка (за вычетом возвратов)'**
  String get shiftZNetRevenue;

  /// No description provided for @shiftZCash.
  ///
  /// In ru, this message translates to:
  /// **'Касса (наличные)'**
  String get shiftZCash;

  /// No description provided for @shiftZOpeningCash.
  ///
  /// In ru, this message translates to:
  /// **'Размен на начало'**
  String get shiftZOpeningCash;

  /// No description provided for @shiftZCashSales.
  ///
  /// In ru, this message translates to:
  /// **'Наличные продажи'**
  String get shiftZCashSales;

  /// No description provided for @shiftZCashRefunds.
  ///
  /// In ru, this message translates to:
  /// **'Наличные возвраты'**
  String get shiftZCashRefunds;

  /// No description provided for @shiftZDebtCash.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долгов (нал.)'**
  String get shiftZDebtCash;

  /// No description provided for @shiftZDebtNonCash.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долгов (безнал.)'**
  String get shiftZDebtNonCash;

  /// No description provided for @shiftZSupplierPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплаты поставщикам'**
  String get shiftZSupplierPaid;

  /// No description provided for @shiftZGiftCash.
  ///
  /// In ru, this message translates to:
  /// **'Сертификаты (нал., аванс)'**
  String get shiftZGiftCash;

  /// No description provided for @shiftZActual.
  ///
  /// In ru, this message translates to:
  /// **'Фактически'**
  String get shiftZActual;

  /// No description provided for @shiftZPrinted.
  ///
  /// In ru, this message translates to:
  /// **'Печать: {date}'**
  String shiftZPrinted(String date);

  /// No description provided for @shiftZCashierSign.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get shiftZCashierSign;

  /// No description provided for @shiftZReceivedSign.
  ///
  /// In ru, this message translates to:
  /// **'Принял'**
  String get shiftZReceivedSign;

  /// No description provided for @shiftZTitleA4.
  ///
  /// In ru, this message translates to:
  /// **'{title} — смена №{number}'**
  String shiftZTitleA4(String title, String number);

  /// No description provided for @shiftZGenerated.
  ///
  /// In ru, this message translates to:
  /// **'Сформирован: {date}'**
  String shiftZGenerated(String date);

  /// No description provided for @shiftZFileName.
  ///
  /// In ru, this message translates to:
  /// **'{title} смена {number}'**
  String shiftZFileName(String title, String number);

  /// No description provided for @shiftPrintUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Печать недоступна'**
  String get shiftPrintUnavailable;

  /// No description provided for @shiftRoll80.
  ///
  /// In ru, this message translates to:
  /// **'Чековая лента 80 мм'**
  String get shiftRoll80;

  /// No description provided for @shiftSheetA4.
  ///
  /// In ru, this message translates to:
  /// **'Лист A4'**
  String get shiftSheetA4;

  /// No description provided for @shiftReportHeader.
  ///
  /// In ru, this message translates to:
  /// **'{title} · смена №{number}'**
  String shiftReportHeader(String title, String number);

  /// No description provided for @shiftReportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по смене'**
  String get shiftReportTitle;

  /// No description provided for @staffTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get staffTitle;

  /// No description provided for @staffNoAccess.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа'**
  String get staffNoAccess;

  /// No description provided for @staffNoAccessHint.
  ///
  /// In ru, this message translates to:
  /// **'Раздел доступен владельцу и администратору'**
  String get staffNoAccessHint;

  /// No description provided for @staffTabTime.
  ///
  /// In ru, this message translates to:
  /// **'Рабочее время'**
  String get staffTabTime;

  /// No description provided for @staffTabMotivation.
  ///
  /// In ru, this message translates to:
  /// **'Мотивация'**
  String get staffTabMotivation;

  /// No description provided for @staffTabRoles.
  ///
  /// In ru, this message translates to:
  /// **'Роли и права'**
  String get staffTabRoles;

  /// No description provided for @staffTabAudit.
  ///
  /// In ru, this message translates to:
  /// **'Журнал действий'**
  String get staffTabAudit;

  /// No description provided for @staffRolesHint.
  ///
  /// In ru, this message translates to:
  /// **'Права ролей заданы системой. Чтобы изменить доступ сотрудника, смените его роль.'**
  String get staffRolesHint;

  /// No description provided for @staffPermColumn.
  ///
  /// In ru, this message translates to:
  /// **'Право'**
  String get staffPermColumn;

  /// No description provided for @staffErrLastOwner.
  ///
  /// In ru, this message translates to:
  /// **'Это единственный активный владелец. Сначала назначьте другого владельца'**
  String get staffErrLastOwner;

  /// No description provided for @staffErrNameTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Имя слишком длинное'**
  String get staffErrNameTooLong;

  /// No description provided for @staffErrSetPin.
  ///
  /// In ru, this message translates to:
  /// **'Задайте PIN'**
  String get staffErrSetPin;

  /// No description provided for @staffErrMaxDiscountRange.
  ///
  /// In ru, this message translates to:
  /// **'Макс. скидка — от 0 до 100%'**
  String get staffErrMaxDiscountRange;

  /// No description provided for @staffErrCommissionRange.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия — от 0 до 100%'**
  String get staffErrCommissionRange;

  /// No description provided for @staffErrPlanNegative.
  ///
  /// In ru, this message translates to:
  /// **'План не может быть отрицательным'**
  String get staffErrPlanNegative;

  /// No description provided for @staffErrPhoneFormat.
  ///
  /// In ru, this message translates to:
  /// **'Неверный формат телефона'**
  String get staffErrPhoneFormat;

  /// No description provided for @staffErrOwnerRoleOnlyOwner.
  ///
  /// In ru, this message translates to:
  /// **'Назначить роль «Владелец» может только владелец'**
  String get staffErrOwnerRoleOnlyOwner;

  /// No description provided for @staffErrOwnerEditOnlyOwner.
  ///
  /// In ru, this message translates to:
  /// **'Изменять данные владельца может только владелец'**
  String get staffErrOwnerEditOnlyOwner;

  /// No description provided for @staffErrCannotDeactivateSelf.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя деактивировать собственную учётную запись'**
  String get staffErrCannotDeactivateSelf;

  /// No description provided for @staffErrActivateNeedsPin.
  ///
  /// In ru, this message translates to:
  /// **'Для активации задайте сотруднику новый PIN'**
  String get staffErrActivateNeedsPin;

  /// No description provided for @staffDurationMin.
  ///
  /// In ru, this message translates to:
  /// **'{m} мин'**
  String staffDurationMin(String m);

  /// No description provided for @staffDurationHm.
  ///
  /// In ru, this message translates to:
  /// **'{h} ч {m} мин'**
  String staffDurationHm(String h, String m);

  /// No description provided for @staffErrAlreadyClockedIn.
  ///
  /// In ru, this message translates to:
  /// **'Приход уже отмечен в {time}'**
  String staffErrAlreadyClockedIn(String time);

  /// No description provided for @staffErrClockInFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала отметьте приход'**
  String get staffErrClockInFirst;

  /// No description provided for @staffErrEndBeforeStart.
  ///
  /// In ru, this message translates to:
  /// **'Время ухода должно быть позже времени прихода'**
  String get staffErrEndBeforeStart;

  /// No description provided for @staffErrStartInFuture.
  ///
  /// In ru, this message translates to:
  /// **'Время прихода не может быть в будущем'**
  String get staffErrStartInFuture;

  /// No description provided for @staffErrEndInFuture.
  ///
  /// In ru, this message translates to:
  /// **'Время ухода не может быть в будущем'**
  String get staffErrEndInFuture;

  /// No description provided for @staffErrTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Смена не может длиться больше 24 часов'**
  String get staffErrTooLong;

  /// No description provided for @staffErrOverlap.
  ///
  /// In ru, this message translates to:
  /// **'Пересекается с другой записью ({from} — {to})'**
  String staffErrOverlap(String from, String to);

  /// No description provided for @staffNow.
  ///
  /// In ru, this message translates to:
  /// **'сейчас'**
  String get staffNow;

  /// No description provided for @staffErrOpenExists.
  ///
  /// In ru, this message translates to:
  /// **'У сотрудника уже есть незавершённая запись'**
  String get staffErrOpenExists;

  /// No description provided for @staffPermSell.
  ///
  /// In ru, this message translates to:
  /// **'Продажа (касса)'**
  String get staffPermSell;

  /// No description provided for @staffPermApplyDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Ручные скидки'**
  String get staffPermApplyDiscount;

  /// No description provided for @staffPermVoidSale.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирование чеков'**
  String get staffPermVoidSale;

  /// No description provided for @staffPermRefund.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get staffPermRefund;

  /// No description provided for @staffPermOpenCloseShift.
  ///
  /// In ru, this message translates to:
  /// **'Открытие/закрытие смены'**
  String get staffPermOpenCloseShift;

  /// No description provided for @staffPermCashInOut.
  ///
  /// In ru, this message translates to:
  /// **'Внесения и выплаты'**
  String get staffPermCashInOut;

  /// No description provided for @staffPermViewProducts.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр товаров'**
  String get staffPermViewProducts;

  /// No description provided for @staffPermEditProducts.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование товаров'**
  String get staffPermEditProducts;

  /// No description provided for @staffPermEditPrices.
  ///
  /// In ru, this message translates to:
  /// **'Изменение цен'**
  String get staffPermEditPrices;

  /// No description provided for @staffPermViewCost.
  ///
  /// In ru, this message translates to:
  /// **'Себестоимость и прибыль'**
  String get staffPermViewCost;

  /// No description provided for @staffPermStockOps.
  ///
  /// In ru, this message translates to:
  /// **'Складские операции'**
  String get staffPermStockOps;

  /// No description provided for @staffPermPurchasing.
  ///
  /// In ru, this message translates to:
  /// **'Закупки'**
  String get staffPermPurchasing;

  /// No description provided for @staffPermViewCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр клиентов'**
  String get staffPermViewCustomers;

  /// No description provided for @staffPermEditCustomers.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование клиентов'**
  String get staffPermEditCustomers;

  /// No description provided for @staffPermManageDebts.
  ///
  /// In ru, this message translates to:
  /// **'Долги клиентов'**
  String get staffPermManageDebts;

  /// No description provided for @staffPermManagePromotions.
  ///
  /// In ru, this message translates to:
  /// **'Акции и маркетинг'**
  String get staffPermManagePromotions;

  /// No description provided for @staffPermViewReports.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get staffPermViewReports;

  /// No description provided for @staffPermViewAllShifts.
  ///
  /// In ru, this message translates to:
  /// **'Все смены'**
  String get staffPermViewAllShifts;

  /// No description provided for @staffPermManageStaff.
  ///
  /// In ru, this message translates to:
  /// **'Управление сотрудниками'**
  String get staffPermManageStaff;

  /// No description provided for @staffPermManageSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get staffPermManageSettings;

  /// No description provided for @staffPermViewAudit.
  ///
  /// In ru, this message translates to:
  /// **'Журнал действий'**
  String get staffPermViewAudit;

  /// No description provided for @staffAuditAuthLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход в систему'**
  String get staffAuditAuthLogin;

  /// No description provided for @staffAuditAuthFail.
  ///
  /// In ru, this message translates to:
  /// **'Неверный PIN'**
  String get staffAuditAuthFail;

  /// No description provided for @staffAuditAuthLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выход из системы'**
  String get staffAuditAuthLogout;

  /// No description provided for @staffAuditSaleDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка в чеке'**
  String get staffAuditSaleDiscount;

  /// No description provided for @staffAuditSaleReturn.
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get staffAuditSaleReturn;

  /// No description provided for @staffAuditSaleVoid.
  ///
  /// In ru, this message translates to:
  /// **'Аннулирование чека'**
  String get staffAuditSaleVoid;

  /// No description provided for @staffAuditSaleCreate.
  ///
  /// In ru, this message translates to:
  /// **'Продажа'**
  String get staffAuditSaleCreate;

  /// No description provided for @staffAuditShiftOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открытие смены'**
  String get staffAuditShiftOpen;

  /// No description provided for @staffAuditShiftClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрытие смены'**
  String get staffAuditShiftClose;

  /// No description provided for @staffAuditCashPayIn.
  ///
  /// In ru, this message translates to:
  /// **'Внесение в кассу'**
  String get staffAuditCashPayIn;

  /// No description provided for @staffAuditCashPayOut.
  ///
  /// In ru, this message translates to:
  /// **'Выплата из кассы'**
  String get staffAuditCashPayOut;

  /// No description provided for @staffAuditCashExpense.
  ///
  /// In ru, this message translates to:
  /// **'Расход из кассы'**
  String get staffAuditCashExpense;

  /// No description provided for @staffAuditCashCollection.
  ///
  /// In ru, this message translates to:
  /// **'Инкассация'**
  String get staffAuditCashCollection;

  /// No description provided for @staffAuditStockReceive.
  ///
  /// In ru, this message translates to:
  /// **'Приход товара'**
  String get staffAuditStockReceive;

  /// No description provided for @staffAuditStockWriteoff.
  ///
  /// In ru, this message translates to:
  /// **'Списание товара'**
  String get staffAuditStockWriteoff;

  /// No description provided for @staffAuditStockAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка остатка'**
  String get staffAuditStockAdjust;

  /// No description provided for @staffAuditStockSet.
  ///
  /// In ru, this message translates to:
  /// **'Установка остатка'**
  String get staffAuditStockSet;

  /// No description provided for @staffAuditUserCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создан сотрудник'**
  String get staffAuditUserCreate;

  /// No description provided for @staffAuditUserUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Изменены данные сотрудника'**
  String get staffAuditUserUpdate;

  /// No description provided for @staffAuditUserRole.
  ///
  /// In ru, this message translates to:
  /// **'Изменена роль сотрудника'**
  String get staffAuditUserRole;

  /// No description provided for @staffAuditUserPinChange.
  ///
  /// In ru, this message translates to:
  /// **'Смена PIN'**
  String get staffAuditUserPinChange;

  /// No description provided for @staffAuditUserActivate.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник активирован'**
  String get staffAuditUserActivate;

  /// No description provided for @staffAuditUserDeactivate.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник деактивирован'**
  String get staffAuditUserDeactivate;

  /// No description provided for @staffAuditProductPrice.
  ///
  /// In ru, this message translates to:
  /// **'Изменение цены'**
  String get staffAuditProductPrice;

  /// No description provided for @staffAuditDebtPayment.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долга'**
  String get staffAuditDebtPayment;

  /// No description provided for @staffAuditBonusAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Корректировка бонусов'**
  String get staffAuditBonusAdjust;

  /// No description provided for @staffAuditInventoryComplete.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация проведена'**
  String get staffAuditInventoryComplete;

  /// No description provided for @staffAuditDiscountOverride.
  ///
  /// In ru, this message translates to:
  /// **'Скидка сверх лимита'**
  String get staffAuditDiscountOverride;

  /// No description provided for @staffAuditDiscountApprove.
  ///
  /// In ru, this message translates to:
  /// **'Скидка подтверждена менеджером'**
  String get staffAuditDiscountApprove;

  /// No description provided for @staffAuditAuthApproveFail.
  ///
  /// In ru, this message translates to:
  /// **'Неверный PIN подтверждения'**
  String get staffAuditAuthApproveFail;

  /// No description provided for @staffAuditBackupAuto.
  ///
  /// In ru, this message translates to:
  /// **'Автоматическая резервная копия'**
  String get staffAuditBackupAuto;

  /// No description provided for @staffAuditTimeClockIn.
  ///
  /// In ru, this message translates to:
  /// **'Приход на работу'**
  String get staffAuditTimeClockIn;

  /// No description provided for @staffAuditTimeClockOut.
  ///
  /// In ru, this message translates to:
  /// **'Уход с работы'**
  String get staffAuditTimeClockOut;

  /// No description provided for @staffAuditTimeAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавлена запись рабочего времени'**
  String get staffAuditTimeAdd;

  /// No description provided for @staffAuditTimeEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменена запись рабочего времени'**
  String get staffAuditTimeEdit;

  /// No description provided for @staffAuditTimeDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалена запись рабочего времени'**
  String get staffAuditTimeDelete;

  /// No description provided for @staffAuditStockReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Приход товара'**
  String get staffAuditStockReceipt;

  /// No description provided for @staffAuditProductCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создан товар'**
  String get staffAuditProductCreate;

  /// No description provided for @staffAuditProductUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Изменён товар'**
  String get staffAuditProductUpdate;

  /// No description provided for @staffAuditProductDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалён товар'**
  String get staffAuditProductDelete;

  /// No description provided for @staffAuditProductCost.
  ///
  /// In ru, this message translates to:
  /// **'Изменение себестоимости'**
  String get staffAuditProductCost;

  /// No description provided for @staffAuditProductImport.
  ///
  /// In ru, this message translates to:
  /// **'Импорт товаров'**
  String get staffAuditProductImport;

  /// No description provided for @staffAuditProductBulkPrice.
  ///
  /// In ru, this message translates to:
  /// **'Массовое изменение цен'**
  String get staffAuditProductBulkPrice;

  /// No description provided for @staffAuditProductBulkCategory.
  ///
  /// In ru, this message translates to:
  /// **'Массовая смена категории'**
  String get staffAuditProductBulkCategory;

  /// No description provided for @staffAuditCategoryDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалена категория'**
  String get staffAuditCategoryDelete;

  /// No description provided for @staffAuditCustomerCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создан клиент'**
  String get staffAuditCustomerCreate;

  /// No description provided for @staffAuditCustomerDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалён клиент'**
  String get staffAuditCustomerDelete;

  /// No description provided for @staffAuditCustomerTerms.
  ///
  /// In ru, this message translates to:
  /// **'Изменены условия клиента'**
  String get staffAuditCustomerTerms;

  /// No description provided for @staffAuditSupplierPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата поставщику'**
  String get staffAuditSupplierPayment;

  /// No description provided for @staffAuditSupplierDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалён поставщик'**
  String get staffAuditSupplierDelete;

  /// No description provided for @staffAuditPoOrdered.
  ///
  /// In ru, this message translates to:
  /// **'Заказ поставщику отправлен'**
  String get staffAuditPoOrdered;

  /// No description provided for @staffAuditPoReceive.
  ///
  /// In ru, this message translates to:
  /// **'Приёмка заказа поставщика'**
  String get staffAuditPoReceive;

  /// No description provided for @staffAuditPromotionCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создана акция'**
  String get staffAuditPromotionCreate;

  /// No description provided for @staffAuditPromotionUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Изменена акция'**
  String get staffAuditPromotionUpdate;

  /// No description provided for @staffAuditPromotionDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалена акция'**
  String get staffAuditPromotionDelete;

  /// No description provided for @staffAuditGiftCardIssue.
  ///
  /// In ru, this message translates to:
  /// **'Выпущен подарочный сертификат'**
  String get staffAuditGiftCardIssue;

  /// No description provided for @staffAuditWarrantyCreate.
  ///
  /// In ru, this message translates to:
  /// **'Гарантийное обращение'**
  String get staffAuditWarrantyCreate;

  /// No description provided for @staffAuditWarrantyStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус гарантийного обращения'**
  String get staffAuditWarrantyStatus;

  /// No description provided for @staffAuditInventoryCreate.
  ///
  /// In ru, this message translates to:
  /// **'Начата инвентаризация'**
  String get staffAuditInventoryCreate;

  /// No description provided for @staffAuditInventoryCancel.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация отменена'**
  String get staffAuditInventoryCancel;

  /// No description provided for @staffAuditPosPriceEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменение цены в чеке'**
  String get staffAuditPosPriceEdit;

  /// No description provided for @staffAuditPosCartClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистка чека'**
  String get staffAuditPosCartClear;

  /// No description provided for @staffAuditSettingsChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменены настройки'**
  String get staffAuditSettingsChange;

  /// No description provided for @staffAuditRegisterDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалена касса'**
  String get staffAuditRegisterDelete;

  /// No description provided for @staffAuditRegisterBindDevice.
  ///
  /// In ru, this message translates to:
  /// **'Привязка устройства к кассе'**
  String get staffAuditRegisterBindDevice;

  /// No description provided for @staffAuditDataExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт данных'**
  String get staffAuditDataExport;

  /// No description provided for @staffAuditBackupCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создана резервная копия'**
  String get staffAuditBackupCreate;

  /// No description provided for @staffAuditBackupDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалена резервная копия'**
  String get staffAuditBackupDelete;

  /// No description provided for @staffAuditBackupRestoreScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Запланировано восстановление'**
  String get staffAuditBackupRestoreScheduled;

  /// No description provided for @staffAuditBackupRestoreCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление отменено'**
  String get staffAuditBackupRestoreCancelled;

  /// No description provided for @staffAuditBackupRestoreApplied.
  ///
  /// In ru, this message translates to:
  /// **'Данные восстановлены из копии'**
  String get staffAuditBackupRestoreApplied;

  /// No description provided for @staffGroupAuth.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get staffGroupAuth;

  /// No description provided for @staffGroupSale.
  ///
  /// In ru, this message translates to:
  /// **'Продажи'**
  String get staffGroupSale;

  /// No description provided for @staffGroupShift.
  ///
  /// In ru, this message translates to:
  /// **'Смены'**
  String get staffGroupShift;

  /// No description provided for @staffGroupCash.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get staffGroupCash;

  /// No description provided for @staffGroupStock.
  ///
  /// In ru, this message translates to:
  /// **'Склад'**
  String get staffGroupStock;

  /// No description provided for @staffGroupInventory.
  ///
  /// In ru, this message translates to:
  /// **'Инвентаризация'**
  String get staffGroupInventory;

  /// No description provided for @staffGroupUser.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get staffGroupUser;

  /// No description provided for @staffGroupTime.
  ///
  /// In ru, this message translates to:
  /// **'Рабочее время'**
  String get staffGroupTime;

  /// No description provided for @staffGroupProduct.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get staffGroupProduct;

  /// No description provided for @staffGroupDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долги'**
  String get staffGroupDebt;

  /// No description provided for @staffGroupBonus.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get staffGroupBonus;

  /// No description provided for @staffGroupDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидки'**
  String get staffGroupDiscount;

  /// No description provided for @staffGroupPos.
  ///
  /// In ru, this message translates to:
  /// **'Касса (чек)'**
  String get staffGroupPos;

  /// No description provided for @staffGroupCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Клиенты'**
  String get staffGroupCustomer;

  /// No description provided for @staffGroupSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Поставщики'**
  String get staffGroupSupplier;

  /// No description provided for @staffGroupPo.
  ///
  /// In ru, this message translates to:
  /// **'Закупки'**
  String get staffGroupPo;

  /// No description provided for @staffGroupPromotion.
  ///
  /// In ru, this message translates to:
  /// **'Акции'**
  String get staffGroupPromotion;

  /// No description provided for @staffGroupSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get staffGroupSettings;

  /// No description provided for @staffGroupBackup.
  ///
  /// In ru, this message translates to:
  /// **'Резервные копии'**
  String get staffGroupBackup;

  /// No description provided for @staffDetailDiscount.
  ///
  /// In ru, this message translates to:
  /// **'скидка'**
  String get staffDetailDiscount;

  /// No description provided for @staffDetailTotal.
  ///
  /// In ru, this message translates to:
  /// **'сумма'**
  String get staffDetailTotal;

  /// No description provided for @staffDetailOpening.
  ///
  /// In ru, this message translates to:
  /// **'размен'**
  String get staffDetailOpening;

  /// No description provided for @staffDetailExpected.
  ///
  /// In ru, this message translates to:
  /// **'ожидалось'**
  String get staffDetailExpected;

  /// No description provided for @staffDetailCounted.
  ///
  /// In ru, this message translates to:
  /// **'пересчитано'**
  String get staffDetailCounted;

  /// No description provided for @staffDetailManual.
  ///
  /// In ru, this message translates to:
  /// **'ручная скидка'**
  String get staffDetailManual;

  /// No description provided for @staffDetailMethod.
  ///
  /// In ru, this message translates to:
  /// **'способ'**
  String get staffDetailMethod;

  /// No description provided for @staffMethodCash.
  ///
  /// In ru, this message translates to:
  /// **'наличные'**
  String get staffMethodCash;

  /// No description provided for @staffMethodCard.
  ///
  /// In ru, this message translates to:
  /// **'карта'**
  String get staffMethodCard;

  /// No description provided for @staffMethodDebt.
  ///
  /// In ru, this message translates to:
  /// **'в долг'**
  String get staffMethodDebt;

  /// No description provided for @staffMethodBonus.
  ///
  /// In ru, this message translates to:
  /// **'бонусы'**
  String get staffMethodBonus;

  /// No description provided for @staffMethodTransfer.
  ///
  /// In ru, this message translates to:
  /// **'перевод'**
  String get staffMethodTransfer;

  /// No description provided for @staffMethodGiftCard.
  ///
  /// In ru, this message translates to:
  /// **'сертификат'**
  String get staffMethodGiftCard;

  /// No description provided for @staffDetailPromos.
  ///
  /// In ru, this message translates to:
  /// **'акции: {list}'**
  String staffDetailPromos(String list);

  /// No description provided for @staffDetailReturnNo.
  ///
  /// In ru, this message translates to:
  /// **'чек возврата №{number}'**
  String staffDetailReturnNo(String number);

  /// No description provided for @staffSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя или телефон'**
  String get staffSearchHint;

  /// No description provided for @staffInactiveFilter.
  ///
  /// In ru, this message translates to:
  /// **'Неактивные'**
  String get staffInactiveFilter;

  /// No description provided for @staffInactiveFilterTip.
  ///
  /// In ru, this message translates to:
  /// **'Показать деактивированных сотрудников'**
  String get staffInactiveFilterTip;

  /// No description provided for @staffAddUser.
  ///
  /// In ru, this message translates to:
  /// **'Добавить сотрудника'**
  String get staffAddUser;

  /// No description provided for @staffEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудников пока нет'**
  String get staffEmpty;

  /// No description provided for @staffNobodyFound.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено'**
  String get staffNobodyFound;

  /// No description provided for @staffEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте кассиров и менеджеров, чтобы они могли входить по PIN'**
  String get staffEmptyHint;

  /// No description provided for @staffDeactivateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать {name}?'**
  String staffDeactivateTitle(String name);

  /// No description provided for @staffDeactivateMessage.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник не сможет входить в систему, его открытая отметка рабочего времени будет закрыта. История продаж и смен сохранится. Активировать можно в любой момент.'**
  String get staffDeactivateMessage;

  /// No description provided for @staffDeactivate.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать'**
  String get staffDeactivate;

  /// No description provided for @staffDeactivated.
  ///
  /// In ru, this message translates to:
  /// **'{name} деактивирован(а)'**
  String staffDeactivated(String name);

  /// No description provided for @staffActivateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Активировать {name}'**
  String staffActivateTitle(String name);

  /// No description provided for @staffActivateMessage.
  ///
  /// In ru, this message translates to:
  /// **'Задайте новый PIN — старый мог быть выдан другому сотруднику.'**
  String get staffActivateMessage;

  /// No description provided for @staffReactivated.
  ///
  /// In ru, this message translates to:
  /// **'{name} снова активен(на)'**
  String staffReactivated(String name);

  /// No description provided for @staffNeverLoggedIn.
  ///
  /// In ru, this message translates to:
  /// **'ещё не входил(а)'**
  String get staffNeverLoggedIn;

  /// No description provided for @staffLastLogin.
  ///
  /// In ru, this message translates to:
  /// **'вход {date}'**
  String staffLastLogin(String date);

  /// No description provided for @staffYou.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get staffYou;

  /// No description provided for @staffInactiveChip.
  ///
  /// In ru, this message translates to:
  /// **'Неактивен'**
  String get staffInactiveChip;

  /// No description provided for @staffAtWork.
  ///
  /// In ru, this message translates to:
  /// **'На работе'**
  String get staffAtWork;

  /// No description provided for @staffTodayLower.
  ///
  /// In ru, this message translates to:
  /// **'сегодня'**
  String get staffTodayLower;

  /// No description provided for @staffEditAction.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get staffEditAction;

  /// No description provided for @staffActivate.
  ///
  /// In ru, this message translates to:
  /// **'Активировать'**
  String get staffActivate;

  /// No description provided for @staffNewUser.
  ///
  /// In ru, this message translates to:
  /// **'Новый сотрудник'**
  String get staffNewUser;

  /// No description provided for @staffUserTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник: {name}'**
  String staffUserTitle(String name);

  /// No description provided for @staffDemoteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Понизить собственную роль?'**
  String get staffDemoteTitle;

  /// No description provided for @staffDemoteMessage.
  ///
  /// In ru, this message translates to:
  /// **'После сохранения у вас («{role}») не будет доступа к разделу «Сотрудники». Вернуть права сможет только владелец или администратор.'**
  String staffDemoteMessage(String role);

  /// No description provided for @staffDemote.
  ///
  /// In ru, this message translates to:
  /// **'Понизить'**
  String get staffDemote;

  /// No description provided for @staffUserAdded.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник добавлен'**
  String get staffUserAdded;

  /// No description provided for @staffChangesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Изменения сохранены'**
  String get staffChangesSaved;

  /// No description provided for @staffFrom0To100.
  ///
  /// In ru, this message translates to:
  /// **'От 0 до 100'**
  String get staffFrom0To100;

  /// No description provided for @staffNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя *'**
  String get staffNameLabel;

  /// No description provided for @staffOwnerRoleLocked.
  ///
  /// In ru, this message translates to:
  /// **'Изменить роль владельца может только владелец'**
  String get staffOwnerRoleLocked;

  /// No description provided for @staffRoleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Роль *'**
  String get staffRoleLabel;

  /// No description provided for @staffPinSection.
  ///
  /// In ru, this message translates to:
  /// **'PIN для входа'**
  String get staffPinSection;

  /// No description provided for @staffResetPin.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить PIN'**
  String get staffResetPin;

  /// No description provided for @staffResetPinHint.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник будет входить с новым PIN'**
  String get staffResetPinHint;

  /// No description provided for @staffPinLabel.
  ///
  /// In ru, this message translates to:
  /// **'PIN *'**
  String get staffPinLabel;

  /// No description provided for @staffPinRepeatLabel.
  ///
  /// In ru, this message translates to:
  /// **'PIN ещё раз *'**
  String get staffPinRepeatLabel;

  /// No description provided for @staffPinMismatch.
  ///
  /// In ru, this message translates to:
  /// **'PIN не совпадает'**
  String get staffPinMismatch;

  /// No description provided for @staffPinHint.
  ///
  /// In ru, this message translates to:
  /// **'4–8 цифр, уникальный для каждого сотрудника'**
  String get staffPinHint;

  /// No description provided for @staffLimitsSection.
  ///
  /// In ru, this message translates to:
  /// **'Ограничения и мотивация'**
  String get staffLimitsSection;

  /// No description provided for @staffMaxDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Макс. скидка'**
  String get staffMaxDiscount;

  /// No description provided for @staffMaxDiscountHelper.
  ///
  /// In ru, this message translates to:
  /// **'без согласования'**
  String get staffMaxDiscountHelper;

  /// No description provided for @staffCommission.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия'**
  String get staffCommission;

  /// No description provided for @staffCommissionHelper.
  ///
  /// In ru, this message translates to:
  /// **'от чистой выручки'**
  String get staffCommissionHelper;

  /// No description provided for @staffSalesPlan.
  ///
  /// In ru, this message translates to:
  /// **'План продаж на месяц'**
  String get staffSalesPlan;

  /// No description provided for @staffSalesPlanHelper.
  ///
  /// In ru, this message translates to:
  /// **'0 или пусто — без плана'**
  String get staffSalesPlanHelper;

  /// No description provided for @staffSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get staffSaving;

  /// No description provided for @staffEnterPin.
  ///
  /// In ru, this message translates to:
  /// **'Введите PIN'**
  String get staffEnterPin;

  /// No description provided for @staffPinMin4.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 4 цифры'**
  String get staffPinMin4;

  /// No description provided for @staffNewPin.
  ///
  /// In ru, this message translates to:
  /// **'Новый PIN'**
  String get staffNewPin;

  /// No description provided for @staffPin4to8.
  ///
  /// In ru, this message translates to:
  /// **'От 4 до 8 цифр'**
  String get staffPin4to8;

  /// No description provided for @staffRepeatPin.
  ///
  /// In ru, this message translates to:
  /// **'Повторите PIN'**
  String get staffRepeatPin;

  /// No description provided for @staffNoPlan.
  ///
  /// In ru, this message translates to:
  /// **'без плана'**
  String get staffNoPlan;

  /// No description provided for @staffClockIn.
  ///
  /// In ru, this message translates to:
  /// **'Отметить начало работы'**
  String get staffClockIn;

  /// No description provided for @staffClockedIn.
  ///
  /// In ru, this message translates to:
  /// **'Начало работы отмечено в {time}'**
  String staffClockedIn(String time);

  /// No description provided for @staffClockInShort.
  ///
  /// In ru, this message translates to:
  /// **'Начать работу'**
  String get staffClockInShort;

  /// No description provided for @staffClockOutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметить уход?'**
  String get staffClockOutTitle;

  /// No description provided for @staffClockOutMessage.
  ///
  /// In ru, this message translates to:
  /// **'На работе с {time} ({duration}).'**
  String staffClockOutMessage(String time, String duration);

  /// No description provided for @staffClockOut.
  ///
  /// In ru, this message translates to:
  /// **'Отметить уход'**
  String get staffClockOut;

  /// No description provided for @staffClockedOut.
  ///
  /// In ru, this message translates to:
  /// **'Уход отмечен'**
  String get staffClockedOut;

  /// No description provided for @staffClockOutTip.
  ///
  /// In ru, this message translates to:
  /// **'На работе с {time} · отметить уход'**
  String staffClockOutTip(String time);

  /// No description provided for @staffAtWorkSince.
  ///
  /// In ru, this message translates to:
  /// **'На работе с {time}'**
  String staffAtWorkSince(String time);

  /// No description provided for @staffClockOutShortDur.
  ///
  /// In ru, this message translates to:
  /// **'Уход · {duration}'**
  String staffClockOutShortDur(String duration);

  /// No description provided for @staffClockOutDur.
  ///
  /// In ru, this message translates to:
  /// **'Отметить уход · {duration}'**
  String staffClockOutDur(String duration);

  /// No description provided for @staffThisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get staffThisWeek;

  /// No description provided for @staffThisMonth.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get staffThisMonth;

  /// No description provided for @staffLastMonth.
  ///
  /// In ru, this message translates to:
  /// **'Прошлый месяц'**
  String get staffLastMonth;

  /// No description provided for @staffAllEmployees.
  ///
  /// In ru, this message translates to:
  /// **'Все сотрудники'**
  String get staffAllEmployees;

  /// No description provided for @staffEntryShort.
  ///
  /// In ru, this message translates to:
  /// **'Запись'**
  String get staffEntryShort;

  /// No description provided for @staffAddEntry.
  ///
  /// In ru, this message translates to:
  /// **'Добавить запись'**
  String get staffAddEntry;

  /// No description provided for @staffNoMarks.
  ///
  /// In ru, this message translates to:
  /// **'Нет отметок за период'**
  String get staffNoMarks;

  /// No description provided for @staffNoMarksHint.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники отмечают приход и уход кнопкой «Отметить начало работы»'**
  String get staffNoMarksHint;

  /// No description provided for @staffAtWorkLower.
  ///
  /// In ru, this message translates to:
  /// **'на работе'**
  String get staffAtWorkLower;

  /// No description provided for @staffNewEntryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая запись рабочего времени'**
  String get staffNewEntryTitle;

  /// No description provided for @staffEntryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Запись рабочего времени'**
  String get staffEntryTitle;

  /// No description provided for @staffSelectEmployee.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сотрудника'**
  String get staffSelectEmployee;

  /// No description provided for @staffEntrySaved.
  ///
  /// In ru, this message translates to:
  /// **'Запись сохранена'**
  String get staffEntrySaved;

  /// No description provided for @staffDeleteEntryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить запись?'**
  String get staffDeleteEntryTitle;

  /// No description provided for @staffDeleteEntryMessage.
  ///
  /// In ru, this message translates to:
  /// **'Действие будет записано в журнал.'**
  String get staffDeleteEntryMessage;

  /// No description provided for @staffEntryDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Запись удалена'**
  String get staffEntryDeleted;

  /// No description provided for @staffEmployeeRequired.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник *'**
  String get staffEmployeeRequired;

  /// No description provided for @staffClockInField.
  ///
  /// In ru, this message translates to:
  /// **'Приход'**
  String get staffClockInField;

  /// No description provided for @staffClockOutField.
  ///
  /// In ru, this message translates to:
  /// **'Уход'**
  String get staffClockOutField;

  /// No description provided for @staffStillAtWorkLower.
  ///
  /// In ru, this message translates to:
  /// **'ещё на работе'**
  String get staffStillAtWorkLower;

  /// No description provided for @staffStillAtWork.
  ///
  /// In ru, this message translates to:
  /// **'Ещё на работе'**
  String get staffStillAtWork;

  /// No description provided for @staffEndBeforeStartShort.
  ///
  /// In ru, this message translates to:
  /// **'Уход раньше прихода'**
  String get staffEndBeforeStartShort;

  /// No description provided for @staffDurationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Длительность: {duration}'**
  String staffDurationLabel(String duration);

  /// No description provided for @staffEntryNote.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (причина правки)'**
  String get staffEntryNote;

  /// No description provided for @staffMonth1.
  ///
  /// In ru, this message translates to:
  /// **'Январь'**
  String get staffMonth1;

  /// No description provided for @staffMonth2.
  ///
  /// In ru, this message translates to:
  /// **'Февраль'**
  String get staffMonth2;

  /// No description provided for @staffMonth3.
  ///
  /// In ru, this message translates to:
  /// **'Март'**
  String get staffMonth3;

  /// No description provided for @staffMonth4.
  ///
  /// In ru, this message translates to:
  /// **'Апрель'**
  String get staffMonth4;

  /// No description provided for @staffMonth5.
  ///
  /// In ru, this message translates to:
  /// **'Май'**
  String get staffMonth5;

  /// No description provided for @staffMonth6.
  ///
  /// In ru, this message translates to:
  /// **'Июнь'**
  String get staffMonth6;

  /// No description provided for @staffMonth7.
  ///
  /// In ru, this message translates to:
  /// **'Июль'**
  String get staffMonth7;

  /// No description provided for @staffMonth8.
  ///
  /// In ru, this message translates to:
  /// **'Август'**
  String get staffMonth8;

  /// No description provided for @staffMonth9.
  ///
  /// In ru, this message translates to:
  /// **'Сентябрь'**
  String get staffMonth9;

  /// No description provided for @staffMonth10.
  ///
  /// In ru, this message translates to:
  /// **'Октябрь'**
  String get staffMonth10;

  /// No description provided for @staffMonth11.
  ///
  /// In ru, this message translates to:
  /// **'Ноябрь'**
  String get staffMonth11;

  /// No description provided for @staffMonth12.
  ///
  /// In ru, this message translates to:
  /// **'Декабрь'**
  String get staffMonth12;

  /// No description provided for @staffPrevMonth.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий месяц'**
  String get staffPrevMonth;

  /// No description provided for @staffNextMonth.
  ///
  /// In ru, this message translates to:
  /// **'Следующий месяц'**
  String get staffNextMonth;

  /// No description provided for @staffCurrentMonth.
  ///
  /// In ru, this message translates to:
  /// **'Текущий'**
  String get staffCurrentMonth;

  /// No description provided for @staffMotivationHint.
  ///
  /// In ru, this message translates to:
  /// **'Выручка продавца без аннулированных чеков, за вычетом возвратов, сделанных в этом месяце'**
  String get staffMotivationHint;

  /// No description provided for @staffNoSellers.
  ///
  /// In ru, this message translates to:
  /// **'Нет продавцов'**
  String get staffNoSellers;

  /// No description provided for @staffNoSellersHint.
  ///
  /// In ru, this message translates to:
  /// **'Задайте сотрудникам план продаж и комиссию в карточке сотрудника'**
  String get staffNoSellersHint;

  /// No description provided for @staffNetRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Чистая выручка'**
  String get staffNetRevenue;

  /// No description provided for @staffPlanValue.
  ///
  /// In ru, this message translates to:
  /// **'План {amount}'**
  String staffPlanValue(String amount);

  /// No description provided for @staffCommissionDue.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия к выплате'**
  String get staffCommissionDue;

  /// No description provided for @staffRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get staffRevenue;

  /// No description provided for @staffRefunds.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты'**
  String get staffRefunds;

  /// No description provided for @staffReceiptsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Чеков'**
  String get staffReceiptsLabel;

  /// No description provided for @staffAvgCheck.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get staffAvgCheck;

  /// No description provided for @staffCommissionPct.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия {pct}%'**
  String staffCommissionPct(String pct);

  /// No description provided for @staffPlanLeft.
  ///
  /// In ru, this message translates to:
  /// **'{done} из {plan} · осталось {left}'**
  String staffPlanLeft(String done, String plan, String left);

  /// No description provided for @staffPlanDone.
  ///
  /// In ru, this message translates to:
  /// **'{done} из {plan} · план выполнен'**
  String staffPlanDone(String done, String plan);

  /// No description provided for @staffActionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Действие'**
  String get staffActionLabel;

  /// No description provided for @staffAllActions.
  ///
  /// In ru, this message translates to:
  /// **'Все действия'**
  String get staffAllActions;

  /// No description provided for @staffNoRecords.
  ///
  /// In ru, this message translates to:
  /// **'Записей не найдено'**
  String get staffNoRecords;

  /// No description provided for @staffNoRecordsHint.
  ///
  /// In ru, this message translates to:
  /// **'Измените период или фильтры'**
  String get staffNoRecordsHint;

  /// No description provided for @staffAuditLimit.
  ///
  /// In ru, this message translates to:
  /// **'Показаны последние {n} записей — уточните фильтр'**
  String staffAuditLimit(String n);

  /// No description provided for @staffSystem.
  ///
  /// In ru, this message translates to:
  /// **'система'**
  String get staffSystem;

  /// No description provided for @syncErrNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером синхронизации. Проверьте интернет.'**
  String get syncErrNetwork;

  /// No description provided for @syncErrAuth.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email или пароль, либо сессия истекла. Войдите снова.'**
  String get syncErrAuth;

  /// No description provided for @syncErrForbidden.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к этому магазину.'**
  String get syncErrForbidden;

  /// No description provided for @syncErrEnvironmentMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Демо-база может подключаться только к тестовому магазину.'**
  String get syncErrEnvironmentMismatch;

  /// No description provided for @syncErrNotEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этой базе уже есть данные (товары, продажи, клиенты). Подключить её к существующему магазину нельзя: две базы не объединяются. Используйте чистую установку.'**
  String get syncErrNotEmpty;

  /// No description provided for @syncErrServer.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера синхронизации.'**
  String get syncErrServer;

  /// No description provided for @syncErrNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация не настроена.'**
  String get syncErrNotConfigured;

  /// No description provided for @syncErrNotSignedIn.
  ///
  /// In ru, this message translates to:
  /// **'Сначала войдите в аккаунт синхронизации.'**
  String get syncErrNotSignedIn;

  /// No description provided for @syncErrInsecureUrl.
  ///
  /// In ru, this message translates to:
  /// **'Адрес сервера должен начинаться с https://.'**
  String get syncErrInsecureUrl;

  /// No description provided for @syncErrInvalidUrl.
  ///
  /// In ru, this message translates to:
  /// **'Неверный адрес сервера.'**
  String get syncErrInvalidUrl;

  /// No description provided for @syncErrProtocol.
  ///
  /// In ru, this message translates to:
  /// **'Неожиданный ответ сервера синхронизации.'**
  String get syncErrProtocol;

  /// No description provided for @syncErrStoreNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Магазин не найден.'**
  String get syncErrStoreNotFound;

  /// No description provided for @syncErrAlreadyConnected.
  ///
  /// In ru, this message translates to:
  /// **'Эта база уже подключена к магазину. Сначала отключите синхронизацию.'**
  String get syncErrAlreadyConnected;

  /// No description provided for @syncPhaseOff.
  ///
  /// In ru, this message translates to:
  /// **'Выключена'**
  String get syncPhaseOff;

  /// No description provided for @syncPhaseIdle.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировано'**
  String get syncPhaseIdle;

  /// No description provided for @syncPhaseSyncing.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация…'**
  String get syncPhaseSyncing;

  /// No description provided for @syncPhaseError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка синхронизации'**
  String get syncPhaseError;

  /// No description provided for @syncPhaseOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи'**
  String get syncPhaseOffline;

  /// No description provided for @syncEnvTest.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый магазин'**
  String get syncEnvTest;

  /// No description provided for @syncEnvProduction.
  ///
  /// In ru, this message translates to:
  /// **'Рабочий магазин'**
  String get syncEnvProduction;

  /// Title of a local notification about a sync conflict; subject is one of the syncConflictSubject* texts.
  ///
  /// In ru, this message translates to:
  /// **'Конфликт синхронизации: {subject}'**
  String syncConflictTitle(String subject);

  /// No description provided for @syncConflictSubjectBarcode.
  ///
  /// In ru, this message translates to:
  /// **'штрихкод {code}'**
  String syncConflictSubjectBarcode(String code);

  /// No description provided for @syncConflictSubjectCard.
  ///
  /// In ru, this message translates to:
  /// **'карта клиента {code}'**
  String syncConflictSubjectCard(String code);

  /// No description provided for @syncConflictSubjectGiftCard.
  ///
  /// In ru, this message translates to:
  /// **'сертификат {code}'**
  String syncConflictSubjectGiftCard(String code);

  /// No description provided for @syncConflictSubjectStock.
  ///
  /// In ru, this message translates to:
  /// **'остаток «{name}»'**
  String syncConflictSubjectStock(String name);

  /// No description provided for @syncConflictSubjectBonus.
  ///
  /// In ru, this message translates to:
  /// **'бонусы «{name}»'**
  String syncConflictSubjectBonus(String name);

  /// No description provided for @syncConflictBarcodeBody.
  ///
  /// In ru, this message translates to:
  /// **'Штрихкод {code} был назначен двум товарам на разных кассах. Он оставлен у товара «{winner}», у товара «{loser}» штрихкод очищен.'**
  String syncConflictBarcodeBody(String code, String winner, String loser);

  /// No description provided for @syncConflictCardBody.
  ///
  /// In ru, this message translates to:
  /// **'Номер карты {code} был назначен двум клиентам на разных кассах. Он оставлен у клиента «{winner}», у клиента «{loser}» номер карты очищен.'**
  String syncConflictCardBody(String code, String winner, String loser);

  /// No description provided for @syncConflictGiftCodeBody.
  ///
  /// In ru, this message translates to:
  /// **'Код сертификата {code} совпал на разных кассах. Дубликат заблокирован и получил код {newCode}.'**
  String syncConflictGiftCodeBody(String code, String newCode);

  /// No description provided for @syncConflictStockBody.
  ///
  /// In ru, this message translates to:
  /// **'Остаток товара «{name}» стал отрицательным ({qty}) после продаж на разных кассах. Проверьте остаток.'**
  String syncConflictStockBody(String name, String qty);

  /// No description provided for @syncConflictGiftBalanceBody.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {code} списан на разных кассах больше номинала: баланс {amount}.'**
  String syncConflictGiftBalanceBody(String code, String amount);

  /// No description provided for @syncConflictBonusBody.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы клиента «{name}» стали отрицательными ({amount}) после операций на разных кассах.'**
  String syncConflictBonusBody(String name, String amount);

  /// No description provided for @syncSectionDesc.
  ///
  /// In ru, this message translates to:
  /// **'Несколько касс одного магазина работают с общими товарами, клиентами и продажами через облако. Без интернета касса продолжает работать, изменения отправятся при появлении связи.'**
  String get syncSectionDesc;

  /// No description provided for @syncUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'В этой версии программы синхронизация недоступна.'**
  String get syncUnavailable;

  /// No description provided for @syncOffTitle.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация выключена'**
  String get syncOffTitle;

  /// No description provided for @syncOffMessage.
  ///
  /// In ru, this message translates to:
  /// **'Эта касса работает отдельно. Подключите её к магазину в облаке, чтобы все кассы видели общие данные.'**
  String get syncOffMessage;

  /// No description provided for @syncConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get syncConnect;

  /// No description provided for @syncSyncNow.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировать сейчас'**
  String get syncSyncNow;

  /// No description provided for @syncDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get syncDisconnect;

  /// No description provided for @syncSignInAgain.
  ///
  /// In ru, this message translates to:
  /// **'Войти снова'**
  String get syncSignInAgain;

  /// No description provided for @syncStoreLabel.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get syncStoreLabel;

  /// No description provided for @syncDeviceCode.
  ///
  /// In ru, this message translates to:
  /// **'Код кассы'**
  String get syncDeviceCode;

  /// No description provided for @syncDeviceCodeExample.
  ///
  /// In ru, this message translates to:
  /// **'номера чеков: {example}'**
  String syncDeviceCodeExample(String example);

  /// No description provided for @syncPending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают отправки'**
  String get syncPending;

  /// No description provided for @syncLastSync.
  ///
  /// In ru, this message translates to:
  /// **'Последняя синхронизация'**
  String get syncLastSync;

  /// No description provided for @syncNever.
  ///
  /// In ru, this message translates to:
  /// **'ещё не было'**
  String get syncNever;

  /// No description provided for @syncAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get syncAccount;

  /// No description provided for @syncNextRetry.
  ///
  /// In ru, this message translates to:
  /// **'Следующая попытка в {time}'**
  String syncNextRetry(String time);

  /// No description provided for @syncDoneToast.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация завершена: отправлено {pushed}, получено {pulled}'**
  String syncDoneToast(String pushed, String pulled);

  /// No description provided for @syncDisconnectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отключить синхронизацию?'**
  String get syncDisconnectTitle;

  /// No description provided for @syncDisconnectMessage.
  ///
  /// In ru, this message translates to:
  /// **'Касса перестанет обмениваться данными с магазином «{store}». Все данные на этой кассе сохранятся, номера чеков останутся уникальными. Подключиться снова можно в любой момент.'**
  String syncDisconnectMessage(String store);

  /// No description provided for @syncDisconnectedToast.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизация отключена. Данные на кассе сохранены.'**
  String get syncDisconnectedToast;

  /// No description provided for @syncConnectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к облаку'**
  String get syncConnectTitle;

  /// No description provided for @syncSignInIntro.
  ///
  /// In ru, this message translates to:
  /// **'Введите адрес сервера и данные аккаунта владельца магазина.'**
  String get syncSignInIntro;

  /// No description provided for @syncServerUrl.
  ///
  /// In ru, this message translates to:
  /// **'Адрес сервера *'**
  String get syncServerUrl;

  /// No description provided for @syncServerUrlHint.
  ///
  /// In ru, this message translates to:
  /// **'https://…supabase.co'**
  String get syncServerUrlHint;

  /// No description provided for @syncAnonKey.
  ///
  /// In ru, this message translates to:
  /// **'Ключ доступа (anon key) *'**
  String get syncAnonKey;

  /// No description provided for @syncEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email *'**
  String get syncEmail;

  /// No description provided for @syncPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль *'**
  String get syncPassword;

  /// No description provided for @syncPasswordShow.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get syncPasswordShow;

  /// No description provided for @syncPasswordHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get syncPasswordHide;

  /// No description provided for @syncPasswordNote.
  ///
  /// In ru, this message translates to:
  /// **'Пароль не сохраняется на кассе.'**
  String get syncPasswordNote;

  /// No description provided for @syncSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get syncSignIn;

  /// No description provided for @syncInvalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email'**
  String get syncInvalidEmail;

  /// No description provided for @syncSignedInAs.
  ///
  /// In ru, this message translates to:
  /// **'Вход выполнен: {email}'**
  String syncSignedInAs(String email);

  /// No description provided for @syncChooseAction.
  ///
  /// In ru, this message translates to:
  /// **'Что сделать с этой кассой?'**
  String get syncChooseAction;

  /// No description provided for @syncCreateStore.
  ///
  /// In ru, this message translates to:
  /// **'Создать магазин в облаке'**
  String get syncCreateStore;

  /// No description provided for @syncCreateStoreHint.
  ///
  /// In ru, this message translates to:
  /// **'Эта касса станет первой. Все её данные будут загружены в облако.'**
  String get syncCreateStoreHint;

  /// No description provided for @syncJoinStore.
  ///
  /// In ru, this message translates to:
  /// **'Подключить к существующему'**
  String get syncJoinStore;

  /// No description provided for @syncJoinStoreHint.
  ///
  /// In ru, this message translates to:
  /// **'Данные магазина будут загружены на эту кассу. Только для пустой базы.'**
  String get syncJoinStoreHint;

  /// No description provided for @syncStoreName.
  ///
  /// In ru, this message translates to:
  /// **'Название магазина *'**
  String get syncStoreName;

  /// No description provided for @syncEnvironment.
  ///
  /// In ru, this message translates to:
  /// **'Тип магазина'**
  String get syncEnvironment;

  /// No description provided for @syncEnvTestHint.
  ///
  /// In ru, this message translates to:
  /// **'Для обучения и проверки. Демо-база может подключаться только сюда.'**
  String get syncEnvTestHint;

  /// No description provided for @syncEnvProductionHint.
  ///
  /// In ru, this message translates to:
  /// **'Для реальной работы. Тип нельзя изменить позже.'**
  String get syncEnvProductionHint;

  /// No description provided for @syncEnvProductionDemo.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно для демо-базы'**
  String get syncEnvProductionDemo;

  /// No description provided for @syncCreateAndUpload.
  ///
  /// In ru, this message translates to:
  /// **'Создать и загрузить'**
  String get syncCreateAndUpload;

  /// No description provided for @syncChooseStore.
  ///
  /// In ru, this message translates to:
  /// **'Выберите магазин'**
  String get syncChooseStore;

  /// No description provided for @syncNoStores.
  ///
  /// In ru, this message translates to:
  /// **'У этого аккаунта нет магазинов. Создайте магазин на первой кассе или попросите владельца добавить вас.'**
  String get syncNoStores;

  /// No description provided for @syncUploading.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем данные в облако…'**
  String get syncUploading;

  /// No description provided for @syncDownloading.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем данные магазина…'**
  String get syncDownloading;

  /// No description provided for @syncConnectedToast.
  ///
  /// In ru, this message translates to:
  /// **'Касса подключена к магазину «{store}». Код кассы: {code}'**
  String syncConnectedToast(String store, String code);

  /// No description provided for @syncIntegrityTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверка целостности'**
  String get syncIntegrityTitle;

  /// No description provided for @syncIntegrityDesc.
  ///
  /// In ru, this message translates to:
  /// **'Сверяет остатки, долги, бонусы и балансы с журналами движений. Ничего не меняет.'**
  String get syncIntegrityDesc;

  /// No description provided for @syncIntegrityRun.
  ///
  /// In ru, this message translates to:
  /// **'Проверить'**
  String get syncIntegrityRun;

  /// No description provided for @syncIntegrityNotRun.
  ///
  /// In ru, this message translates to:
  /// **'Проверка ещё не запускалась.'**
  String get syncIntegrityNotRun;

  /// No description provided for @syncIntegrityOk.
  ///
  /// In ru, this message translates to:
  /// **'Расхождений нет: все остатки и балансы совпадают с журналами.'**
  String get syncIntegrityOk;

  /// No description provided for @syncIntegrityFound.
  ///
  /// In ru, this message translates to:
  /// **'Найдено расхождений: {count}'**
  String syncIntegrityFound(String count);

  /// No description provided for @syncIntegrityValues.
  ///
  /// In ru, this message translates to:
  /// **'сохранено {cached} · по журналу {derived}'**
  String syncIntegrityValues(String cached, String derived);

  /// No description provided for @syncCacheStock.
  ///
  /// In ru, this message translates to:
  /// **'Остаток товара'**
  String get syncCacheStock;

  /// No description provided for @syncCacheDebt.
  ///
  /// In ru, this message translates to:
  /// **'Долг клиента'**
  String get syncCacheDebt;

  /// No description provided for @syncCacheBonus.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы клиента'**
  String get syncCacheBonus;

  /// No description provided for @syncCacheSupplierBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс поставщика'**
  String get syncCacheSupplierBalance;

  /// No description provided for @syncCacheGiftBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс сертификата'**
  String get syncCacheGiftBalance;

  /// No description provided for @syncCacheGiftStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус сертификата'**
  String get syncCacheGiftStatus;

  /// No description provided for @syncCachePoPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено по заказу'**
  String get syncCachePoPaid;

  /// No description provided for @syncCachePoReceived.
  ///
  /// In ru, this message translates to:
  /// **'Получено по позиции заказа'**
  String get syncCachePoReceived;

  /// No description provided for @syncCacheSaleRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено по чеку'**
  String get syncCacheSaleRefunded;

  /// No description provided for @syncCacheSaleStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус чека'**
  String get syncCacheSaleStatus;

  /// No description provided for @syncCacheReturnedQty.
  ///
  /// In ru, this message translates to:
  /// **'Возвращено по позиции чека'**
  String get syncCacheReturnedQty;

  /// No description provided for @syncConflictsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Конфликты синхронизации'**
  String get syncConflictsTitle;

  /// No description provided for @syncConflictsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Что пришлось решить автоматически при обмене данными между кассами'**
  String get syncConflictsSubtitle;

  /// No description provided for @syncConflictsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Конфликтов нет'**
  String get syncConflictsEmpty;

  /// No description provided for @syncConflictsShowResolved.
  ///
  /// In ru, this message translates to:
  /// **'Показать просмотренные'**
  String get syncConflictsShowResolved;

  /// No description provided for @syncConflictsMarkAll.
  ///
  /// In ru, this message translates to:
  /// **'Отметить все просмотренными'**
  String get syncConflictsMarkAll;

  /// No description provided for @syncConflictMarkRead.
  ///
  /// In ru, this message translates to:
  /// **'Отметить просмотренным'**
  String get syncConflictMarkRead;

  /// No description provided for @syncConflictKindBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Совпадение штрихкода'**
  String get syncConflictKindBarcode;

  /// No description provided for @syncConflictKindCard.
  ///
  /// In ru, this message translates to:
  /// **'Совпадение номера карты'**
  String get syncConflictKindCard;

  /// No description provided for @syncConflictKindGiftCode.
  ///
  /// In ru, this message translates to:
  /// **'Совпадение кода сертификата'**
  String get syncConflictKindGiftCode;

  /// No description provided for @syncConflictKindStock.
  ///
  /// In ru, this message translates to:
  /// **'Отрицательный остаток'**
  String get syncConflictKindStock;

  /// No description provided for @syncConflictKindGiftBalance.
  ///
  /// In ru, this message translates to:
  /// **'Отрицательный баланс сертификата'**
  String get syncConflictKindGiftBalance;

  /// No description provided for @syncConflictKindBonus.
  ///
  /// In ru, this message translates to:
  /// **'Отрицательные бонусы'**
  String get syncConflictKindBonus;

  /// No description provided for @syncConflictKindNormalize.
  ///
  /// In ru, this message translates to:
  /// **'Выравнивание при обновлении'**
  String get syncConflictKindNormalize;

  /// No description provided for @syncConflictKindOther.
  ///
  /// In ru, this message translates to:
  /// **'Конфликт'**
  String get syncConflictKindOther;

  /// No description provided for @syncIndicatorTooltip.
  ///
  /// In ru, this message translates to:
  /// **'{state}. Ожидают отправки: {count}. Нажмите, чтобы синхронизировать.'**
  String syncIndicatorTooltip(String state, String count);

  /// No description provided for @syncSubjectReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number}'**
  String syncSubjectReceipt(String number);

  /// No description provided for @syncSubjectOrder.
  ///
  /// In ru, this message translates to:
  /// **'Заказ №{number}'**
  String syncSubjectOrder(String number);

  /// No description provided for @syncErrTestData.
  ///
  /// In ru, this message translates to:
  /// **'Эта база была подключена к тестовому магазину и может содержать тестовые данные других касс. Создать из неё рабочий магазин нельзя: используйте базу без тестовых данных.'**
  String get syncErrTestData;

  /// No description provided for @syncConflictSubjectSale.
  ///
  /// In ru, this message translates to:
  /// **'чек №{number}'**
  String syncConflictSubjectSale(String number);

  /// No description provided for @syncConflictSubjectDocNumber.
  ///
  /// In ru, this message translates to:
  /// **'номер документа {number}'**
  String syncConflictSubjectDocNumber(String number);

  /// No description provided for @syncConflictSubjectDevice.
  ///
  /// In ru, this message translates to:
  /// **'код кассы'**
  String get syncConflictSubjectDevice;

  /// No description provided for @syncConflictNumberBody.
  ///
  /// In ru, this message translates to:
  /// **'Номер {number} оказался у двух разных документов (например, после восстановления резервной копии на подключённой кассе). Более новый документ получил номер {newNumber}.'**
  String syncConflictNumberBody(String number, String newNumber);

  /// No description provided for @syncConflictVoidReturnBody.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} аннулирован на одной кассе, а на другой по нему оформлен возврат на {amount}. Деньги и товар учтены дважды: проверьте кассу и остатки.'**
  String syncConflictVoidReturnBody(String number, String amount);

  /// No description provided for @syncConflictOverReturnBody.
  ///
  /// In ru, this message translates to:
  /// **'По чеку №{number} на разных кассах вернули больше, чем было продано: возвраты на {refunded} при сумме чека {total}. Проверьте кассу и остатки.'**
  String syncConflictOverReturnBody(
    String number,
    String refunded,
    String total,
  );

  /// No description provided for @syncConflictIdentityBody.
  ///
  /// In ru, this message translates to:
  /// **'Эта база оказалась копией кассы {oldCode}, которая продолжала работать (восстановлена резервная копия или база скопирована на другой компьютер). Данные, которых не было в копии, загружены из облака, а касса получила новый код {newCode}, чтобы номера документов не повторялись.'**
  String syncConflictIdentityBody(String oldCode, String newCode);

  /// No description provided for @syncConflictKindNumber.
  ///
  /// In ru, this message translates to:
  /// **'Совпадение номера документа'**
  String get syncConflictKindNumber;

  /// No description provided for @syncConflictKindVoidReturn.
  ///
  /// In ru, this message translates to:
  /// **'Возврат по аннулированному чеку'**
  String get syncConflictKindVoidReturn;

  /// No description provided for @syncConflictKindOverReturn.
  ///
  /// In ru, this message translates to:
  /// **'Возврат больше продажи'**
  String get syncConflictKindOverReturn;

  /// No description provided for @syncConflictKindIdentity.
  ///
  /// In ru, this message translates to:
  /// **'Копия базы кассы'**
  String get syncConflictKindIdentity;

  /// No description provided for @syncConflictKindDoubleVoid.
  ///
  /// In ru, this message translates to:
  /// **'Двойное аннулирование сертификата'**
  String get syncConflictKindDoubleVoid;

  /// No description provided for @syncConflictDoubleVoidBody.
  ///
  /// In ru, this message translates to:
  /// **'Продажа сертификата {code} (№{number}) аннулирована на двух кассах, и деньги ({amount}) вернули дважды. Учтено одно аннулирование: в отчёте смены №{shift} этого возврата нет. Проверьте кассу.'**
  String syncConflictDoubleVoidBody(
    String code,
    String number,
    String amount,
    String shift,
  );

  /// No description provided for @syncConflictKindVoidRedeem.
  ///
  /// In ru, this message translates to:
  /// **'Оплата аннулированным сертификатом'**
  String get syncConflictKindVoidRedeem;

  /// No description provided for @syncConflictVoidRedeemBody.
  ///
  /// In ru, this message translates to:
  /// **'Сертификат {code} аннулирован на одной кассе (деньги возвращены), а на другой им оплатили {amount}. Сумма учтена дважды: проверьте кассу.'**
  String syncConflictVoidRedeemBody(String code, String amount);

  /// No description provided for @syncJoinRejoinHint.
  ///
  /// In ru, this message translates to:
  /// **'В базе уже есть данные, поэтому подключиться можно только к магазину «{name}», от которого эта касса была отключена.'**
  String syncJoinRejoinHint(String name);

  /// No description provided for @syncConflictKindJoinUsers.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники этой кассы отключены'**
  String get syncConflictKindJoinUsers;

  /// No description provided for @syncConflictSubjectJoinUsers.
  ///
  /// In ru, this message translates to:
  /// **'сотрудники этой кассы'**
  String get syncConflictSubjectJoinUsers;

  /// No description provided for @syncConflictJoinUsersBody.
  ///
  /// In ru, this message translates to:
  /// **'При подключении к магазину сотрудники, созданные на этой кассе до подключения, отключены: {names}. Их PIN-коды могли совпасть с PIN-кодами сотрудников магазина. Входите PIN-кодами сотрудников магазина; нужного сотрудника можно включить заново с новым PIN-кодом.'**
  String syncConflictJoinUsersBody(String names);

  /// No description provided for @syncConflictKindRejected.
  ///
  /// In ru, this message translates to:
  /// **'Изменение из облака пропущено'**
  String get syncConflictKindRejected;

  /// No description provided for @syncConflictRejectedBody.
  ///
  /// In ru, this message translates to:
  /// **'Изменение записи {entity} ({id}) пришло из облака повреждённым или от несовместимой версии программы, поэтому оно пропущено. Остальные данные синхронизируются как обычно. Проверьте, что на всех кассах установлена одна версия DreamPOS.'**
  String syncConflictRejectedBody(String entity, String id);

  /// No description provided for @warrantyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия'**
  String get warrantyTitle;

  /// No description provided for @warrantySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Гарантийные и сервисные заявки'**
  String get warrantySubtitle;

  /// No description provided for @warrantyStatusReceived.
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get warrantyStatusReceived;

  /// No description provided for @warrantyStatusInRepair.
  ///
  /// In ru, this message translates to:
  /// **'В ремонте'**
  String get warrantyStatusInRepair;

  /// No description provided for @warrantyStatusReplaced.
  ///
  /// In ru, this message translates to:
  /// **'Замена'**
  String get warrantyStatusReplaced;

  /// No description provided for @warrantyStatusRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возврат денег'**
  String get warrantyStatusRefunded;

  /// No description provided for @warrantyStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отказ'**
  String get warrantyStatusRejected;

  /// No description provided for @warrantyStatusReturned.
  ///
  /// In ru, this message translates to:
  /// **'Выдан клиенту'**
  String get warrantyStatusReturned;

  /// No description provided for @warrantyActionInRepair.
  ///
  /// In ru, this message translates to:
  /// **'Передать в ремонт'**
  String get warrantyActionInRepair;

  /// No description provided for @warrantyActionReplace.
  ///
  /// In ru, this message translates to:
  /// **'Заменить товар'**
  String get warrantyActionReplace;

  /// No description provided for @warrantyActionRefund.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть деньги'**
  String get warrantyActionRefund;

  /// No description provided for @warrantyActionReject.
  ///
  /// In ru, this message translates to:
  /// **'Отказать'**
  String get warrantyActionReject;

  /// No description provided for @warrantyActionReturn.
  ///
  /// In ru, this message translates to:
  /// **'Выдать клиенту'**
  String get warrantyActionReturn;

  /// No description provided for @warrantyGroupOpen.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get warrantyGroupOpen;

  /// No description provided for @warrantyGroupResolved.
  ///
  /// In ru, this message translates to:
  /// **'Решены'**
  String get warrantyGroupResolved;

  /// No description provided for @warrantyGroupClosed.
  ///
  /// In ru, this message translates to:
  /// **'Выданы'**
  String get warrantyGroupClosed;

  /// No description provided for @warrantyNotSet.
  ///
  /// In ru, this message translates to:
  /// **'не установлена'**
  String get warrantyNotSet;

  /// No description provided for @warrantyActUntilActive.
  ///
  /// In ru, this message translates to:
  /// **'до {date} (действует)'**
  String warrantyActUntilActive(String date);

  /// No description provided for @warrantyActUntilExpired.
  ///
  /// In ru, this message translates to:
  /// **'до {date} (истекла)'**
  String warrantyActUntilExpired(String date);

  /// No description provided for @warrantyActTitle.
  ///
  /// In ru, this message translates to:
  /// **'АКТ ПРИЁМА ТОВАРА НА ГАРАНТИЙНОЕ ОБСЛУЖИВАНИЕ'**
  String get warrantyActTitle;

  /// No description provided for @warrantyActNumber.
  ///
  /// In ru, this message translates to:
  /// **'№{number} от {date}'**
  String warrantyActNumber(String number, String date);

  /// No description provided for @warrantySerialNumber.
  ///
  /// In ru, this message translates to:
  /// **'Серийный номер'**
  String get warrantySerialNumber;

  /// No description provided for @warrantyActPurchaseDoc.
  ///
  /// In ru, this message translates to:
  /// **'Документ покупки'**
  String get warrantyActPurchaseDoc;

  /// No description provided for @warrantyActNotPresented.
  ///
  /// In ru, this message translates to:
  /// **'не предъявлен'**
  String get warrantyActNotPresented;

  /// No description provided for @warrantyReceiptRef.
  ///
  /// In ru, this message translates to:
  /// **'чек №{number} от {date}'**
  String warrantyReceiptRef(String number, String date);

  /// No description provided for @warrantyWarranty.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия'**
  String get warrantyWarranty;

  /// No description provided for @warrantyActProblem.
  ///
  /// In ru, this message translates to:
  /// **'Заявленная неисправность'**
  String get warrantyActProblem;

  /// No description provided for @warrantyActCompleteness.
  ///
  /// In ru, this message translates to:
  /// **'Комплектность и внешний вид'**
  String get warrantyActCompleteness;

  /// No description provided for @warrantyResolution.
  ///
  /// In ru, this message translates to:
  /// **'Решение'**
  String get warrantyResolution;

  /// No description provided for @warrantyActTerms.
  ///
  /// In ru, this message translates to:
  /// **'Срок рассмотрения заявки — в соответствии с законодательством о защите прав потребителей. Товар выдаётся при предъявлении настоящего акта.'**
  String get warrantyActTerms;

  /// No description provided for @warrantyActHandedBy.
  ///
  /// In ru, this message translates to:
  /// **'Сдал (клиент):'**
  String get warrantyActHandedBy;

  /// No description provided for @warrantyActReceivedBy.
  ///
  /// In ru, this message translates to:
  /// **'Принял (сотрудник):'**
  String get warrantyActReceivedBy;

  /// No description provided for @warrantyActJobName.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия {number}'**
  String warrantyActJobName(String number);

  /// No description provided for @warrantyClaimAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Заявка №{number} принята'**
  String warrantyClaimAccepted(String number);

  /// No description provided for @warrantyPrintActQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Распечатать акт приёма для подписи клиента?'**
  String get warrantyPrintActQuestion;

  /// No description provided for @warrantyPrintAct.
  ///
  /// In ru, this message translates to:
  /// **'Печать акта'**
  String get warrantyPrintAct;

  /// No description provided for @warrantySearchHintWide.
  ///
  /// In ru, this message translates to:
  /// **'Номер заявки или чека, клиент, серийный номер, товар'**
  String get warrantySearchHintWide;

  /// No description provided for @warrantySearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Заявка, чек, клиент, S/N, товар'**
  String get warrantySearchHint;

  /// No description provided for @warrantyNewClaim.
  ///
  /// In ru, this message translates to:
  /// **'Новая заявка'**
  String get warrantyNewClaim;

  /// No description provided for @warrantyClaimFab.
  ///
  /// In ru, this message translates to:
  /// **'Заявка'**
  String get warrantyClaimFab;

  /// No description provided for @warrantySelectClaim.
  ///
  /// In ru, this message translates to:
  /// **'Выберите заявку'**
  String get warrantySelectClaim;

  /// No description provided for @warrantySelectClaimHint.
  ///
  /// In ru, this message translates to:
  /// **'Карточка заявки, смена статуса и печать акта'**
  String get warrantySelectClaimHint;

  /// No description provided for @warrantyEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заявок пока нет'**
  String get warrantyEmptyTitle;

  /// No description provided for @warrantyEmptyFiltered.
  ///
  /// In ru, this message translates to:
  /// **'Измените поиск или выберите другой статус'**
  String get warrantyEmptyFiltered;

  /// No description provided for @warrantyEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Примите товар на гарантию по номеру чека или вручную'**
  String get warrantyEmptyHint;

  /// No description provided for @warrantyShowMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get warrantyShowMore;

  /// No description provided for @warrantyNoProduct.
  ///
  /// In ru, this message translates to:
  /// **'товар не указан'**
  String get warrantyNoProduct;

  /// No description provided for @warrantyReceiptShort.
  ///
  /// In ru, this message translates to:
  /// **'чек №{number}'**
  String warrantyReceiptShort(String number);

  /// No description provided for @warrantyDaysShort.
  ///
  /// In ru, this message translates to:
  /// **'{days} дн.'**
  String warrantyDaysShort(String days);

  /// No description provided for @warrantyClaimTitle.
  ///
  /// In ru, this message translates to:
  /// **'Гарантийная заявка'**
  String get warrantyClaimTitle;

  /// No description provided for @warrantyClaimNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Заявка не найдена'**
  String get warrantyClaimNotFound;

  /// No description provided for @warrantyClaimNumber.
  ///
  /// In ru, this message translates to:
  /// **'Заявка №{number}'**
  String warrantyClaimNumber(String number);

  /// No description provided for @warrantyAcceptedAt.
  ///
  /// In ru, this message translates to:
  /// **'принята {date}'**
  String warrantyAcceptedAt(String date);

  /// No description provided for @warrantyActButton.
  ///
  /// In ru, this message translates to:
  /// **'Акт приёма'**
  String get warrantyActButton;

  /// No description provided for @warrantyProductName.
  ///
  /// In ru, this message translates to:
  /// **'Наименование'**
  String get warrantyProductName;

  /// No description provided for @warrantyPurchase.
  ///
  /// In ru, this message translates to:
  /// **'Покупка'**
  String get warrantyPurchase;

  /// No description provided for @warrantyNoReceipt.
  ///
  /// In ru, this message translates to:
  /// **'без чека'**
  String get warrantyNoReceipt;

  /// No description provided for @warrantyOpenReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чек'**
  String get warrantyOpenReceipt;

  /// No description provided for @warrantyUntil.
  ///
  /// In ru, this message translates to:
  /// **'до {date}'**
  String warrantyUntil(String date);

  /// No description provided for @warrantyExpiredOn.
  ///
  /// In ru, this message translates to:
  /// **'истекла {date}'**
  String warrantyExpiredOn(String date);

  /// No description provided for @warrantyNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'не указан'**
  String get warrantyNotSpecified;

  /// No description provided for @warrantyProblem.
  ///
  /// In ru, this message translates to:
  /// **'Неисправность'**
  String get warrantyProblem;

  /// No description provided for @warrantyHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get warrantyHistory;

  /// No description provided for @warrantyHistoryCreated.
  ///
  /// In ru, this message translates to:
  /// **'Заявка принята'**
  String get warrantyHistoryCreated;

  /// No description provided for @warrantyStatusChanged.
  ///
  /// In ru, this message translates to:
  /// **'Статус: {status}'**
  String warrantyStatusChanged(String status);

  /// No description provided for @warrantyStatusChangedWriteOff.
  ///
  /// In ru, this message translates to:
  /// **'Статус: {status} · 1 ед. списана'**
  String warrantyStatusChangedWriteOff(String status);

  /// No description provided for @warrantyRefundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформите возврат денег'**
  String get warrantyRefundTitle;

  /// No description provided for @warrantyRefundMessage.
  ///
  /// In ru, this message translates to:
  /// **'Деньги возвращаются только через возврат по чеку в разделе «Чеки» — так касса, склад и отчёты останутся верными. Перейти к оформлению?'**
  String get warrantyRefundMessage;

  /// No description provided for @warrantyOpenReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Открыть «Чеки»'**
  String get warrantyOpenReceipts;

  /// No description provided for @warrantyOpenReceiptNumber.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чек №{number}'**
  String warrantyOpenReceiptNumber(String number);

  /// No description provided for @warrantyRefundHint.
  ///
  /// In ru, this message translates to:
  /// **'Решение — возврат денег. Оформите возврат по чеку (без возврата на склад).'**
  String get warrantyRefundHint;

  /// No description provided for @warrantyToReceipt.
  ///
  /// In ru, this message translates to:
  /// **'К чеку'**
  String get warrantyToReceipt;

  /// No description provided for @warrantyHintInRepair.
  ///
  /// In ru, this message translates to:
  /// **'Сервисный центр, ориентировочный срок'**
  String get warrantyHintInRepair;

  /// No description provided for @warrantyHintReplaced.
  ///
  /// In ru, this message translates to:
  /// **'Например: заменён на новый, серийный № …'**
  String get warrantyHintReplaced;

  /// No description provided for @warrantyHintRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Например: дефект подтверждён, возврат денег'**
  String get warrantyHintRefunded;

  /// No description provided for @warrantyHintRejected.
  ///
  /// In ru, this message translates to:
  /// **'Причина отказа: следы удара, вскрытие, нарушение условий…'**
  String get warrantyHintRejected;

  /// No description provided for @warrantyHintReturned.
  ///
  /// In ru, this message translates to:
  /// **'Кому и когда выдано'**
  String get warrantyHintReturned;

  /// No description provided for @warrantyTransition.
  ///
  /// In ru, this message translates to:
  /// **'Заявка №{number}: {from} → {to}'**
  String warrantyTransition(String number, String from, String to);

  /// No description provided for @warrantyResolutionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Решение *'**
  String get warrantyResolutionRequired;

  /// No description provided for @warrantyEnterResolution.
  ///
  /// In ru, this message translates to:
  /// **'Укажите решение'**
  String get warrantyEnterResolution;

  /// No description provided for @warrantyWriteOffOne.
  ///
  /// In ru, this message translates to:
  /// **'Списать 1 ед. со склада'**
  String get warrantyWriteOffOne;

  /// No description provided for @warrantyWriteOffHint.
  ///
  /// In ru, this message translates to:
  /// **'Причина: «Гарантийная замена» — выданный клиенту товар уйдёт из остатка'**
  String get warrantyWriteOffHint;

  /// No description provided for @warrantyWriteOffUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно: нет прав на складские операции или не указан товар'**
  String get warrantyWriteOffUnavailable;

  /// No description provided for @warrantyRefundNote.
  ///
  /// In ru, this message translates to:
  /// **'Статус не двигает деньги. После сохранения оформите возврат по чеку в разделе «Чеки».'**
  String get warrantyRefundNote;

  /// No description provided for @warrantyNewClaimTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новая гарантийная заявка'**
  String get warrantyNewClaimTitle;

  /// No description provided for @warrantyEnterReceiptDigits.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер чека цифрами'**
  String get warrantyEnterReceiptDigits;

  /// No description provided for @warrantyReceiptNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} не найден'**
  String warrantyReceiptNotFound(String number);

  /// No description provided for @warrantyBlockVoided.
  ///
  /// In ru, this message translates to:
  /// **'чек аннулирован'**
  String get warrantyBlockVoided;

  /// No description provided for @warrantyBlockReturned.
  ///
  /// In ru, this message translates to:
  /// **'товар возвращён'**
  String get warrantyBlockReturned;

  /// No description provided for @warrantyExpiredTitle.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия истекла'**
  String get warrantyExpiredTitle;

  /// No description provided for @warrantyNotSetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия не установлена'**
  String get warrantyNotSetTitle;

  /// No description provided for @warrantyPaidRepairQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Заявку можно принять как платный ремонт или на экспертизу. Принять?'**
  String get warrantyPaidRepairQuestion;

  /// No description provided for @warrantyAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get warrantyAccept;

  /// No description provided for @warrantyDuplicateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть открытая заявка'**
  String get warrantyDuplicateTitle;

  /// No description provided for @warrantyDuplicateMessage.
  ///
  /// In ru, this message translates to:
  /// **'По этому товару из чека уже принята заявка №{number} ({status}). Создать ещё одну?'**
  String warrantyDuplicateMessage(String number, String status);

  /// No description provided for @warrantyFindReceiptAndItem.
  ///
  /// In ru, this message translates to:
  /// **'Найдите чек и выберите товар из него'**
  String get warrantyFindReceiptAndItem;

  /// No description provided for @warrantySelectProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товар'**
  String get warrantySelectProduct;

  /// No description provided for @warrantyByReceipt.
  ///
  /// In ru, this message translates to:
  /// **'По чеку'**
  String get warrantyByReceipt;

  /// No description provided for @warrantyWithoutReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Без чека'**
  String get warrantyWithoutReceipt;

  /// No description provided for @warrantySerialImei.
  ///
  /// In ru, this message translates to:
  /// **'Серийный номер / IMEI'**
  String get warrantySerialImei;

  /// No description provided for @warrantyProblemLabel.
  ///
  /// In ru, this message translates to:
  /// **'Описание неисправности *'**
  String get warrantyProblemLabel;

  /// No description provided for @warrantyProblemHint.
  ///
  /// In ru, this message translates to:
  /// **'Что не работает, когда проявилось, внешний вид, комплектность'**
  String get warrantyProblemHint;

  /// No description provided for @warrantyDescribeProblem.
  ///
  /// In ru, this message translates to:
  /// **'Опишите неисправность'**
  String get warrantyDescribeProblem;

  /// No description provided for @warrantySubmit.
  ///
  /// In ru, this message translates to:
  /// **'Принять заявку'**
  String get warrantySubmit;

  /// No description provided for @warrantyReceiptNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер чека'**
  String get warrantyReceiptNumber;

  /// No description provided for @warrantyFind.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get warrantyFind;

  /// No description provided for @warrantyReceiptPickItem.
  ///
  /// In ru, this message translates to:
  /// **'Чек №{number} от {date} — выберите товар'**
  String warrantyReceiptPickItem(String number, String date);

  /// No description provided for @warrantyReceiptVoided.
  ///
  /// In ru, this message translates to:
  /// **'Чек аннулирован — принять товар по нему нельзя. Используйте режим «Без чека».'**
  String get warrantyReceiptVoided;

  /// No description provided for @warrantyNoWarranty.
  ///
  /// In ru, this message translates to:
  /// **'без гарантии'**
  String get warrantyNoWarranty;

  /// No description provided for @warrantyChipUntil.
  ///
  /// In ru, this message translates to:
  /// **'гарантия до {date}'**
  String warrantyChipUntil(String date);

  /// No description provided for @warrantyChipExpired.
  ///
  /// In ru, this message translates to:
  /// **'гарантия истекла {date}'**
  String warrantyChipExpired(String date);

  /// No description provided for @warrantyBannerActive.
  ///
  /// In ru, this message translates to:
  /// **'На гарантии до {date}'**
  String warrantyBannerActive(String date);

  /// No description provided for @warrantyBannerExpired.
  ///
  /// In ru, this message translates to:
  /// **'Гарантия истекла {date}. Заявку можно принять как платный ремонт.'**
  String warrantyBannerExpired(String date);

  /// No description provided for @warrantyBannerNone.
  ///
  /// In ru, this message translates to:
  /// **'На этот товар гарантия не установлена'**
  String get warrantyBannerNone;

  /// No description provided for @warrantySelectProductRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товар *'**
  String get warrantySelectProductRequired;

  /// No description provided for @warrantyRequiredNoReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно для заявки без чека'**
  String get warrantyRequiredNoReceipt;

  /// No description provided for @warrantyManualHint.
  ///
  /// In ru, this message translates to:
  /// **'Для товара без чека или проданного вне системы'**
  String get warrantyManualHint;

  /// No description provided for @warrantyCustomerOptional.
  ///
  /// In ru, this message translates to:
  /// **'Клиент (необязательно)'**
  String get warrantyCustomerOptional;

  /// No description provided for @warrantyCustomerHint.
  ///
  /// In ru, this message translates to:
  /// **'Нужен для связи о готовности'**
  String get warrantyCustomerHint;

  /// No description provided for @warrantyRemoveCustomer.
  ///
  /// In ru, this message translates to:
  /// **'Убрать клиента'**
  String get warrantyRemoveCustomer;

  /// No description provided for @warrantyReceiptLineNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Позиция чека не найдена'**
  String get warrantyReceiptLineNotFound;

  /// No description provided for @warrantyCannotTransition.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя перевести заявку из «{from}» в «{to}»'**
  String warrantyCannotTransition(String from, String to);

  /// No description provided for @warrantyEnterClaimResolution.
  ///
  /// In ru, this message translates to:
  /// **'Укажите решение по заявке'**
  String get warrantyEnterClaimResolution;

  /// No description provided for @warrantyWriteOffOnlyReplace.
  ///
  /// In ru, this message translates to:
  /// **'Списание возможно только при замене'**
  String get warrantyWriteOffOnlyReplace;

  /// No description provided for @warrantyNoProductInClaim.
  ///
  /// In ru, this message translates to:
  /// **'В заявке не указан товар'**
  String get warrantyNoProductInClaim;

  /// No description provided for @warrantyStockUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Склад недоступен'**
  String get warrantyStockUnavailable;

  /// No description provided for @warrantyChangedByOther.
  ///
  /// In ru, this message translates to:
  /// **'Заявка уже изменена другим пользователем'**
  String get warrantyChangedByOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
