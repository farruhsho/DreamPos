// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get commonCancel => 'Bekor qilish';

  @override
  String get commonSave => 'Saqlash';

  @override
  String get commonDelete => 'Oʻchirish';

  @override
  String get commonClose => 'Yopish';

  @override
  String get commonSearch => 'Qidiruv';

  @override
  String get commonAdd => 'Qoʻshish';

  @override
  String get commonEdit => 'Tahrirlash';

  @override
  String get commonCreate => 'Yaratish';

  @override
  String get commonConfirm => 'Tasdiqlash';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Ha';

  @override
  String get commonNo => 'Yoʻq';

  @override
  String get commonRetry => 'Qayta urinish';

  @override
  String get commonLoading => 'Yuklanmoqda…';

  @override
  String get commonError => 'Xatolik';

  @override
  String get commonEmpty => 'Maʼlumot yoʻq';

  @override
  String get commonNothingFound => 'Hech narsa topilmadi';

  @override
  String get commonPrint => 'Chop etish';

  @override
  String get commonExport => 'Eksport';

  @override
  String get commonImport => 'Import';

  @override
  String get commonTotal => 'Jami';

  @override
  String get commonDate => 'Sana';

  @override
  String get commonTime => 'Vaqt';

  @override
  String get commonAmount => 'Summa';

  @override
  String get commonQty => 'Miqdor';

  @override
  String get commonPrice => 'Narx';

  @override
  String get commonCost => 'Tannarx';

  @override
  String get commonStatus => 'Holat';

  @override
  String get commonReason => 'Sabab';

  @override
  String get commonComment => 'Izoh';

  @override
  String get commonNote => 'Izoh';

  @override
  String get commonName => 'Nomi';

  @override
  String get commonPersonName => 'Ism';

  @override
  String get commonPhone => 'Telefon';

  @override
  String get commonAddress => 'Manzil';

  @override
  String get commonBack => 'Orqaga';

  @override
  String get commonNext => 'Keyingi';

  @override
  String get commonDone => 'Tayyor';

  @override
  String get commonApply => 'Qoʻllash';

  @override
  String get commonReset => 'Tiklash';

  @override
  String get commonClear => 'Tozalash';

  @override
  String get commonAll => 'Hammasi';

  @override
  String get commonFilter => 'Filtr';

  @override
  String get commonSort => 'Saralash';

  @override
  String get commonPeriod => 'Davr';

  @override
  String get commonToday => 'Bugun';

  @override
  String get commonYesterday => 'Kecha';

  @override
  String get commonWeek => 'Hafta';

  @override
  String get commonMonth => 'Oy';

  @override
  String get commonYear => 'Yil';

  @override
  String get commonActions => 'Amallar';

  @override
  String get commonDetails => 'Batafsil';

  @override
  String get commonMore => 'Yana';

  @override
  String get commonShowAll => 'Hammasini koʻrsatish';

  @override
  String get commonRequired => 'Majburiy maydon';

  @override
  String get commonInvalidAmount => 'Notoʻgʻri summa';

  @override
  String get commonEnterNumber => 'Son kiriting';

  @override
  String get commonMustBePositive => 'Noldan katta boʻlishi kerak';

  @override
  String get commonAmountMustBePositive => 'Noldan katta boʻlishi kerak';

  @override
  String get commonCannotBeNegative => 'Manfiy boʻlishi mumkin emas';

  @override
  String get commonIntegerOnly => 'Faqat butun son';

  @override
  String get commonEnterName => 'Ismni kiriting';

  @override
  String get commonSomethingWentWrong => 'Nimadir notoʻgʻri ketdi';

  @override
  String get commonProduct => 'Mahsulot';

  @override
  String get commonProducts => 'Mahsulotlar';

  @override
  String get commonCustomer => 'Mijoz';

  @override
  String get commonCustomers => 'Mijozlar';

  @override
  String get commonSupplier => 'Taʼminotchi';

  @override
  String get commonCashier => 'Kassir';

  @override
  String get commonEmployee => 'Xodim';

  @override
  String get commonShift => 'Smena';

  @override
  String get commonReceipt => 'Chek';

  @override
  String get commonSale => 'Sotuv';

  @override
  String get commonReturn => 'Qaytarish';

  @override
  String get commonPayment => 'Toʻlov';

  @override
  String get commonPaymentMethod => 'Toʻlov usuli';

  @override
  String get commonDiscount => 'Chegirma';

  @override
  String get commonChange => 'Qaytim';

  @override
  String get commonDebt => 'Qarz';

  @override
  String get commonBonuses => 'Bonuslar';

  @override
  String get commonBalance => 'Balans';

  @override
  String get commonGiftCard => 'Sertifikat';

  @override
  String get commonCategory => 'Kategoriya';

  @override
  String get commonBarcode => 'Shtrix-kod';

  @override
  String get commonSku => 'Artikul';

  @override
  String get commonStock => 'Qoldiq';

  @override
  String get commonUnit => 'Oʻlch. birl.';

  @override
  String get commonVat => 'QQS';

  @override
  String get commonDocument => 'Hujjat';

  @override
  String get commonVoided => 'Bekor qilingan';

  @override
  String get commonEnabled => 'Yoqilgan';

  @override
  String get commonDisabled => 'Oʻchirilgan';

  @override
  String get commonNew => 'Yangi';

  @override
  String get commonOpen => 'Ochish';

  @override
  String get commonCustomerNotFound => 'Mijoz topilmadi';

  @override
  String commonPositionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta pozitsiya',
    );
    return '$_temp0';
  }

  @override
  String commonDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta hujjat',
    );
    return '$_temp0';
  }

  @override
  String commonReceiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta chek',
    );
    return '$_temp0';
  }

  @override
  String commonReturnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta qaytarish',
    );
    return '$_temp0';
  }

  @override
  String commonMarksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta qayd',
    );
    return '$_temp0';
  }

  @override
  String commonProductsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta mahsulot',
    );
    return '$_temp0';
  }

  @override
  String commonCustomersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta mijoz',
    );
    return '$_temp0';
  }

  @override
  String commonDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun',
    );
    return '$_temp0';
  }

  @override
  String get payCash => 'Naqd';

  @override
  String get payCard => 'Karta';

  @override
  String get payTransfer => 'Oʻtkazma';

  @override
  String get payBonus => 'Bonuslar';

  @override
  String get payDebt => 'Qarzga';

  @override
  String get payGiftCard => 'Sertifikat';

  @override
  String get unitPcs => 'dona';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'l';

  @override
  String get unitM => 'm';

  @override
  String get unitPack => 'qadoq';

  @override
  String get roleOwner => 'Egasi';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleManager => 'Menejer';

  @override
  String get roleCashier => 'Kassir';

  @override
  String get roleStorekeeper => 'Omborchi';

  @override
  String get coreLanguage => 'Til';

  @override
  String get coreUiLanguage => 'Interfeys tili';

  @override
  String get coreReceiptLanguage => 'Chek tili';

  @override
  String get coreDuplicateBarcode =>
      'Bunday shtrix-kodli mahsulot allaqachon mavjud';

  @override
  String get coreDuplicateCard => 'Bunday raqamli karta allaqachon bor';

  @override
  String get coreDuplicateCode => 'Bunday kod allaqachon mavjud';

  @override
  String get coreDuplicateRecord => 'Bunday yozuv allaqachon mavjud';

  @override
  String get coreErase => 'Oʻchirish';

  @override
  String get corePickProductTitle => 'Mahsulot tanlash';

  @override
  String get corePickProductHint => 'Nomi, artikul yoki shtrix-kod';

  @override
  String coreSkuShort(String sku) {
    return 'art. $sku';
  }

  @override
  String coreStockShort(String qty) {
    return 'qoldiq $qty';
  }

  @override
  String get coreNewCustomer => 'Yangi mijoz';

  @override
  String get coreNameRequiredLabel => 'Ism *';

  @override
  String get coreCustomerSearchHint => 'Ism, telefon yoki karta raqami';

  @override
  String get coreCreateCustomer => 'Mijoz yaratish';

  @override
  String coreCardShort(String number) {
    return 'karta $number';
  }

  @override
  String coreDiscountShort(String percent) {
    return 'chegirma $percent%';
  }

  @override
  String coreDebtShort(String amount) {
    return 'qarz $amount';
  }

  @override
  String coreBonusShort(String amount) {
    return 'bonuslar $amount';
  }

  @override
  String get corePinFormat => 'PIN — 4 tadan 8 tagacha raqam';

  @override
  String get corePinTooSimple => 'PIN juda oddiy';

  @override
  String corePrintPhone(String phone) {
    return 'Tel: $phone';
  }

  @override
  String corePrintTaxId(String taxId) {
    return 'STIR: $taxId';
  }

  @override
  String coreReceiptTitle(String number) {
    return 'CHEK №$number';
  }

  @override
  String coreReceiptCopyTitle(String number) {
    return 'NUSXA CHEK №$number';
  }

  @override
  String corePrintCashier(String name) {
    return 'Kassir: $name';
  }

  @override
  String corePrintCustomer(String name) {
    return 'Mijoz: $name';
  }

  @override
  String corePrintWarrantyUntil(String date) {
    return 'Kafolat $date gacha';
  }

  @override
  String get corePrintTotal => 'JAMI';

  @override
  String get corePrintVatIncluded => 'shu jumladan QQS';

  @override
  String get corePrintBonusEarned => 'Bonus hisoblandi';

  @override
  String get corePrintCustomerDebt => 'Mijoz qarzi';

  @override
  String get corePrintVoided => '*** BEKOR QILINGAN ***';

  @override
  String corePrintReason(String reason) {
    return 'Sabab: $reason';
  }

  @override
  String corePrintJobReceipt(String number) {
    return 'Chek $number';
  }

  @override
  String corePrintJobGift(String number) {
    return 'Sertifikat $number';
  }

  @override
  String coreGiftSlipTitle(String number) {
    return 'Sertifikat sotuvi №$number';
  }

  @override
  String coreGiftSlipCopyTitle(String number) {
    return 'NUSXA Sertifikat sotuvi №$number';
  }

  @override
  String get coreGiftSlipNote =>
      'Sertifikat tovar uchun fiskal chek hisoblanmaydi';

  @override
  String get coreGiftCode => 'Sertifikat kodi';

  @override
  String get coreGiftFaceValue => 'Nominal';

  @override
  String get coreGiftValidity => 'Amal qilish muddati';

  @override
  String get coreGiftNoExpiry => 'muddatsiz';

  @override
  String coreGiftUntil(String date) {
    return '$date gacha';
  }

  @override
  String get navDashboard => 'Bosh sahifa';

  @override
  String get navPos => 'Kassa';

  @override
  String get navSales => 'Cheklar';

  @override
  String get navShifts => 'Smena';

  @override
  String get navProducts => 'Mahsulotlar';

  @override
  String get navInventory => 'Ombor';

  @override
  String get navPurchasing => 'Xaridlar';

  @override
  String get navCustomers => 'Mijozlar';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navWarranty => 'Kafolat';

  @override
  String get navReports => 'Hisobotlar';

  @override
  String get navStaff => 'Xodimlar';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get navNotifications => 'Bildirishnomalar';

  @override
  String get appMenu => 'Menyu';

  @override
  String get appShiftClosed => 'Smena yopiq';

  @override
  String appShiftChip(String number, String time) {
    return 'Smena №$number · $time dan';
  }

  @override
  String appShiftChipShort(String number) {
    return 'Smena №$number';
  }

  @override
  String appShiftChipNumber(String number) {
    return '№$number';
  }

  @override
  String get appProfile => 'Profil';

  @override
  String get appLockSwitch => 'Bloklash / kassirni almashtirish';

  @override
  String get domCustomerDiscount => 'Mijoz chegirmasi';

  @override
  String get errPinInUse => 'Bu PIN boshqa xodim tomonidan ishlatilmoqda';

  @override
  String errTooManyAttempts(String minutes) {
    return 'Notoʻgʻri urinishlar juda koʻp. $minutes daqiqa kuting';
  }

  @override
  String get errAccountLockedTryLater =>
      'Hisob vaqtincha bloklangan. Keyinroq urinib koʻring';

  @override
  String get errAccountLocked => 'Hisob vaqtincha bloklangan';

  @override
  String get errWrongPin => 'PIN notoʻgʻri';

  @override
  String get errAmountMustBePositive => 'Summa noldan katta boʻlishi kerak';

  @override
  String get errNoDebt => 'Mijozning qarzi yoʻq';

  @override
  String get errAmountExceedsDebt => 'Summa mijoz qarzidan katta';

  @override
  String get errOpenShiftForCash =>
      'Naqd pul qabul qilish uchun smenani oching';

  @override
  String get errBonusNegative => 'Bonus balansi manfiy boʻlishi mumkin emas';

  @override
  String get errGiftCodeTooShort => 'Sertifikat kodi — kamida 6 belgi';

  @override
  String get errGiftCodeTooLong => 'Sertifikat kodi juda uzun';

  @override
  String get errGiftCodeChars => 'Kod: faqat lotin harflari va raqamlar';

  @override
  String get errFaceValuePositive => 'Nominal noldan katta boʻlishi kerak';

  @override
  String get errExpiryPassed => 'Amal qilish muddati allaqachon tugagan';

  @override
  String get errOpenShiftToSellGift => 'Sertifikat sotish uchun smenani oching';

  @override
  String get errChoosePaymentMethod => 'Toʻlov usulini tanlang';

  @override
  String get errGiftPaymentMethods =>
      'Sertifikatni faqat naqd, karta yoki oʻtkazma orqali toʻlash mumkin';

  @override
  String get errPaymentMustBePositive =>
      'Toʻlov summasi noldan katta boʻlishi kerak';

  @override
  String get errGiftPaymentsMismatch =>
      'Toʻlovlar summasi sertifikat nominaliga mos emas';

  @override
  String get errCashNotInPayment => 'Naqd pul toʻlovga kirmaydi';

  @override
  String get errCashTenderedLess =>
      'Qabul qilingan naqd pul toʻlov summasidan kam';

  @override
  String errGiftCodeExists(String code) {
    return '$code kodli sertifikat allaqachon mavjud';
  }

  @override
  String get errDocumentNotFound => 'Hujjat topilmadi';

  @override
  String get errGiftSaleAlreadyVoided => 'Sotuv allaqachon bekor qilingan';

  @override
  String get errGiftNotFound => 'Sertifikat topilmadi';

  @override
  String get errGiftUsedCannotVoid =>
      'Sertifikat allaqachon ishlatilgan — bekor qilib boʻlmaydi';

  @override
  String get errVoidReasonRequired => 'Bekor qilish sababini koʻrsating';

  @override
  String get errOpenShiftToVoid => 'Sotuvni bekor qilish uchun smenani oching';

  @override
  String errGiftSaleNumberVoided(String number) {
    return 'Sertifikat sotuvi №$number allaqachon bekor qilingan';
  }

  @override
  String get errAddLine => 'Kamida bitta pozitsiya qoʻshing';

  @override
  String get errPurchasePriceNegative =>
      'Xarid narxi manfiy boʻlishi mumkin emas';

  @override
  String get errRetailPricePositive =>
      'Chakana narx noldan katta boʻlishi kerak';

  @override
  String get errProductNotFound => 'Mahsulot topilmadi';

  @override
  String errProductDeleted(String name) {
    return '“$name” mahsuloti oʻchirilgan';
  }

  @override
  String errLinePurchasePriceNegative(String name) {
    return '$name: xarid narxi manfiy';
  }

  @override
  String errProductRepeated(String name) {
    return '“$name” mahsuloti hujjatda takrorlangan — qatorlarni birlashtiring';
  }

  @override
  String get errSupplierNotFound => 'Taʼminotchi topilmadi';

  @override
  String get errOrderNotFound => 'Buyurtma topilmadi';

  @override
  String get errOrderOtherSupplier => 'Buyurtma bu taʼminotchiga tegishli emas';

  @override
  String errOrderClosed(String number) {
    return 'Buyurtma №$number allaqachon yopilgan';
  }

  @override
  String get errOrderLineNotFound => 'Pozitsiya buyurtmada topilmadi';

  @override
  String get errOrderLineWithoutOrder =>
      'Buyurtma pozitsiyasi buyurtmasiz koʻrsatilgan';

  @override
  String get errReversalReasonRequired => 'Storno sababini koʻrsating';

  @override
  String get errReceiptNotFound => 'Kirim topilmadi';

  @override
  String errReceiptAlreadyReversed(String number) {
    return 'Kirim №$number allaqachon storno qilingan';
  }

  @override
  String errSupplierDeletedNoReversal(String name, String number) {
    return '“$name” taʼminotchisi oʻchirilgan — kirim №$number ni storno qilib boʻlmaydi';
  }

  @override
  String get errQtyMustBePositive => 'Miqdor noldan katta boʻlishi kerak';

  @override
  String errQtyIntegerOnly(String unit) {
    return '“$unit” uchun faqat butun son ruxsat etiladi';
  }

  @override
  String get errQtyTooLarge => 'Miqdor juda katta';

  @override
  String get errCartEmpty => 'Chek boʻsh';

  @override
  String get errPriceNegative => 'Narx manfiy boʻlishi mumkin emas';

  @override
  String get errPaymentNegative => 'Toʻlov summasi manfiy boʻlishi mumkin emas';

  @override
  String errUnknownPaymentMethodNamed(String method) {
    return 'Nomaʼlum toʻlov usuli: $method';
  }

  @override
  String get errUnknownPaymentMethod => 'Nomaʼlum toʻlov usuli';

  @override
  String get errOpenShiftToSell => 'Sotish uchun smenani oching';

  @override
  String get errShiftClosedOpenNew => 'Smena yopilgan. Yangi smena oching';

  @override
  String get errProductNotFoundOrDeleted =>
      'Mahsulot topilmadi yoki oʻchirilgan';

  @override
  String get errPromoInvalid => 'Promokod yaroqsiz';

  @override
  String errManualDiscountLimit(String percent, String limit) {
    return 'Qoʻlda berilgan chegirma $percent% ruxsat etilgandan ($limit%) oshadi. Menejer tasdigʻi kerak';
  }

  @override
  String get errNonCashExceedsTotal => 'Naqdsiz toʻlov chek summasidan oshadi';

  @override
  String errInsufficientPayment(String amount) {
    return 'Toʻlov yetarli emas: $amount yetishmaydi';
  }

  @override
  String get errBonusNeedsCustomer =>
      'Bonus bilan toʻlash uchun mijozni tanlang';

  @override
  String get errLoyaltyDisabled => 'Bonus dasturi oʻchirilgan';

  @override
  String errInsufficientBonus(String amount) {
    return 'Bonuslar yetarli emas: mavjud $amount';
  }

  @override
  String errBonusMaxRedeem(String amount) {
    return 'Bonus bilan koʻpi bilan $amount toʻlash mumkin';
  }

  @override
  String get errDebtNeedsCustomer => 'Qarzga sotish uchun mijozni tanlang';

  @override
  String errCreditLimitExceeded(String limit, String debt) {
    return 'Mijozning kredit limiti ($limit) oshib ketdi. Joriy qarz: $debt';
  }

  @override
  String get errNoCredit => 'Mijozga kredit ochilmagan';

  @override
  String errGiftCardNotFound(String code) {
    return '$code sertifikati topilmadi';
  }

  @override
  String errGiftCardInactive(String code) {
    return '$code sertifikati faol emas';
  }

  @override
  String errGiftCardExpired(String code) {
    return '$code sertifikatining amal qilish muddati tugagan';
  }

  @override
  String errGiftCardInsufficient(String code, String amount) {
    return '$code sertifikatida faqat $amount bor';
  }

  @override
  String get errSelectReturnItems => 'Qaytarish uchun mahsulotlarni tanlang';

  @override
  String get errSaleNotFound => 'Chek topilmadi';

  @override
  String get errFullyReturned =>
      'Bu chek boʻyicha toʻliq qaytarish allaqachon rasmiylashtirilgan';

  @override
  String errReturnPeriodExpired(String days) {
    return 'Qaytarish muddati ($days kun) tugagan';
  }

  @override
  String get errLineNotInSale => 'Pozitsiya bu chekdan emas';

  @override
  String errReturnQtyExceeded(String name, String qty) {
    return '“$name”: koʻpi bilan $qty qaytarish mumkin';
  }

  @override
  String get errSaleNoCustomer => 'Chekda mijoz yoʻq';

  @override
  String get errOpenShiftForCashRefund =>
      'Naqd pul qaytarish uchun smenani oching';

  @override
  String get errVoidOnlyWithoutReturns =>
      'Faqat qaytarishsiz chekni bekor qilish mumkin';

  @override
  String get errSaleOtherShift =>
      'Chek boshqa smenadan — qaytarishni rasmiylashtiring';

  @override
  String get errAmountNegative => 'Summa manfiy boʻlishi mumkin emas';

  @override
  String errShiftAlreadyOpen(String number) {
    return 'Smena №$number allaqachon ochiq';
  }

  @override
  String get errUnknownOperation => 'Nomaʼlum operatsiya';

  @override
  String get errShiftClosed => 'Smena yopilgan';

  @override
  String get errNotEnoughCash => 'Kassada naqd pul yetarli emas';

  @override
  String get errShiftAlreadyClosed => 'Smena allaqachon yopilgan';

  @override
  String errInsufficientStock(String name, String qty) {
    return '“$name” mahsuloti yetarli emas: mavjud $qty';
  }

  @override
  String get errCountClosed => 'Inventarizatsiya allaqachon yopilgan';

  @override
  String errSupplierDeleted(String name) {
    return '“$name” taʼminotchisi oʻchirilgan — amalni bajarib boʻlmaydi';
  }

  @override
  String get errOpenShiftForCashPayout =>
      'Kassadan naqd toʻlash uchun smenani oching';

  @override
  String errOverpaySupplier(String amount) {
    return 'Summa taʼminotchiga qarzdan ($amount) katta. Ortiqcha toʻlovni tasdiqlang.';
  }

  @override
  String errOrderCancelled(String number) {
    return 'Buyurtma №$number bekor qilingan';
  }

  @override
  String get errShiftClosedOpenShift => 'Smena yopilgan — smenani oching';

  @override
  String get errCancelReasonRequired =>
      'Toʻlovni bekor qilish sababini koʻrsating';

  @override
  String get errPaymentNotFound => 'Toʻlov topilmadi';

  @override
  String get errPaymentAlreadyCancelled => 'Toʻlov allaqachon bekor qilingan';

  @override
  String get errPaymentShiftClosed =>
      'Toʻlov smenasi yopilgan — bekor qilib boʻlmaydi';

  @override
  String get errAdjustmentZero => 'Tuzatish summasi nol boʻlishi mumkin emas';

  @override
  String get errAdjustmentReasonRequired => 'Tuzatish sababini koʻrsating';

  @override
  String get errPinAmbiguous =>
      'Bu PIN-kod bir nechta xodimda bor (kassalar sinxronlangandan keyin). Boshqa xodim sifatida kiring va ulardan biriga PIN-kodni almashtiring.';

  @override
  String get errPaymentOtherRegisterShift =>
      'Naqd toʻlov boshqa kassaning smenasida kiritilgan — uni faqat oʻsha kassada bekor qilish mumkin';

  @override
  String errReceiptOpeningNoReversal(String number) {
    return 'Kirim №$number — sinxronlash boshlangʻich qoldigʻi, uni storno qilib boʻlmaydi';
  }

  @override
  String get errEffectDoneElsewhere =>
      'Bu hujjat boshqa kassada allaqachon oʻtkazilgan, lekin uning barcha oʻzgarishlari hali kelmagan. Kassani sinxronlang va hujjatni qayta oching.';

  @override
  String get authEnterPin => 'PIN-kodni kiriting';

  @override
  String get authDemoMode => 'Demo rejim';

  @override
  String get setupDefaultReceiptFooter => 'Xaridingiz uchun rahmat!';

  @override
  String get setupWelcome => 'DreamPOSga xush kelibsiz';

  @override
  String get setupIntro =>
      'Sozlash bir daqiqadan kam vaqt oladi. Hammasini keyinroq “Sozlamalar”da oʻzgartirish mumkin.';

  @override
  String get setupStart => 'Ishni boshlash';

  @override
  String get setupStoreName => 'Doʻkon nomi *';

  @override
  String get setupEnterStoreName => 'Nomini kiriting';

  @override
  String get setupTaxId => 'STIR / INN';

  @override
  String get setupCurrency => 'Hisob valyutasi';

  @override
  String setupCurrencyExample(String amount) {
    return 'Misol: $amount';
  }

  @override
  String get setupCurrencyWarning =>
      'Birinchi sotuvdan keyin valyutani oʻzgartirib boʻlmaydi — bazadagi barcha summalar unga bogʻliq.';

  @override
  String get setupOwnerName => 'Ismingiz (egasi) *';

  @override
  String get setupPin => 'PIN-kod (4–8 raqam) *';

  @override
  String get setupPinRepeat => 'PINni takrorlang *';

  @override
  String get setupPinMismatch => 'PIN mos kelmadi';

  @override
  String get setupDemo => 'Demo maʼlumotlar bilan toʻldirish';

  @override
  String get setupDemoHint =>
      'Tizim bilan tanishish uchun mahsulotlar, mijozlar va aksiyalar. Haqiqiy doʻkon uchun yoqmang.';

  @override
  String get setupStepStore => 'Doʻkon';

  @override
  String get setupStepCurrency => 'Valyuta';

  @override
  String get setupStepOwner => 'Egasi';

  @override
  String get setupOr => 'yoki';

  @override
  String get setupJoinStore => 'Mavjud doʻkonga ulanish';

  @override
  String get setupJoinStoreHint =>
      'Agar doʻkon boshqa kassada bulutda ishlayotgan boʻlsa: tovarlar, mijozlar va foydalanuvchilar oʻsha yerdan yuklanadi.';

  @override
  String get setupJoinTitle => 'Doʻkonga ulanish';

  @override
  String get setupJoinIntro =>
      'Bulut hisobiga kiring va doʻkonni tanlang. Uning maʼlumotlari va foydalanuvchilari bu kassaga yuklanadi, soʻng PIN-kod bilan kiring.';

  @override
  String get setupJoinNewStore => 'Yangi doʻkon yaratish';

  @override
  String get setupJoinDone =>
      'Doʻkon maʼlumotlari yuklandi. PIN-kod bilan kiring.';

  @override
  String get setupJoinPartial =>
      'Kassa ulandi, lekin maʼlumotlarni yuklash tugamadi. Aloqani tekshirib, qayta urinib koʻring.';

  @override
  String get setupJoinRetry => 'Yuklashni takrorlash';

  @override
  String get setupJoinSignUpIntro =>
      'Firebase loyihangizda ega hisobini yarating. Soʻng bu kassada yangi doʻkon yarating, uni bulutga oʻtkazish uchun Sozlamalar › Sinxronlash boʻlimida «Bulutda doʻkon yaratish»ni tanlang.';

  @override
  String get custCreated => 'Mijoz yaratildi';

  @override
  String get custNoneToExport => 'Eksport uchun mijozlar yoʻq';

  @override
  String custCsvCopied(String count) {
    return '$count ta mijoz CSV formatida nusxalandi — Excelga joylang';
  }

  @override
  String custTotalCount(String count) {
    return 'Jami: $count';
  }

  @override
  String get custExportTooltip =>
      'Joriy roʻyxatni CSVga nusxalash (Excel uchun)';

  @override
  String get custNewTooltip => 'Yangi mijoz (Ctrl+N)';

  @override
  String get custNew => 'Yangi mijoz';

  @override
  String get custSelectTitle => 'Mijozni tanlang';

  @override
  String get custSelectMessage =>
      'Bu yerda mijozning xaridlari, qarzlari, bonuslari va sevimli mahsulotlari koʻrinadi.';

  @override
  String get custStatCustomers => 'Mijozlar';

  @override
  String get custStatReceivable => 'Debitorlik';

  @override
  String custOverdueLower(String amount) {
    return 'muddati oʻtgan $amount';
  }

  @override
  String custOverdue(String amount) {
    return 'Muddati oʻtgan $amount';
  }

  @override
  String get custStatBonusLiability => 'Bonus majburiyatlari';

  @override
  String get custSearchHintWide => 'Ism, telefon yoki karta (Ctrl+F)';

  @override
  String get custSearchHint => 'Ism, telefon, karta';

  @override
  String custSortTooltip(String sort) {
    return 'Saralash: $sort';
  }

  @override
  String get custTagFilter => 'Teg boʻyicha filtr';

  @override
  String custTagTooltip(String tag) {
    return 'Teg: $tag';
  }

  @override
  String get custAllTags => 'Barcha teglar';

  @override
  String get custEmptyTitle => 'Hozircha mijozlar yoʻq';

  @override
  String get custEmptyMessage =>
      'Chegirma berish, bonus hisoblash va qarzga sotish uchun mijozlarni qoʻshing.';

  @override
  String get custAdd => 'Mijoz qoʻshish';

  @override
  String get custNotFoundTitle => 'Hech kim topilmadi';

  @override
  String get custNotFoundMessage =>
      'Soʻrovni oʻzgartiring yoki filtrlarni tozalang';

  @override
  String get custResetFilters => 'Filtrlarni tozalash';

  @override
  String custTileCard(String card) {
    return 'karta $card';
  }

  @override
  String custDiscountLower(String value) {
    return 'chegirma $value';
  }

  @override
  String custTilePurchases(String amount) {
    return 'xaridlar $amount';
  }

  @override
  String custTileVisits(String count) {
    return '$count tashrif';
  }

  @override
  String get custTileNeverBought => 'xarid qilmagan';

  @override
  String custTileLastVisit(String date) {
    return 'oxirgi $date';
  }

  @override
  String get custBirthdayToday => 'Bugun tugʻilgan kuni';

  @override
  String custBirthdayIn(String days) {
    return 'Tugʻilgan kuniga $days kun qoldi';
  }

  @override
  String custTileDebt(String amount) {
    return 'qarz $amount';
  }

  @override
  String get custTileOverdueChip => 'muddati oʻtgan';

  @override
  String custTileBonus(String amount) {
    return 'bonuslar $amount';
  }

  @override
  String get custCardTitle => 'Mijoz kartochkasi';

  @override
  String custDeleteDebt(String amount) {
    return '$amount qarzi bor mijozni oʻchirib boʻlmaydi. Avval toʻlovni qabul qiling.';
  }

  @override
  String get custDeleteOverpaid =>
      'Ortiqcha toʻlovi bor mijozni oʻchirib boʻlmaydi.';

  @override
  String get custDeleteTitle => 'Mijoz oʻchirilsinmi?';

  @override
  String custDeleteMessage(String name) {
    return '“$name” roʻyxatdan yashiriladi. Sotuvlar tarixi saqlanadi.';
  }

  @override
  String custDeleteBonusLost(String amount) {
    return '$amount bonusdan foydalanib boʻlmay qoladi.';
  }

  @override
  String get custDeleted => 'Mijoz oʻchirildi';

  @override
  String get custNotFoundOrDeleted => 'Mijoz topilmadi yoki oʻchirilgan';

  @override
  String get custKpiSpent => 'Xaridlar summasi';

  @override
  String get custKpiVisits => 'Tashriflar';

  @override
  String get custKpiAvg => 'Oʻrtacha chek';

  @override
  String get custKpiLastVisit => 'Oxirgi tashrif';

  @override
  String get custNoPurchasesYet => 'Hali xarid boʻlmagan';

  @override
  String get custNoPurchasesLower => 'xarid boʻlmagan';

  @override
  String custLimit(String amount) {
    return 'Limit $amount';
  }

  @override
  String custLimitLower(String amount) {
    return 'limit $amount';
  }

  @override
  String get custNoCredit => 'Kredit ochilmagan';

  @override
  String get custNoCreditLower => 'kredit ochilmagan';

  @override
  String get custBdayToday => 'bugun!';

  @override
  String custBdayIn(String days) {
    return '$days kundan keyin';
  }

  @override
  String custDiscountChip(String percent) {
    return 'Chegirma $percent%';
  }

  @override
  String get custDelete => 'Mijozni oʻchirish';

  @override
  String get custNoPayPerm => 'Toʻlov qabul qilish huquqi yoʻq';

  @override
  String get custAcceptDebtPayment => 'Qarz toʻlovini qabul qilish';

  @override
  String get custNoEditPerm => 'Mijozlarni tahrirlash huquqi yoʻq';

  @override
  String get custRemind => 'Eslatish';

  @override
  String get custNeedPromoPerm => '“Aksiyalar va bonuslar” huquqi kerak';

  @override
  String get custReminder => 'Eslatma';

  @override
  String get custTabSales => 'Xaridlar';

  @override
  String get custTabSalesShort => 'Xaridlar';

  @override
  String get custTabLedgerShort => 'Operatsiyalar';

  @override
  String get custTabLedger => 'Qarzlar va bonuslar';

  @override
  String get custTabFavShort => 'Sevimli';

  @override
  String get custTabFav => 'Sevimli mahsulotlar';

  @override
  String get custAgoToday => 'bugun';

  @override
  String get custAgoYesterday => 'kecha';

  @override
  String custAgoDays(String days) {
    return '$days kun oldin';
  }

  @override
  String get custCopy => 'Nusxalash';

  @override
  String custCopied(String text) {
    return 'Nusxalandi: $text';
  }

  @override
  String get custSalesEmptyTitle => 'Hozircha xaridlar yoʻq';

  @override
  String get custSalesEmptyMessage =>
      'Tarix va bonuslar yigʻilishi uchun kassada mijozni tanlang.';

  @override
  String custReceiptNo(String number) {
    return 'Chek №$number';
  }

  @override
  String custReturnLower(String amount) {
    return 'qaytarish $amount';
  }

  @override
  String custReturnedQty(String qty) {
    return 'qaytarilgan $qty';
  }

  @override
  String custBonusEarned(String amount) {
    return 'Bonus hisoblandi: $amount';
  }

  @override
  String get custLedgerEmpty => 'Qarz va bonuslar boʻyicha operatsiyalar yoʻq';

  @override
  String custDueUntil(String date) {
    return 'muddat $date gacha';
  }

  @override
  String custBalanceAfter(String amount) {
    return 'qoldiq $amount';
  }

  @override
  String get custDuePassed => 'muddat oʻtdi';

  @override
  String get custFavEmpty => 'Hozircha xaridlar haqida maʼlumot yoʻq';

  @override
  String custBought(String qty) {
    return 'sotib olingan $qty';
  }

  @override
  String get custSegDebtors => 'Qarzdorlar';

  @override
  String get custSegOverdue => 'Muddati oʻtgan';

  @override
  String get custSegVip => 'VIP';

  @override
  String get custSegSleeping => 'Faol emas';

  @override
  String get custSegBirthdays => 'Tugʻilgan kunlar';

  @override
  String get custSegAllHint => 'Barcha mijozlar';

  @override
  String get custSegDebtorsHint => 'Toʻlanmagan qarzi bor mijozlar';

  @override
  String get custSegOverdueHint => 'Qarzni toʻlash muddati oʻtgan';

  @override
  String get custSegVipHint => 'Xaridlar summasi boʻyicha top-10% mijozlar';

  @override
  String custSegSleepingHint(String days) {
    return '$days kundan ortiq xarid qilmagan';
  }

  @override
  String custSegBirthdaysHint(String days) {
    return 'Yaqin $days kun ichida tugʻilgan kuni';
  }

  @override
  String get custSortName => 'Ism boʻyicha';

  @override
  String get custSortLastVisit => 'Oxirgi tashrif boʻyicha';

  @override
  String get custSortSpent => 'Xaridlar summasi boʻyicha';

  @override
  String get custSortDebt => 'Qarz boʻyicha';

  @override
  String get custSortBonus => 'Bonuslar boʻyicha';

  @override
  String get custSortCreated => 'Avval yangilari';

  @override
  String get custLedgerDebtSale => 'Qarzga sotish';

  @override
  String get custLedgerDebtPayment => 'Qarzni toʻlash';

  @override
  String get custLedgerDebtAdjust => 'Qarzni tuzatish';

  @override
  String get custLedgerBonusEarn => 'Bonus hisoblash';

  @override
  String get custLedgerBonusSpend => 'Bonusni yechish';

  @override
  String get custLedgerBonusAdjust => 'Bonuslarni tuzatish';

  @override
  String get custStatusCompleted => 'Toʻlangan';

  @override
  String get custStatusPartReturned => 'Qisman qaytarilgan';

  @override
  String get custStatusReturned => 'Qaytarilgan';

  @override
  String get custStatusHeld => 'Kechiktirilgan';

  @override
  String custReminderGreeting(String name, String store, String debt) {
    return 'Assalomu alaykum, $name! $store doʻkonidagi qarzingiz $debt.';
  }

  @override
  String custReminderOverdue(String amount) {
    return 'Shundan muddati oʻtgani: $amount.';
  }

  @override
  String custReminderDue(String date) {
    return 'Toʻlov muddati — $date gacha.';
  }

  @override
  String get custReminderAsk =>
      'Iltimos, doʻkonga navbatdagi tashrifingizda qarzni toʻlang.';

  @override
  String custReminderPhone(String phone) {
    return 'Aloqa uchun telefon: $phone.';
  }

  @override
  String get custThanks => 'Rahmat!';

  @override
  String get custCsvCard => 'Karta';

  @override
  String get custCsvDiscount => 'Chegirma %';

  @override
  String custPaymentAccepted(String amount) {
    return '$amount toʻlov qabul qilindi';
  }

  @override
  String get custCurrentDebt => 'Joriy qarz:';

  @override
  String get custPayAmount => 'Toʻlov summasi *';

  @override
  String custNotMoreThanDebt(String amount) {
    return 'Qarzdan koʻp emas ($amount)';
  }

  @override
  String custFullAmountValue(String amount) {
    return 'Butun summa: $amount';
  }

  @override
  String get custFullAmount => 'Butun summa';

  @override
  String get custShiftClosedCash =>
      'Smena yopiq: naqd pul qabul qilish uchun smenani oching yoki boshqa usulni tanlang.';

  @override
  String custCashToShift(String number) {
    return 'Naqd pul smena №$number kassasida hisobga olinadi';
  }

  @override
  String get custPrintSlip => 'Kvitansiyani chop etish';

  @override
  String get custAcceptPayment => 'Toʻlovni qabul qilish';

  @override
  String get custPdfSlipTitle => 'KVITANSIYA';

  @override
  String get custPdfSlipSubtitle => 'qarz toʻlovi haqida';

  @override
  String get custPdfDebtBefore => 'Toʻlovgacha qarz';

  @override
  String custPdfPaid(String method) {
    return 'Toʻlandi ($method)';
  }

  @override
  String get custPdfDebtAfter => 'Qarz qoldigʻi';

  @override
  String get custPdfSignature => 'Mijoz imzosi: ____________';

  @override
  String custPdfJobName(String name) {
    return 'Kvitansiya $name';
  }

  @override
  String custBonusAdded(String amount) {
    return '$amount hisoblandi';
  }

  @override
  String custBonusRemoved(String amount) {
    return '$amount yechildi';
  }

  @override
  String custBonusHeader(String name, String amount) {
    return '$name · balans $amount';
  }

  @override
  String get custBonusAdd => 'Hisoblash';

  @override
  String get custBonusRemove => 'Yechish';

  @override
  String get custBonusAmount => 'Bonus summasi *';

  @override
  String custBonusOnlyOnBalance(String amount) {
    return 'Balansda faqat $amount';
  }

  @override
  String get custReasonRequired => 'Sabab *';

  @override
  String get custReasonHint =>
      'Masalan: buyurtma kechikkani uchun kompensatsiya';

  @override
  String get custReasonError => 'Tuzatish sababini koʻrsating';

  @override
  String get custOurStore => 'bizning doʻkon';

  @override
  String get custReminderTitle => 'Qarz haqida eslatma';

  @override
  String get custPhoneCopied => 'Telefon nusxalandi';

  @override
  String get custReminderEmpty => 'Eslatma matni boʻsh';

  @override
  String get custReminderCopied => 'Eslatma matni nusxalandi';

  @override
  String custPhoneValue(String phone) {
    return 'Telefon: $phone';
  }

  @override
  String get custReminderSendHint =>
      'Matnni telefoningizdan messenjer yoki SMS orqali yuboring.';

  @override
  String get custCopyPhone => 'Telefonni nusxalash';

  @override
  String get custCopyText => 'Matnni nusxalash';

  @override
  String get custEditTitle => 'Mijozni tahrirlash';

  @override
  String get custBirthday => 'Tugʻilgan kun';

  @override
  String get custCardTaken => 'Bu karta boshqa mijozga biriktirilgan';

  @override
  String get custPhoneUsedTitle => 'Telefon allaqachon ishlatilgan';

  @override
  String custPhoneUsedMessage(String phone, String name) {
    return '$phone raqami “$name” mijozida bor. Shu raqam bilan yana bir mijoz saqlansinmi?';
  }

  @override
  String get custNameField => 'Ism *';

  @override
  String get custEnterName => 'Mijoz ismini kiriting';

  @override
  String custPhoneExists(String names) {
    return 'Allaqachon bor: $names';
  }

  @override
  String get custPhoneTooShort => 'Raqam juda qisqa';

  @override
  String get custPhoneTooLong => 'Raqam juda uzun';

  @override
  String get custEmailInvalidFormat => 'Email formati notoʻgʻri';

  @override
  String get custCardNumber => 'Karta raqami';

  @override
  String get custGenerateCard => 'Karta raqamini yaratish';

  @override
  String get custNotSet => 'Koʻrsatilmagan';

  @override
  String get custNoDiscountPerm => 'Chegirmani oʻzgartirish huquqi yoʻq';

  @override
  String get custPersonalDiscount => 'Shaxsiy chegirma';

  @override
  String get custDiscountHelper =>
      'Aksiyalar bilan qoʻshilmaydi: eng yaxshisi olinadi';

  @override
  String get custPercentRange => '0 dan 100% gacha';

  @override
  String get custNoDebtPerm => 'Qarzlarni boshqarish huquqi yoʻq';

  @override
  String get custDebtLimit => 'Qarz limiti';

  @override
  String get custDebtLimitHelper => '0 — qarzga sotish taqiqlangan';

  @override
  String get custManagerOnly => 'Faqat menejer uchun';

  @override
  String get custTags => 'Teglar';

  @override
  String get custTagsHelper => 'Vergul bilan, masalan: ulgurji, doimiy';

  @override
  String get custNote => 'Izoh';

  @override
  String get custCardGenFailed =>
      'Karta raqamini yaratib boʻlmadi, qayta urinib koʻring';

  @override
  String get custNameTooLong => 'Ism juda uzun';

  @override
  String get custDiscountRange => 'Chegirma 0 dan 100% gacha boʻlishi kerak';

  @override
  String get custDebtLimitNegative => 'Qarz limiti manfiy boʻlishi mumkin emas';

  @override
  String get custEmailInvalid => 'Email notoʻgʻri';

  @override
  String custCardTakenBy(String card) {
    return '$card kartasi boshqa mijozga biriktirilgan';
  }

  @override
  String get custNoAssignDiscountPerm =>
      'Mijozga chegirma belgilash huquqi yoʻq';

  @override
  String get custNoOpenCreditPerm => 'Mijozga kredit ochish huquqi yoʻq';

  @override
  String get custNoChangeDiscountPerm =>
      'Mijoz chegirmasini oʻzgartirish huquqi yoʻq';

  @override
  String get custNoChangeDebtLimitPerm =>
      'Qarz limitini oʻzgartirish huquqi yoʻq';

  @override
  String get custDeleteDebtRepo =>
      'Qarzi bor mijozni oʻchirib boʻlmaydi. Avval qarz toʻlovini qabul qiling.';

  @override
  String get dash7Days => '7 kun';

  @override
  String get dashAllReceipts => 'Barcha cheklar';

  @override
  String get dashAvgCheck => 'Oʻrtacha chek';

  @override
  String dashBarTooltip(String revenue, String receipts) {
    return 'Tushum: $revenue\nCheklar: $receipts';
  }

  @override
  String get dashDebtAllPaid => 'Barcha mijozlar hisob-kitob qilgan';

  @override
  String get dashDebtLoading => 'Qarzlar…';

  @override
  String get dashDebtNone => 'Qarzlar yoʻq';

  @override
  String dashDebtTotal(String amount) {
    return 'Mijozlar qarzi: $amount';
  }

  @override
  String dashDebtors(String count) {
    return 'Qarzdorlar: $count';
  }

  @override
  String dashDuration(String hours, String minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String get dashGrossProfit => 'Yalpi foyda';

  @override
  String dashMargin(String pct) {
    return 'marja $pct%';
  }

  @override
  String get dashNoAccess => 'Boʻlimga ruxsat yoʻq';

  @override
  String get dashNoPaymentsToday => 'Bugun hali toʻlovlar boʻlmagan';

  @override
  String get dashNoReceipts => 'Hozircha cheklar yoʻq';

  @override
  String get dashNoSales => 'Hozircha sotuvlar yoʻq';

  @override
  String get dashOnbProductsButton => 'Mahsulotlarga';

  @override
  String dashOnbProductsDone(String count) {
    return 'Katalogda $count ta mahsulot. Yana qoʻshish yoki qoldiqlarni yuklash mumkin.';
  }

  @override
  String get dashOnbProductsText =>
      'Mahsulotlarni narx va qoldiqlari bilan kiriting — qoʻlda yoki shtrix-kod skaneri bilan.';

  @override
  String get dashOnbProductsTitle => 'Mahsulotlarni qoʻshing';

  @override
  String get dashOnbSaleButton => 'Kassaga oʻtish';

  @override
  String get dashOnbSaleText =>
      'Mahsulotni skanerlang yoki kassada tanlang va toʻlovni qabul qiling.';

  @override
  String get dashOnbSaleTitle => 'Birinchi sotuvni amalga oshiring';

  @override
  String get dashOnbShiftButton => 'Smenani ochish';

  @override
  String dashOnbShiftDone(String number) {
    return 'Smena №$number ochiq — sotish mumkin.';
  }

  @override
  String get dashOnbShiftText =>
      'Kechqurun naqd pulni solishtirish uchun kassadagi maydalik summasini kiriting.';

  @override
  String get dashOnbShiftTitle => 'Smenani oching';

  @override
  String get dashPaymentsToday => 'Bugungi toʻlovlar';

  @override
  String dashPcs(String count) {
    return '$count dona';
  }

  @override
  String get dashPos => 'Kassa';

  @override
  String dashReceiptNumber(String number) {
    return 'Chek №$number';
  }

  @override
  String get dashReceipts => 'Cheklar';

  @override
  String get dashRecentReceipts => 'Soʻnggi cheklar';

  @override
  String get dashReports => 'Hisobotlar';

  @override
  String get dashReturns => 'Qaytarishlar';

  @override
  String get dashRevenue14 => '14 kunlik tushum';

  @override
  String dashRevenueSummary(String total, String avg) {
    return 'Jami $total · savdo kuniga oʻrtacha $avg';
  }

  @override
  String get dashRevenueToday => 'Bugungi tushum';

  @override
  String get dashRevenueTooltip =>
      'Sotuvlar minus qaytarishlar (bekor qilingan cheklar hisobga olinmaydi)';

  @override
  String get dashShiftClosed => 'Smena yopiq';

  @override
  String get dashShiftClosedText => 'Smena ochilmaguncha sotish mumkin emas';

  @override
  String get dashShiftLong => 'Uzoq ochiq';

  @override
  String get dashShiftLongText =>
      'Smena 16 soatdan koʻproq ochiq — uni yoping va kassani solishtiring.';

  @override
  String dashShiftOpen(String number) {
    return 'Smena №$number ochiq';
  }

  @override
  String get dashShiftRunning => 'Davom etmoqda';

  @override
  String dashShiftSince(String time) {
    return '$time dan';
  }

  @override
  String dashShiftTotals(String receipts, String revenue) {
    return 'Cheklar: $receipts · tushum $revenue';
  }

  @override
  String get dashStatusPartReturned => 'qisman qaytarilgan';

  @override
  String get dashStatusReturned => 'qaytarilgan';

  @override
  String get dashStatusVoided => 'bekor qilingan';

  @override
  String dashStepsDone(String done, String total) {
    return '$total tadan $done tasi bajarildi';
  }

  @override
  String get dashStockLoading => 'Qoldiqlar…';

  @override
  String dashStockLow(String low, String out) {
    return 'Tugayapti: $low · mavjud emas: $out';
  }

  @override
  String get dashStockOk => 'Qoldiqlar yetarli';

  @override
  String get dashStockSubtitle => 'Qoldigʻi minimaldan past mahsulotlar';

  @override
  String get dashTitle => 'Bosh sahifa';

  @override
  String dashTodayDate(String date) {
    return 'Bugun, $date';
  }

  @override
  String get dashTop5 => 'Top-5 mahsulot';

  @override
  String dashVoidedSuffix(String count) {
    return ' · bekor qilingan cheklar: $count';
  }

  @override
  String get dashWelcome => 'DreamPOSga xush kelibsiz!';

  @override
  String get dashWelcomeText =>
      'Uch qadam — va bu yerda tushum, foyda, eng yaxshi mahsulotlar va maslahatlar paydo boʻladi.';

  @override
  String dashYesterdaySoFar(String value) {
    return 'kecha shu vaqtgacha: $value';
  }

  @override
  String get invReceipt => 'Kirim';

  @override
  String get invMoveReceiptReversal => 'Kirim stornosi';

  @override
  String get invWriteoff => 'Hisobdan chiqarish';

  @override
  String get invAdjustment => 'Tuzatish';

  @override
  String get invCount => 'Inventarizatsiya';

  @override
  String get invMoveTransfer => 'Koʻchirish';

  @override
  String get invMovements => 'Harakatlar';

  @override
  String get invStockTab => 'Qoldiqlar';

  @override
  String get invReasonDefect => 'Nuqsonli';

  @override
  String get invReasonExpired => 'Muddati oʻtgan';

  @override
  String get invReasonSpoiled => 'Buzilgan';

  @override
  String get invReasonShortage => 'Kamomad';

  @override
  String get invReasonPersonalUse => 'Shaxsiy isteʼmol';

  @override
  String get invReasonOther => 'Boshqa';

  @override
  String get invReceiptPosted => 'Oʻtkazilgan';

  @override
  String get invReceiptReversed => 'Storno qilingan';

  @override
  String get invCountDraft => 'Qoralama';

  @override
  String get invCountCompleted => 'Oʻtkazilgan';

  @override
  String get invCountCancelled => 'Bekor qilingan';

  @override
  String get invDeletedProduct => 'Oʻchirilgan mahsulot';

  @override
  String invReceiptRef(String number) {
    return 'Kirim №$number';
  }

  @override
  String get invFilterLow => 'Kam';

  @override
  String get invFilterOut => 'Mavjud emas';

  @override
  String get invFilterNegative => 'Minus';

  @override
  String get invQtyRequired => 'Miqdorni kiriting';

  @override
  String get invQtyNegative => 'Miqdor manfiy boʻlishi mumkin emas';

  @override
  String get invQtyPositive => 'Miqdor noldan katta boʻlishi kerak';

  @override
  String invQtyIntegerOnly(String unit) {
    return '“$unit” uchun faqat butun son ruxsat etiladi';
  }

  @override
  String get invQtyTooLarge => 'Miqdor juda katta';

  @override
  String get invAddAtLeastOneLine => 'Kamida bitta pozitsiya qoʻshing';

  @override
  String invCostNegative(String name) {
    return '$name: xarid narxi manfiy';
  }

  @override
  String invRetailMustBePositive(String name) {
    return '$name: chakana narx noldan katta boʻlishi kerak';
  }

  @override
  String get invSelectCategory => 'Kategoriyani tanlang';

  @override
  String get invSelectProducts => 'Mahsulotlarni tanlang';

  @override
  String get invNoProductsToCount => 'Inventarizatsiya uchun mahsulotlar yoʻq';

  @override
  String get invCountClosed => 'Inventarizatsiya allaqachon yopilgan';

  @override
  String get invNoCountedQty => 'Birorta ham haqiqiy miqdor kiritilmagan';

  @override
  String get invNoAccess => 'Ruxsat yoʻq';

  @override
  String get invNoAccessMessage =>
      'Ombor operatsiyalari omborchi, menejer va egaga ochiq';

  @override
  String get invNoProductsTitle => 'Hozircha mahsulotlar yoʻq';

  @override
  String get invNoProductsMessage =>
      'Avval “Mahsulotlar” boʻlimida mahsulot qoʻshing, soʻng kirim qiling.';

  @override
  String get invChangeFiltersOrQuery => 'Filtrlar yoki soʻrovni oʻzgartiring';

  @override
  String get invStockValue => 'Zaxira summasi';

  @override
  String get invPositionsTracked => 'Hisobdagi pozitsiyalar';

  @override
  String get invStockAtCost => 'Zaxira tannarxda';

  @override
  String get invStockAtRetail => 'Zaxira chakana narxda';

  @override
  String invPotentialMargin(String amount) {
    return 'Kutilgan ustama $amount';
  }

  @override
  String get invLowOutNegative => 'Kam / yoʻq / minus';

  @override
  String get invAllCategories => 'Barcha kategoriyalar';

  @override
  String get invSearchHint => 'Nomi, artikul, shtrix-kod';

  @override
  String get invStatusOut => 'Yoʻq';

  @override
  String invSkuShort(String sku) {
    return 'art. $sku';
  }

  @override
  String invMinShort(String qty) {
    return 'min. $qty';
  }

  @override
  String get invInactive => 'faol emas';

  @override
  String invQuickReceiptTitle(String name) {
    return 'Kirim: $name';
  }

  @override
  String invCurrentStock(String qty) {
    return 'Joriy qoldiq: $qty';
  }

  @override
  String get invUnitCostRequired => 'Birlik xarid narxi *';

  @override
  String get invPostIn => 'Kirim qilish';

  @override
  String get invSelectProduct => 'Mahsulotni tanlang';

  @override
  String get invSpecifyWriteoffReason =>
      'Hisobdan chiqarish sababini koʻrsating';

  @override
  String get invDescribeReason => 'Sababni izohda yozing';

  @override
  String get invWriteoffConfirmTitle => 'Mahsulot hisobdan chiqarilsinmi?';

  @override
  String invWriteoffConfirmMessage(
    String name,
    String qty,
    String amount,
    String reason,
  ) {
    return '$name\n$qty, summasi $amount (tannarxda)\nSabab: $reason';
  }

  @override
  String get invWriteoffAction => 'Hisobdan chiqarish';

  @override
  String invWrittenOff(String qty, String name) {
    return '“$name” hisobdan chiqarildi: $qty';
  }

  @override
  String get invChooseProduct => 'Mahsulotni tanlash…';

  @override
  String invStockLine(String qty) {
    return 'Qoldiq: $qty';
  }

  @override
  String invStockLineWithCost(String qty, String cost) {
    return 'Qoldiq: $qty · tannarx $cost';
  }

  @override
  String get invCommentRequired => 'Izoh *';

  @override
  String invWriteoffSum(String amount) {
    return 'Hisobdan chiqarish summasi: $amount';
  }

  @override
  String get invStockUnchanged => 'Qoldiq oʻzgarmadi';

  @override
  String get invStockCorrected => 'Qoldiq tuzatildi';

  @override
  String get invAdjustTitle => 'Qoldiqni tuzatish';

  @override
  String invBookStock(String qty) {
    return 'Hisobdagi qoldiq: $qty';
  }

  @override
  String get invActualStock => 'Haqiqiy qoldiq';

  @override
  String get invReasonRequired => 'Sabab *';

  @override
  String get invSpecifyAdjustReason => 'Tuzatish sababini koʻrsating';

  @override
  String get invUseCountHint =>
      'Qoldiqlarni toʻliq tekshirish uchun inventarizatsiyadan foydalaning.';

  @override
  String invHistoryTitle(String name) {
    return 'Harakatlar: $name';
  }

  @override
  String get invNoMovementsYet => 'Hozircha harakatlar yoʻq';

  @override
  String invPriceDetail(String amount) {
    return 'narx $amount';
  }

  @override
  String invStockAfter(String qty) {
    return 'qoldiq $qty';
  }

  @override
  String get invNewWriteoff => 'Yangi hisobdan chiqarish';

  @override
  String get invWhatToWriteOff => 'Nima hisobdan chiqariladi?';

  @override
  String get invWriteoffs30 => '30 kunlik hisobdan chiqarishlar';

  @override
  String get invNoWriteoffs30 =>
      'Soʻnggi 30 kunda hisobdan chiqarish boʻlmagan';

  @override
  String invTotalAtCost(String amount) {
    return 'Jami tannarxda: $amount';
  }

  @override
  String get invDays7 => '7 kun';

  @override
  String get invDays30 => '30 kun';

  @override
  String get invAllTime => 'Butun davr';

  @override
  String get invPeriodCustom => 'Davr…';

  @override
  String get invMovementsPeriod => 'Harakatlar davri';

  @override
  String get invType => 'Turi';

  @override
  String get invAllTypes => 'Barcha turlar';

  @override
  String get invAllProducts => 'Barcha mahsulotlar';

  @override
  String get invFilterByProduct => 'Mahsulot boʻyicha filtr';

  @override
  String get invNoMovements => 'Harakatlar yoʻq';

  @override
  String get invChangeFiltersOrPeriod => 'Filtrlar yoki davrni oʻzgartiring';

  @override
  String invRecords(String count) {
    return 'Yozuvlar: $count';
  }

  @override
  String invRecordsLimited(String count, String limit) {
    return 'Yozuvlar: $count (oxirgi $limit tasi koʻrsatilgan — filtrni aniqlang)';
  }

  @override
  String invInOut(String inQty, String outQty) {
    return 'kirim +$inQty · chiqim $outQty';
  }

  @override
  String invCurrentStockOf(String name, String qty) {
    return '“$name” joriy qoldigʻi: $qty';
  }

  @override
  String get invDocsPeriod => 'Hujjatlar davri';

  @override
  String get invSearchShort => '№ yoki yuk xati';

  @override
  String get invSearchLong => 'Qidiruv: kirim yoki yuk xati №';

  @override
  String get invAllSuppliers => 'Barcha taʼminotchilar';

  @override
  String get invNoDocs => 'Hujjatlar yoʻq';

  @override
  String get invPostedAppearHere => 'Oʻtkazilgan kirimlar shu yerda koʻrinadi';

  @override
  String invDocsCount(String count) {
    return 'Hujjatlar: $count';
  }

  @override
  String invDocsCountLimited(String count, String limit) {
    return 'Hujjatlar: $count (oxirgi $limit tasi koʻrsatilgan — filtrni aniqlang)';
  }

  @override
  String invPostedFor(String amount) {
    return '$amount ga oʻtkazilgan';
  }

  @override
  String get invNoSupplier => 'Taʼminotchisiz';

  @override
  String get invDeletedSupplier => 'Oʻchirilgan taʼminotchi';

  @override
  String invOrderRef(String number) {
    return 'Buyurtma №$number';
  }

  @override
  String get invOrder => 'Buyurtma';

  @override
  String get invNoHeader => '№';

  @override
  String invNumber(String number) {
    return '№$number';
  }

  @override
  String get invInvoice => 'Yuk xati';

  @override
  String get invPositionsHeader => 'Pozitsiyalar';

  @override
  String get invSource => 'Manba';

  @override
  String invInvoiceShort(String invoice) {
    return 'yuk xati $invoice';
  }

  @override
  String get invReceiptDocTitle => 'Kirim hujjati';

  @override
  String invReceiptPostedToast(String number) {
    return 'Kirim №$number oʻtkazildi';
  }

  @override
  String invReceiptPostedToastDetails(String number, String details) {
    return 'Kirim №$number oʻtkazildi · $details';
  }

  @override
  String invReverseTitle(String number) {
    return 'Kirim №$number storno qilinsinmi?';
  }

  @override
  String get invReverseInfo =>
      'Mahsulot qoldiqlari hujjatdagi miqdorga kamayadi, tannarx qayta hisoblanadi. Ushbu kirim oʻzgartirgan chakana narxlar, keyin oʻzgartirilmagan boʻlsa, avvalgi holiga qaytadi.';

  @override
  String invReverseSupplierDebt(String supplier, String amount) {
    return '$supplier taʼminotchisi oldidagi qarz $amount ga kamayadi.';
  }

  @override
  String get invReverseIrreversible => 'Stornoni bekor qilib boʻlmaydi.';

  @override
  String get invReverseReasonLabel => 'Storno sababi *';

  @override
  String get invReverseReasonRequired => 'Storno sababini koʻrsating';

  @override
  String get invReverse => 'Storno qilish';

  @override
  String get invDocNotFound => 'Hujjat topilmadi';

  @override
  String get invDocNotFoundMessage =>
      'Ehtimol, u oʻchirilgan yoki hali sinxronlanmagan';

  @override
  String get invSupplierInvoice => 'Taʼminotchi yuk xati';

  @override
  String get invManualReceipt => 'Qoʻlda kirim';

  @override
  String get invAcceptedBy => 'Qabul qildi';

  @override
  String invReasonLine(String reason) {
    return 'Sabab: $reason';
  }

  @override
  String invTotalsLine(String count, String qty) {
    return 'Pozitsiyalar: $count · miqdor $qty';
  }

  @override
  String invTotalLine(String amount) {
    return 'Jami: $amount';
  }

  @override
  String get invPositionsTitle => 'Pozitsiyalar';

  @override
  String get invNoLinesInDoc => 'Hujjatda pozitsiyalar yoʻq';

  @override
  String invReversedToast(String number) {
    return 'Kirim №$number storno qilindi';
  }

  @override
  String get invQtyShort => 'Miqdor';

  @override
  String get invPurchasePrice => 'Xarid narxi';

  @override
  String get invNewRetailPrice => 'Yangi chakana narx';

  @override
  String invWasPrice(String amount) {
    return 'avval $amount';
  }

  @override
  String invPriceWas(String price, String old) {
    return '$price (avval $old)';
  }

  @override
  String invRetailPriceLine(String price) {
    return 'Chakana narx: $price';
  }

  @override
  String get invNewReceipt => 'Yangi kirim';

  @override
  String get invDocuments => 'Hujjatlar';

  @override
  String invScanNotFound(String code) {
    return 'Shtrix-kodi yoki artikuli “$code” boʻlgan mahsulot topilmadi';
  }

  @override
  String get invAddToReceipt => 'Kirimga qoʻshish';

  @override
  String get invClearDocTitle => 'Hujjat tozalansinmi?';

  @override
  String get invClearDocMessage => 'Barcha pozitsiyalar hujjatdan oʻchiriladi.';

  @override
  String get invCheckFields => 'Belgilangan maydonlarni tekshiring';

  @override
  String get invPostReceiptTitle => 'Kirim oʻtkazilsinmi?';

  @override
  String invPostReceiptMessage(String count, String amount) {
    return 'Pozitsiyalar: $count\nSumma: $amount';
  }

  @override
  String invPostReceiptDebt(String supplier, String amount) {
    return '“$supplier” oldidagi qarz $amount ga oshadi';
  }

  @override
  String get invPost => 'Oʻtkazish';

  @override
  String invLinesFor(String count, String amount) {
    return '$count poz., $amount';
  }

  @override
  String invPositionsLower(String count) {
    return 'pozitsiyalar $count';
  }

  @override
  String get invPostReceipt => 'Kirimni oʻtkazish';

  @override
  String get invSupplierHelper =>
      'Koʻrsatilsa, kirim summasi taʼminotchiga qarzga qoʻshiladi';

  @override
  String get invInvoiceNoShort => 'Yuk xati №';

  @override
  String get invInvoiceNoLong => 'Taʼminotchi yuk xati №';

  @override
  String get invScanShort => 'Shtrix-kod yoki artikul';

  @override
  String get invScanLong => 'Shtrix-kodni skanerlang yoki artikulni kiriting';

  @override
  String get invAddProduct => 'Mahsulot qoʻshish';

  @override
  String get invEmptyDoc => 'Hujjat boʻsh';

  @override
  String get invEmptyDocMessage =>
      'Mahsulotni skanerlang yoki “Mahsulot qoʻshish” tugmasini bosing. Taʼminotchi buyurtmasi boʻyicha qabul qilish uchun “Xaridlar” boʻlimidan foydalaning.';

  @override
  String get invSpecifyPurchasePrice => 'Xarid narxini koʻrsating';

  @override
  String get invNewPrice => 'Yangi narx';

  @override
  String get invNoPricePermission => 'Narxlarni oʻzgartirish huquqi yoʻq';

  @override
  String get invInvalidPrice => 'Notoʻgʻri narx';

  @override
  String get invDeleteLine => 'Qatorni oʻchirish';

  @override
  String invLineInfo(String qty, String price) {
    return 'Qoldiq $qty · chakana $price';
  }

  @override
  String invMarkupPart(String percent) {
    return 'ustama $percent%';
  }

  @override
  String get invNewCount => 'Yangi inventarizatsiya';

  @override
  String get invSelectCount => 'Inventarizatsiyani tanlang';

  @override
  String get invSelectCountMessage =>
      'yoki haqiqiy qoldiqlarni hisobdagilari bilan solishtirish uchun yangisini yarating';

  @override
  String get invNoCountsYet => 'Hali inventarizatsiya oʻtkazilmagan';

  @override
  String get invNoCountsMessage =>
      'Muntazam sanoq kamomadlarni oʻz vaqtida topishga yordam beradi';

  @override
  String invCountTitle(String number) {
    return 'Inventarizatsiya №$number';
  }

  @override
  String get invAddToCount => 'Inventarizatsiyaga mahsulot qoʻshish';

  @override
  String get invAddAtLeastOneProduct => 'Kamida bitta mahsulot qoʻshing';

  @override
  String get invSelected => 'Tanlanganlar';

  @override
  String get invCategoryRequired => 'Kategoriya *';

  @override
  String get invRemove => 'Olib tashlash';

  @override
  String get invCountNoteHint => 'hudud, masʼul';

  @override
  String get invCountCreateInfo =>
      'Hisobdagi qoldiqlar yaratilgan paytda qayd etiladi. Sanoq vaqtidagi sotuvlar oʻtkazishda hisobga olinadi: farq joriy qoldiqdan hisoblanadi.';

  @override
  String invProductNotFound(String code) {
    return '“$code” mahsuloti topilmadi';
  }

  @override
  String get invNotInSheetTitle => 'Mahsulot qaydnomada yoʻq';

  @override
  String invNotInSheetMessage(String name, String unit) {
    return '“$name” ushbu inventarizatsiyaga kirmaydi. Qoʻshib, 1 $unit hisoblansinmi?';
  }

  @override
  String invAddedOne(String name) {
    return '“$name” qoʻshildi: 1';
  }

  @override
  String invCompleteTitle(String number) {
    return 'Inventarizatsiya №$number oʻtkazilsinmi?';
  }

  @override
  String invCompleteCounted(String counted, String total) {
    return 'Sanalgan pozitsiyalar: $counted / $total.';
  }

  @override
  String invCompleteUncounted(String count) {
    return 'Sanalmagan: $count — ularning qoldigʻi oʻzgarmaydi.';
  }

  @override
  String invCompleteSurplus(String count) {
    return 'Ortiqcha: $count poz.';
  }

  @override
  String invCompleteSurplusSum(String count, String amount) {
    return 'Ortiqcha: $count poz., $amount';
  }

  @override
  String invCompleteShortage(String count) {
    return 'Kamomad: $count poz.';
  }

  @override
  String invCompleteShortageSum(String count, String amount) {
    return 'Kamomad: $count poz., $amount';
  }

  @override
  String invCompleteNet(String amount) {
    return 'Natija: $amount';
  }

  @override
  String invCompleteChanged(String count) {
    return '$count poz. boʻyicha qoldiq qaydnoma yaratilgandan keyin oʻzgardi (sotuvlar, kirimlar). Farqlar JORIY qoldiqdan hisoblangan.';
  }

  @override
  String get invCompleteFinal =>
      'Qoldiqlar haqiqiy holatga keltiriladi. Amalni qaytarib boʻlmaydi.';

  @override
  String invCountCompletedToast(String number) {
    return 'Inventarizatsiya №$number oʻtkazildi';
  }

  @override
  String invCancelCountTitle(String number) {
    return 'Inventarizatsiya №$number bekor qilinsinmi?';
  }

  @override
  String get invCancelCountMessage =>
      'Kiritilgan maʼlumotlar tarixda saqlanadi, qoldiqlar oʻzgarmaydi.';

  @override
  String get invCancelCount => 'Inventarizatsiyani bekor qilish';

  @override
  String get invCountCancelledToast => 'Inventarizatsiya bekor qilindi';

  @override
  String get invCountNotFound => 'Inventarizatsiya topilmadi';

  @override
  String invChangedWarning(String count) {
    return '$count poz. boʻyicha hisobdagi qoldiq qaydnoma yaratilgandan keyin oʻzgardi (sotuvlar/kirimlar). Farq joriy qoldiqdan hisoblanadi.';
  }

  @override
  String get invScanPlusOne => 'Skaner: haqiqiyga +1';

  @override
  String get invSearchInSheet => 'Qaydnomada qidirish';

  @override
  String invFilterAllCount(String count) {
    return 'Hammasi ($count)';
  }

  @override
  String invFilterUncounted(String count) {
    return 'Sanalmagan ($count)';
  }

  @override
  String get invDiscrepancies => 'Farqlar';

  @override
  String get invNoLinesForFilter => 'Filtr boʻyicha qatorlar yoʻq';

  @override
  String invCreatedAt(String date) {
    return 'yaratilgan $date';
  }

  @override
  String invCompletedAt(String date) {
    return 'oʻtkazilgan $date';
  }

  @override
  String invCountedChip(String counted, String total) {
    return 'Sanalgan $counted/$total';
  }

  @override
  String invSurplusChip(String count) {
    return 'Ortiqcha $count';
  }

  @override
  String invShortageChip(String count) {
    return 'Kamomad $count';
  }

  @override
  String get invSaving => 'Saqlanmoqda…';

  @override
  String get invDraftSaved => 'Qoralama saqlandi';

  @override
  String get invBlank => 'Blank';

  @override
  String get invCancelShort => 'Bekor qilish';

  @override
  String get invProductBookStock => 'Mahsulot · hisobdagi qoldiq';

  @override
  String get invFact => 'Haqiqiy';

  @override
  String get invDiff => 'Farq';

  @override
  String invBookShort(String qty) {
    return 'hisob $qty';
  }

  @override
  String invNowShort(String qty) {
    return 'hozir $qty';
  }

  @override
  String get invFactHint => 'haqiqiy';

  @override
  String get invNotCounted => 'sanalmagan';

  @override
  String get invNumberQ => 'son?';

  @override
  String get invInvalidShort => 'notoʻgʻri';

  @override
  String invSheetTitle(String number) {
    return 'Inventarizatsiya qaydnomasi №$number';
  }

  @override
  String invPageOf(String page, String total) {
    return 'bet $page/$total';
  }

  @override
  String invSheetSubtitle(String store, String date, String count) {
    return '$store · yaratilgan $date · pozitsiyalar $count';
  }

  @override
  String get invCountedBy => 'Sanadi: ____________________';

  @override
  String get invCheckedBy => 'Tekshirdi: ____________________';

  @override
  String invDateLine(String date) {
    return 'Sana: $date';
  }

  @override
  String get invBarcodeSku => 'Shtrix-kod / art.';

  @override
  String get invUnitShort => 'Birl.';

  @override
  String get invBook => 'Hisob';

  @override
  String invCountFileName(String number) {
    return 'Inventarizatsiya $number';
  }

  @override
  String invReceiptPdfTitle(String number, String date) {
    return 'Kirim yuk xati №$number, $date';
  }

  @override
  String get invHandedBy => 'Topshirdi: ____________________';

  @override
  String get invAcceptedByLine => 'Qabul qildi: ____________________';

  @override
  String get invBasis => 'Asos';

  @override
  String invSupplierOrderRef(String number) {
    return 'Taʼminotchiga buyurtma №$number';
  }

  @override
  String get invReversedCaps => 'STORNO QILINGAN';

  @override
  String get invNewRetailShort => 'Yangi chakana';

  @override
  String invReceiptFileName(String number) {
    return 'Kirim $number';
  }

  @override
  String get mktTitle => 'Marketing';

  @override
  String get mktTabPromos => 'Aksiyalar';

  @override
  String get mktTabGiftCards => 'Sertifikatlar';

  @override
  String get mktTabLoyalty => 'Sodiqlik';

  @override
  String get mktTabMailing => 'Xabarnomalar';

  @override
  String get mktTypePercentOrder => 'Chekka % chegirma';

  @override
  String get mktTypeAmountOrder => 'Chekka summali chegirma';

  @override
  String get mktTypePercentCategory => 'Kategoriyaga % chegirma';

  @override
  String get mktTypePercentProduct => 'Mahsulotga % chegirma';

  @override
  String get mktTypeBuyXGetY => 'X ta ol — Y ta bepul';

  @override
  String get mktTypePromoCode => 'Promokod';

  @override
  String get mktHelpPercentOrder =>
      'Pozitsiya chegirmalaridan keyingi chek summasidan foiz. Chekning minimal summasini belgilash mumkin. Chek chegirmalaridan faqat bittasi — eng foydalisi qoʻllanadi.';

  @override
  String get mktHelpAmountOrder =>
      'Chekka qatʼiy summali chegirma (masalan, 100 000 dan xaridda 10 000). Pozitsiyalarga mutanosib taqsimlanadi — qaytarishlar aniq hisoblanadi.';

  @override
  String get mktHelpPercentCategory =>
      'Tanlangan kategoriyadagi barcha mahsulotlarga foiz. Boshqa pozitsiya chegirmalari va mijozning shaxsiy chegirmasi bilan qoʻshilmaydi — eng yaxshisi olinadi.';

  @override
  String get mktHelpPercentProduct =>
      'Bitta mahsulotga foiz. Boshqa pozitsiya chegirmalari bilan qoʻshilmaydi — eng yaxshisi olinadi.';

  @override
  String get mktHelpBuyXGetY =>
      'X dona mahsulot xarid qilinganda yana Y donasi bepul. Masalan, “2+1”: har uchinchi dona bepul. Bitta mahsulot pozitsiyasiga ishlaydi.';

  @override
  String get mktHelpPromoCode =>
      'Kassir kassada kiritadigan kod boʻyicha chekka chegirma. Foiz yoki summa hamda chekning minimal summasini belgilash mumkin. Boshqa chek chegirmalari bilan raqobatlashadi — eng yaxshisi qoʻllanadi.';

  @override
  String get mktStatusActive => 'Faol';

  @override
  String get mktStatusScheduled => 'Rejalashtirilgan';

  @override
  String get mktStatusFinished => 'Tugagan';

  @override
  String get mktStatusDisabled => 'Oʻchirilgan';

  @override
  String get mktErrEnterName => 'Aksiya nomini kiriting';

  @override
  String get mktErrSelectType => 'Aksiya turini tanlang';

  @override
  String get mktErrEnterPercent => 'Chegirma foizini kiriting';

  @override
  String get mktErrPercentRange =>
      'Chegirma foizi 0 dan katta va 100 dan oshmasligi kerak';

  @override
  String get mktErrEnterAmount => 'Chegirma summasini kiriting';

  @override
  String mktErrPromoCodeMinAmount(String amount) {
    return 'Promokod boʻyicha chegirma summasi kamida $amount boʻlishi kerak';
  }

  @override
  String get mktErrDiscountAboveMin =>
      'Chegirma chekning minimal summasidan katta boʻlishi mumkin emas';

  @override
  String get mktErrSelectCategory => 'Kategoriyani tanlang';

  @override
  String get mktErrSelectProduct => 'Mahsulotni tanlang';

  @override
  String get mktErrBuyMin => '“Ol” — kamida 1 dona';

  @override
  String get mktErrGetMin => '“Bepul” — kamida 1 dona';

  @override
  String get mktErrQtyTooLarge => 'Miqdor juda katta';

  @override
  String get mktErrEnterCode => 'Promokodni kiriting';

  @override
  String get mktErrCodeTooShort => 'Promokod — kamida 3 belgi';

  @override
  String get mktErrCodeTooLong => 'Promokod juda uzun';

  @override
  String get mktErrCodeChars => 'Promokod: faqat harflar, raqamlar, “-” va “_”';

  @override
  String mktErrCodeTaken(String code) {
    return '$code promokodi boshqa faol aksiyada allaqachon ishlatilmoqda';
  }

  @override
  String get mktErrMinNegative => 'Minimal summa manfiy boʻlishi mumkin emas';

  @override
  String get mktErrEndBeforeStart =>
      'Tugash sanasi boshlanish sanasidan oldin boʻlmasligi kerak';

  @override
  String mktDescMinOrder(String amount) {
    return ' $amount dan';
  }

  @override
  String mktDescOrder(String value, String min) {
    return 'chekka $value$min';
  }

  @override
  String mktDescCategory(String value, String target) {
    return '“$target” kategoriyasiga $value';
  }

  @override
  String mktDescProduct(String value, String target) {
    return '“$target” ga $value';
  }

  @override
  String mktDescBuyXGetY(String buy, String get, String target) {
    return '$buy+$get: $buy ta oling, yana $get tasi bepul — “$target”';
  }

  @override
  String mktDescPromoCode(String code, String value, String min) {
    return 'Kod $code: chekka $value$min';
  }

  @override
  String get mktPeriodUnlimited => 'Muddatsiz';

  @override
  String mktPeriodUntil(String date) {
    return '$date gacha';
  }

  @override
  String mktPeriodFrom(String date) {
    return '$date dan';
  }

  @override
  String get mktPromoSaved => 'Aksiya saqlandi';

  @override
  String get mktDeletePromoTitle => 'Aksiya oʻchirilsinmi?';

  @override
  String mktDeletePromoMessage(String name) {
    return '“$name” kassada qoʻllanmay qoladi. Sotilgan cheklar oʻzgarmaydi.';
  }

  @override
  String get mktPromoDeleted => 'Aksiya oʻchirildi';

  @override
  String get mktPromoSearchHint => 'Nomi yoki promokod';

  @override
  String get mktNewPromo => 'Yangi aksiya';

  @override
  String get mktTestOnReceipt => 'Chekda tekshirish';

  @override
  String mktChipAll(String count) {
    return 'Hammasi $count';
  }

  @override
  String get mktPromosEmptyTitle => 'Hozircha aksiyalar yoʻq';

  @override
  String get mktPromosEmptyMessage =>
      'Chekka, kategoriyaga yoki mahsulotga chegirma, “2+1” yoki promokod yarating. Kassa uni avtomatik qoʻllaydi.';

  @override
  String get mktCreatePromo => 'Aksiya yaratish';

  @override
  String get mktPromosNoMatch => 'Bu filtr boʻyicha aksiyalar yoʻq';

  @override
  String get mktTurnOff => 'Oʻchirish';

  @override
  String get mktTurnOn => 'Yoqish';

  @override
  String get mktDuplicate => 'Nusxa yaratish';

  @override
  String get mktEditPromo => 'Aksiyani tahrirlash';

  @override
  String mktCopyName(String name) {
    return '$name (nusxa)';
  }

  @override
  String get mktProductDeleted => 'Mahsulot oʻchirilgan';

  @override
  String get mktStartDate => 'Boshlanish sanasi';

  @override
  String get mktLastDay => 'Aksiyaning oxirgi kuni';

  @override
  String get mktPromoProduct => 'Aksiya uchun mahsulot';

  @override
  String get mktNameLabel => 'Nomi *';

  @override
  String get mktNameHint => 'Masalan: Dam olish kuni chegirmasi';

  @override
  String get mktEnterName => 'Nomini kiriting';

  @override
  String get mktPromoType => 'Aksiya turi';

  @override
  String get mktValidityPeriod => 'Amal qilish davri';

  @override
  String get mktDateFrom => 'Dan';

  @override
  String get mktDateTo => 'Gacha (shu kun ham)';

  @override
  String get mktPromoEnabled => 'Aksiya yoqilgan';

  @override
  String mktStatusLine(String status) {
    return 'Holat: $status';
  }

  @override
  String get mktUnlimited => 'cheklanmagan';

  @override
  String get mktPromoCodeLabel => 'Promokod *';

  @override
  String get mktMin3Chars => 'Kamida 3 belgi';

  @override
  String get mktDiscountColon => 'Chegirma:';

  @override
  String mktAmountIn(String currency) {
    return 'summa, $currency';
  }

  @override
  String get mktCreateCategoriesFirst =>
      'Avval “Mahsulotlar” boʻlimida kategoriyalar yarating';

  @override
  String get mktCategoryLabel => 'Kategoriya *';

  @override
  String get mktProductLabel => 'Mahsulot *';

  @override
  String get mktPickProduct => 'Mahsulotni tanlash…';

  @override
  String get mktBuyQty => 'Ol (dona)';

  @override
  String get mktGetQty => 'Bepul ol (dona)';

  @override
  String get mktMin1 => 'Kamida 1';

  @override
  String mktBuyGetPreview(String total, String free) {
    return '$total donali chekda $free donasi bepul';
  }

  @override
  String get mktDiscountLabel => 'Chegirma *';

  @override
  String get mktEnterPercent => 'Foizni kiriting';

  @override
  String get mktPercentRangeShort => '0 dan katta va 100 dan oshmasin';

  @override
  String get mktDiscountAmountLabel => 'Chegirma summasi *';

  @override
  String get mktMinOrderLabel => 'Chekning min. summasi';

  @override
  String get mktMinOrderHelper => 'Boʻsh — cheklovsiz';

  @override
  String get mktSimTitle => 'Aksiyalarni chekda tekshirish';

  @override
  String get mktSimAddProductTitle => 'Test chekiga mahsulot qoʻshish';

  @override
  String mktSimIntro(String count) {
    return 'Mahsulotlarni qoʻshing va kassa qaysi chegirmalarni qoʻllashini koʻring. Faol aksiyalar: $count. Pozitsiya chegirmalari qoʻshilmaydi — mahsulot/kategoriya aksiyasi, “N+M” va mijozning shaxsiy chegirmasidan eng yaxshisi olinadi. Chek chegirmalaridan (chek aksiyasi, promokod) bittasi, eng foydalisi qoʻllanadi.';
  }

  @override
  String get mktSimAddProduct => 'Mahsulot qoʻshish';

  @override
  String get mktSimCustomerDiscount => 'Mijoz chegirmasi';

  @override
  String get mktSim0To100 => '0 dan 100 gacha';

  @override
  String get mktSimEmptyTitle => 'Test cheki boʻsh';

  @override
  String get mktSimEmptyMessage => 'Bir yoki bir nechta mahsulot qoʻshing';

  @override
  String mktSimPricePer(String price, String unit) {
    return '$price / $unit';
  }

  @override
  String mktSimOrderShare(String amount) {
    return '−$amount · chek chegirmasidan ulush';
  }

  @override
  String get mktSimQtyPositive => 'Noldan katta miqdorni kiriting';

  @override
  String get mktSimQtyShort => 'Miqdor';

  @override
  String get mktRemove => 'Olib tashlash';

  @override
  String get mktSimSubtotal => 'Chegirmasiz summa';

  @override
  String get mktSimToPay => 'Toʻlovga';

  @override
  String get mktSimCodeAccepted => 'Promokod qabul qilindi';

  @override
  String get mktSimCodeRejected =>
      'Promokod topilmadi, faol emas yoki chek summasi minimaldan kam';

  @override
  String get mktSimApplied => 'Qoʻllangan chegirmalar:';

  @override
  String get mktSimNone => 'yoʻq';

  @override
  String get mktLoyaltyProgram => 'Bonus dasturi';

  @override
  String get mktLoyaltyOn => 'Yoqilgan';

  @override
  String get mktLoyaltyOff => 'Oʻchirilgan';

  @override
  String get mktLoyaltyEarn => 'Hisoblash';

  @override
  String mktLoyaltyEarnValue(String percent) {
    return 'toʻlangan summaning $percent% (bonus bilan toʻlangan qismidan tashqari)';
  }

  @override
  String get mktLoyaltyRedeem => 'Bonuslar bilan toʻlov';

  @override
  String mktLoyaltyRedeemValue(String percent) {
    return 'chek summasining $percent% gacha';
  }

  @override
  String get mktLoyaltyRate => 'Kurs';

  @override
  String mktLoyaltyRateValue(String amount) {
    return '1 bonus = $amount';
  }

  @override
  String get mktLoyaltyNote =>
      'Bonuslar mijozga sotuvda avtomatik hisoblanadi va qaytarishda mutanosib ravishda yechiladi.';

  @override
  String get mktOpenSettings => 'Sozlamalarni ochish';

  @override
  String get mktNoSettingsRight => 'Sozlamalarni oʻzgartirish huquqi yoʻq';

  @override
  String get mktEditInSettings => 'Sozlamalarda oʻzgartirish';

  @override
  String get mktStatLiability => 'Bonus majburiyatlari';

  @override
  String get mktStatLiabilityShort => 'Majburiyatlar';

  @override
  String mktStatHolders(String count) {
    return '$count ta mijozda';
  }

  @override
  String get mktStatEarned30 => '30 kunda hisoblangan';

  @override
  String get mktStatEarned => 'Hisoblangan';

  @override
  String get mktStat30Days => '30 kunda';

  @override
  String get mktStatSpent30 => '30 kunda yechilgan';

  @override
  String get mktStatSpent => 'Yechilgan';

  @override
  String get mktStatAdjusted30 => '30 kunda tuzatishlar';

  @override
  String get mktStatAdjusted => 'Tuzatishlar';

  @override
  String get mktStatAdjustedHint => 'qoʻlda va qaytarishlarda';

  @override
  String mktTplBirthday(String name, String store) {
    return 'Assalomu alaykum, $name! $store sizni tugʻilgan kuningiz bilan tabriklaydi! Sizni sovgʻa bilan kutamiz.';
  }

  @override
  String mktTplSleeping(String name, String store, String bonus) {
    return 'Assalomu alaykum, $name! Koʻrishmaganimizga ancha boʻldi — $store da koʻplab yangiliklar bor. Bonuslaringiz: $bonus. Sizni kutamiz!';
  }

  @override
  String mktTplDebt(String name, String store, String debt) {
    return 'Assalomu alaykum, $name! $store dagi qarzingiz $debt ekanini eslatamiz. Rahmat!';
  }

  @override
  String mktTplVip(String name, String store, String bonus) {
    return 'Assalomu alaykum, $name! Siz bizning VIP mijozimizsiz. $store da siz uchun maxsus takliflar bor. Bonuslaringiz: $bonus.';
  }

  @override
  String mktTplAll(String name) {
    return 'Assalomu alaykum, $name! ';
  }

  @override
  String get mktOurStore => 'bizning doʻkon';

  @override
  String get mktSegment => 'Segment';

  @override
  String get mktMessageText => 'Xabar matni';

  @override
  String mktTemplateVars(
    String name,
    String fullname,
    String store,
    String debt,
    String bonus,
    String discount,
  ) {
    return 'Oʻrinbosarlar: $name — ism, $fullname, $store, $debt, $bonus, $discount';
  }

  @override
  String mktPhonesCopied(String count) {
    return 'Nusxalangan telefonlar: $count';
  }

  @override
  String mktCopyPhones(String count) {
    return 'Telefonlarni nusxalash ($count)';
  }

  @override
  String mktMessagesCopied(String count) {
    return 'Nusxalangan xabarlar: $count';
  }

  @override
  String get mktCopyMessages => 'Xabarlarni nusxalash';

  @override
  String get mktSmsNote =>
      'SMS-shlyuz ulanmagan: roʻyxatni nusxalang va xabarlarni messenjer yoki telefon orqali yuboring.';

  @override
  String mktNoPhoneNote(String count) {
    return 'Telefonsiz: $count ta mijoz — ular roʻyxatga kirmaydi.';
  }

  @override
  String get mktNoPhone => 'telefon yoʻq';

  @override
  String get mktToday => 'bugun';

  @override
  String mktInDays(String days) {
    return '$days kundan keyin';
  }

  @override
  String mktLastVisit(String date) {
    return 'oxirgi tashrif $date';
  }

  @override
  String mktPurchases(String amount) {
    return 'xaridlar $amount';
  }

  @override
  String get mktOverdue => 'muddati oʻtgan';

  @override
  String get mktSegmentEmpty => 'Segmentda hech kim yoʻq';

  @override
  String get mktGiftActive => 'Faol';

  @override
  String get mktGiftUsed => 'Ishlatilgan';

  @override
  String get mktGiftExpired => 'Muddati oʻtgan';

  @override
  String get mktGiftBlocked => 'Bloklangan';

  @override
  String get mktErrUniqueCode => 'Noyob kod yaratib boʻlmadi';

  @override
  String get mktErrUnblockVoided =>
      'Sertifikat sotuvi bekor qilingan — blokdan chiqarib boʻlmaydi';

  @override
  String mktBlockTitle(String code) {
    return '$code bloklansinmi?';
  }

  @override
  String get mktGiftBlockedMsg => 'Sertifikat bloklandi';

  @override
  String get mktGiftUnblockedMsg => 'Sertifikat blokdan chiqarildi';

  @override
  String get mktGiftSalesSegment => 'Sotuvlar';

  @override
  String get mktNoSellRight => 'Sotish huquqi yoʻq';

  @override
  String get mktStatActiveShort => 'Faol';

  @override
  String get mktStatActive => 'Faol sertifikatlar';

  @override
  String get mktStatActiveHint => 'sertifikat';

  @override
  String get mktStatOutstandingShort => 'Ishlatilmagan';

  @override
  String get mktStatOutstanding => 'Ishlatilmagan qoldiq';

  @override
  String get mktStatOutstandingHintShort => 'sertifikatlarda';

  @override
  String get mktStatOutstandingHint => 'doʻkon majburiyatlari';

  @override
  String get mktGiftSearchHint => 'Kod yoki mijoz';

  @override
  String get mktGiftSaleTooltip => 'Sertifikat sotuvi (avans, tushum emas)';

  @override
  String get mktIssue => 'Chiqarish';

  @override
  String get mktCheckBalance => 'Balansni tekshirish';

  @override
  String get mktGiftsEmptyTitle => 'Hozircha sertifikatlar yoʻq';

  @override
  String get mktGiftsEmptyMessage =>
      'Sovgʻa sertifikatlarini soting — ularni kassada toʻlov sifatida qabul qilish mumkin.';

  @override
  String get mktIssueGift => 'Sertifikat chiqarish';

  @override
  String get mktCustomerLower => 'mijoz';

  @override
  String get mktCodeCopied => 'Kod nusxalandi';

  @override
  String mktOfAmount(String amount) {
    return '$amount dan';
  }

  @override
  String get mktFaceValueLower => 'nominal';

  @override
  String mktIssuedOn(String date) {
    return 'chiqarilgan $date';
  }

  @override
  String get mktNoExpiryLower => 'muddatsiz';

  @override
  String mktUntil(String date) {
    return '$date gacha';
  }

  @override
  String get mktSaleDocument => 'Sotuv hujjati';

  @override
  String get mktGiftBlank => 'Sertifikat blanki';

  @override
  String get mktCopyCode => 'Kodni nusxalash';

  @override
  String get mktUnblock => 'Blokdan chiqarish';

  @override
  String get mktBlock => 'Bloklash';

  @override
  String get mktGiftBalanceTitle => 'Sertifikat balansi';

  @override
  String get mktCodeEnterOrScan => 'Kod (kiriting yoki skanerlang)';

  @override
  String get mktFind => 'Topish';

  @override
  String mktFaceValueAmount(String amount) {
    return 'Nominal $amount';
  }

  @override
  String get mktNoExpiry => 'Muddatsiz';

  @override
  String mktValidUntil(String date) {
    return '$date gacha amal qiladi';
  }

  @override
  String get mktPdfGiftTitle => 'SOVGʻA SERTIFIKATI';

  @override
  String mktPdfValidUntil(String date) {
    return '$date gacha amal qiladi';
  }

  @override
  String get mktPdfGiftNote =>
      'Sertifikatni kassada koʻrsating.\nPulga almashtirilmaydi.';

  @override
  String mktVoidSaleTitle(String number) {
    return 'Sotuv №$number ni bekor qilish';
  }

  @override
  String get mktReasonRequired => 'Sabab *';

  @override
  String mktVoidSaleQuestion(String number) {
    return 'Sotuv №$number bekor qilinsinmi?';
  }

  @override
  String mktVoidSaleMessage(String code, String amount, String payments) {
    return '$code sertifikati bloklanadi. Xaridorga $amount qaytaring: $payments. Qaytarish joriy smenaga yoziladi.';
  }

  @override
  String get mktVoid => 'Sotuvni bekor qilish';

  @override
  String mktSaleVoided(String number) {
    return 'Sotuv №$number bekor qilindi';
  }

  @override
  String get mktBlank => 'Blank';

  @override
  String get mktNoSaleDocument =>
      'Sertifikat sotuv hujjatlari paydo boʻlishidan oldin chiqarilgan — hujjat yoʻq, bekor qilib boʻlmaydi.';

  @override
  String mktFaceValueLowerAmount(String amount) {
    return 'nominal $amount';
  }

  @override
  String get mktNoVoidRight => 'Sotuvlarni bekor qilish huquqi yoʻq';

  @override
  String get mktOpenShiftToVoid => 'Sotuvni bekor qilish uchun smenani oching';

  @override
  String get mktChecking => 'Tekshirilmoqda…';

  @override
  String mktSaleNumber(String number) {
    return 'Sotuv №$number';
  }

  @override
  String mktVoidedAt(String date) {
    return 'Bekor qilingan $date';
  }

  @override
  String get mktVoidTooltip =>
      'Sertifikat bloklanadi, pul xaridorga qaytariladi';

  @override
  String get mktVoidSale => 'Sotuvni bekor qilish';

  @override
  String get mktSaleCompleted => 'Oʻtkazilgan';

  @override
  String get mktSaleVoidedStatus => 'Bekor qilingan';

  @override
  String get mktPeriod7Days => '7 kun';

  @override
  String get mktPeriod30Days => '30 kun';

  @override
  String get mktPeriodAllTime => 'Butun davr';

  @override
  String get mktGiftSalesEmptyTitle => 'Sertifikat sotuvlari yoʻq';

  @override
  String get mktGiftSalesEmptyMessage =>
      'Tanlangan davrda bunday holatdagi hujjatlar yoʻq.';

  @override
  String mktCompletedFor(String amount) {
    return '$amount ga oʻtkazilgan';
  }

  @override
  String mktVoidedCount(String count) {
    return 'bekor qilingan: $count';
  }

  @override
  String mktReasonLower(String reason) {
    return 'sabab: $reason';
  }

  @override
  String get mktPayMixed => 'Aralash';

  @override
  String get mktValidUntilInclusive => 'Amal qilish muddati (shu kun ham)';

  @override
  String mktPayExceeds(String amount) {
    return 'Karta va oʻtkazma nominaldan $amount ga koʻp';
  }

  @override
  String get mktPayEnterCardTransfer =>
      'Karta va/yoki oʻtkazma summasini kiriting';

  @override
  String mktPayTenderedShort(String amount) {
    return 'Kerakligidan kam olindi: $amount';
  }

  @override
  String get mktCodeExists => 'Bunday kod allaqachon mavjud';

  @override
  String get mktValidUntilLabel => 'Amal qilish muddati';

  @override
  String get mktNoExpiryCap => 'Muddatsiz';

  @override
  String get mktBuyerOptional => 'Xaridor (ixtiyoriy)';

  @override
  String get mktNotSelected => 'Tanlanmagan';

  @override
  String get mktRemoveBuyer => 'Xaridorni olib tashlash';

  @override
  String get mktGiftSaleTitle => 'Sertifikat sotuvi';

  @override
  String get mktShiftClosedNote =>
      'Smena yopiq: sertifikat sotish uchun smenani oching.';

  @override
  String mktShiftAdvanceNote(String number) {
    return 'Smena №$number. Bu avans, tushum emas: toʻlov smena hisobotining “Sertifikatlar” boʻlimiga tushadi.';
  }

  @override
  String get mktFaceValueRequired => 'Nominal *';

  @override
  String get mktGiftCodeRequired => 'Sertifikat kodi *';

  @override
  String get mktGiftCodeHelper =>
      'Avtomatik yaratilgan; skanerlash yoki oʻzingiznikini kiritish mumkin';

  @override
  String get mktGenerate => 'Yaratish';

  @override
  String get mktMin6Chars => 'Kamida 6 belgi';

  @override
  String get mktMax32Chars => 'Koʻpi bilan 32 belgi';

  @override
  String get mktSellGift => 'Sertifikat sotish';

  @override
  String get mktTenderedCash => 'Olingan naqd';

  @override
  String get mktTenderedHelper => 'Boʻsh — qaytimsiz';

  @override
  String get mktSlipNumber => 'Slip raqami (ixtiyoriy)';

  @override
  String get mktTransferNumber => 'Oʻtkazma raqami (ixtiyoriy)';

  @override
  String get mktInCash => 'Naqd';

  @override
  String mktPrintFailed(String error) {
    return 'Chop etib boʻlmadi: $error';
  }

  @override
  String get mktGiftSold => 'Sertifikat sotildi';

  @override
  String notifOutOfStockTitle(String name) {
    return 'Mahsulot tugadi: $name';
  }

  @override
  String notifOutOfStockBody(String qty) {
    return 'Qoldiq $qty. Savdoni yoʻqotmaslik uchun xarid qiling.';
  }

  @override
  String notifLowStockTitle(String name) {
    return 'Mahsulot kam: $name';
  }

  @override
  String notifLowStockBody(String qty, String min) {
    return 'Qoldiq $qty, minimal — $min.';
  }

  @override
  String notifDebtTitle(String name) {
    return 'Qarz muddati oʻtgan: $name';
  }

  @override
  String notifDebtBody(String overdue, String date) {
    return 'Muddati oʻtgan: $overdue, toʻlov muddati $date da tugagan. Mijozga toʻlovni eslating.';
  }

  @override
  String notifDebtBodyPartial(String overdue, String debt, String date) {
    return 'Muddati oʻtgan: $debt dan $overdue, toʻlov muddati $date da tugagan. Mijozga toʻlovni eslating.';
  }

  @override
  String notifBirthdayTitle(String name) {
    return 'Tugʻilgan kun: $name';
  }

  @override
  String get notifBirthdayBody =>
      'Mijozni tabriklang va sovgʻa yoki bonus taklif qiling.';

  @override
  String notifBirthdayBodyAge(String age) {
    return '$age yoshga toʻladi. Mijozni tabriklang va sovgʻa yoki bonus taklif qiling.';
  }

  @override
  String notifShiftTitle(String number, String hours) {
    return 'Smena №$number $hours soatdan beri ochiq';
  }

  @override
  String notifShiftBody(String date, String time) {
    return '$date kuni $time da ochilgan. Smenani yoping va kassadagi naqdni solishtiring.';
  }

  @override
  String get notifKindLowStock => 'Mahsulot kam';

  @override
  String get notifKindOutOfStock => 'Mavjud emas';

  @override
  String get notifKindDebt => 'Qarzlar';

  @override
  String get notifKindBirthday => 'Tugʻilgan kunlar';

  @override
  String get notifKindShift => 'Smenalar';

  @override
  String get notifKindTask => 'Vazifalar';

  @override
  String get notifKindSystem => 'Tizim';

  @override
  String get notifDeleted => 'Bildirishnoma oʻchirildi';

  @override
  String get notifUndo => 'Bekor qilish';

  @override
  String get notifCheckNone => 'Tekshiruv tugadi — yangi bildirishnomalar yoʻq';

  @override
  String notifCheckCreated(String count) {
    return 'Yangi bildirishnomalar: $count';
  }

  @override
  String get notifDeleteReadTitle => 'Oʻqilganlar oʻchirilsinmi?';

  @override
  String notifDeleteReadMessage(String count) {
    return 'Oʻchiriladigan bildirishnomalar: $count. Oʻqilmaganlar qoladi.';
  }

  @override
  String get notifDeleteReadDone => 'Oʻqilgan bildirishnomalar oʻchirildi';

  @override
  String get notifNoAccess =>
      'Boʻlimga ruxsat yoʻq — administratorga murojaat qiling';

  @override
  String get notifAllReadShort => 'Hammasi oʻqilgan';

  @override
  String notifUnreadCount(String count) {
    return 'Oʻqilmagan: $count';
  }

  @override
  String get notifCheckNowTooltip => 'Hozir tekshirish (F5)';

  @override
  String get notifCheckNow => 'Hozir tekshirish';

  @override
  String get notifReadAll => 'Hammasini oʻqish';

  @override
  String get notifAllRead => 'Barcha bildirishnomalar oʻqildi';

  @override
  String get notifDeleteRead => 'Oʻqilganlarni oʻchirish';

  @override
  String get notifEmptyTitle => 'Bildirishnomalar yoʻq';

  @override
  String get notifEmptyMessage =>
      'Bu yerda tugayotgan mahsulotlar, muddati oʻtgan qarzlar, mijozlarning tugʻilgan kunlari va yopilmagan smenalar haqida eslatmalar paydo boʻladi. Tekshiruv har 10 daqiqada avtomatik bajariladi.';

  @override
  String notifFilterAll(String count) {
    return 'Hammasi ($count)';
  }

  @override
  String notifFilterUnread(String count) {
    return 'Oʻqilmagan ($count)';
  }

  @override
  String get notifNoneOfKind => 'Bu turdagi bildirishnomalar yoʻq';

  @override
  String get notifGoTo => 'Oʻtish';

  @override
  String get notifMarkUnread => 'Oʻqilmagan deb belgilash';

  @override
  String get notifMarkRead => 'Oʻqilgan deb belgilash';

  @override
  String posNotFound(String code) {
    return 'Topilmadi: $code';
  }

  @override
  String get posShiftNotOpenSell =>
      'Smena ochilmagan. Sotish uchun smenani oching';

  @override
  String get posHints =>
      'F2 qidiruv · F4 mijoz · F8 kechiktirish · F9 kechiktirilganlar · F12 / Ctrl+Enter toʻlov · Del oʻchirish · +/− miqdor · ↑↓ pozitsiyani tanlash · Esc qidiruvni tozalash · 3*kod — bir necha dona';

  @override
  String get posShiftNotOpenBanner => 'Smena ochilmagan — savdo mumkin emas';

  @override
  String get posShiftNotOpenAskManager =>
      'Smena ochilmagan. Menejerdan smenani ochishni soʻrang';

  @override
  String get posOpenShift => 'Smenani ochish';

  @override
  String get posCartEmpty => 'Chek boʻsh';

  @override
  String posTotalPositions(String count) {
    return 'Jami · $count poz.';
  }

  @override
  String posReceiptPositions(String count) {
    return 'Chek · $count poz.';
  }

  @override
  String get posParkedReceipts => 'Kechiktirilgan cheklar';

  @override
  String get posCartActions => 'Chek amallari';

  @override
  String get posPark => 'Chekni kechiktirish';

  @override
  String get posSeller => 'Sotuvchi';

  @override
  String get posSellGiftCard => 'Sertifikat sotish';

  @override
  String get posClearCart => 'Chekni tozalash';

  @override
  String get posNoSellPerm => 'Sotish huquqi yoʻq';

  @override
  String get posNeedOpenShift => 'Ochiq smena kerak';

  @override
  String posProductInactive(String name) {
    return '“$name” mahsuloti sotuvdan olingan';
  }

  @override
  String get posBadMultiplier =>
      'Koʻpaytuvchi notoʻgʻri. Misol: 3*4780000000011';

  @override
  String get posMultipleFound =>
      'Bir nechta mahsulot topildi — roʻyxatdan keraklisini tanlang';

  @override
  String posProductNotFound(String code) {
    return '“$code” mahsuloti topilmadi';
  }

  @override
  String get posNoPricePerm => 'Narxlarni oʻzgartirish huquqi yoʻq';

  @override
  String get posLineDiscount => 'Pozitsiyaga chegirma';

  @override
  String posLineDiscountFor(String name) {
    return '“$name” uchun chegirma';
  }

  @override
  String get posOrderDiscount => 'Chekka chegirma';

  @override
  String get posPromoCode => 'Promokod';

  @override
  String get posCode => 'Kod';

  @override
  String get posClearCartQ => 'Chek tozalansinmi?';

  @override
  String posClearCartMessage(String count) {
    return 'Chekdan barcha $count poz. oʻchiriladi.';
  }

  @override
  String get posNothingToPark => 'Kechiktiradigan narsa yoʻq — chek boʻsh';

  @override
  String get posParkNote => 'Izoh (xaridor ismi va h.k.)';

  @override
  String get posParkedDone =>
      'Chek kechiktirildi (F9 — kechiktirilganlar roʻyxati)';

  @override
  String get posAutoParked => 'Avtomatik kechiktirilgan';

  @override
  String posRestoredRepriced(String count) {
    return 'Chek tiklandi. Narxlar prays boʻyicha yangilandi: $count poz.';
  }

  @override
  String get posRestored => 'Chek tiklandi';

  @override
  String get posGiftNeedShift => 'Sertifikat sotish uchun smenani oching';

  @override
  String get posShiftNotOpen => 'Smena ochilmagan';

  @override
  String get posGiftNeedShiftDot => 'Sertifikat sotish uchun smenani oching.';

  @override
  String get posNoShiftPerm =>
      'Smena ochish huquqi yoʻq — menejerga murojaat qiling';

  @override
  String get posShiftOpened => 'Smena ochildi. Sotish mumkin';

  @override
  String get posCartEmptyAdd => 'Chek boʻsh — mahsulot qoʻshing';

  @override
  String posPromoInvalid(String code) {
    return '“$code” promokodi yaroqsiz — oʻchiring yoki tuzating';
  }

  @override
  String get posManualDiscounts => 'Chekdagi qoʻlda berilgan chegirmalar';

  @override
  String get posManualOverLimit =>
      'Qoʻlda berilgan chegirmalar limitingizdan oshadi — menejer tasdigʻi kerak yoki chegirmani kamaytiring';

  @override
  String posQtyIntegerOnly(String unit) {
    return '“$unit” uchun faqat butun miqdor';
  }

  @override
  String get posQtyTooSmall => 'Miqdor juda kichik';

  @override
  String get posLineNotFound => 'Pozitsiya topilmadi';

  @override
  String get posDiscountNegative => 'Chegirma manfiy boʻlishi mumkin emas';

  @override
  String get posDiscountOver100 => 'Chegirma 100% dan oshmasligi kerak';

  @override
  String get posDiscountOverLine => 'Chegirma pozitsiya summasidan katta';

  @override
  String get posDiscountOverCart => 'Chegirma chek summasidan katta';

  @override
  String get posCartEmptyHint =>
      'Shtrix-kodni skanerlang yoki katalogdan mahsulot tanlang';

  @override
  String posPositions(String count) {
    return '$count poz.';
  }

  @override
  String get posSellerTooltip => 'Sotuvchi-maslahatchi (motivatsiya uchun)';

  @override
  String get posParkedTooltip => 'Kechiktirilgan cheklar (F9)';

  @override
  String get posParkedShort => 'Kechiktirilganlar';

  @override
  String get posCustomerF4 => 'Mijoz (F4)';

  @override
  String posCustDiscount(String percent) {
    return 'chegirma $percent%';
  }

  @override
  String posCustBonus(String amount) {
    return 'bonuslar $amount';
  }

  @override
  String posCustDebt(String amount) {
    return 'qarz $amount';
  }

  @override
  String posCustDebtLimit(String amount) {
    return 'limit $amount';
  }

  @override
  String get posDetachCustomer => 'Mijozni chekdan olib tashlash';

  @override
  String get posPromotion => 'Aksiya';

  @override
  String get posManualDiscount => 'Qoʻlda chegirma';

  @override
  String get posApprovedMark => '(tasdiq.)';

  @override
  String posOrderDiscountLine(String amount) {
    return 'Chekka chegirma: −$amount';
  }

  @override
  String posOnlyInStock(String qty) {
    return 'Omborda faqat $qty';
  }

  @override
  String get posLess => 'Kamroq (−)';

  @override
  String get posMore => 'Koʻproq (+)';

  @override
  String get posEditPrice => 'Narxni oʻzgartirish';

  @override
  String get posRemoveLine => 'Pozitsiyani oʻchirish (Del)';

  @override
  String posPromoInvalidChip(String code) {
    return '$code — yaroqsiz';
  }

  @override
  String get posRemovePromo => 'Promokodni olib tashlash';

  @override
  String posOrderDiscountValue(String value) {
    return 'Chekka chegirma $value';
  }

  @override
  String get posRemoveDiscount => 'Chegirmani olib tashlash';

  @override
  String get posSubtotal => 'Oraliq jami';

  @override
  String get posVatIncluded => 'shu jumladan QQS';

  @override
  String posDiscountCalcFailed(String error) {
    return 'Chegirmalarni hisoblab boʻlmadi: $error';
  }

  @override
  String get posOpenShiftToSell => 'Sotish uchun smenani oching';

  @override
  String get posAddProducts => 'Chekka mahsulot qoʻshing';

  @override
  String get posPayTooltip => 'Toʻlov (F12 yoki Ctrl+Enter)';

  @override
  String get posPay => 'Toʻlash';

  @override
  String get posPayF12 => 'Toʻlash  ·  F12';

  @override
  String posNonCashOver(String amount) {
    return 'Naqdsiz toʻlov chek summasidan $amount ga koʻp';
  }

  @override
  String posMissing(String amount) {
    return '$amount yetmaydi';
  }

  @override
  String get posCashNotNeeded =>
      'Naqd pul kerak emas — chek allaqachon toʻlangan';

  @override
  String get posDebtDue => 'Qarzni qaytarish muddati';

  @override
  String posDays(String days) {
    return '$days kun';
  }

  @override
  String get posPickDate => 'Sanani tanlash';

  @override
  String posUntil(String date) {
    return '$date gacha';
  }

  @override
  String posBonusMax(String amount) {
    return 'Bonuslar bilan koʻpi bilan $amount toʻlash mumkin';
  }

  @override
  String posCreditExceeded(String amount) {
    return 'Kredit limiti oshdi: mavjud $amount';
  }

  @override
  String get posCheckGiftCode => 'Sertifikat kodini tekshiring';

  @override
  String posGiftOnly(String amount) {
    return 'Sertifikatda faqat $amount';
  }

  @override
  String get posEnterGiftCode => 'Sertifikat kodini kiriting';

  @override
  String get posGiftNotFound => 'Sertifikat topilmadi';

  @override
  String posGiftInactive(String status) {
    return 'Sertifikat faol emas ($status)';
  }

  @override
  String get posGiftUsed => 'ishlatilgan';

  @override
  String posGiftExpired(String date) {
    return 'Amal qilish muddati $date da tugagan';
  }

  @override
  String get posGiftEmpty => 'Sertifikatda mablagʻ yoʻq';

  @override
  String get posAll => 'Hammasi';

  @override
  String get posToPay => 'Toʻlovga';

  @override
  String posRounding(String amount) {
    return 'Yaxlitlash: −$amount';
  }

  @override
  String posCustomerValue(String name) {
    return 'Mijoz: $name';
  }

  @override
  String get posCloseEsc => 'Yopish (Esc)';

  @override
  String get posCashReceived => 'Olingan naqd';

  @override
  String posCashNeeded(String amount) {
    return 'Naqd kerak: $amount';
  }

  @override
  String get posNoChange => 'Qaytimsiz';

  @override
  String get posByCard => 'Karta bilan';

  @override
  String get posByTransfer => 'Oʻtkazma bilan';

  @override
  String get posMixed => 'Aralash toʻlov';

  @override
  String get posTransferRef => 'Operatsiya № / izoh (ixtiyoriy)';

  @override
  String posBonusHelper(String balance, String max) {
    return 'Balans $balance · $max gacha yechish mumkin';
  }

  @override
  String posDebtNoLimit(String debt) {
    return 'Qarz $debt · limit belgilanmagan';
  }

  @override
  String posDebtHelper(String debt, String limit, String available) {
    return 'Qarz $debt / $limit · mavjud $available';
  }

  @override
  String get posSelectCustomerForDebt =>
      'Qarzga yoki bonus bilan toʻlash uchun mijozni tanlang';

  @override
  String get posSelectCustomerForDebtF4 =>
      'Qarzga yoki bonus bilan toʻlash uchun mijozni tanlang (F4)';

  @override
  String get posGiftCode => 'Sertifikat kodi';

  @override
  String posGiftBalance(String amount) {
    return 'Balans $amount';
  }

  @override
  String get posCheck => 'Tekshirish';

  @override
  String get posPayByGift => 'Sertifikat bilan toʻlov';

  @override
  String get posProcessing => 'Oʻtkazilmoqda…';

  @override
  String get posConfirmPay => 'Toʻlovni oʻtkazish';

  @override
  String get posConfirmPayEnter => 'Toʻlovni oʻtkazish (Enter)';

  @override
  String get posNonCashOverpay => 'Naqdsiz ortiqcha toʻlov';

  @override
  String get posMissingLabel => 'Yetmaydi';

  @override
  String get posQtyWeight => 'Miqdor / ogʻirlik';

  @override
  String get posQtyExample => 'Masalan: 0,75';

  @override
  String get posSalePrice => 'Sotish narxi';

  @override
  String posListPrice(String amount) {
    return 'Prays boʻyicha narx: $amount';
  }

  @override
  String get posNewPrice => 'Yangi narx';

  @override
  String get posRestoreListPrice => 'Prays narxini qaytarish';

  @override
  String get posNotMore100 => '100% dan koʻp emas';

  @override
  String posMoreThanAmount(String amount) {
    return 'Summadan koʻp ($amount)';
  }

  @override
  String posAmountValue(String amount) {
    return 'Summa: $amount';
  }

  @override
  String get posPercentSeg => 'Foiz, %';

  @override
  String get posDiscountPct => 'Chegirma, %';

  @override
  String get posDiscountAmount => 'Chegirma, summa';

  @override
  String posDiscountSummary(String amount, String percent, String due) {
    return 'Chegirma: $amount ($percent%) · toʻlovga $due';
  }

  @override
  String posOverLimit(String limit) {
    return 'Limitingiz $limit% dan oshadi — menejer PIN-kodi kerak';
  }

  @override
  String posYourLimit(String limit) {
    return 'Chegirma limitingiz: $limit%';
  }

  @override
  String posApproverNoPerm(String name) {
    return '$name: chegirmalarni tasdiqlash huquqi yoʻq';
  }

  @override
  String posApproverLimitNotHigher(String name) {
    return '$name: chegirma limiti kassirnikidan yuqori emas';
  }

  @override
  String posApproverLimit(String name, String limit, String requested) {
    return '$name limiti — $limit%, soʻralgan $requested%';
  }

  @override
  String get posOtherPinNeeded =>
      'Boshqa xodimning PIN-kodi kerak (menejer yoki egasi)';

  @override
  String get posManagerApproval => 'Menejer tasdigʻi';

  @override
  String posApprovalMessage(String what, String percent, String limit) {
    return '$what: $percent% — kassir limitidan koʻp ($limit%).\nMenejer yoki egasi oʻz PIN-kodini kiritadi.';
  }

  @override
  String get posOpenShiftHint =>
      'Pul qutisidagi naqd pulni sanab, maydalik summasini kiriting.';

  @override
  String get posOpeningCash => 'Kassadagi maydalik';

  @override
  String get posOpeningCashHelper => 'Quti boʻsh boʻlsa, 0 boʻlishi mumkin';

  @override
  String get posSellerConsultant => 'Sotuvchi-maslahatchi';

  @override
  String get posCashierDefault => 'Kassir (standart)';

  @override
  String get posNoParked => 'Kechiktirilgan cheklar yoʻq';

  @override
  String get posNoParkedHint =>
      'Keyingi xaridorga xizmat koʻrsatish uchun joriy chekni kechiktiring (F8)';

  @override
  String get posParkedTapHint => 'Kassaga qaytarish uchun chekni bosing';

  @override
  String posAndMore(String count) {
    return 'va yana $count';
  }

  @override
  String posReceiptFrom(String time) {
    return '$time dagi chek';
  }

  @override
  String get posDeleteParked => 'Kechiktirilgan chekni oʻchirish';

  @override
  String get posDeleteParkedQ => 'Kechiktirilgan chek oʻchirilsinmi?';

  @override
  String get posDeleteParkedMessage => 'Bu chekdagi mahsulotlar yoʻqoladi.';

  @override
  String get posSearchHintShort => 'Shtrix-kod yoki nom';

  @override
  String get posSearchHint =>
      'Shtrix-kodni skanerlang yoki nomini kiriting (F2)';

  @override
  String get posClearEsc => 'Tozalash (Esc)';

  @override
  String get posFavorites => 'Sevimlilar';

  @override
  String posNoResults(String query) {
    return '“$query” soʻrovi boʻyicha mahsulot yoʻq. Nomini tekshiring yoki shtrix-kodni skanerlang.';
  }

  @override
  String get posCategoryEmpty => 'Kategoriyada mahsulot yoʻq';

  @override
  String get posCatalogEmpty => 'Katalog boʻsh';

  @override
  String get posCatalogEmptyHint =>
      'Sotish uchun “Mahsulotlar” boʻlimida mahsulot qoʻshing';

  @override
  String get posNoStockTracking => 'qoldiq hisobisiz';

  @override
  String posPrintFailed(String error) {
    return 'Chekni chop etib boʻlmadi: $error';
  }

  @override
  String posSaleDone(String number) {
    return 'Chek №$number oʻtkazildi';
  }

  @override
  String posReceiptSum(String amount) {
    return 'Chek summasi: $amount';
  }

  @override
  String posDiscountValue(String amount) {
    return 'Chegirma: $amount';
  }

  @override
  String posBonusEarned(String amount) {
    return 'Bonus hisoblandi: $amount';
  }

  @override
  String get posPrintAgain => 'Yana bir bor';

  @override
  String get posPrintReceipt => 'Chekni chop etish';

  @override
  String get posNewSale => 'Yangi sotuv (Enter)';

  @override
  String get prodRoundNearest => 'Eng yaqiniga';

  @override
  String get prodRoundUp => 'Yuqoriga';

  @override
  String get prodRoundDown => 'Pastga';

  @override
  String get prodRoundNone => 'Yaxlitlashsiz';

  @override
  String prodRoundTo(String amount) {
    return '$amount gacha';
  }

  @override
  String get prodStockAll => 'Barcha qoldiqlar';

  @override
  String get prodStockIn => 'Mavjud';

  @override
  String get prodStockLow => 'Kam';

  @override
  String get prodStockOut => 'Mavjud emas';

  @override
  String get prodStockNegative => 'Minus';

  @override
  String get prodActive => 'Faol';

  @override
  String get prodArchive => 'Arxiv';

  @override
  String get prodSortName => 'Nomi boʻyicha';

  @override
  String get prodSortPrice => 'Narxi boʻyicha';

  @override
  String get prodSortStock => 'Qoldiq boʻyicha';

  @override
  String get prodSortMargin => 'Marja boʻyicha';

  @override
  String get prodSortUpdated => 'Oʻzgarish boʻyicha';

  @override
  String get prodUnitShort => 'Birl.';

  @override
  String get prodDelimTab => 'tabulyatsiya';

  @override
  String get prodDelimSemicolon => 'nuqtali vergul';

  @override
  String get prodDelimComma => 'vergul';

  @override
  String prodImpErrMissing(String field) {
    return '$field: koʻrsatilmagan';
  }

  @override
  String prodImpErrNegative(String field) {
    return '$field: manfiy boʻlishi mumkin emas';
  }

  @override
  String prodImpErrNotNumber(String field, String value) {
    return '$field: “$value” — son emas';
  }

  @override
  String get prodImpErrNoName => 'Nomi koʻrsatilmagan';

  @override
  String get prodNameTooLong => 'Nomi 200 belgidan uzun';

  @override
  String prodImpErrBarcodeSci(String code) {
    return 'Shtrix-kod “$code” Excel tomonidan buzilgan (eksponensial format)';
  }

  @override
  String prodImpErrBarcodeDup(String code, String line) {
    return 'Shtrix-kod $code takrorlanmoqda ($line-qator)';
  }

  @override
  String get prodEan13BadCheck => 'EAN-13 nazorat raqami notoʻgʻri';

  @override
  String prodImpErrUnit(String unit) {
    return 'Nomaʼlum oʻlchov birligi “$unit” (pcs, kg, g, l, m, pack)';
  }

  @override
  String prodImpErrStockNotNumber(String value) {
    return 'Qoldiq: “$value” — son emas';
  }

  @override
  String get prodImpErrStockNegative => 'Qoldiq manfiy boʻlishi mumkin emas';

  @override
  String prodImpErrStockInteger(String unit) {
    return '“$unit” uchun qoldiq butun son boʻlishi kerak';
  }

  @override
  String get prodPriceBelowCost => 'Narx tannarxdan past';

  @override
  String get prodMoveReceipt => 'Kirim';

  @override
  String get prodMoveReceiptReversal => 'Kirim stornosi';

  @override
  String get prodMoveWriteoff => 'Hisobdan chiqarish';

  @override
  String get prodMoveAdjustment => 'Tuzatish';

  @override
  String get prodMoveInventory => 'Inventarizatsiya';

  @override
  String get prodMoveTransfer => 'Koʻchirish';

  @override
  String get prodErrEnterName => 'Mahsulot nomini kiriting';

  @override
  String get prodErrPriceNegative => 'Narx manfiy boʻlishi mumkin emas';

  @override
  String get prodErrCostNegative => 'Tannarx manfiy boʻlishi mumkin emas';

  @override
  String get prodErrWholesaleNegative =>
      'Ulgurji narx manfiy boʻlishi mumkin emas';

  @override
  String get prodErrVatRange => 'QQS 0 dan 100% gacha boʻlishi kerak';

  @override
  String get prodErrMinStockNegative =>
      'Minimal qoldiq manfiy boʻlishi mumkin emas';

  @override
  String get prodErrInitStockNegative =>
      'Boshlangʻich qoldiq manfiy boʻlishi mumkin emas';

  @override
  String prodErrBarcodeUsedBy(String code, String name) {
    return 'Shtrix-kod $code allaqachon “$name” mahsulotida ishlatilgan';
  }

  @override
  String prodErrInitStockInteger(String unit) {
    return '“$unit” uchun boshlangʻich qoldiq butun son boʻlishi kerak';
  }

  @override
  String get prodNoPricePerm => 'Narxlarni oʻzgartirish huquqi yoʻq';

  @override
  String prodErrBarcodeUsedOther(String code) {
    return 'Shtrix-kod $code boshqa mahsulotda ishlatilgan';
  }

  @override
  String get prodErrAlreadyDeleted => 'Mahsulot allaqachon oʻchirilgan';

  @override
  String prodErrFractionalStock(String qty, String unit) {
    return 'Qoldiq $qty kasr son — avval uni “Ombor” boʻlimida tuzating, soʻng birlikni “$unit” ga oʻzgartiring';
  }

  @override
  String get prodErrHasHistory =>
      'Mahsulot boʻyicha operatsiyalar bor (sotuvlar, harakatlar). Uni faqat arxivlash mumkin.';

  @override
  String prodErrPriceNegativeFor(String name) {
    return 'Narx manfiy boʻlishi mumkin emas: $name';
  }

  @override
  String get prodErrEnterCategoryName => 'Kategoriya nomini kiriting';

  @override
  String get prodErrCategoryNameTooLong => 'Nomi 120 belgidan uzun';

  @override
  String prodErrCategoryExists(String name) {
    return '“$name” kategoriyasi allaqachon mavjud';
  }

  @override
  String prodErrCategoryInUse(String count) {
    return 'Kategoriyada $count ta mahsulot bor — ularni qayerga koʻchirishni tanlang';
  }

  @override
  String get prodErrPickOtherCategory => 'Boshqa kategoriyani tanlang';

  @override
  String get prodImpNoteStockUnchanged =>
      'Qoldiq oʻzgarmaydi — “Ombor” boʻlimidan foydalaning';

  @override
  String prodImpNoteBarcodeTaken(String name) {
    return 'Shtrix-kod allaqachon “$name” mahsulotida';
  }

  @override
  String get prodNotFoundTitle => 'Mahsulot topilmadi';

  @override
  String prodBarcodeNotInCatalog(String code) {
    return 'Katalogda $code shtrix-kodi yoʻq. Shu shtrix-kod bilan yangi mahsulot yaratilsinmi?';
  }

  @override
  String get prodCategories => 'Kategoriyalar';

  @override
  String get prodImportFromCsv => 'CSV fayldan import';

  @override
  String get prodExportToCsv => 'CSV faylga eksport';

  @override
  String get prodByCurrentFilter => 'joriy filtr boʻyicha';

  @override
  String get prodWholeCatalog => 'butun katalog';

  @override
  String get prodNewProduct => 'Yangi mahsulot';

  @override
  String get prodNoCategory => 'Kategoriyasiz';

  @override
  String get prodSearchHintShort => 'Nomi, artikul, shtrix-kod';

  @override
  String get prodSearchHint => 'Nomi, artikul yoki shtrix-kod (Ctrl+F)';

  @override
  String get prodAllCategories => 'Barcha kategoriyalar';

  @override
  String get prodFavorites => 'Sevimlilar';

  @override
  String get prodSortTooltip => 'Saralash (qayta tanlash — teskari tartib)';

  @override
  String prodCountLabel(String count) {
    return 'Mahsulotlar: $count';
  }

  @override
  String get prodSelect => 'Tanlash';

  @override
  String get prodNoEditPerm => 'Mahsulotlarni tahrirlash huquqi yoʻq';

  @override
  String get prodPricesPercent => 'Narxlar, %';

  @override
  String get prodPriceLabels => 'Narx yorliqlari';

  @override
  String get prodToArchive => 'Arxivga';

  @override
  String get prodRestore => 'Qaytarish';

  @override
  String get prodCancelSelection => 'Tanlovni bekor qilish (Esc)';

  @override
  String prodSelectedCount(String count) {
    return 'Tanlandi: $count';
  }

  @override
  String get prodTryOtherFilters => 'Filtrlarni oʻzgartirib koʻring';

  @override
  String prodNoResultsFor(String query) {
    return '“$query” soʻrovi boʻyicha mahsulot yoʻq';
  }

  @override
  String get prodResetFilters => 'Filtrlarni tozalash';

  @override
  String get prodCatalogEmpty => 'Katalog boʻsh';

  @override
  String get prodEmptyHintEditor =>
      'Birinchi mahsulotni qoʻshing yoki roʻyxatni Exceldan (CSV) yuklang.';

  @override
  String get prodEmptyHintViewer =>
      'Mahsulotlarni menejer yoki administrator qoʻshadi.';

  @override
  String get prodImportCsv => 'CSV import';

  @override
  String get prodStockUntracked => 'Qoldiq hisobga olinmaydi';

  @override
  String prodStockLowTip(String qty) {
    return 'Kam: minimum $qty';
  }

  @override
  String get prodStockNegativeTip =>
      'Manfiy qoldiq — kirim/inventarizatsiyani tekshiring';

  @override
  String prodSkuShort(String sku) {
    return 'art. $sku';
  }

  @override
  String get prodCostShort => 'Tannarx';

  @override
  String get prodMargin => 'Marja';

  @override
  String get prodArchiveOneQ => 'Mahsulot arxivlansinmi?';

  @override
  String prodArchiveManyQ(String count) {
    return '$count ta mahsulot arxivlansinmi?';
  }

  @override
  String get prodArchiveMessage =>
      'Arxivdagi mahsulotlar sotilmaydi va kassada koʻrinmaydi. Sotuvlar tarixi saqlanadi. Istalgan vaqtda qaytarish mumkin (“Arxiv” filtri).';

  @override
  String get prodRestored => 'Mahsulotlar sotuvga qaytarildi';

  @override
  String get prodArchived => 'Arxivga koʻchirildi';

  @override
  String get prodCannotDeleteArchived =>
      'Mahsulot boʻyicha operatsiyalar bor — oʻchirib boʻlmaydi, u allaqachon arxivda';

  @override
  String get prodCannotDeleteTitle => 'Oʻchirib boʻlmaydi';

  @override
  String prodCannotDeleteMessage(String name) {
    return '“$name” mahsuloti boʻyicha sotuvlar yoki ombor harakatlari bor — hisobotlar uchun u bazada qolishi kerak. Arxivga koʻchirilsinmi?';
  }

  @override
  String get prodMovedToArchive => 'Mahsulot arxivga koʻchirildi';

  @override
  String prodDeleteQ(String name) {
    return '“$name” oʻchirilsinmi?';
  }

  @override
  String get prodDeleteMessage =>
      'Operatsiyasiz mahsulot katalogdan oʻchiriladi.';

  @override
  String get prodDeleted => 'Mahsulot oʻchirildi';

  @override
  String get prodNotFoundOrDeleted => 'Mahsulot topilmadi yoki oʻchirilgan';

  @override
  String get prodPriceLabel => 'Narx yorligʻi';

  @override
  String get prodDuplicate => 'Nusxa yaratish';

  @override
  String get prodUnfavorited => 'Sevimlilardan olib tashlandi';

  @override
  String get prodFavorited => 'Sevimlilarga qoʻshildi';

  @override
  String get prodUnfavorite => 'Sevimlilardan olib tashlash';

  @override
  String get prodFavorite => 'Sevimlilarga';

  @override
  String get prodRestoreFromArchive => 'Arxivdan qaytarish';

  @override
  String get prodFavoriteChip => 'Sevimli';

  @override
  String get prodNoStockTracking => 'Qoldiq hisobisiz';

  @override
  String get prodNoReceiptsYet => 'kirimlar boʻlmagan';

  @override
  String get prodToday => 'bugun';

  @override
  String prodDaysAgo(String days) {
    return '$days kun oldin';
  }

  @override
  String prodWholesaleShort(String price) {
    return 'ulgurji $price';
  }

  @override
  String prodPerUnit(String unit) {
    return '1 $unit uchun';
  }

  @override
  String prodMarginLower(String pct) {
    return 'marja $pct';
  }

  @override
  String get prodUntrackedLower => 'hisobsiz';

  @override
  String prodMinShort(String qty) {
    return 'min. $qty';
  }

  @override
  String get prodMinNotSet => 'minimum belgilanmagan';

  @override
  String get prodSold => 'Sotildi';

  @override
  String get prodLast30Days => '30 kunda';

  @override
  String prodLast30DaysReceipts(String count) {
    return '30 kunda · cheklar: $count';
  }

  @override
  String get prodRevenue => 'Tushum';

  @override
  String get prodLastReceipt => 'Oxirgi kirim';

  @override
  String get prodSpecs => 'Xususiyatlar';

  @override
  String get prodWholesalePrice => 'Ulgurji narx';

  @override
  String get prodNoVatLower => 'QQSsiz';

  @override
  String get prodNegativeSale => 'Minusga sotish';

  @override
  String get prodAllowed => 'ruxsat etilgan';

  @override
  String get prodForbidden => 'taqiqlangan';

  @override
  String get prodWarranty => 'Kafolat';

  @override
  String get prodNoneLower => 'yoʻq';

  @override
  String prodMonthsShort(String count) {
    return '$count oy';
  }

  @override
  String get prodUpdatedAt => 'Oʻzgartirilgan';

  @override
  String get prodMovements => 'Mahsulot harakati';

  @override
  String get prodLast50 => 'oxirgi 50';

  @override
  String get prodNoMovements =>
      'Hozircha harakatlar boʻlmagan. Kirim “Ombor” yoki “Xaridlar” boʻlimida rasmiylashtiriladi.';

  @override
  String prodStockAfterShort(String qty) {
    return 'qol. $qty';
  }

  @override
  String prodCopySuffix(String name) {
    return '$name (nusxa)';
  }

  @override
  String get prodReplaceBarcodeQ => 'Shtrix-kod almashtirilsinmi?';

  @override
  String prodReplaceBarcodeMessage(String code) {
    return 'Joriy $code shtrix-kodi ichki kod bilan almashtiriladi. Eski yorliqlar skanerlanmay qoladi.';
  }

  @override
  String get prodReplace => 'Almashtirish';

  @override
  String get prodCloseUnsavedQ => 'Saqlamasdan yopilsinmi?';

  @override
  String get prodUnsavedLost => 'Kiritilgan oʻzgarishlar yoʻqoladi.';

  @override
  String get prodCheckFields => 'Ajratilgan maydonlarni tekshiring';

  @override
  String prodBarcodeInUseBy(String name) {
    return 'Band: “$name”';
  }

  @override
  String prodBarcodeAssignedTo(String code, String name) {
    return 'Shtrix-kod $code allaqachon “$name” mahsulotiga biriktirilgan';
  }

  @override
  String prodPriceBelowCostMessage(String price, String cost) {
    return 'Narx $price tannarx $cost dan past. Har bir sotuv zarar keltiradi. Saqlansinmi?';
  }

  @override
  String get prodZeroPrice => 'Nol narx';

  @override
  String get prodZeroPriceMessage =>
      'Mahsulot bepul sotiladi. Davom etilsinmi?';

  @override
  String prodCreated(String name) {
    return '“$name” mahsuloti yaratildi';
  }

  @override
  String get prodChangesSaved => 'Oʻzgarishlar saqlandi';

  @override
  String get prodCopyTitle => 'Mahsulot nusxasi';

  @override
  String get prodEditTitle => 'Mahsulotni tahrirlash';

  @override
  String get prodCreateProduct => 'Mahsulot yaratish';

  @override
  String get prodCloseEsc => 'Yopish (Esc)';

  @override
  String get prodEditorShortcuts => 'Ctrl+S — saqlash, Esc — yopish';

  @override
  String get prodSectionBasic => 'Asosiy';

  @override
  String get prodNameRequired => 'Nomi *';

  @override
  String get prodNewCategory => 'Yangi kategoriya';

  @override
  String get prodUnitLabel => 'Oʻlchov birligi';

  @override
  String get prodFractionalHint => 'Kasr miqdor (tortiladigan mahsulot)';

  @override
  String get prodDescription => 'Tavsif';

  @override
  String get prodActiveSwitch => 'Faol (sotiladi)';

  @override
  String get prodFavoriteSwitch => 'Kassada sevimli';

  @override
  String get prodSectionPrices => 'Narxlar';

  @override
  String get prodRetailPriceRequired => 'Chakana narx *';

  @override
  String get prodRetailPrice => 'Chakana narx';

  @override
  String get prodCostHintNew => 'Boshlangʻich qoldiq uchun';

  @override
  String get prodCostHintAvg => 'Oʻrtacha, kirimlar boʻyicha';

  @override
  String get prodMarginColon => 'Marja: ';

  @override
  String get prodMarkupColon => 'Ustama: ';

  @override
  String get prodProfitPerUnitColon => 'Birlikdan foyda: ';

  @override
  String get prodVatIncluded => 'QQS (narxga kiritilgan)';

  @override
  String get prodNoVat => 'QQSsiz';

  @override
  String get prodVatOther => 'Boshqa';

  @override
  String get prodInternalEan => 'Ichki EAN-13';

  @override
  String get prodSectionCodes => 'Kodlar';

  @override
  String get prodScanOrType => 'Skanerlang yoki kiriting';

  @override
  String get prodGenerateBarcode => 'Ichki EAN-13 yaratish (200 prefiksi)';

  @override
  String get prodBarcodeTooLong => 'Shtrix-kod juda uzun';

  @override
  String get prodBarcodeNoSpaces => 'Shtrix-kodda boʻsh joy boʻlmasligi kerak';

  @override
  String get prodSkuLabel => 'Artikul (SKU)';

  @override
  String prodSkuFree(String sku) {
    return 'Boʻsh: $sku';
  }

  @override
  String prodSkuUse(String sku) {
    return '$sku ni qoʻyish';
  }

  @override
  String get prodSectionStock => 'Ombor';

  @override
  String get prodTrackStock => 'Qoldiqni hisobga olish';

  @override
  String get prodAllowNegative => 'Minusga sotishga ruxsat';

  @override
  String get prodMinStock => 'Minimal qoldiq';

  @override
  String get prodMinStockHint => 'Undan past boʻlsa — “Kam” deb belgilanadi';

  @override
  String get prodEnterNonNegative => 'Son kiriting (≥ 0)';

  @override
  String get prodInitialStock => 'Boshlangʻich qoldiq';

  @override
  String get prodInitialStockHint =>
      '“Boshlangʻich qoldiq” sifatida kirim qilinadi';

  @override
  String get prodCurrentStock => 'Joriy qoldiq';

  @override
  String get prodCurrentStockHint =>
      '“Ombor” boʻlimida oʻzgartiriladi: kirim, hisobdan chiqarish, inventarizatsiya';

  @override
  String get prodSectionWarranty => 'Kafolat va taʼminotchi';

  @override
  String get prodMonthsSuffix => 'oy';

  @override
  String get prodWarrantyHint => '0 — kafolatsiz';

  @override
  String get prodWarrantyRange => '0 dan 240 oygacha';

  @override
  String get prodSuppliersHint =>
      'Taʼminotchilar “Xaridlar” boʻlimida qoʻshiladi';

  @override
  String get prodNotSpecified => 'Koʻrsatilmagan';

  @override
  String get prodUnitNamePcs => 'Dona';

  @override
  String get prodUnitNameKg => 'Kilogramm (kg)';

  @override
  String get prodUnitNameG => 'Gramm (g)';

  @override
  String get prodUnitNameL => 'Litr (l)';

  @override
  String get prodUnitNameM => 'Metr (m)';

  @override
  String get prodUnitNamePack => 'Qadoq';

  @override
  String prodBulkCategoryTitle(String count) {
    return '$count ta mahsulot uchun kategoriya';
  }

  @override
  String prodBulkCategoryDone(String count) {
    return '$count ta mahsulotning kategoriyasi oʻzgartirildi';
  }

  @override
  String get prodBulkPriceTitle => 'Narxlarni % ga oʻzgartirish';

  @override
  String get prodBulkPctError =>
      '−99 dan 1000 gacha foiz kiriting, masalan 10 yoki −5';

  @override
  String get prodBulkNoChange =>
      'Narxlar oʻzgarmaydi — boshqa foiz yoki yaxlitlashni tanlang';

  @override
  String prodBulkPriceConfirmQ(String count) {
    return '$count ta mahsulot narxi oʻzgartirilsinmi?';
  }

  @override
  String get prodBulkPriceConfirmMessage =>
      'Har bir oʻzgarish audit jurnaliga yoziladi. Narx yorliqlarini qayta chop etish kerak boʻladi.';

  @override
  String get prodChangePrices => 'Narxlarni oʻzgartirish';

  @override
  String prodBulkPriceDone(String count) {
    return '$count ta mahsulot narxi yangilandi';
  }

  @override
  String get prodChangePct => 'Oʻzgarish, %';

  @override
  String get prodChangePctHint => 'masalan 10 yoki -5';

  @override
  String get prodChangePctHelper => 'Plyus — qimmatlash, minus — arzonlash';

  @override
  String get prodChangePctRange => '−99 dan 1000 gacha';

  @override
  String get prodRounding => 'Yaxlitlash';

  @override
  String prodWillChange(String count) {
    return 'Oʻzgaradi: $count';
  }

  @override
  String prodBelowCostCount(String count) {
    return 'Tannarxdan past: $count';
  }

  @override
  String prodCostMarginLine(String cost, String margin) {
    return 'tannarx $cost · marja $margin';
  }

  @override
  String prodApplyTo(String count) {
    return '$count taga qoʻllash';
  }

  @override
  String get prodErrEnterNameShort => 'Nomini kiriting';

  @override
  String get prodColor => 'Rang';

  @override
  String prodDeleteCategoryQ(String name) {
    return '“$name” kategoriyasi oʻchirilsinmi?';
  }

  @override
  String get prodCategoryEmptyMsg => 'Kategoriyada mahsulot yoʻq.';

  @override
  String get prodCategoryDeleted => 'Kategoriya oʻchirildi';

  @override
  String prodCategoryMoveQ(String count) {
    return 'Kategoriyada $count ta mahsulot bor. Ularni qayerga koʻchirish kerak?';
  }

  @override
  String get prodMoveTo => 'Qayerga koʻchirish';

  @override
  String get prodMoveAndDelete => 'Koʻchirish va oʻchirish';

  @override
  String get prodCategoryDeletedMoved =>
      'Kategoriya oʻchirildi, mahsulotlar koʻchirildi';

  @override
  String get prodNoCategoriesYet => 'Hozircha kategoriyalar yoʻq';

  @override
  String get prodCategoriesHint =>
      'Kategoriyalar kassada va hisobotlarda mahsulotlarni tez topishga yordam beradi.';

  @override
  String prodCategoriesFooter(String count) {
    return 'Kassadagi tartibni oʻzgartirish uchun sudrang. Kategoriyasiz: $count ta mahsulot.';
  }

  @override
  String get prodImportTitle => 'Mahsulotlarni CSV fayldan import qilish';

  @override
  String get prodImpEnterPath => '.csv fayl yoʻlini kiriting';

  @override
  String prodImpFileNotFound(String path) {
    return 'Fayl topilmadi: $path';
  }

  @override
  String get prodImpFileTooBig => 'Fayl 20 MB dan katta';

  @override
  String prodImpFileLoaded(String name) {
    return 'Fayl yuklandi: $name';
  }

  @override
  String get prodImpPasteOrLoad =>
      'Exceldan maʼlumotlarni qoʻying yoki faylni yuklang';

  @override
  String get prodImpNoRows => 'Maʼlumotli qatorlar yoʻq';

  @override
  String prodImpTooManyRows(String count) {
    return 'Qatorlar juda koʻp ($count). Faylni 20 000 qatorgacha boʻlgan qismlarga ajrating.';
  }

  @override
  String get prodImpNothing =>
      'Import qilinadigan narsa yoʻq — maʼlumotlardagi xatolarni tuzating';

  @override
  String prodImpDone(String created, String updated) {
    return 'Yaratildi: $created, yangilandi: $updated';
  }

  @override
  String prodImpDoneSkipped(String count) {
    return ', oʻtkazib yuborildi: $count';
  }

  @override
  String prodImpDoneCategories(String count) {
    return ', yangi kategoriyalar: $count';
  }

  @override
  String get prodImpIntro =>
      'Excel / Google Sheets dan qatorlarni nusxalab, quyiga qoʻying yoki .csv fayl yoʻlini koʻrsating. Ustunlar: nomi; shtrix-kod; artikul; kategoriya; narx; tannarx; birlik; qoldiq. Sarlavha va ajratuvchi (; , tabulyatsiya) avtomatik aniqlanadi.';

  @override
  String get prodImpPasteHint => 'Maʼlumotlarni qoʻying (Ctrl+V)…';

  @override
  String get prodImpOrPath => 'Yoki fayl yoʻli';

  @override
  String get prodImpPathHint => 'C:\\Users\\...\\mahsulotlar.csv';

  @override
  String get prodImpLoad => 'Yuklash';

  @override
  String get prodImpUpdateExisting =>
      'Mavjud mahsulotlarni shtrix-kod boʻyicha yangilash';

  @override
  String get prodImpUpdateExistingHint =>
      'Aks holda maʼlum shtrix-kodli qatorlar oʻtkazib yuboriladi. Mavjud mahsulotlar qoldigʻi oʻzgarmaydi.';

  @override
  String get prodImpSample => 'Namuna';

  @override
  String get prodImpCheck => 'Tekshirish';

  @override
  String prodImpRows(String count) {
    return 'Qatorlar: $count';
  }

  @override
  String prodImpNew(String count) {
    return 'Yangi: $count';
  }

  @override
  String prodImpUpdateCount(String count) {
    return 'Yangilash: $count';
  }

  @override
  String prodImpSkipErrors(String count) {
    return 'Oʻtkazish/xatolar: $count';
  }

  @override
  String prodImpNewCategories(String count) {
    return 'Yangi kategoriyalar: $count';
  }

  @override
  String prodImpDelimiterWithHeader(String delimiter) {
    return 'Ajratuvchi: $delimiter, sarlavha bilan';
  }

  @override
  String prodImpDelimiterNoHeader(String delimiter) {
    return 'Ajratuvchi: $delimiter, sarlavhasiz';
  }

  @override
  String get prodImpNoPricePerm =>
      'Sizda narxlarni oʻzgartirish huquqi yoʻq: mavjud mahsulotlar narxi yangilanmaydi.';

  @override
  String get prodImpUpdate => 'Yangilash';

  @override
  String get prodImpSkip => 'Oʻtkazish';

  @override
  String get prodImpNoName => '(nomsiz)';

  @override
  String get prodImpBackToData => 'Maʼlumotlarga qaytish';

  @override
  String prodImpImportN(String count) {
    return '$count tani import qilish';
  }

  @override
  String get prodExpNothing =>
      'Joriy filtr boʻyicha eksport uchun mahsulot yoʻq';

  @override
  String get prodExpFileStem => 'mahsulotlar';

  @override
  String prodExpDoneTitle(String count) {
    return 'Eksport qilingan mahsulotlar: $count';
  }

  @override
  String get prodExpCopied =>
      'Maʼlumotlar buferga nusxalandi — ularni Excelga qoʻying (Ctrl+V).';

  @override
  String get prodExpSaved => 'Fayl saqlandi:';

  @override
  String prodExpSaveFailed(String error) {
    return 'Faylni saqlab boʻlmadi: $error';
  }

  @override
  String get prodExpCopyPath => 'Yoʻlni nusxalash';

  @override
  String get prodLabelSmall => 'Kichik 4×10 (52×29 mm)';

  @override
  String get prodLabelMedium => 'Oʻrta 3×8 (70×37 mm)';

  @override
  String get prodLabelLarge => 'Katta 2×5 (105×59 mm)';

  @override
  String get prodPrintLabelsTitle => 'Narx yorliqlarini chop etish';

  @override
  String get prodCopiesRange => 'Nusxalar soni — 1 dan 100 gacha';

  @override
  String prodLabelsIntro(String count) {
    return 'Mahsulotlar: $count. A4 format, kesish chiziqlari punktir.';
  }

  @override
  String get prodLabelSize => 'Yorliq oʻlchami';

  @override
  String get prodCopiesEach => 'Har biridan nusxa';

  @override
  String prodLabelsTotal(String total, String pages) {
    return 'Jami yorliqlar: $total\nA4 sahifalar: $pages';
  }

  @override
  String get prodPrintBarcode => 'Shtrix-kodni chop etish';

  @override
  String get prodPreparingPdf => 'PDF tayyorlanmoqda…';

  @override
  String get purActCopied =>
      'Solishtirma dalolatnoma nusxalandi — Excelga joylang';

  @override
  String get purActCopyCsv => 'CSV nusxalash';

  @override
  String get purActFilePrefix => 'Solishtirma_dalolatnoma';

  @override
  String get purActFileSupplier => 'taminotchi';

  @override
  String get purActLegend =>
      'Kirim (+) doʻkonning taʼminotchi oldidagi qarzini oshiradi, chiqim (−) uni kamaytiradi. Musbat balans — doʻkon qarzi, manfiy balans — taʼminotchidagi avans.';

  @override
  String get purActPrint => 'Chop etish / PDF';

  @override
  String get purActSaveCsv => 'CSV saqlash (Excel)';

  @override
  String get purActShare => 'PDF yuborish';

  @override
  String get purActShort => 'Solishtirma dalolatnoma';

  @override
  String get purActTitle =>
      'Oʻzaro hisob-kitoblarni solishtirish dalolatnomasi';

  @override
  String get purActive => 'Faol';

  @override
  String get purAddOneProduct => 'Kamida bitta mahsulot qoʻshing';

  @override
  String get purAddSupplier => 'Taʼminotchi qoʻshish';

  @override
  String get purAddToOrder => 'Buyurtmaga qoʻshish';

  @override
  String purAdjustDone(String amount) {
    return '$amount tuzatish amalga oshirildi';
  }

  @override
  String get purAdjustReasonHint =>
      'Masalan: … dagi solishtirma dalolatnoma boʻyicha';

  @override
  String get purAdjustTitle => 'Balansni tuzatish';

  @override
  String get purAdvanceLower => 'avans';

  @override
  String purAdvanceLowerValue(String amount) {
    return 'avans $amount';
  }

  @override
  String purAdvanceSuffix(String amount) {
    return '$amount avans';
  }

  @override
  String purAdvanceValue(String amount) {
    return 'Taʼminotchidagi avans: $amount';
  }

  @override
  String get purAdvanceWithSupplier => 'Taʼminotchidagi avans';

  @override
  String purAfterAdjust(String value) {
    return 'Tuzatishdan soʻng: $value';
  }

  @override
  String get purAllAsOrdered => 'Hammasi buyurtma boʻyicha';

  @override
  String get purAllReceived =>
      'Buyurtmaning barcha pozitsiyalari qabul qilingan';

  @override
  String get purAllTimeLower => 'butun davr';

  @override
  String get purAmountRequired => 'Summa *';

  @override
  String purBalanceLower(String value) {
    return 'balans $value';
  }

  @override
  String get purBuyer => 'Xaridor';

  @override
  String get purCancelCashHint =>
      'Naqd toʻlovni faqat uning smenasi ochiq boʻlganda bekor qilish mumkin.';

  @override
  String get purCancelOrder => 'Buyurtmani bekor qilish';

  @override
  String purCancelOrderTitle(String number) {
    return 'Buyurtma №$number bekor qilinsinmi?';
  }

  @override
  String get purCancelPayment => 'Toʻlovni bekor qilish';

  @override
  String purCancelPaymentMessage(String date, String method) {
    return '$date dagi toʻlov ($method) tarixda “Bekor qilingan” belgisi bilan qoladi, taʼminotchiga qarz shu summaga oshadi.';
  }

  @override
  String purCancelPaymentTitle(String amount) {
    return '$amount toʻlov bekor qilinsinmi?';
  }

  @override
  String get purCancelReasonLabel => 'Bekor qilish sababi *';

  @override
  String purCancelledAt(String date) {
    return 'Bekor qilingan $date';
  }

  @override
  String get purCancelledFem => 'Bekor qilingan';

  @override
  String get purCashNeedsShift =>
      'Kassadan naqd toʻlov uchun smena ochiq boʻlishi kerak. Smenani oching yoki boshqa usulni tanlang.';

  @override
  String purCashOutFromShift(String number) {
    return 'Smena №$number kassasidan toʻlov sifatida hisobga olinadi';
  }

  @override
  String get purChangesSaved => 'Oʻzgarishlar saqlandi';

  @override
  String get purCheckPhone => 'Telefon raqamini tekshiring';

  @override
  String get purChooseAnotherPeriod => 'Boshqa davrni tanlang';

  @override
  String purCloseOrderTitle(String number) {
    return 'Buyurtma №$number qoldiqsiz yopilsinmi?';
  }

  @override
  String get purCloseWithoutRest => 'Qoldiqsiz yopish';

  @override
  String get purClosingBalance => 'Davr oxiridagi saldo';

  @override
  String get purClosingShort => 'Yakuniy saldo';

  @override
  String purConclusionNone(String at) {
    return '$at holatiga tomonlar oʻrtasida qarzdorlik yoʻq.';
  }

  @override
  String purConclusionStoreOwes(
    String at,
    String store,
    String supplier,
    String amount,
  ) {
    return '$at holatiga “$store”ning “$supplier” oldidagi qarzi $amount.';
  }

  @override
  String purConclusionSupplierOwes(
    String at,
    String supplier,
    String store,
    String amount,
  ) {
    return '$at holatiga “$supplier”ning “$store” oldidagi qarzi (avans) $amount.';
  }

  @override
  String get purContactPerson => 'Aloqa uchun shaxs';

  @override
  String purCoverDays(String days) {
    return '$days kunga yetadi';
  }

  @override
  String get purCreateOrder => 'Buyurtma yaratish';

  @override
  String get purCreateOrders => 'Buyurtmalar yaratish';

  @override
  String purCreatedOn(String date) {
    return 'yaratilgan $date';
  }

  @override
  String purDaysShort(String n) {
    return '$n kun';
  }

  @override
  String get purDaysSuffix => 'kun';

  @override
  String get purDebtOnly => 'Faqat qarzimiz borlar';

  @override
  String get purDecrease => 'Chiqim (−)';

  @override
  String get purDecreaseDebt => 'Qarzni kamaytirish';

  @override
  String get purDeleteLine => 'Qatorni oʻchirish';

  @override
  String get purDeleteSupplierMessage =>
      'Taʼminotchi roʻyxatlardan yashiriladi. Buyurtma va toʻlovlar tarixi saqlanadi.';

  @override
  String purDeleteSupplierTitle(String name) {
    return '“$name” taʼminotchisi oʻchirilsinmi?';
  }

  @override
  String get purDeletedProduct => 'Oʻchirilgan mahsulot';

  @override
  String get purDeliveryDate => 'Yetkazish sanasi';

  @override
  String purDeliveryOn(String date) {
    return 'Yetkazish $date';
  }

  @override
  String get purDraftSaved => 'Buyurtma qoralamasi saqlandi';

  @override
  String get purEditorEmptyHint =>
      'Mahsulotlarni qoʻshing: skaner, “Mahsulot” tugmasi yoki “Avtobuyurtma” boʻlimi orqali';

  @override
  String purEditorTotal(String amount, String count) {
    return 'Jami: $amount · pozitsiyalar $count';
  }

  @override
  String get purEnterAdjustReason => 'Tuzatish sababini kiriting';

  @override
  String get purEnterPrice => 'Narxni kiriting';

  @override
  String get purEnterReason => 'Sababni kiriting';

  @override
  String get purEnterSupplierName => 'Taʼminotchi nomini kiriting';

  @override
  String get purErrAddOneProduct => 'Buyurtmaga kamida bitta mahsulot qoʻshing';

  @override
  String get purErrAlreadyClosed => 'Buyurtma allaqachon yopilgan';

  @override
  String get purErrAlreadySent => 'Buyurtma allaqachon yuborilgan';

  @override
  String purErrDeleteNonZeroBalance(String balance) {
    return 'Balansi nol boʻlmagan taʼminotchini oʻchirib boʻlmaydi ($balance)';
  }

  @override
  String get purErrDuplicateProduct =>
      'Mahsulot buyurtmada takrorlanmoqda — qatorlarni birlashtiring';

  @override
  String get purErrEnterQtyOneLine =>
      'Kamida bitta pozitsiya boʻyicha miqdorni kiriting';

  @override
  String get purErrLineNotFound => 'Pozitsiya buyurtmada topilmadi';

  @override
  String purErrLinePriceNegative(String name) {
    return '“$name”: narx manfiy boʻlishi mumkin emas';
  }

  @override
  String get purErrLineTwice => 'Buyurtma pozitsiyasi ikki marta koʻrsatilgan';

  @override
  String get purErrNameTooLong => 'Nom juda uzun';

  @override
  String get purErrNoLines => 'Buyurtmada pozitsiyalar yoʻq';

  @override
  String get purErrNothingToOrder => 'Buyurtma uchun pozitsiyalar yoʻq';

  @override
  String get purErrOnlyDraftEditable =>
      'Faqat buyurtma qoralamasini oʻzgartirish mumkin';

  @override
  String purErrOrderAlreadyStatus(String number, String status) {
    return 'Buyurtma №$number allaqachon $status';
  }

  @override
  String purErrReceiveAtMost(String name, String qty) {
    return '“$name”: $qty dan koʻp qabul qilib boʻlmaydi';
  }

  @override
  String purErrSupplierExists(String name) {
    return '“$name” taʼminotchisi allaqachon mavjud';
  }

  @override
  String purErrSupplierHasOpenOrders(String n) {
    return 'Taʼminotchida yopilmagan buyurtmalar bor ($n)';
  }

  @override
  String get purErrSupplierNameRequired => 'Taʼminotchi nomini kiriting';

  @override
  String purErrWholeQty(String name) {
    return '“$name”: faqat butun miqdor';
  }

  @override
  String purExpectedOn(String date) {
    return 'kutilmoqda $date';
  }

  @override
  String get purFromBuyer => 'Xaridor tomonidan';

  @override
  String get purFromSupplier => 'Taʼminotchi tomonidan';

  @override
  String get purFullyReceivedSuffix => ' — buyurtma toʻliq qabul qilindi';

  @override
  String purHeadingAllTime(String period) {
    return '$period uchun';
  }

  @override
  String purHeadingPeriod(String period) {
    return '$period davr uchun';
  }

  @override
  String get purIncrease => 'Kirim (+)';

  @override
  String get purIncreaseDebt => 'Qarzni oshirish';

  @override
  String get purInvalid => 'Notoʻgʻri';

  @override
  String purInvoiceShort(String number) {
    return 'yuk xati $number';
  }

  @override
  String purItemProgress(String ordered, String received) {
    return 'buyurtma $ordered · qabul $received';
  }

  @override
  String purItemRestSuffix(String qty) {
    return ' · qoldi $qty';
  }

  @override
  String purLastReceipt(String date, String count) {
    return 'oxirgi kirim $date · kirimlar $count';
  }

  @override
  String get purLedgerAdjustment => 'Tuzatish';

  @override
  String get purLedgerEmpty => 'Hali hisob-kitoblar boʻlmagan';

  @override
  String get purLedgerEmptyMessage =>
      'Bu yerda kirimlar, toʻlovlar va tuzatishlar joriy balans bilan koʻrinadi';

  @override
  String get purLedgerEmptyPeriod => 'Davr uchun operatsiyalar yoʻq';

  @override
  String purLedgerOpNumbered(String op, String number) {
    return '$op №$number';
  }

  @override
  String get purLedgerOpening => 'Boshlangʻich qoldiq';

  @override
  String get purLedgerPaymentCancel => 'Toʻlovni bekor qilish';

  @override
  String get purLedgerPeriodHelp => 'Hisob-kitoblar davri';

  @override
  String get purLedgerReceipt => 'Kirim';

  @override
  String get purLedgerReceiptReversal => 'Kirim stornosi';

  @override
  String get purMarkOrdered => 'Buyurtma berildi deb belgilash';

  @override
  String get purMax160Chars => '160 belgidan oshmasin';

  @override
  String purMaxQty(String qty) {
    return 'Maks. $qty';
  }

  @override
  String get purMethodTransfer => 'Oʻtkazma';

  @override
  String purMinValue(String qty) {
    return 'min. $qty';
  }

  @override
  String get purNameRequiredLabel => 'Nomi *';

  @override
  String get purNewOrder => 'Yangi buyurtma';

  @override
  String get purNewPo => 'Taʼminotchiga yangi buyurtma';

  @override
  String get purNewSupplier => 'Yangi taʼminotchi';

  @override
  String get purNoAccess => 'Ruxsat yoʻq';

  @override
  String get purNoAccessMessage =>
      'Xaridlar omborchi, menejer va egasi uchun ochiq';

  @override
  String get purNoCashOutPermission => 'Kassadan naqd pul berishga ruxsat yoʻq';

  @override
  String get purNoCashPermission => 'Naqd pul bilan ishlashga ruxsat yoʻq';

  @override
  String get purNoChange => 'oʻzgarishsiz';

  @override
  String get purNoDebt => 'qarz yoʻq';

  @override
  String get purNoLinesAdded => 'Pozitsiyalar qoʻshilmagan';

  @override
  String get purNoOrders => 'Hozircha taʼminotchilarga buyurtmalar yoʻq';

  @override
  String get purNoOrdersForFilter => 'Filtr boʻyicha buyurtmalar yoʻq';

  @override
  String get purNoOrdersMessage =>
      'Buyurtmani qoʻlda yarating yoki “Avtobuyurtma” boʻlimidan foydalaning';

  @override
  String get purNoOrdersYet => 'Hali buyurtmalar boʻlmagan';

  @override
  String get purNoPaymentsYet => 'Hali toʻlovlar boʻlmagan';

  @override
  String get purNoProductsForFilter => 'Filtr boʻyicha mahsulotlar yoʻq';

  @override
  String get purNoReceiptsYet =>
      'Buyurtma boʻyicha mahsulot hali qabul qilinmagan';

  @override
  String get purNoSales => 'sotuvlar boʻlmagan';

  @override
  String get purNoSupplier => 'Taʼminotchisiz';

  @override
  String get purNoSupplierHelper =>
      'Bu mahsulotlar kartochkasida taʼminotchi koʻrsatilmagan';

  @override
  String get purNoSuppliers => 'Hozircha taʼminotchilar yoʻq';

  @override
  String get purNoSuppliersMessage =>
      'Buyurtmalar va qarzlarni yuritish uchun taʼminotchilarni qoʻshing';

  @override
  String purNowValue(String value) {
    return 'Hozir: $value';
  }

  @override
  String get purNumberGeZero => 'Son ≥ 0';

  @override
  String purOnOrderValue(String qty) {
    return 'buyurtmalarda $qty';
  }

  @override
  String get purOpeningBalance => 'Davr boshidagi saldo';

  @override
  String get purOpeningShort => 'Boshlangʻich saldo';

  @override
  String get purOperation => 'Operatsiya';

  @override
  String purOrderAmount(String amount) {
    return 'Buyurtma summasi $amount';
  }

  @override
  String get purOrderButton => 'Buyurtma';

  @override
  String get purOrderCancelled => 'Buyurtma bekor qilindi';

  @override
  String get purOrderClosed => 'Buyurtma yopildi';

  @override
  String get purOrderFromSupplier => 'Taʼminotchidan buyurtma qilish';

  @override
  String purOrderListTitle(String number, String supplier) {
    return '№$number · $supplier';
  }

  @override
  String get purOrderNotFound => 'Buyurtma topilmadi';

  @override
  String purOrderNumber(String number) {
    return 'Buyurtma №$number';
  }

  @override
  String get purOrderReceipts => 'Buyurtma boʻyicha kirimlar';

  @override
  String get purOrderSavedSent =>
      'Buyurtma saqlandi va yuborilgan deb belgilandi';

  @override
  String purOrderSent(String number) {
    return 'Buyurtma №$number taʼminotchiga yuborildi';
  }

  @override
  String purOrderedRest(String ordered, String rest) {
    return 'buyurtma $ordered · qoldi $rest';
  }

  @override
  String get purOurDebtLower => 'bizning qarz';

  @override
  String purOurDebtLowerValue(String amount) {
    return 'bizning qarz $amount';
  }

  @override
  String get purOurDebtToSupplier => 'Taʼminotchiga qarzimiz';

  @override
  String purOurDebtValue(String amount) {
    return 'Bizning qarz: $amount';
  }

  @override
  String purOverpayMessage(String debt, String amount, String advance) {
    return 'Taʼminotchiga qarz: $debt.\n$amount toʻlangandan soʻng $advance avans hosil boʻladi. Davom etilsinmi?';
  }

  @override
  String get purOverpayTitle => 'Summa qarzdan koʻp';

  @override
  String purPaidAmount(String amount) {
    return 'Toʻlangan $amount';
  }

  @override
  String get purPay => 'Toʻlash';

  @override
  String get purPayWithAdvance => 'Avans bilan toʻlash';

  @override
  String purPaymentCancelled(String amount) {
    return '$amount toʻlov bekor qilindi';
  }

  @override
  String get purPaymentCommentLabel => 'Izoh (toʻlov hujjati №…)';

  @override
  String purPaymentDone(String amount) {
    return '$amount toʻlov amalga oshirildi';
  }

  @override
  String get purPaymentTitle => 'Taʼminotchiga toʻlov';

  @override
  String get purPeriodAll => 'Butun davr';

  @override
  String get purPeriodCustom => 'Davr…';

  @override
  String get purPeriodLastMonth => 'Oʻtgan oy';

  @override
  String get purPeriodQuarter => 'Chorak';

  @override
  String get purPeriodThisMonth => 'Shu oy';

  @override
  String purPeriodUntil(String date) {
    return '$date gacha';
  }

  @override
  String get purPoColBarcode => 'Shtrix-kod / art.';

  @override
  String get purPoColNo => '№';

  @override
  String get purPoColQty => 'Miqdor';

  @override
  String get purPoColReceived => 'Qabul qilindi';

  @override
  String purPoDated(String date, String status) {
    return '$date · $status';
  }

  @override
  String purPoExpected(String date) {
    return 'Kutilayotgan yetkazib berish sanasi: $date';
  }

  @override
  String purPoNote(String note) {
    return 'Izoh: $note';
  }

  @override
  String purPoOrderedBy(String line) {
    return 'Buyurtmachi: $line';
  }

  @override
  String purPoPrintName(String number) {
    return 'Taʼminotchiga buyurtma $number';
  }

  @override
  String get purPoShort => 'Taʼminotchiga buyurtma';

  @override
  String purPoSupplier(String name) {
    return 'Taʼminotchi: $name';
  }

  @override
  String purPoTitle(String number) {
    return 'Taʼminotchiga buyurtma №$number';
  }

  @override
  String purPoTotal(String amount) {
    return 'Jami: $amount';
  }

  @override
  String get purPostAdjust => 'Tuzatishni oʻtkazish';

  @override
  String get purPriceRiseChip => 'Oʻsish > 10%';

  @override
  String get purPriceRiseFilter => 'Narx oʻsishi > 10%';

  @override
  String get purPricesEmpty => 'Davr uchun kirimlar yoʻq';

  @override
  String get purPricesEmptyMessage =>
      'Xarid narxlari tarixi mahsulot kirimlari boʻyicha tuziladi';

  @override
  String purPricesSummary(String count, String spikes) {
    return 'Kirimi bor mahsulotlar: $count · 10% dan koʻp qimmatlashgan: $spikes';
  }

  @override
  String purProductNotFound(String code) {
    return '“$code” mahsuloti topilmadi';
  }

  @override
  String get purPurchasePrice => 'Xarid narxi';

  @override
  String get purQtyMoreThanZero => '0 dan katta';

  @override
  String get purQtyMoreThanZeroCap => '0 dan katta';

  @override
  String get purQtyWhole => 'butun son';

  @override
  String get purQtyWholeCap => 'Butun son';

  @override
  String get purReasonRequired => 'Sabab *';

  @override
  String get purRecalculate => 'Qayta hisoblash';

  @override
  String purReceiptNumber(String number) {
    return 'Kirim №$number';
  }

  @override
  String purReceiptPosted(String number, String amount) {
    return 'Kirim №$number $amount ga oʻtkazildi';
  }

  @override
  String purReceiveConfirmMessage(String count, String amount) {
    return 'Pozitsiyalar: $count, summasi $amount.\nQoldiqlar ortadi, taʼminotchiga qarz shu summaga oshadi.';
  }

  @override
  String get purReceiveConfirmTitle => 'Mahsulot qabul qilinsinmi?';

  @override
  String get purReceiveEnterQty =>
      'Kamida bitta pozitsiya boʻyicha qabul qilingan miqdorni kiriting';

  @override
  String get purReceiveGoods => 'Mahsulotni qabul qilish';

  @override
  String get purReceiveShort => 'Qabul qilish';

  @override
  String get purReceiveStaysOpen =>
      'Buyurtma ochiq qoladi — yetishmayotganini keyinroq qabul qilish mumkin.';

  @override
  String purReceiveTitle(String number) {
    return 'Buyurtma №$number boʻyicha qabul';
  }

  @override
  String get purReceiveWillClose =>
      'Buyurtma qabul qilingan sifatida yopiladi.';

  @override
  String purReceivedAmount(String amount) {
    return 'Qabul qilingan summa $amount';
  }

  @override
  String get purReceivedField => 'Qabul qilindi';

  @override
  String purReceivedOn(String date) {
    return 'qabul qilingan $date';
  }

  @override
  String get purReorderAssignSupplier =>
      'Taʼminotchisiz mahsulotlar uchun taʼminotchi tanlang';

  @override
  String purReorderConfirmHead(String count) {
    return 'Yaratiladigan qoralamalar: $count';
  }

  @override
  String purReorderConfirmLine(String name, String count) {
    return '• $name: $count poz.';
  }

  @override
  String get purReorderConfirmTitle => 'Buyurtmalar yaratilsinmi?';

  @override
  String purReorderCreated(String count) {
    return 'Buyurtma qoralamalari yaratildi: $count. Ularni “Buyurtmalar” boʻlimida tekshiring';
  }

  @override
  String get purReorderDaysInvalid => 'Zaxirani 1 dan 365 kungacha kiriting';

  @override
  String get purReorderDaysLabel => 'Zaxira, kun';

  @override
  String get purReorderEmpty => 'Buyurtma qilinadigan narsa yoʻq';

  @override
  String get purReorderEmptyMessage =>
      'Zaxiralar tanlangan davrga yetadi. Mahsulot kartochkalarida minimal qoldiqlarni belgilang.';

  @override
  String get purReorderHint =>
      'Oʻrtacha sarf 30 kunlik sotuvlar boʻyicha hisoblanadi; qoldiqlar, minimum va buyurtma qilinganlar hisobga olingan.';

  @override
  String get purReorderNothingSelected => 'Birorta ham pozitsiya tanlanmagan';

  @override
  String purReorderSkipped(String count) {
    return 'Taʼminotchisiz $count poz. oʻtkazib yuborildi';
  }

  @override
  String purRetailSuffix(String price) {
    return ' · chakana $price';
  }

  @override
  String purSalesPerDay(String value) {
    return 'sotuv/kun $value';
  }

  @override
  String get purSaveAndSend => 'Saqlash va yuborish';

  @override
  String get purSaveDraft => 'Qoralamani saqlash';

  @override
  String get purSearchOrder => 'Buyurtmani qidirish';

  @override
  String get purSelectOrder => 'Buyurtmani tanlang';

  @override
  String get purSelectOrderMessage =>
      'Chapdagi roʻyxatdan buyurtmani oching yoki yangisini yarating';

  @override
  String get purSelectSupplier => 'Taʼminotchini tanlang';

  @override
  String purSelectedCount(String count) {
    return 'Tanlangan pozitsiyalar: $count';
  }

  @override
  String get purShiftClosedNoCash =>
      'Smena yopiq — kassadan naqd pul berib boʻlmaydi';

  @override
  String get purSignatureCaption => 'imzo                         F.I.Sh.';

  @override
  String get purStampPlace => 'M.Oʻ.';

  @override
  String get purStatusCancelled => 'Bekor qilingan';

  @override
  String get purStatusDraft => 'Qoralama';

  @override
  String get purStatusOrdered => 'Buyurtma berilgan';

  @override
  String get purStatusPartial => 'Qisman qabul qilingan';

  @override
  String get purStatusReceived => 'Qabul qilingan';

  @override
  String purStockValue(String qty) {
    return 'qoldiq $qty';
  }

  @override
  String get purStore => 'Doʻkon';

  @override
  String get purSupplierAdded => 'Taʼminotchi qoʻshildi';

  @override
  String get purSupplierDeleted => 'Taʼminotchi oʻchirildi';

  @override
  String get purSupplierInvoiceNo => 'Taʼminotchi yuk xati №';

  @override
  String get purSupplierNotFound => 'Taʼminotchi topilmadi yoki oʻchirilgan';

  @override
  String get purSupplierRequired => 'Taʼminotchi *';

  @override
  String get purTabLedger => 'Hisob-kitoblar';

  @override
  String get purTabOrders => 'Buyurtmalar';

  @override
  String get purTabPayments => 'Toʻlovlar';

  @override
  String get purTabPrices => 'Xarid narxlari';

  @override
  String get purTabReorder => 'Avtobuyurtma';

  @override
  String get purTabSuppliers => 'Taʼminotchilar';

  @override
  String get purTaxId => 'STIR';

  @override
  String get purTaxIdInvalid => 'STIR — 9 dan 14 tagacha raqam';

  @override
  String purTaxIdValue(String taxId) {
    return 'STIR $taxId';
  }

  @override
  String get purTitle => 'Xaridlar';

  @override
  String purToPost(String amount) {
    return 'Kirim qilinadi: $amount';
  }

  @override
  String get purTurnover => 'Davr aylanmasi';

  @override
  String get purUrgent => 'Shoshilinch';

  @override
  String purWeOwe(String amount) {
    return 'Bizning qarz: $amount';
  }

  @override
  String get purZeroAll => 'Nolga tushirish';

  @override
  String get repAbcHintA => 'Asosiy tushum (birinchi 80%)';

  @override
  String get repAbcHintB => 'Oʻrtacha ulush (keyingi 15%)';

  @override
  String get repAbcHintC => 'Kichik ulush (oxirgi 5%)';

  @override
  String get repGiftSalesTitle => 'Sertifikat sotuvi (avans, tushum emas)';

  @override
  String get repGiftSalesHint =>
      'Sotilgan sertifikatlar uchun pul — avans. Ular mahsulot sertifikat bilan toʻlanganda tushumga kiradi.';

  @override
  String repGiftSalesSubtitle(String period, String sold, String voided) {
    return '$period · sotildi $sold, bekor qilindi $voided';
  }

  @override
  String get repColSold => 'Sotildi';

  @override
  String get repColVoided => 'Bekor qilindi';

  @override
  String get repGiftVoidedTooltip =>
      'Sotuv bekor qilinganda xaridorlarga qaytarildi';

  @override
  String get repPeriodLastMonth => 'Oʻtgan oy';

  @override
  String get repPeriodQuarter => 'Chorak';

  @override
  String get repPeriodCustom => 'Ixtiyoriy';

  @override
  String get repNoCategory => 'Kategoriyasiz';

  @override
  String get repNotSpecified => 'Koʻrsatilmagan';

  @override
  String get repNoReason => 'Sababsiz';

  @override
  String get repExportFolder => 'Hisobotlar';

  @override
  String repForecastTitle(String days) {
    return '$days kunlik talab prognozi va buyurtma';
  }

  @override
  String repAsOf(String date) {
    return '$date holatiga';
  }

  @override
  String get repColSalesPerDay => 'Kuniga sotuv';

  @override
  String get repColSalesPerDayTooltip =>
      '28 kunlik oʻrtacha (yangilari uchun — yaratilgandan beri, kamida 7 kun)';

  @override
  String get repColTrend7 => '7 kunlik trend';

  @override
  String get repColTrend7Tooltip =>
      'Oxirgi 7 kundagi sotuv surʼati oʻrtachaga nisbatan';

  @override
  String get repColCover => 'Yetadi';

  @override
  String get repColRunsOut => 'Tugaydi';

  @override
  String get repColToOrder => 'Buyurtma';

  @override
  String get repColOrderSum => 'Buyurtma summasi';

  @override
  String repDaysShort(String days) {
    return '$days kun';
  }

  @override
  String get repAlreadyOut => 'allaqachon yoʻq';

  @override
  String get repOutOfStock => 'Mavjud emas';

  @override
  String get repRisk => 'Xavf';

  @override
  String get repNormal => 'Meʼyor';

  @override
  String get repNoSalesShort => 'Sotuv yoʻq';

  @override
  String get repRunOutIn7 => '7 kunda tugaydi';

  @override
  String get repOutButWanted => 'Mavjud emas, lekin soʻraladi';

  @override
  String get repItemsToOrder => 'Buyurtma uchun pozitsiyalar';

  @override
  String get repOrderSumAtCost => 'Buyurtma summasi (tannarxda)';

  @override
  String get repForecastHow => 'Prognoz qanday hisoblanadi';

  @override
  String repForecastHelp(String horizon, String riskDays) {
    return '• Kuniga sotuv = oxirgi 28 kunda sotilgan (qaytarishlarsiz) ÷ 28. Yangi mahsulotlar uchun — qoʻshilgandan beri, lekin kamida 7 kun.\n• Yetadi = qoldiq ÷ kuniga sotuv.\n• Buyurtma = kuniga sotuv × $horizon kun + minimal qoldiq − joriy qoldiq.\n• “Xavf” — mahsulot yaqin $riskDays kun ichida tugaydi.';
  }

  @override
  String repNothingToOrder(String days) {
    return 'Buyurtma kerak emas — zaxira $days kunga yetadi';
  }

  @override
  String get repNoTrackedProducts =>
      'Qoldiq hisobi yuritiladigan mahsulot yoʻq';

  @override
  String get repOnlyToOrder => 'Faqat buyurtma kerak boʻlganlar';

  @override
  String get repGoToPurchasing => 'Xaridlarga oʻtish';

  @override
  String repInsQuoted(String name) {
    return '“$name”';
  }

  @override
  String repInsWeekExpl(String week, String prev) {
    return 'Oxirgi 7 kunda: $week, undan oldingi 7 kunda: $prev (qaytarishlar hisobga olingan sof tushum).';
  }

  @override
  String repInsRevenueUpTitle(String pct) {
    return 'Haftalik tushum $pct ga oshdi';
  }

  @override
  String repInsRevenueUpExpl(String base) {
    return '$base Ajoyib natija — ommabop mahsulotlar qoldigʻi yetarliligini tekshiring.';
  }

  @override
  String repInsRevenueDownTitle(String pct) {
    return 'Haftalik tushum $pct ga kamaydi';
  }

  @override
  String repInsRevenueDownExpl(String base) {
    return '$base Ommabop mahsulotlar borligini tekshiring va aksiya boshlang.';
  }

  @override
  String get repInsActLaunchPromo => 'Aksiya boshlash';

  @override
  String repInsOutOfStockOne(String name) {
    return 'Ommabop mahsulot tugadi: $name';
  }

  @override
  String repInsOutOfStockMany(String items) {
    return 'Sotuvi bor $items tugadi';
  }

  @override
  String repInsOutOfStockExpl(String names) {
    return '$names — qoldiq 0, lekin oxirgi 4 haftada ular sotilgan. Mahsulotsiz har bir kun — yoʻqotilgan tushum.';
  }

  @override
  String get repInsActOrderSupplier => 'Taʼminotchidan buyurtma';

  @override
  String repInsStockoutTitle(String name, String days) {
    return '$name ${days}dan keyin tugaydi';
  }

  @override
  String repInsStockoutExpl(
    String stock,
    String avg,
    String window,
    String reorder,
    String horizon,
  ) {
    return 'Qoldiq $stock, kuniga oʻrtacha $avg sotiladi ($window boʻyicha). ${horizon}ga $reorder buyurtma qilishni tavsiya qilamiz.';
  }

  @override
  String get repInsActPurchase => 'Xarid qilish';

  @override
  String get repInsStockoutMoreOne =>
      'Yana 1 ta mahsulot bir hafta ichida tugaydi';

  @override
  String repInsStockoutMoreMany(String items) {
    return 'Yana $items bir hafta ichida tugaydi';
  }

  @override
  String get repInsStockoutMoreExpl =>
      '“Talab prognozi” boʻlimiga qarang — u yerda buyurtma uchun tavsiya etilgan miqdor bor.';

  @override
  String repInsCategoryTitle(String name, String pct) {
    return '“$name” kategoriyasi foydaning $pct qismini beradi';
  }

  @override
  String repInsCategoryExpl(String profit, String total) {
    return '30 kunda: $total yalpi foydadan $profit. Bu kategoriyani doim mavjud va koʻzga koʻrinadigan joyda saqlang.';
  }

  @override
  String get repInsActOpenProducts => 'Mahsulotlarni ochish';

  @override
  String repInsLossTitle(String name) {
    return '$name zarariga sotilmoqda';
  }

  @override
  String repInsLowMarginTitle(String name) {
    return '$name marjasi 5% dan past';
  }

  @override
  String repInsMarginExpl(String revenue, String cost, String margin) {
    return '30 kunda: tushum $revenue, tannarx $cost, marja $margin%. Narxni oshiring yoki xarid narxi va chegirmalarni qayta koʻrib chiqing.';
  }

  @override
  String get repInsActChangePrice => 'Narxni oʻzgartirish';

  @override
  String repInsInactiveTitle(String customers) {
    return '$customers 60 kundan beri kelmadi — aksiya boshlang';
  }

  @override
  String get repInsInactiveExpl =>
      'Bu mijozlar avval xarid qilgan, lekin 60 kundan beri qaytmagan. Shaxsiy chegirma yoki bonuslar koʻpincha ularning 10–20% ini qaytaradi.';

  @override
  String get repInsActCreatePromo => 'Aksiya yaratish';

  @override
  String repInsDiscountsTitle(String pct) {
    return 'Chegirmalar tushumning $pct qismini oldi';
  }

  @override
  String repInsDiscountsExpl(String discounts, String subtotal) {
    return '30 kunda chegirmalar chegirmagacha boʻlgan $subtotal dan $discounts ni tashkil etdi. Aksiyalar va kassirlarning qoʻlda bergan chegirmalarini tekshiring (“Xodimlar” boʻlimi).';
  }

  @override
  String get repInsActCheckPromos => 'Aksiyalarni tekshirish';

  @override
  String repInsReturnsTitle(String pct) {
    return 'Qaytarishlar — sotuvning $pct';
  }

  @override
  String repInsReturnsExpl(String returns, String amount) {
    return '30 kunda $amount ga $returns. Chakana savdo uchun meʼyor — 3–5% gacha. Mahsulot sifati va qaytarish sabablarini tekshiring.';
  }

  @override
  String get repInsActOpenReceipts => 'Cheklarni ochish';

  @override
  String repInsPeakTitle(String from, String to) {
    return 'Eng band soatlar $from–$to — ikkinchi kassir qoʻying';
  }

  @override
  String repInsPeakExpl(String from, String to, String pct) {
    return '$from:00 dan $to:00 gacha 30 kunlik barcha cheklarning $pct qismi toʻgʻri keladi. Bu vaqtda ikkinchi kassir navbatlar va yoʻqotilgan sotuvlarni kamaytiradi.';
  }

  @override
  String get repInsActStaff => 'Xodimlar';

  @override
  String repInsDeadTitle(String items) {
    return '$items 60 kun davomida sotilmadi';
  }

  @override
  String repInsDeadExplCost(String amount) {
    return 'Ularda tannarx boʻyicha $amount muzlab qolgan. Pulni boʻshatish uchun narxni tushiring yoki aksiya qiling.';
  }

  @override
  String get repInsDeadExpl =>
      'Pul va javondagi joyni boʻshatish uchun narxni tushiring yoki aksiya qiling.';

  @override
  String get repInsActOpenInventory => 'Omborni ochish';

  @override
  String repInsOverdueTitle(String customers) {
    return 'Muddati oʻtgan qarzlar: $customers';
  }

  @override
  String repInsOverdueExpl(String amount) {
    return 'Muddati oʻtgan: $amount — bu qarzlarning toʻlov muddati oʻtdi. Mijozlarga eslating va qarz uzilguncha ularga qarzga sotmang.';
  }

  @override
  String get repInsActOpenCustomers => 'Mijozlarni ochish';

  @override
  String repInsTopTitle(String name) {
    return 'Hafta hiti — $name';
  }

  @override
  String repInsTopExpl(String amount, String pct) {
    return '7 kunda tushum $amount (barcha sotuvning $pct). U tugab qolmasligini kuzating.';
  }

  @override
  String get repInsActCheckStock => 'Qoldiqlarni tekshirish';

  @override
  String get repSevCritical => 'Shoshilinch';

  @override
  String get repSevWarning => 'Diqqat';

  @override
  String get repSevInfo => 'Maslahat';

  @override
  String get repSevPositive => 'Yaxshi';

  @override
  String get repInsightsIntro =>
      'Oxirgi 30 kunlik maʼlumotlaringiz boʻyicha maslahatlar. Ushbu qurilmada, internetsiz hisoblanadi; har biri raqamlar qayerdan olinganini tushuntiradi.';

  @override
  String get repRefresh => 'Yangilash';

  @override
  String get repInsightsEmptyTitle => 'Hozircha maslahat yoʻq';

  @override
  String get repInsightsEmptyMessage =>
      'Maslahatlar kamida bir haftalik sotuv yigʻilganda paydo boʻladi. Qoldiq, qarz va marja bilan muammolar topilmadi.';

  @override
  String get repByProducts => 'Mahsulotlar';

  @override
  String get repByCategories => 'Kategoriyalar';

  @override
  String get repSalesByCategory => 'Kategoriyalar boʻyicha sotuv';

  @override
  String get repColProducts => 'Mahsulotlar';

  @override
  String get repColQty => 'Miqdor';

  @override
  String get repColRevenue => 'Tushum';

  @override
  String get repColRevenueShare => 'Tushum ulushi';

  @override
  String get repProfitByCategory => 'Kategoriyalar boʻyicha foyda';

  @override
  String get repRevenueByCategory => 'Kategoriyalar boʻyicha tushum';

  @override
  String get repSalesByProduct => 'Mahsulotlar boʻyicha sotuv';

  @override
  String get repColShare => 'Ulush';

  @override
  String get repAbcTooltip =>
      'A — tushumning 80%, B — keyingi 15%, C — oxirgi 5%';

  @override
  String repAbcClass(String cls, String hint) {
    return '$cls sinfi — $hint';
  }

  @override
  String repProductsShort(String count) {
    return '$count ta mahsulot';
  }

  @override
  String repRevenueSharePct(String pct) {
    return 'tushumning $pct%';
  }

  @override
  String get repNoSales => 'Davrda sotuv yoʻq';

  @override
  String get repSearchProduct => 'Mahsulot qidirish';

  @override
  String get repNoDataForPeriod => 'Davr uchun maʼlumot yoʻq';

  @override
  String repShowMore(String shown, String total) {
    return 'Yana koʻrsatish ($total tadan $shown ta koʻrsatildi)';
  }

  @override
  String get repNoSort => 'Saralanmagan';

  @override
  String repSortBy(String column) {
    return 'Saralash: $column';
  }

  @override
  String get repCopyCsv => 'CSV nusxalash';

  @override
  String get repSaveCsv => 'CSV saqlash (Excel)';

  @override
  String get repSavePdf => 'PDF saqlash';

  @override
  String get repTableCopied => 'Jadval nusxalandi — Excel yoki xabarga joylang';

  @override
  String get repFileSaved => 'Fayl saqlandi';

  @override
  String get repCopyPath => 'Yoʻlni nusxalash';

  @override
  String get repNoSalesInPeriod => 'Tanlangan davrda sotuv yoʻq';

  @override
  String get repPickAnotherPeriod => 'Ekran tepasida boshqa davrni tanlang.';

  @override
  String repPrevPeriod(String amount) {
    return 'oldingi davr: $amount';
  }

  @override
  String get repNetRevenue => 'Sof tushum';

  @override
  String get repNetRevenueTooltip =>
      'Davrdagi sotuvlar minus qaytarishlar (bekor qilingan cheklar hisobga olinmaydi)';

  @override
  String get repReturns => 'Qaytarishlar';

  @override
  String repReturnsHint(String count, String pct) {
    return '$count ta · sotuvning $pct';
  }

  @override
  String get repDiscounts => 'Chegirmalar';

  @override
  String repDiscountsHint(String pct) {
    return '$pct — chegirmagacha summadan';
  }

  @override
  String get repReceipts => 'Cheklar';

  @override
  String repVoidedCount(String count) {
    return 'bekor qilingan: $count';
  }

  @override
  String get repNoVoids => 'bekor qilinganlar yoʻq';

  @override
  String get repAvgCheck => 'Oʻrtacha chek';

  @override
  String get repGrossProfit => 'Yalpi foyda';

  @override
  String get repGrossProfitTooltip =>
      'Sof tushum minus sotilgan mahsulot tannarxi (omborga qaytarishlar hisobga olingan)';

  @override
  String get repMargin => 'Marja';

  @override
  String repCostHint(String amount) {
    return 'tannarx: $amount';
  }

  @override
  String get repSalesByDay => 'Kunlar boʻyicha sotuv';

  @override
  String get repProfit => 'Foyda';

  @override
  String get repNetRevenueByDay => 'Kunlar boʻyicha sof tushum';

  @override
  String repTipNetRevenue(String amount) {
    return 'Sof tushum: $amount';
  }

  @override
  String repTipReceipts(String count) {
    return 'Cheklar: $count';
  }

  @override
  String repTipReturns(String amount) {
    return 'Qaytarishlar: $amount';
  }

  @override
  String get repSalesByHour => 'Soatlar boʻyicha sotuv';

  @override
  String get repHour => 'Soat';

  @override
  String get repReceiptsPerDay => 'Kuniga cheklar';

  @override
  String get repReceiptsPerDayTooltip =>
      'Kuniga shu soatdagi oʻrtacha cheklar soni';

  @override
  String get repReceiptsShare => 'Cheklar ulushi';

  @override
  String get repLoadByHour => 'Soatlar boʻyicha yuklama';

  @override
  String repPeak(String from, String to) {
    return 'Eng band: $from:00–$to:00';
  }

  @override
  String get repLoadByHourHint =>
      'Har soatda nechta chek urilishi — smenalar va ikkinchi kassirni rejalashtirishga yordam beradi.';

  @override
  String repTipReceiptsPerDay(String count, String perDay) {
    return 'Cheklar: $count (kuniga ≈$perDay)';
  }

  @override
  String repTipSales(String amount) {
    return 'Sotuvlar: $amount';
  }

  @override
  String get repByWeekday => 'Hafta kunlari boʻyicha';

  @override
  String repTipReceiptsLower(String count) {
    return 'cheklar: $count';
  }

  @override
  String get repTitle => 'Hisobotlar';

  @override
  String get repTabSales => 'Sotuvlar';

  @override
  String get repTabStaff => 'Xodimlar';

  @override
  String get repTabPayments => 'Toʻlovlar';

  @override
  String get repTabStock => 'Ombor';

  @override
  String get repTabForecast => 'Talab prognozi';

  @override
  String get repTabInsights => 'AI-tahlil';

  @override
  String get repForecastSubtitle => 'Oxirgi 28 kunlik sotuv boʻyicha';

  @override
  String get repLast30Days => 'Oxirgi 30 kun';

  @override
  String repPeriodTooltip(String period) {
    return 'Davr: $period';
  }

  @override
  String get repPeriodCustomMenu => 'Ixtiyoriy…';

  @override
  String get repPickPeriod => 'Davrni tanlang';

  @override
  String get repFrom => 'Dan';

  @override
  String get repTo => 'Gacha';

  @override
  String get repWdMon => 'Du';

  @override
  String get repWdTue => 'Se';

  @override
  String get repWdWed => 'Ch';

  @override
  String get repWdThu => 'Pa';

  @override
  String get repWdFri => 'Ju';

  @override
  String get repWdSat => 'Sh';

  @override
  String get repWdSun => 'Ya';

  @override
  String get repDeltaNew => 'yangi';

  @override
  String get repSalesByCashier => 'Kassirlar boʻyicha sotuv';

  @override
  String get repSalesBySeller => 'Sotuvchilar boʻyicha sotuv';

  @override
  String get repStaffDiscountsTooltip =>
      'Xodim cheklaridagi chegirmalar summasi va chegirmagacha summadan ulushi';

  @override
  String get repStaffReturnsTooltip =>
      'Davr ichida rasmiylashtirilgan ushbu xodim cheklari boʻyicha qaytarishlar';

  @override
  String get repColVoidedShort => 'Bekor q.';

  @override
  String get repVoidedReceipts => 'Bekor qilingan cheklar';

  @override
  String get repCashiers => 'Kassirlar';

  @override
  String get repSellers => 'Sotuvchilar';

  @override
  String get repNetRevenueByStaff => 'Xodimlar boʻyicha sof tushum';

  @override
  String get repPaymentsByMethod => 'Toʻlov usullari boʻyicha';

  @override
  String get repColReceived => 'Olindi';

  @override
  String get repColRefunded => 'Qaytarildi';

  @override
  String get repPaymentsStructure => 'Toʻlovlar tarkibi';

  @override
  String get repNoPayments => 'Davrda toʻlovlar yoʻq';

  @override
  String get repCustomerDebts => 'Mijozlar qarzlari';

  @override
  String get repDebtIssued => 'Qarzga berildi';

  @override
  String get repDebtCollected => 'Toʻlandi';

  @override
  String get repDebtAdjusted => 'Tuzatishlar (qaytarishlar, bekor qilishlar)';

  @override
  String get repDebtChange => 'Davrdagi qarz oʻzgarishi';

  @override
  String repDebtOutstanding(String count) {
    return 'Mijozlarning joriy qarzi ($count)';
  }

  @override
  String get repStockByCategory => 'Kategoriyalar boʻyicha qoldiqlar (hozirgi)';

  @override
  String get repColPositions => 'Pozitsiyalar';

  @override
  String get repColAtCost => 'Tannarxda';

  @override
  String get repColAtRetail => 'Chakana narxda';

  @override
  String get repColPotentialProfit => 'Taxminiy foyda';

  @override
  String get repPositionsInStock => 'Mavjud pozitsiyalar';

  @override
  String repCategoriesCount(String count) {
    return 'kategoriyalar: $count';
  }

  @override
  String get repStockAtCost => 'Ombor tannarxda';

  @override
  String get repStockAtCostTooltip =>
      'Ombordagi mahsulotga qancha pul sarflangan';

  @override
  String get repStockAtCostHint => 'mahsulotga sarflangan';

  @override
  String get repStockAtRetail => 'Ombor chakana narxda';

  @override
  String get repStockAtRetailHint => 'hammasi joriy narxda sotilsa';

  @override
  String get repPotentialProfit => 'Taxminiy foyda';

  @override
  String repAvgMarkup(String pct) {
    return 'oʻrtacha ustama $pct';
  }

  @override
  String get repNoStock => 'Omborda musbat qoldiqli mahsulot yoʻq';

  @override
  String repDeadStockTitle(String days) {
    return 'Sotilmayotgan mahsulot: $days kun sotuv yoʻq';
  }

  @override
  String get repColFrozen => 'Muzlab qolgan';

  @override
  String get repColLastSale => 'Oxirgi sotuv';

  @override
  String get repNeverSold => 'sotilmagan';

  @override
  String get repNoDeadStock => 'Ajoyib — sotilmay qolgan mahsulot yoʻq';

  @override
  String repDeadStockHint(String days) {
    return '$days kun davomida sotilmagan qoldiqli mahsulotlar. Narxni tushiring, aksiya qiling yoki taʼminotchiga qaytaring.';
  }

  @override
  String get repWriteOffsByReason => 'Sabablar boʻyicha hisobdan chiqarish';

  @override
  String get repColOperations => 'Operatsiyalar';

  @override
  String get repNoWriteOffs => 'Davrda hisobdan chiqarish yoʻq';

  @override
  String get salesStatusCompleted => 'Oʻtkazilgan';

  @override
  String get salesStatusPartial => 'Qisman qaytarilgan';

  @override
  String get salesStatusReturned => 'Qaytarilgan';

  @override
  String get salesStatusHeld => 'Kechiktirilgan';

  @override
  String get salesPeriodWeek => '7 kun';

  @override
  String get salesPeriodAll => 'Butun davr';

  @override
  String get salesPeriodCustom => 'Davr…';

  @override
  String get salesRefundHintCash => 'Pulni kassadan berish';

  @override
  String get salesRefundHintCard => 'Terminal orqali kartaga qaytarish';

  @override
  String get salesRefundHintTransfer => 'Oʻtkazma orqali qaytarish';

  @override
  String get salesRefundHintDebt => 'Mijoz qarzini kamaytirish';

  @override
  String get salesRefundHintBonus => 'Mijozning bonus hisobiga oʻtkazish';

  @override
  String salesReturnPeriodExpired(String days) {
    return 'Qaytarish muddati ($days kun) tugagan';
  }

  @override
  String get salesVoidAlready => 'Chek allaqachon bekor qilingan';

  @override
  String get salesVoidOnlyNoReturns =>
      'Faqat qaytarishsiz chekni bekor qilish mumkin';

  @override
  String get salesVoidShiftClosed =>
      'Chek smenasi yopilgan — qaytarishni rasmiylashtiring';

  @override
  String get salesVoidOtherShift =>
      'Chek boshqa smenadan — qaytarishni rasmiylashtiring';

  @override
  String get salesReasonDefect => 'Nuqsonli';

  @override
  String get salesReasonNotFit => 'Toʻgʻri kelmadi';

  @override
  String get salesReasonCashierError => 'Kassir xatosi';

  @override
  String get salesReasonOther => 'Boshqa';

  @override
  String get salesPickPeriod => 'Davrni tanlang';

  @override
  String salesSlipTitle(String number) {
    return 'TOVARNI QAYTARISH DALOLATNOMASI №$number';
  }

  @override
  String get salesSlipBySale => 'Chek boʻyicha';

  @override
  String salesSlipSaleRef(String number, String date) {
    return '№$number, $date';
  }

  @override
  String get salesSlipBuyer => 'Xaridor';

  @override
  String get salesSlipMethod => 'Qaytarish usuli';

  @override
  String get salesSlipRestock => 'Omborga';

  @override
  String get salesSlipYes => 'ha';

  @override
  String get salesSlipNoRestock => 'yoʻq (nuqsonli / sotuvga yaroqsiz)';

  @override
  String get salesSlipQty => 'Miqdor';

  @override
  String salesSlipTotal(String amount) {
    return 'Jami qaytariladi: $amount';
  }

  @override
  String salesSlipIssued(String name) {
    return 'Berdi: $name ____________';
  }

  @override
  String get salesSlipReceived => 'Oldi: ____________';

  @override
  String salesSlipJobName(String number) {
    return 'Qaytarish $number';
  }

  @override
  String salesReturnWizardTitle(String number) {
    return 'Chek №$number boʻyicha qaytarish';
  }

  @override
  String salesNotMore(String qty) {
    return 'Koʻpi bilan $qty';
  }

  @override
  String get salesIntegerOnly => 'Faqat butun son';

  @override
  String get salesCheckQty => 'Belgilangan qatorlardagi miqdorni tekshiring';

  @override
  String get salesSelectItems => 'Qaytarish uchun mahsulot va miqdorni tanlang';

  @override
  String get salesEnterReason => 'Qaytarish sababini koʻrsating';

  @override
  String get salesOpenShiftForCash => 'Naqd qaytarish uchun smenani oching';

  @override
  String get salesConfirmReturnTitle => 'Qaytarish rasmiylashtirilsinmi?';

  @override
  String salesConfirmReturnMessage(
    String method,
    String amount,
    String count,
    String restock,
  ) {
    return '$method: $amount\nPozitsiyalar: $count. $restock';
  }

  @override
  String get salesRestockYes => 'Mahsulot omborga qaytadi.';

  @override
  String get salesRestockNo => 'Mahsulot omborga QAYTMAYDI.';

  @override
  String get salesDoReturn => 'Qaytarishni rasmiylashtirish';

  @override
  String get salesAllReturned => 'Barcha mahsulotlar allaqachon qaytarilgan';

  @override
  String salesReturnExpiredBanner(String reason, String date) {
    return '$reason. $date sanali chek boʻyicha qaytarish mumkin emas — nuqson uchun kafolat arizasini rasmiylashtiring.';
  }

  @override
  String get salesWhatToReturn => 'Nima qaytariladi';

  @override
  String get salesReturnAll => 'Hammasini qaytarish';

  @override
  String get salesHowToRefund => 'Pulni qanday qaytarish';

  @override
  String get salesNoShiftNoCash =>
      'Smena ochilmagan — naqd qaytarish mumkin emas';

  @override
  String salesDebtExcess(String debt, String excess) {
    return 'Mijoz qarzi $debt — ortiqcha $excess mijoz avansiga aylanadi';
  }

  @override
  String salesPaidList(String list) {
    return 'Toʻlangan: $list';
  }

  @override
  String get salesRestockTitle => 'Mahsulotni omborga qaytarish';

  @override
  String get salesRestockOn => 'Qoldiq qaytarilgan miqdorga oshadi';

  @override
  String get salesRestockOff =>
      'Mahsulot qoldiqqa qaytmaydi (nuqson). Qaytarishdan keyin kafolat arizasini rasmiylashtirish mumkin';

  @override
  String get salesReasonLabel => 'Qaytarish sababi *';

  @override
  String get salesReasonRequired => 'Sababni koʻrsating';

  @override
  String salesBonusClawback(String amount) {
    return 'Mijozdan $amount gacha hisoblangan bonus yechiladi';
  }

  @override
  String get salesToRefund => 'Qaytariladi';

  @override
  String salesBought(String qty) {
    return 'sotib olingan $qty';
  }

  @override
  String salesReturnedQty(String qty) {
    return 'qaytarilgan $qty';
  }

  @override
  String salesPaidAmount(String amount) {
    return 'toʻlangan $amount';
  }

  @override
  String get salesLess => 'Kamroq';

  @override
  String get salesMore => 'Koʻproq';

  @override
  String salesOfQty(String qty) {
    return '$qty dan';
  }

  @override
  String get salesReceiptNotFound => 'Chek topilmadi';

  @override
  String get salesReceiptVoided => 'Chek bekor qilingan';

  @override
  String get salesReceiptCopy => 'Chek nusxasi';

  @override
  String get salesReceiptText => 'Chek matni';

  @override
  String get salesVoid => 'Chekni bekor qilish';

  @override
  String salesReturnsSection(String count) {
    return 'Qaytarishlar ($count)';
  }

  @override
  String salesReceiptNo(String number) {
    return 'Chek №$number';
  }

  @override
  String salesShiftNo(String number) {
    return 'smena №$number';
  }

  @override
  String salesVoidedReason(String reason) {
    return 'Bekor qilingan: $reason';
  }

  @override
  String get salesParticipants => 'Ishtirokchilar';

  @override
  String get salesSeller => 'Sotuvchi';

  @override
  String get salesNoCustomer => 'mijozsiz';

  @override
  String get salesPromoCode => 'Promokod';

  @override
  String salesItemsSection(String count) {
    return 'Mahsulotlar ($count)';
  }

  @override
  String get salesSubtotal => 'Chegirmasiz summa';

  @override
  String get salesVatIncluded => 'shu jumladan QQS';

  @override
  String get salesBonusEarned => 'Hisoblangan bonuslar';

  @override
  String get salesRefunded => 'Qaytarilgan';

  @override
  String get salesReceiptTextCopied => 'Chek matni nusxalandi';

  @override
  String get salesCopy => 'Nusxalash';

  @override
  String salesVoidPromptTitle(String number) {
    return 'Chek №${number}ni bekor qilish';
  }

  @override
  String get salesReasonRequiredLabel => 'Sabab *';

  @override
  String get salesVoidConfirmTitle => 'Chek bekor qilinsinmi?';

  @override
  String salesVoidConfirmMessage(String number, String amount) {
    return 'Chek №$number ($amount) toʻliq bekor qilinadi: mahsulot omborga qaytadi, toʻlov — dastlabki usullar boʻyicha. Amalni ortga qaytarib boʻlmaydi.';
  }

  @override
  String salesVoidDone(String number) {
    return 'Chek №$number bekor qilindi';
  }

  @override
  String salesReturnDoneTitle(String number) {
    return 'Qaytarish №$number rasmiylashtirildi';
  }

  @override
  String get salesNotRestockedHint =>
      'Mahsulot omborga qaytarilmadi. Agar bu kafolatli nuqson boʻlsa — kafolat arizasini rasmiylashtiring.';

  @override
  String get salesWarrantyClaim => 'Kafolat arizasi';

  @override
  String get salesReturnSlip => 'Qaytarish dalolatnomasi';

  @override
  String salesItemDiscount(String amount) {
    return 'chegirma $amount';
  }

  @override
  String salesItemWarranty(String date) {
    return 'kafolat $date gacha';
  }

  @override
  String salesReturnHeader(String number, String date) {
    return 'Qaytarish №$number · $date';
  }

  @override
  String get salesToStock => 'omborga';

  @override
  String get salesNoRestock => 'omborga qaytarilmasdan';

  @override
  String salesReasonValue(String reason) {
    return 'Sabab: $reason';
  }

  @override
  String salesReceiptNoNotFound(String number) {
    return 'Chek №$number topilmadi';
  }

  @override
  String get salesTitle => 'Cheklar';

  @override
  String get salesSubtitle => 'Sotuvlar tarixi va qaytarishlar';

  @override
  String get salesTabReturns => 'Qaytarishlar';

  @override
  String get salesNoShiftReceipts =>
      'Smena ochilmagan. Siz faqat joriy smena cheklarini koʻrasiz.';

  @override
  String salesShiftReceipts(String number) {
    return 'Joriy smena №$number cheklari koʻrsatilgan';
  }

  @override
  String get salesSelectReceipt => 'Chekni tanlang';

  @override
  String get salesSelectReceiptHint =>
      'Bu yerda chek tarkibi, toʻlovlar, qaytarishlar va amallar chiqadi';

  @override
  String get salesNoReceipts => 'Cheklar topilmadi';

  @override
  String get salesNoReceiptsFiltered =>
      'Qidiruv shartlarini oʻzgartiring yoki filtrlarni tozalang';

  @override
  String get salesNoSalesInShift => 'Joriy smenada hali sotuvlar yoʻq';

  @override
  String get salesNoSalesInPeriod => 'Tanlangan davrda sotuvlar yoʻq';

  @override
  String get salesResetFilters => 'Filtrlarni tozalash';

  @override
  String get salesShowAllTime => 'Butun davr uchun koʻrsatish';

  @override
  String get salesShowMore => 'Yana koʻrsatish';

  @override
  String get salesSearchHint => 'Chek raqami, mijoz yoki mahsulot';

  @override
  String get salesAnyFem => 'Istalgan';

  @override
  String get salesReceiptsLabel => 'Cheklar';

  @override
  String get salesSalesLabel => 'Sotuvlar';

  @override
  String get salesVoidedLabel => 'Bekor qilingan';

  @override
  String salesPositionsShort(String n) {
    return '$n poz.';
  }

  @override
  String get salesNoReturns => 'Qaytarishlar yoʻq';

  @override
  String get salesChangeSearch => 'Qidiruv shartlarini oʻzgartiring';

  @override
  String get salesNoReturnsHint =>
      'Qaytarishlar “Cheklar” boʻlimidagi chek kartasidan rasmiylashtiriladi';

  @override
  String salesReturnTitle(String number, String sale) {
    return 'Qaytarish №$number · chek №$sale';
  }

  @override
  String get salesReturnsSearchHint => 'Raqam, mijoz yoki sabab';

  @override
  String get salesMethodLabel => 'Usul';

  @override
  String get salesAnyMasc => 'Istalgan';

  @override
  String get salesNoShiftReturns =>
      'Smena ochilmagan. Siz faqat joriy smena qaytarishlarini koʻrasiz.';

  @override
  String salesShiftReturns(String number) {
    return 'Joriy smena №$number qaytarishlari koʻrsatilgan';
  }

  @override
  String get salesReturnsCountLabel => 'Qaytarishlar';

  @override
  String get salesSumLabel => 'Summasi';

  @override
  String get salesSelectReturn => 'Qaytarishni tanlang';

  @override
  String get salesSelectReturnHint =>
      'Bu yerda chek, qaytarish tarkibi va chop etish uchun dalolatnoma chiqadi';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsNoAccess => 'Ruxsat yoʻq';

  @override
  String get settingsNoAccessMessage =>
      'Sozlamalarni faqat egasi yoki administrator oʻzgartira oladi.';

  @override
  String get settingsSecStore => 'Doʻkon';

  @override
  String get settingsSecStoreHint => 'Nomi, rekvizitlar, chek';

  @override
  String get settingsSecCurrency => 'Valyuta va soliqlar';

  @override
  String get settingsSecCurrencyHint => 'Hisob valyutasi, QQS';

  @override
  String get settingsSecSales => 'Sotuvlar';

  @override
  String get settingsSecSalesHint => 'Smenalar, qaytarishlar, toʻlov';

  @override
  String get settingsSecLoyalty => 'Sodiqlik';

  @override
  String get settingsSecLoyaltyHint => 'Bonus dasturi';

  @override
  String get settingsSecDevices => 'Kassalar va qurilmalar';

  @override
  String get settingsSecDevicesHint => 'Kassalar, printer, skaner';

  @override
  String get settingsSecAppearance => 'Koʻrinish';

  @override
  String get settingsSecAppearanceHint => 'Yorugʻ va qorongʻi mavzu';

  @override
  String get settingsSecBackup => 'Zaxira nusxa';

  @override
  String get settingsSecBackupHint => 'Nusxalar va tiklash';

  @override
  String get settingsSecData => 'Maʼlumotlar';

  @override
  String get settingsSecDataHint => 'Demo rejim, eksport';

  @override
  String get settingsSecAbout => 'Dastur haqida';

  @override
  String get settingsSecAboutHint => 'Versiya, litsenziya, yordam';

  @override
  String get settingsDiscardTitle => 'Oʻzgarishlar bekor qilinsinmi?';

  @override
  String get settingsDiscardMessage =>
      'Boʻlimda saqlanmagan oʻzgarishlar bor. Chiqib ketsangiz, ular yoʻqoladi.';

  @override
  String get settingsDiscardOk => 'Saqlamaslik';

  @override
  String get settingsUnsavedBar =>
      'Saqlanmagan oʻzgarishlar bor (Ctrl+S — saqlash)';

  @override
  String get settingsCancelVerb => 'Bekor qilish';

  @override
  String get settingsSaved => 'Sozlamalar saqlandi';

  @override
  String settingsSwitchOn(String title) {
    return '“$title” — yoqildi';
  }

  @override
  String settingsSwitchOff(String title) {
    return '“$title” — oʻchirildi';
  }

  @override
  String get settingsCopied => 'Nusxalandi';

  @override
  String settingsErrPercentRange(String min, String max) {
    return '$min dan $max gacha qiymat kiriting';
  }

  @override
  String get settingsErrPercentNumber => 'Son kiriting, masalan 2 yoki 2,5';

  @override
  String settingsErrPercentAllowed(String min, String max) {
    return 'Ruxsat etilgan: $min dan $max % gacha';
  }

  @override
  String get settingsErrTwoDecimals => 'Verguldan keyin koʻpi bilan ikki raqam';

  @override
  String get settingsErrReturnDaysEmpty =>
      'Kunlar sonini kiriting (0 — cheklovsiz)';

  @override
  String get settingsErrReturnDaysInt => 'Butun kunlar sonini kiriting';

  @override
  String get settingsErrNotNegative => 'Manfiy boʻlishi mumkin emas';

  @override
  String get settingsErrReturnDaysMax => 'Koʻpi bilan 3650 kun (10 yil)';

  @override
  String get settingsErrStoreNameRequired =>
      'Doʻkon nomi majburiy — u chekda chop etiladi';

  @override
  String settingsErrMaxLength(String max) {
    return 'Koʻpi bilan $max belgi';
  }

  @override
  String get settingsErrPhoneChars =>
      'Faqat raqamlar, boʻsh joy, +, - va qavslar';

  @override
  String get settingsErrPhoneDigits =>
      'Raqamni tekshiring: 5 dan 15 gacha raqam';

  @override
  String get settingsErrTaxIdDigits => 'STIR faqat raqamlardan iborat';

  @override
  String get settingsErrTaxIdLength =>
      'STIR 9 dan 14 gacha raqamdan iborat boʻlishi kerak';

  @override
  String get settingsErrFooterLines => 'Koʻpi bilan 6 qator';

  @override
  String settingsErrBanknoteNotNumber(String value) {
    return '“$value” — son emas. Kasr qismini nuqta bilan yozing';
  }

  @override
  String settingsErrBanknoteNoFraction(String value, String code) {
    return '“$value”: $code da kasr birliklar yoʻq';
  }

  @override
  String settingsErrBanknoteTooManyDecimals(String value) {
    return '“$value”: nuqtadan keyin raqamlar juda koʻp';
  }

  @override
  String settingsErrBanknotePositive(String value) {
    return '“$value” — nominal noldan katta boʻlishi kerak';
  }

  @override
  String settingsErrBanknoteTooBig(String value) {
    return '“$value” — nominal juda katta';
  }

  @override
  String settingsErrBanknoteDuplicate(String value) {
    return '“$value” nominali ikki marta koʻrsatilgan';
  }

  @override
  String settingsErrBanknotesMax(String max) {
    return 'Koʻpi bilan $max ta nominal — tugmalar ekranga sigʻishi kerak';
  }

  @override
  String get settingsErrRegisterNameEmpty => 'Kassa nomini kiriting';

  @override
  String get settingsErrRegisterDuplicate =>
      'Bunday nomli kassa allaqachon bor';

  @override
  String get settingsCurrencyLocked =>
      'Valyutani oʻzgartirib boʻlmaydi: bazada sotuvlar bor';

  @override
  String get settingsRegisterBusy =>
      'Bu kassada smena ochiq. Avval smenani yoping, keyin kassani faolsizlantiring yoki oʻchiring.';

  @override
  String get settingsRoundingNone => 'Yaxlitlamasdan';

  @override
  String settingsRoundingStep(String amount) {
    return '$amount ga karrali';
  }

  @override
  String settingsLoyaltyExample(
    String purchase,
    String earned,
    String symbol,
    String percent,
    String redeem,
  ) {
    return '$purchase miqdoridagi xariddan $earned bonus hisoblanadi (1 bonus = 1 $symbol). Bonuslar bilan chekning $percent% igacha — $redeem gacha toʻlash mumkin.';
  }

  @override
  String settingsBytes(String n) {
    return '$n B';
  }

  @override
  String settingsKilobytes(String n) {
    return '$n KB';
  }

  @override
  String settingsMegabytes(String n) {
    return '$n MB';
  }

  @override
  String settingsGigabytes(String n) {
    return '$n GB';
  }

  @override
  String get settingsSampleCashier => 'Namuna';

  @override
  String get settingsSampleItemMilk => 'Sut 2,5% 1 l';

  @override
  String get settingsSampleItemBread => 'Oq non';

  @override
  String get settingsSampleItemTea => 'Qora choy 100 g';

  @override
  String settingsDiagPlatform(String value) {
    return 'Platforma: $value';
  }

  @override
  String settingsDiagStore(String value) {
    return 'Doʻkon: $value';
  }

  @override
  String settingsCurrencyValue(String value) {
    return 'Valyuta: $value';
  }

  @override
  String settingsDiagDemo(String value) {
    return 'Demo rejim: $value';
  }

  @override
  String get settingsYesLower => 'ha';

  @override
  String get settingsNoLower => 'yoʻq';

  @override
  String settingsDiagDbSize(String value) {
    return 'Baza hajmi: $value';
  }

  @override
  String settingsDiagProducts(String value) {
    return 'Mahsulotlar: $value';
  }

  @override
  String settingsDiagSales(String value) {
    return 'Sotuvlar: $value';
  }

  @override
  String settingsDiagCustomers(String value) {
    return 'Mijozlar: $value';
  }

  @override
  String settingsDiagUsers(String value) {
    return 'Xodimlar: $value';
  }

  @override
  String settingsDiagLastBackup(String value) {
    return 'Oxirgi zaxira nusxa: $value';
  }

  @override
  String settingsDiagGenerated(String value) {
    return 'Tuzilgan: $value';
  }

  @override
  String get settingsErrBackupFailed => 'Zaxira nusxani yaratib boʻlmadi';

  @override
  String settingsErrNotBackup(String name) {
    return '“$name” fayli DreamPOS zaxira nusxasi emas';
  }

  @override
  String get settingsCsvName => 'Nomi';

  @override
  String get settingsCsvMinStock => 'Min. qoldiq';

  @override
  String get settingsCsvVatPercent => 'QQS %';

  @override
  String get settingsCsvActive => 'Faol';

  @override
  String get settingsCsvCard => 'Karta';

  @override
  String get settingsCsvDiscountPercent => 'Chegirma %';

  @override
  String get settingsCsvDebtLimit => 'Qarz limiti';

  @override
  String get settingsCsvTotalSpent => 'Xaridlar summasi';

  @override
  String get settingsCsvVisits => 'Tashriflar';

  @override
  String settingsVersion(String version) {
    return 'Versiya $version';
  }

  @override
  String get settingsAboutTagline =>
      'Chakana doʻkonlar uchun kassa va hisob. Internetsiz ishlaydi.';

  @override
  String get settingsLicense => 'Litsenziya';

  @override
  String get settingsPlan => 'Tarif: “Doʻkon” (1 savdo nuqtasi)';

  @override
  String get settingsTrialExpired => 'Sinov muddati tugadi';

  @override
  String get settingsTrial => 'Sinov muddati';

  @override
  String get settingsTrialEnded =>
      'Sinov muddati tugadi. Uzaytirish uchun qoʻllab-quvvatlash xizmatiga murojaat qiling — maʼlumotlar saqlangan.';

  @override
  String settingsTrialLeft(int count, String total, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$total kundan $count kun qoldi · oʻrnatilgan: $date',
    );
    return '$_temp0';
  }

  @override
  String get settingsSupport => 'Qoʻllab-quvvatlash xizmati';

  @override
  String get settingsSupportHint =>
      'Qoʻllab-quvvatlashga murojaat qilganda quyidagi maʼlumotlarni ilova qiling — ular muammoni tezroq hal qilishga yordam beradi. Mijozlarning shaxsiy maʼlumotlari ularga kirmaydi.';

  @override
  String get settingsInfoCopied => 'Maʼlumotlar nusxalandi';

  @override
  String get settingsCopyInfo => 'Maʼlumotlarni nusxalash';

  @override
  String get settingsRefresh => 'Yangilash';

  @override
  String get settingsAppearanceDesc =>
      'Bezak mavzusi ushbu dasturning barcha ekranlarida darhol qoʻllanadi.';

  @override
  String get settingsTheme => 'Mavzu';

  @override
  String get settingsThemeAuto => 'Avto';

  @override
  String get settingsThemeLight => 'Yorugʻ';

  @override
  String get settingsThemeDark => 'Qorongʻi';

  @override
  String get settingsThemeHint =>
      '“Avto” — Windows/Android sozlamalaridagidek. Qorongʻi mavzu kechki smenada koʻzni kamroq charchatadi va OLED ekranli telefonlarda quvvatni tejaydi. Yorugʻ mavzu savdo zalining yorqin yoritilishida yaxshiroq oʻqiladi.';

  @override
  String settingsBackupCreated(String name, String size) {
    return 'Nusxa yaratildi: $name ($size)';
  }

  @override
  String get settingsBackupDeleteTitle => 'Nusxa oʻchirilsinmi?';

  @override
  String settingsBackupDeleteMessage(String name, String date, String size) {
    return '$name\n$date · $size\n\nFayl diskdan qayta tiklash imkoniyatisiz oʻchiriladi.';
  }

  @override
  String get settingsBackupDeleted => 'Nusxa oʻchirildi';

  @override
  String get settingsRestoreTitle => 'Maʼlumotlar nusxadan tiklansinmi?';

  @override
  String settingsRestoreMessage(String date) {
    return '$date sanasidagi nusxa BARCHA joriy maʼlumotlarni almashtiradi: mahsulotlar, sotuvlar, mijozlar, smenalar va sozlamalar. Shu sanadan keyin qilingan hamma narsa yoʻqoladi.\n\nTiklashdan oldin joriy maʼlumotlarning nusxasi avtomatik yaratiladi.\n\nMaʼlumotlar dastur keyingi safar ishga tushganda almashtiriladi.';
  }

  @override
  String get settingsRestore => 'Tiklash';

  @override
  String get settingsRestartTitle => 'Dasturni qayta ishga tushiring';

  @override
  String get settingsRestartMessage =>
      'Tiklash tayyorlandi.\n\n1. Ushbu kompyuterda DreamPOSni yoping.\n2. Dasturni qayta ishga tushiring — maʼlumotlar nusxa bilan almashtiriladi.\n3. Kiring va mahsulotlar hamda oxirgi sotuvlarni tekshiring.\n\nQayta ishga tushirishgacha sotuv oʻtkazmang: ular yoʻqoladi.';

  @override
  String get settingsGotIt => 'Tushunarli';

  @override
  String get settingsRestoreCancelled => 'Tiklash bekor qilindi';

  @override
  String get settingsBackupDesc =>
      'Maʼlumotlar bazasining nusxasi kompyuter buzilganda, virus yoki xatolik tufayli maʼlumotlar yoʻqolishidan himoya qiladi. Nusxalarni fleshka yoki bulutda ham saqlang.';

  @override
  String get settingsRestorePending =>
      'Nusxadan tiklash tayyorlandi. Maʼlumotlarni almashtirish uchun dasturni qayta ishga tushiring.';

  @override
  String get settingsLastBackup => 'Oxirgi nusxa';

  @override
  String get settingsNeverBackedUp => 'hali yaratilmagan';

  @override
  String get settingsBackupWeekly =>
      'Nusxani kamida haftada bir marta yaratishni tavsiya qilamiz';

  @override
  String get settingsBackupCreateNow => 'Hozir nusxa yaratish';

  @override
  String get settingsAutoBackup => 'Har kungi avtomatik nusxa';

  @override
  String get settingsAutoBackupHint =>
      'Dastur ishga tushganda kuniga bir marta yaratiladi';

  @override
  String get settingsBackupFolder => 'Nusxalar papkasi';

  @override
  String get settingsCopyPath => 'Yoʻlni nusxalash';

  @override
  String get settingsPathCopied => 'Yoʻl nusxalandi';

  @override
  String get settingsBackups => 'Nusxalar';

  @override
  String get settingsNoBackups =>
      'Hozircha nusxalar yoʻq. “Hozir nusxa yaratish” tugmasini bosing.';

  @override
  String get settingsRestoreInfo =>
      'Tiklash dasturning barcha maʼlumotlarini nusxa tarkibi bilan almashtiradi va qayta ishga tushirishni talab qiladi. Tiklashdan oldin joriy maʼlumotlarning nusxasi avtomatik yaratiladi.';

  @override
  String get settingsCurUzs => 'Oʻzbek soʻmi';

  @override
  String get settingsCurTjs => 'Tojik somonisi';

  @override
  String get settingsCurKzt => 'Qozogʻiston tengesi';

  @override
  String get settingsCurKgs => 'Qirgʻiz somi';

  @override
  String get settingsCurRub => 'Rossiya rubli';

  @override
  String get settingsCurUsd => 'AQSH dollari';

  @override
  String settingsCurChangeTitle(String code) {
    return 'Valyuta $code ga almashtirilsinmi?';
  }

  @override
  String settingsCurChangeSymbol(String symbol) {
    return 'Barcha summalar “$symbol” da koʻrsatiladi.';
  }

  @override
  String settingsCurChangeRescale(String products, String from, String to) {
    return 'Diqqat: sizda allaqachon mahsulotlar kiritilgan: $products. Narxlar eng kichik birliklarda saqlanadi, shuning uchun $from narx $to boʻladi. Valyutani almashtirgandan keyin narxlarni tekshiring va tuzating.';
  }

  @override
  String get settingsCurChangeResetsCash =>
      'Tezkor toʻlov kupyura nominallari va naqd pulni yaxlitlash yangi valyuta uchun standart qiymatlarga qaytariladi (“Sotuvlar” boʻlimi).';

  @override
  String get settingsCurChangeFinal =>
      'Birinchi sotuvdan keyin valyutani oʻzgartirib boʻlmaydi.';

  @override
  String get settingsCurChangeOk => 'Valyutani almashtirish';

  @override
  String get settingsCurrencyDesc =>
      'Hisob yuritiladigan valyuta va yangi mahsulotlar uchun standart QQS stavkasi.';

  @override
  String get settingsCurBase => 'Hisob valyutasi';

  @override
  String get settingsCurLockedTooltip =>
      'Valyuta birinchi sotuvdan keyin qatʼiylashtirilgan';

  @override
  String get settingsCurLockedBanner =>
      'Valyuta qatʼiylashtirilgan: bazada sotuvlar bor. Cheklar, hisobotlar, qarzlar va bonuslardagi barcha summalar shu valyutada saqlanadi — uni almashtirish butun tarixni buzib yuboradi.';

  @override
  String settingsCurCheckFailed(String error) {
    return 'Sotuvlar borligini tekshirib boʻlmadi: $error';
  }

  @override
  String settingsCurExampleCents(String amount) {
    return 'Misol: $amount · tiyinlar bilan';
  }

  @override
  String settingsCurExampleNoCents(String amount) {
    return 'Misol: $amount · tiyinsiz';
  }

  @override
  String get settingsVatDefault => 'Yangi mahsulotlar uchun standart QQS';

  @override
  String get settingsVatHelper => '0 — agar doʻkon QQS toʻlovchisi boʻlmasa';

  @override
  String get settingsVatInfo =>
      'Mahsulot narxlari QQS bilan koʻrsatiladi. QQS summasi mahsulot stavkasi boʻyicha narxdan ajratiladi va chekda “shu jumladan QQS” qatori bilan chop etiladi. Stavkani mahsulot kartochkasida oʻzgartirish mumkin.';

  @override
  String settingsFileSaved(String path) {
    return 'Fayl saqlandi: $path';
  }

  @override
  String get settingsDataDesc =>
      'Demo rejim va maʼlumotnomalarni Excel uchun fayllarga eksport qilish.';

  @override
  String get settingsMode => 'Ish rejimi';

  @override
  String get settingsDemoMode => 'Demo rejim';

  @override
  String get settingsLiveDb => 'Ishchi baza';

  @override
  String get settingsDemoText =>
      'Hozir bazada namunaviy mahsulotlar, mijozlar va sotuvlar bor. Ular dastur bilan tanishish uchun kerak. Ularni haqiqiy savdo bilan aralashtirmang.';

  @override
  String get settingsLiveText =>
      'Dastur doʻkonning haqiqiy maʼlumotlari bilan ishlaydi.';

  @override
  String get settingsDemoWarning =>
      'Demo maʼlumotlarni tugma bilan oʻchirib boʻlmaydi: bu qaytarib boʻlmaydigan amal va hisobotlar, qoldiqlar hamda jurnalga taʼsir qiladi. Toza baza bilan ishni boshlash uchun:';

  @override
  String get settingsDemoStep1 =>
      'Zaxira nusxa yarating (“Zaxira nusxa” boʻlimi) — demo maʼlumotlar yana kerak boʻlib qolsa.';

  @override
  String get settingsDemoStep2 => 'Dasturni yoping.';

  @override
  String get settingsDemoStep3 =>
      'Maʼlumotlar bazasi faylini va, agar boʻlsa, uning yonidagi nomi “wal” yoki “shm” bilan tugaydigan fayllarni oʻchiring.';

  @override
  String settingsDbFile(String path) {
    return 'Baza fayli: $path';
  }

  @override
  String get settingsDemoStep4 =>
      'DreamPOSni ishga tushiring — boshlangʻich sozlash ustasi ochiladi. “Demo maʼlumotlar bilan toʻldirish” belgisini qoʻymang.';

  @override
  String get settingsCopyDbPath => 'Baza yoʻlini nusxalash';

  @override
  String get settingsExportProductsHint =>
      'Nomi, shtrix-kod, narxlar, qoldiqlar';

  @override
  String get settingsExportCustomersHint =>
      'Kontaktlar, chegirmalar, bonuslar va qarzlar';

  @override
  String get settingsExportInfo =>
      'Fayllar “Hujjatlar/DreamPOS/exports” papkasiga CSV formatida saqlanadi (ajratgich “;”, kodlash UTF-8) — Excel va Google Sheetsda ochiladi. Mijozlar faylida telefonlar va qarzlar bor — uni begonalarga yubormang.';

  @override
  String get settingsLastFile => 'Oxirgi fayl';

  @override
  String get settingsDevicesDesc =>
      'Doʻkonning kassa joylari, ushbu kompyuterni kassaga bogʻlash, skaner va chek printeri.';

  @override
  String settingsRegisterAdded(String name) {
    return '“$name” kassasi qoʻshildi';
  }

  @override
  String get settingsRegisterSaved => 'Kassa saqlandi';

  @override
  String settingsRegisterDeleteTitle(String name) {
    return '“$name” kassasi oʻchirilsinmi?';
  }

  @override
  String get settingsRegisterDeleteMessage =>
      'Kassa roʻyxatdan yoʻqoladi. Unda urilgan cheklar va hisobotlar saqlanib qoladi.';

  @override
  String get settingsRegisterDeleted => 'Kassa oʻchirildi';

  @override
  String get settingsRegisters => 'Kassalar';

  @override
  String get settingsNoRegisters =>
      'Hozircha kassalar yoʻq. Doʻkonda bir nechta kassa joyi boʻlsa, kassa qoʻshing — shunda hisobotlarda chek qayerda urilgani koʻrinadi.';

  @override
  String get settingsRegisterDisabled => 'Faolsiz';

  @override
  String get settingsThisDevice => 'Ushbu kompyuter';

  @override
  String settingsRegisterDefaultName(String number) {
    return 'Kassa $number';
  }

  @override
  String get settingsNewRegister => 'Yangi kassa';

  @override
  String get settingsRegister => 'Kassa';

  @override
  String get settingsRegisterNameHint => 'Kassa 1, Ombor, 2-boʻlim';

  @override
  String get settingsRegisterActive => 'Faol';

  @override
  String get settingsRegisterActiveHint =>
      'Faolsiz kassani ish uchun tanlab boʻlmaydi';

  @override
  String get settingsThisDeviceHint =>
      'Ushbu qurilma qaysi kassa sifatida ishlashini tanlang. Sozlama faqat shu kompyuterda saqlanadi va boshqalarga oʻtkazilmaydi.';

  @override
  String get settingsAddRegisterFirst =>
      'Avval kamida bitta faol kassa qoʻshing.';

  @override
  String get settingsDeviceRegister => 'Ushbu qurilma kassasi';

  @override
  String get settingsNotSelected => 'Tanlanmagan';

  @override
  String get settingsDeviceRegisterSet => 'Ushbu qurilma uchun kassa tanlandi';

  @override
  String get settingsDeviceRegisterGone =>
      'Avval tanlangan kassa oʻchirilgan yoki faolsizlantirilgan — boshqasini tanlang.';

  @override
  String get settingsTestPrintTitle => 'SINOV CHOP ETISH';

  @override
  String get settingsNotFiscal => 'Fiskal hujjat emas';

  @override
  String get settingsTestReceiptJob => 'Sinov cheki';

  @override
  String get settingsPrinter => 'Chek printeri';

  @override
  String settingsPrinterHint(String width) {
    return 'Chek tizimning chop etish oynasi orqali chop etiladi. Printer drayverini oʻrnating va uni standart printer qilib tanlang. Hozirgi lenta kengligi: $width mm (“Doʻkon” boʻlimida oʻzgartiriladi).';
  }

  @override
  String get settingsPrintTest => 'Sinov chekini chop etish';

  @override
  String get settingsScanner => 'Shtrix-kod skaneri';

  @override
  String get settingsScannerTip1 =>
      'USB skanerni ulang — u klaviatura kabi ishlaydi, odatda drayver kerak emas.';

  @override
  String get settingsScannerTip2 =>
      'Skaner koddan keyin Enter yuborishi kerak (CR suffiksi). Aksariyat modellarda shunday sozlangan.';

  @override
  String get settingsScannerTip3 =>
      'Klaviatura tartibi: raqamlar oʻrniga boshqa belgilar chiqsa, tartibni ENga oʻtkazing yoki skanerni “raqamli” rejimga sozlang.';

  @override
  String get settingsScannerTip4 =>
      'Tekshirish: mahsulot qidiruvini oching va shtrix-kodni skanerlang — kod toʻliq chiqishi kerak.';

  @override
  String get settingsScannerTip5 =>
      'Simsiz skanerlar ham xuddi shunday ishlaydi; bazani kassadan 10 m doirasida saqlang.';

  @override
  String get settingsLoyaltyDesc =>
      'Bonus dasturi: mijoz xaridlardan bonus oladi va ular bilan keyingi xaridlarning bir qismini toʻlaydi. 1 bonus = 1 valyuta birligi.';

  @override
  String get settingsLoyaltyEnabled => 'Bonus dasturi yoqilgan';

  @override
  String get settingsLoyaltyEnabledHint =>
      'Bonuslar faqat chekda tanlangan xaridorlarga hisoblanadi';

  @override
  String get settingsRules => 'Qoidalar';

  @override
  String get settingsLoyaltyOff =>
      'Dastur oʻchirilgan: bonuslar hisoblanmaydi va yechilmaydi. Mijozlarning toʻplangan balanslari saqlanadi.';

  @override
  String get settingsEarnLabel => 'Xariddan hisoblash';

  @override
  String get settingsPercentRangeHelper => '0 dan 100 gacha';

  @override
  String get settingsRedeemLabel => 'Bonus bilan toʻlov, koʻpi bilan';

  @override
  String get settingsRedeemSuffix => '% chekdan';

  @override
  String get settingsLoyaltyEnterPercents =>
      'Misolni koʻrish uchun 0 dan 100 gacha foiz kiriting.';

  @override
  String get settingsLoyaltyReturnInfo =>
      'Mahsulot qaytarilganda u uchun hisoblangan bonuslar mutanosib ravishda yechiladi. Yangi foizlar keyingi sotuvlarga amal qiladi; oʻtgan cheklar qayta hisoblanmaydi.';

  @override
  String get settingsShiftOffTitle => 'Smenasiz savdoga ruxsat berilsinmi?';

  @override
  String get settingsShiftOffMessage =>
      'Tavsiya etilmaydi. Ochiq smenasiz:\n• kassadagi naqd pul nazorati va Z-hisobot boʻlmaydi;\n• sotuvlar hech qaysi smenaga tushmaydi, kamomadlarni topib boʻlmaydi;\n• kassirlar maydalikni sanamasdan sotishi mumkin.\n\nFaqat kassa naqd pul qabul qilmasa oʻchiring.';

  @override
  String get settingsShiftOffOk => 'Baribir oʻchirish';

  @override
  String get settingsNegativeTitle =>
      'Qoldiq nol boʻlganda sotishga ruxsat berilsinmi?';

  @override
  String get settingsNegativeMessage =>
      'Qoldiq minusga tushishi mumkin. Bu kirim sotuvdan keyin rasmiylashtirilsa qulay, lekin mahsulotlar chalkashligi va kamomadlarni yashiradi. Manfiy qoldiqlarni muntazam ravishda kirim yoki inventarizatsiya bilan tuzatish kerak.';

  @override
  String get settingsAllow => 'Ruxsat berish';

  @override
  String get settingsSalesDesc =>
      'Kassa har bir sotuv va qaytarishda tekshiradigan qoidalar.';

  @override
  String get settingsControl => 'Nazorat';

  @override
  String get settingsRequireShift => 'Faqat ochiq smenada sotish';

  @override
  String get settingsRequireShiftHint =>
      'Tavsiya etiladi: har bir smena boʻyicha naqd pul nazorati va Z-hisobot';

  @override
  String get settingsAllowNegative => 'Qoldiq nol boʻlganda sotishga ruxsat';

  @override
  String get settingsAllowNegativeHint =>
      'Qoldiq minusga tushishi mumkin (barcha mahsulotlar uchun)';

  @override
  String get settingsDebtLimit => 'Qarzga — faqat limiti bor mijozlarga';

  @override
  String get settingsDebtLimitHint =>
      'Limiti belgilanmagan mijozga qarzga sotish taqiqlanadi';

  @override
  String get settingsReturns => 'Qaytarishlar';

  @override
  String get settingsReturnDays => 'Qaytarish muddati, kun';

  @override
  String get settingsDaysSuffix => 'kun';

  @override
  String get settingsReturnNoLimit => 'Muddat cheklanmagan';

  @override
  String settingsReturnWithin(String days) {
    return 'Chek boʻyicha qaytarish $days kun ichida mumkin. 0 — cheklovsiz';
  }

  @override
  String get settingsQuickCash => 'Naqd bilan tezkor toʻlov';

  @override
  String get settingsBanknotesLabel => 'Toʻlov ekranidagi kupyura nominallari';

  @override
  String settingsBanknotesHelper(String max) {
    return 'Vergul bilan, $max tagacha. Boʻsh — standart toʻplam';
  }

  @override
  String get settingsPosButtons => 'Kassadagi tugmalar:';

  @override
  String get settingsCashRounding => 'Naqd pulni yaxlitlash';

  @override
  String get settingsRoundingLabel => 'Naqd toʻlovda jamini yaxlitlash';

  @override
  String settingsRoundingChanged(String value) {
    return 'Yaxlitlash: $value';
  }

  @override
  String get settingsRoundingOff => 'Naqd toʻlov jami yaxlitlanmaydi.';

  @override
  String settingsRoundingExample(String from, String to) {
    return 'Misol: $from → $to. Xaridor foydasiga pastga, faqat naqd toʻlovda yaxlitlanadi.';
  }

  @override
  String get settingsStoreName => 'Doʻkon nomi *';

  @override
  String get settingsStoreNameHelper =>
      'Chek sarlavhasida va kirish ekranida koʻrsatiladi';

  @override
  String get settingsAddressHint => 'Toshkent sh., Navoiy koʻch., 12';

  @override
  String get settingsTaxId => 'STIR / INN';

  @override
  String get settingsTaxIdHelper => 'Faqat raqamlar, 9–14 belgi';

  @override
  String get settingsFooter => 'Chek ostidagi matn';

  @override
  String get settingsFooterHint =>
      'Xaridingiz uchun rahmat!\nAlmashtirish va qaytarish 14 kun ichida';

  @override
  String get settingsPaperWidth => 'Lenta kengligi';

  @override
  String get settingsPaperWidthHint =>
      'Printer yoʻriqnomasiga qarang: 58 mm — ixcham, 80 mm — standart';

  @override
  String settingsMm(String width) {
    return '$width mm';
  }

  @override
  String get settingsAutoPrint => 'Chekni avtomatik chop etish';

  @override
  String get settingsAutoPrintHint =>
      'Toʻlovdan soʻng darhol, kassirdan soʻramasdan';

  @override
  String get settingsStoreDesc =>
      'Doʻkon rekvizitlari va chek koʻrinishi. Oʻzgarishlar chek namunasida darhol koʻrinadi.';

  @override
  String get settingsReceiptSample => 'Chek namunasi';

  @override
  String get settingsSecSync => 'Sinxronlash';

  @override
  String get settingsSecSyncHint => 'Bir nechta kassa, bulut';

  @override
  String get shiftClosingTitle => 'Smenani yopish';

  @override
  String get shiftClosed => 'Smena yopildi';

  @override
  String get shiftCloseConfirmTitle => 'Smena yopilsinmi?';

  @override
  String shiftCountedValue(String amount) {
    return 'Sanaldi: $amount';
  }

  @override
  String shiftExpectedValue(String amount) {
    return 'Kutilgan: $amount';
  }

  @override
  String get shiftShortage => 'Kamomad';

  @override
  String get shiftSurplus => 'Ortiqcha';

  @override
  String shiftCollectionAtCloseValue(String amount) {
    return 'Yopishdagi inkassatsiya: $amount';
  }

  @override
  String get shiftCloseConfirmMessage =>
      'Yopilgandan soʻng yangi smena ochilguncha sotuv mumkin boʻlmaydi.';

  @override
  String get shiftCloseAction => 'Smenani yopish';

  @override
  String get shiftCountCashHint => 'Pul yashigidagi naqd pulni sanang.';

  @override
  String get shiftByDenomination => 'Kupyuralar boʻyicha';

  @override
  String get shiftByTotal => 'Umumiy summa';

  @override
  String get shiftCashInDrawer => 'Kassadagi naqd';

  @override
  String get shiftExpectedInDrawer => 'Kassada kutilmoqda';

  @override
  String get shiftInclGiftCash => 'shu jumladan sertifikatlar (naqd)';

  @override
  String get shiftCounted => 'Sanaldi';

  @override
  String get shiftDifference => 'Farq';

  @override
  String get shiftDiffReasonLabel => 'Farq sababi *';

  @override
  String get shiftNoteOptional => 'Izoh (ixtiyoriy)';

  @override
  String get shiftCollectionAtClose => 'Yopishdagi inkassatsiya';

  @override
  String shiftCollectionSummary(String collect, String leave) {
    return '$collect topshirish, $leave maydalik uchun qoldirish';
  }

  @override
  String get shiftCollectionHint =>
      'Tushumning bir qismini topshirib, keyingi smenaga maydalik qoldirish';

  @override
  String get shiftCollectionAmount => 'Inkassatsiya summasi';

  @override
  String get shiftCollectAll => 'Hammasini topshirish';

  @override
  String get shiftNoDifference => 'farqsiz';

  @override
  String get shiftShortageLower => 'kamomad';

  @override
  String get shiftSurplusLower => 'ortiqcha';

  @override
  String shiftOpenedToast(String amount) {
    return 'Smena ochildi. Maydalik: $amount';
  }

  @override
  String get shiftOpenHint =>
      'Sotishni boshlash uchun smenani oching va kassadagi maydalik summasini kiriting.';

  @override
  String get shiftOpeningCash => 'Smena boshidagi maydalik';

  @override
  String get shiftOpeningSuggested => 'Taklif: oldingi smenadan qolgan qoldiq';

  @override
  String get shiftOpeningCashNow => 'Hozir pul yashigidagi naqd pul';

  @override
  String get shiftNoRightOpen => 'Smena ochishga ruxsat yoʻq';

  @override
  String get shiftOpenAction => 'Smenani ochish';

  @override
  String get shiftSales => 'Sotuvlar';

  @override
  String shiftSalesHint(String receipts, String avg) {
    return '$receipts · oʻrtacha $avg';
  }

  @override
  String get shiftReturns => 'Qaytarishlar';

  @override
  String get shiftNoReturns => 'Qaytarishlar boʻlmadi';

  @override
  String get shiftGrossProfit => 'Yalpi foyda';

  @override
  String get shiftNetRevenue => 'Qaytarishlarsiz tushum';

  @override
  String shiftRevenueValue(String amount) {
    return 'Tushum $amount';
  }

  @override
  String shiftExpectedHint(String amount) {
    return 'Naqd · maydalik $amount';
  }

  @override
  String get shiftXReport => 'X-hisobot';

  @override
  String get shiftZReport => 'Z-hisobot';

  @override
  String shiftNumber(String number) {
    return 'Smena №$number';
  }

  @override
  String get shiftStatusOpen => 'Ochiq';

  @override
  String shiftOpenedAt(String date) {
    return 'Ochilgan $date';
  }

  @override
  String get shiftJustNow => 'hozirgina';

  @override
  String shiftRunning(String duration) {
    return 'davom etmoqda $duration';
  }

  @override
  String shiftHoursMinutes(String hours, String minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String shiftMinutes(String minutes) {
    return '$minutes daq';
  }

  @override
  String get shiftCloseTooltip => 'Kassani sanab, smenani yopish (Z-hisobot)';

  @override
  String get shiftNoRightClose => 'Smenani yopishga ruxsat yoʻq';

  @override
  String get shiftCashOperations => 'Kassa operatsiyalari';

  @override
  String get shiftNoRightCash => 'Kassa operatsiyalariga ruxsat yoʻq';

  @override
  String get shiftOperationsList => 'Smenadagi operatsiyalar';

  @override
  String get shiftNoOperations => 'Hali kiritish va pul berish boʻlmagan';

  @override
  String shiftNumberOpen(String number) {
    return 'Smena №$number ochiq';
  }

  @override
  String get shiftTabCurrent => 'Joriy smena';

  @override
  String get shiftTabHistory => 'Smenalar tarixi';

  @override
  String get shiftOnlyMine => 'Faqat mening smenalarim';

  @override
  String get shiftHistoryEmptyTitle => 'Hozircha smenalar yoʻq';

  @override
  String get shiftHistoryEmptyMessage =>
      'Yopilgan smenalar va ularning Z-hisobotlari shu yerda paydo boʻladi';

  @override
  String get shiftPickShift => 'Smenani tanlang';

  @override
  String get shiftPickShiftMessage =>
      'Bu yerda uning chop etish mumkin boʻlgan hisoboti chiqadi';

  @override
  String get shiftNow => 'hozir';

  @override
  String get shiftEnterCountedCash => 'Kassadagi naqd pul summasini kiriting';

  @override
  String get shiftAmountNegative => 'Summa manfiy boʻlishi mumkin emas';

  @override
  String get shiftCollectionNegative =>
      'Inkassatsiya summasi manfiy boʻlishi mumkin emas';

  @override
  String get shiftCollectionTooBig =>
      'Inkassatsiya sanalgan summadan oshmasligi kerak';

  @override
  String get shiftEnterDiffReason => 'Farq sababini koʻrsating';

  @override
  String get shiftKindPayIn => 'Kiritish';

  @override
  String get shiftKindPayOut => 'Pul berish';

  @override
  String get shiftKindExpense => 'Xarajat';

  @override
  String get shiftKindCollection => 'Inkassatsiya';

  @override
  String get shiftExpRent => 'Ijara';

  @override
  String get shiftExpSalary => 'Ish haqi';

  @override
  String get shiftExpSupplies => 'Xoʻjalik mollari';

  @override
  String get shiftExpTransport => 'Transport';

  @override
  String get shiftExpUtilities => 'Kommunal';

  @override
  String get shiftExpOther => 'Boshqa';

  @override
  String get shiftKindPayInHint => 'Maydalik, hisobdor pulni qaytarish va h.k.';

  @override
  String get shiftKindPayOutHint =>
      'Kassadan naqd pul berish (hisobdor, avans)';

  @override
  String get shiftKindExpenseHint => 'Doʻkon xarajatlarini kassadan toʻlash';

  @override
  String get shiftKindCollectionHint => 'Tushumni egasiga / bankka topshirish';

  @override
  String get shiftPickExpenseCategory => 'Xarajat kategoriyasini tanlang';

  @override
  String shiftCashInDrawerNow(String amount) {
    return 'Hozir kassada: $amount';
  }

  @override
  String get shiftEnterAmount => 'Summani kiriting';

  @override
  String shiftOnlyInDrawer(String amount) {
    return 'Kassada faqat $amount';
  }

  @override
  String get shiftExpenseCategory => 'Xarajat kategoriyasi';

  @override
  String get shiftReasonRequired => 'Asos / izoh *';

  @override
  String get shiftPayOutHint => 'Pul kimga va nima uchun berildi';

  @override
  String get shiftEnterReason => 'Asosni koʻrsating';

  @override
  String get shiftSaving => 'Saqlanmoqda…';

  @override
  String get shiftPost => 'Oʻtkazish';

  @override
  String get shiftZShiftNo => 'Smena №';

  @override
  String get shiftZOpened => 'Ochilgan';

  @override
  String get shiftZClosed => 'Yopilgan';

  @override
  String get shiftZReceipts => 'Cheklar';

  @override
  String get shiftZSalesTotal => 'Sotuv summasi';

  @override
  String shiftZIncl(String method) {
    return 'shu jumladan $method';
  }

  @override
  String get shiftZDiscounts => 'Chegirmalar';

  @override
  String get shiftZAvgCheck => 'Oʻrtacha chek';

  @override
  String get shiftZVoidedReceipts => 'Bekor qilingan cheklar';

  @override
  String get shiftZReturnsCount => 'Qaytarishlar soni';

  @override
  String get shiftZReturnsTotal => 'Qaytarishlar summasi';

  @override
  String get shiftZGiftCards => 'Sertifikatlar';

  @override
  String get shiftZSold => 'Sotildi';

  @override
  String get shiftZGiftSalesTotal => 'Sotuv summasi (avans)';

  @override
  String get shiftZVoided => 'Bekor qilindi';

  @override
  String get shiftZRefundedToBuyers => 'Xaridorlarga qaytarildi';

  @override
  String get shiftZCashImpact => 'Kassaga taʼsiri (naqd)';

  @override
  String get shiftZAdvanceNote => 'avans, tushumga kirmaydi';

  @override
  String get shiftZSummary => 'Yakun';

  @override
  String get shiftZNetRevenue => 'Tushum (qaytarishlarsiz)';

  @override
  String get shiftZCash => 'Kassa (naqd)';

  @override
  String get shiftZOpeningCash => 'Boshidagi maydalik';

  @override
  String get shiftZCashSales => 'Naqd sotuvlar';

  @override
  String get shiftZCashRefunds => 'Naqd qaytarishlar';

  @override
  String get shiftZDebtCash => 'Qarz toʻlovlari (naqd)';

  @override
  String get shiftZDebtNonCash => 'Qarz toʻlovlari (naqdsiz)';

  @override
  String get shiftZSupplierPaid => 'Taʼminotchilarga toʻlovlar';

  @override
  String get shiftZGiftCash => 'Sertifikatlar (naqd, avans)';

  @override
  String get shiftZActual => 'Haqiqiy';

  @override
  String shiftZPrinted(String date) {
    return 'Chop etildi: $date';
  }

  @override
  String get shiftZCashierSign => 'Kassir';

  @override
  String get shiftZReceivedSign => 'Qabul qildi';

  @override
  String shiftZTitleA4(String title, String number) {
    return '$title — smena №$number';
  }

  @override
  String shiftZGenerated(String date) {
    return 'Tuzildi: $date';
  }

  @override
  String shiftZFileName(String title, String number) {
    return '$title smena $number';
  }

  @override
  String get shiftPrintUnavailable => 'Chop etish mavjud emas';

  @override
  String get shiftRoll80 => 'Chek lentasi 80 mm';

  @override
  String get shiftSheetA4 => 'A4 varaq';

  @override
  String shiftReportHeader(String title, String number) {
    return '$title · smena №$number';
  }

  @override
  String get shiftReportTitle => 'Smena hisoboti';

  @override
  String get staffTitle => 'Xodimlar';

  @override
  String get staffNoAccess => 'Ruxsat yoʻq';

  @override
  String get staffNoAccessHint => 'Boʻlim faqat egasi va administrator uchun';

  @override
  String get staffTabTime => 'Ish vaqti';

  @override
  String get staffTabMotivation => 'Motivatsiya';

  @override
  String get staffTabRoles => 'Rollar va huquqlar';

  @override
  String get staffTabAudit => 'Amallar jurnali';

  @override
  String get staffRolesHint =>
      'Rollar huquqlari tizim tomonidan belgilangan. Xodim ruxsatini oʻzgartirish uchun uning rolini almashtiring.';

  @override
  String get staffPermColumn => 'Huquq';

  @override
  String get staffErrLastOwner =>
      'Bu yagona faol ega. Avval boshqa egani tayinlang';

  @override
  String get staffErrNameTooLong => 'Ism juda uzun';

  @override
  String get staffErrSetPin => 'PIN kiriting';

  @override
  String get staffErrMaxDiscountRange => 'Maks. chegirma — 0 dan 100% gacha';

  @override
  String get staffErrCommissionRange => 'Komissiya — 0 dan 100% gacha';

  @override
  String get staffErrPlanNegative => 'Reja manfiy boʻlishi mumkin emas';

  @override
  String get staffErrPhoneFormat => 'Telefon formati notoʻgʻri';

  @override
  String get staffErrOwnerRoleOnlyOwner =>
      '“Ega” rolini faqat ega tayinlay oladi';

  @override
  String get staffErrOwnerEditOnlyOwner =>
      'Ega maʼlumotlarini faqat ega oʻzgartira oladi';

  @override
  String get staffErrCannotDeactivateSelf =>
      'Oʻz hisobingizni faolsizlantirib boʻlmaydi';

  @override
  String get staffErrActivateNeedsPin =>
      'Faollashtirish uchun xodimga yangi PIN bering';

  @override
  String staffDurationMin(String m) {
    return '$m daq';
  }

  @override
  String staffDurationHm(String h, String m) {
    return '$h soat $m daq';
  }

  @override
  String staffErrAlreadyClockedIn(String time) {
    return 'Kelish allaqachon $time da belgilangan';
  }

  @override
  String get staffErrClockInFirst => 'Avval kelishni belgilang';

  @override
  String get staffErrEndBeforeStart =>
      'Ketish vaqti kelish vaqtidan keyin boʻlishi kerak';

  @override
  String get staffErrStartInFuture =>
      'Kelish vaqti kelajakda boʻlishi mumkin emas';

  @override
  String get staffErrEndInFuture =>
      'Ketish vaqti kelajakda boʻlishi mumkin emas';

  @override
  String get staffErrTooLong => 'Smena 24 soatdan oshmasligi kerak';

  @override
  String staffErrOverlap(String from, String to) {
    return 'Boshqa yozuv bilan kesishadi ($from — $to)';
  }

  @override
  String get staffNow => 'hozir';

  @override
  String get staffErrOpenExists => 'Xodimda tugallanmagan yozuv bor';

  @override
  String get staffPermSell => 'Sotuv (kassa)';

  @override
  String get staffPermApplyDiscount => 'Qoʻlda chegirma';

  @override
  String get staffPermVoidSale => 'Cheklarni bekor qilish';

  @override
  String get staffPermRefund => 'Qaytarishlar';

  @override
  String get staffPermOpenCloseShift => 'Smenani ochish/yopish';

  @override
  String get staffPermCashInOut => 'Kiritish va pul berish';

  @override
  String get staffPermViewProducts => 'Mahsulotlarni koʻrish';

  @override
  String get staffPermEditProducts => 'Mahsulotlarni tahrirlash';

  @override
  String get staffPermEditPrices => 'Narxlarni oʻzgartirish';

  @override
  String get staffPermViewCost => 'Tannarx va foyda';

  @override
  String get staffPermStockOps => 'Ombor operatsiyalari';

  @override
  String get staffPermPurchasing => 'Xaridlar';

  @override
  String get staffPermViewCustomers => 'Mijozlarni koʻrish';

  @override
  String get staffPermEditCustomers => 'Mijozlarni tahrirlash';

  @override
  String get staffPermManageDebts => 'Mijozlar qarzlari';

  @override
  String get staffPermManagePromotions => 'Aksiyalar va marketing';

  @override
  String get staffPermViewReports => 'Hisobotlar';

  @override
  String get staffPermViewAllShifts => 'Barcha smenalar';

  @override
  String get staffPermManageStaff => 'Xodimlarni boshqarish';

  @override
  String get staffPermManageSettings => 'Sozlamalar';

  @override
  String get staffPermViewAudit => 'Amallar jurnali';

  @override
  String get staffAuditAuthLogin => 'Tizimga kirish';

  @override
  String get staffAuditAuthFail => 'Notoʻgʻri PIN';

  @override
  String get staffAuditAuthLogout => 'Tizimdan chiqish';

  @override
  String get staffAuditSaleDiscount => 'Chekdagi chegirma';

  @override
  String get staffAuditSaleReturn => 'Qaytarish';

  @override
  String get staffAuditSaleVoid => 'Chekni bekor qilish';

  @override
  String get staffAuditSaleCreate => 'Sotuv';

  @override
  String get staffAuditShiftOpen => 'Smena ochildi';

  @override
  String get staffAuditShiftClose => 'Smena yopildi';

  @override
  String get staffAuditCashPayIn => 'Kassaga kiritish';

  @override
  String get staffAuditCashPayOut => 'Kassadan pul berish';

  @override
  String get staffAuditCashExpense => 'Kassadan xarajat';

  @override
  String get staffAuditCashCollection => 'Inkassatsiya';

  @override
  String get staffAuditStockReceive => 'Mahsulot kirimi';

  @override
  String get staffAuditStockWriteoff => 'Mahsulotni hisobdan chiqarish';

  @override
  String get staffAuditStockAdjust => 'Qoldiqni tuzatish';

  @override
  String get staffAuditStockSet => 'Qoldiqni belgilash';

  @override
  String get staffAuditUserCreate => 'Xodim yaratildi';

  @override
  String get staffAuditUserUpdate => 'Xodim maʼlumotlari oʻzgartirildi';

  @override
  String get staffAuditUserRole => 'Xodim roli oʻzgartirildi';

  @override
  String get staffAuditUserPinChange => 'PIN almashtirildi';

  @override
  String get staffAuditUserActivate => 'Xodim faollashtirildi';

  @override
  String get staffAuditUserDeactivate => 'Xodim faolsizlantirildi';

  @override
  String get staffAuditProductPrice => 'Narx oʻzgarishi';

  @override
  String get staffAuditDebtPayment => 'Qarzni toʻlash';

  @override
  String get staffAuditBonusAdjust => 'Bonuslarni tuzatish';

  @override
  String get staffAuditInventoryComplete => 'Inventarizatsiya oʻtkazildi';

  @override
  String get staffAuditDiscountOverride => 'Limitdan ortiq chegirma';

  @override
  String get staffAuditDiscountApprove => 'Chegirmani menejer tasdiqladi';

  @override
  String get staffAuditAuthApproveFail => 'Tasdiqlash PIN-kodi notoʻgʻri';

  @override
  String get staffAuditBackupAuto => 'Avtomatik zaxira nusxa';

  @override
  String get staffAuditTimeClockIn => 'Ishga kelish';

  @override
  String get staffAuditTimeClockOut => 'Ishdan ketish';

  @override
  String get staffAuditTimeAdd => 'Ish vaqti yozuvi qoʻshildi';

  @override
  String get staffAuditTimeEdit => 'Ish vaqti yozuvi oʻzgartirildi';

  @override
  String get staffAuditTimeDelete => 'Ish vaqti yozuvi oʻchirildi';

  @override
  String get staffAuditStockReceipt => 'Mahsulot kirimi';

  @override
  String get staffAuditProductCreate => 'Mahsulot yaratildi';

  @override
  String get staffAuditProductUpdate => 'Mahsulot oʻzgartirildi';

  @override
  String get staffAuditProductDelete => 'Mahsulot oʻchirildi';

  @override
  String get staffAuditProductCost => 'Tannarx oʻzgarishi';

  @override
  String get staffAuditProductImport => 'Mahsulotlar importi';

  @override
  String get staffAuditProductBulkPrice => 'Narxlarni ommaviy oʻzgartirish';

  @override
  String get staffAuditProductBulkCategory =>
      'Kategoriyani ommaviy almashtirish';

  @override
  String get staffAuditCategoryDelete => 'Kategoriya oʻchirildi';

  @override
  String get staffAuditCustomerCreate => 'Mijoz yaratildi';

  @override
  String get staffAuditCustomerDelete => 'Mijoz oʻchirildi';

  @override
  String get staffAuditCustomerTerms => 'Mijoz shartlari oʻzgartirildi';

  @override
  String get staffAuditSupplierPayment => 'Taʼminotchiga toʻlov';

  @override
  String get staffAuditSupplierDelete => 'Taʼminotchi oʻchirildi';

  @override
  String get staffAuditPoOrdered => 'Taʼminotchiga buyurtma yuborildi';

  @override
  String get staffAuditPoReceive => 'Taʼminotchi buyurtmasini qabul qilish';

  @override
  String get staffAuditPromotionCreate => 'Aksiya yaratildi';

  @override
  String get staffAuditPromotionUpdate => 'Aksiya oʻzgartirildi';

  @override
  String get staffAuditPromotionDelete => 'Aksiya oʻchirildi';

  @override
  String get staffAuditGiftCardIssue => 'Sovgʻa sertifikati chiqarildi';

  @override
  String get staffAuditWarrantyCreate => 'Kafolat murojaati';

  @override
  String get staffAuditWarrantyStatus => 'Kafolat murojaati holati';

  @override
  String get staffAuditInventoryCreate => 'Inventarizatsiya boshlandi';

  @override
  String get staffAuditInventoryCancel => 'Inventarizatsiya bekor qilindi';

  @override
  String get staffAuditPosPriceEdit => 'Chekda narxni oʻzgartirish';

  @override
  String get staffAuditPosCartClear => 'Chekni tozalash';

  @override
  String get staffAuditSettingsChange => 'Sozlamalar oʻzgartirildi';

  @override
  String get staffAuditRegisterDelete => 'Kassa oʻchirildi';

  @override
  String get staffAuditRegisterBindDevice => 'Qurilmani kassaga bogʻlash';

  @override
  String get staffAuditDataExport => 'Maʼlumotlar eksporti';

  @override
  String get staffAuditBackupCreate => 'Zaxira nusxa yaratildi';

  @override
  String get staffAuditBackupDelete => 'Zaxira nusxa oʻchirildi';

  @override
  String get staffAuditBackupRestoreScheduled => 'Tiklash rejalashtirildi';

  @override
  String get staffAuditBackupRestoreCancelled => 'Tiklash bekor qilindi';

  @override
  String get staffAuditBackupRestoreApplied => 'Maʼlumotlar nusxadan tiklandi';

  @override
  String get staffGroupAuth => 'Kirish';

  @override
  String get staffGroupSale => 'Sotuvlar';

  @override
  String get staffGroupShift => 'Smenalar';

  @override
  String get staffGroupCash => 'Kassa';

  @override
  String get staffGroupStock => 'Ombor';

  @override
  String get staffGroupInventory => 'Inventarizatsiya';

  @override
  String get staffGroupUser => 'Xodimlar';

  @override
  String get staffGroupTime => 'Ish vaqti';

  @override
  String get staffGroupProduct => 'Mahsulotlar';

  @override
  String get staffGroupDebt => 'Qarzlar';

  @override
  String get staffGroupBonus => 'Bonuslar';

  @override
  String get staffGroupDiscount => 'Chegirmalar';

  @override
  String get staffGroupPos => 'Kassa (chek)';

  @override
  String get staffGroupCustomer => 'Mijozlar';

  @override
  String get staffGroupSupplier => 'Taʼminotchilar';

  @override
  String get staffGroupPo => 'Xaridlar';

  @override
  String get staffGroupPromotion => 'Aksiyalar';

  @override
  String get staffGroupSettings => 'Sozlamalar';

  @override
  String get staffGroupBackup => 'Zaxira nusxalar';

  @override
  String get staffDetailDiscount => 'chegirma';

  @override
  String get staffDetailTotal => 'summa';

  @override
  String get staffDetailOpening => 'maydalik';

  @override
  String get staffDetailExpected => 'kutilgan';

  @override
  String get staffDetailCounted => 'sanaldi';

  @override
  String get staffDetailManual => 'qoʻlda chegirma';

  @override
  String get staffDetailMethod => 'usul';

  @override
  String get staffMethodCash => 'naqd';

  @override
  String get staffMethodCard => 'karta';

  @override
  String get staffMethodDebt => 'qarzga';

  @override
  String get staffMethodBonus => 'bonuslar';

  @override
  String get staffMethodTransfer => 'oʻtkazma';

  @override
  String get staffMethodGiftCard => 'sertifikat';

  @override
  String staffDetailPromos(String list) {
    return 'aksiyalar: $list';
  }

  @override
  String staffDetailReturnNo(String number) {
    return 'qaytarish cheki №$number';
  }

  @override
  String get staffSearchHint => 'Ism yoki telefon';

  @override
  String get staffInactiveFilter => 'Nofaollar';

  @override
  String get staffInactiveFilterTip =>
      'Faolsizlantirilgan xodimlarni koʻrsatish';

  @override
  String get staffAddUser => 'Xodim qoʻshish';

  @override
  String get staffEmpty => 'Hozircha xodimlar yoʻq';

  @override
  String get staffNobodyFound => 'Hech kim topilmadi';

  @override
  String get staffEmptyHint =>
      'PIN orqali kirishlari uchun kassir va menejerlarni qoʻshing';

  @override
  String staffDeactivateTitle(String name) {
    return '$name faolsizlantirilsinmi?';
  }

  @override
  String get staffDeactivateMessage =>
      'Xodim tizimga kira olmaydi, uning ochiq ish vaqti qaydi yopiladi. Sotuvlar va smenalar tarixi saqlanadi. Istalgan vaqtda faollashtirish mumkin.';

  @override
  String get staffDeactivate => 'Faolsizlantirish';

  @override
  String staffDeactivated(String name) {
    return '$name faolsizlantirildi';
  }

  @override
  String staffActivateTitle(String name) {
    return '${name}ni faollashtirish';
  }

  @override
  String get staffActivateMessage =>
      'Yangi PIN kiriting — eskisi boshqa xodimga berilgan boʻlishi mumkin.';

  @override
  String staffReactivated(String name) {
    return '$name yana faol';
  }

  @override
  String get staffNeverLoggedIn => 'hali kirmagan';

  @override
  String staffLastLogin(String date) {
    return 'kirish $date';
  }

  @override
  String get staffYou => 'Siz';

  @override
  String get staffInactiveChip => 'Nofaol';

  @override
  String get staffAtWork => 'Ishda';

  @override
  String get staffTodayLower => 'bugun';

  @override
  String get staffEditAction => 'Tahrirlash';

  @override
  String get staffActivate => 'Faollashtirish';

  @override
  String get staffNewUser => 'Yangi xodim';

  @override
  String staffUserTitle(String name) {
    return 'Xodim: $name';
  }

  @override
  String get staffDemoteTitle => 'Oʻz rolingizni pasaytirasizmi?';

  @override
  String staffDemoteMessage(String role) {
    return 'Saqlangandan keyin sizda (“$role”) “Xodimlar” boʻlimiga ruxsat boʻlmaydi. Huquqlarni faqat ega yoki administrator qaytara oladi.';
  }

  @override
  String get staffDemote => 'Pasaytirish';

  @override
  String get staffUserAdded => 'Xodim qoʻshildi';

  @override
  String get staffChangesSaved => 'Oʻzgarishlar saqlandi';

  @override
  String get staffFrom0To100 => '0 dan 100 gacha';

  @override
  String get staffNameLabel => 'Ism *';

  @override
  String get staffOwnerRoleLocked => 'Ega rolini faqat ega oʻzgartira oladi';

  @override
  String get staffRoleLabel => 'Rol *';

  @override
  String get staffPinSection => 'Kirish uchun PIN';

  @override
  String get staffResetPin => 'PINni tiklash';

  @override
  String get staffResetPinHint => 'Xodim yangi PIN bilan kiradi';

  @override
  String get staffPinLabel => 'PIN *';

  @override
  String get staffPinRepeatLabel => 'PIN yana bir bor *';

  @override
  String get staffPinMismatch => 'PIN mos kelmadi';

  @override
  String get staffPinHint => '4–8 raqam, har bir xodim uchun noyob';

  @override
  String get staffLimitsSection => 'Cheklovlar va motivatsiya';

  @override
  String get staffMaxDiscount => 'Maks. chegirma';

  @override
  String get staffMaxDiscountHelper => 'tasdiqsiz';

  @override
  String get staffCommission => 'Komissiya';

  @override
  String get staffCommissionHelper => 'sof tushumdan';

  @override
  String get staffSalesPlan => 'Oylik sotuv rejasi';

  @override
  String get staffSalesPlanHelper => '0 yoki boʻsh — rejasiz';

  @override
  String get staffSaving => 'Saqlanmoqda…';

  @override
  String get staffEnterPin => 'PIN kiriting';

  @override
  String get staffPinMin4 => 'Kamida 4 raqam';

  @override
  String get staffNewPin => 'Yangi PIN';

  @override
  String get staffPin4to8 => '4 dan 8 gacha raqam';

  @override
  String get staffRepeatPin => 'PINni takrorlang';

  @override
  String get staffNoPlan => 'rejasiz';

  @override
  String get staffClockIn => 'Ish boshlanishini belgilash';

  @override
  String staffClockedIn(String time) {
    return 'Ish boshlanishi $time da belgilandi';
  }

  @override
  String get staffClockInShort => 'Ishni boshlash';

  @override
  String get staffClockOutTitle => 'Ketishni belgilaysizmi?';

  @override
  String staffClockOutMessage(String time, String duration) {
    return '$time dan beri ishda ($duration).';
  }

  @override
  String get staffClockOut => 'Ketishni belgilash';

  @override
  String get staffClockedOut => 'Ketish belgilandi';

  @override
  String staffClockOutTip(String time) {
    return '$time dan beri ishda · ketishni belgilash';
  }

  @override
  String staffAtWorkSince(String time) {
    return '$time dan beri ishda';
  }

  @override
  String staffClockOutShortDur(String duration) {
    return 'Ketish · $duration';
  }

  @override
  String staffClockOutDur(String duration) {
    return 'Ketishni belgilash · $duration';
  }

  @override
  String get staffThisWeek => 'Shu hafta';

  @override
  String get staffThisMonth => 'Shu oy';

  @override
  String get staffLastMonth => 'Oʻtgan oy';

  @override
  String get staffAllEmployees => 'Barcha xodimlar';

  @override
  String get staffEntryShort => 'Yozuv';

  @override
  String get staffAddEntry => 'Yozuv qoʻshish';

  @override
  String get staffNoMarks => 'Davr uchun qaydlar yoʻq';

  @override
  String get staffNoMarksHint =>
      'Xodimlar kelish va ketishni “Ish boshlanishini belgilash” tugmasi bilan belgilaydi';

  @override
  String get staffAtWorkLower => 'ishda';

  @override
  String get staffNewEntryTitle => 'Yangi ish vaqti yozuvi';

  @override
  String get staffEntryTitle => 'Ish vaqti yozuvi';

  @override
  String get staffSelectEmployee => 'Xodimni tanlang';

  @override
  String get staffEntrySaved => 'Yozuv saqlandi';

  @override
  String get staffDeleteEntryTitle => 'Yozuv oʻchirilsinmi?';

  @override
  String get staffDeleteEntryMessage => 'Amal jurnalga yoziladi.';

  @override
  String get staffEntryDeleted => 'Yozuv oʻchirildi';

  @override
  String get staffEmployeeRequired => 'Xodim *';

  @override
  String get staffClockInField => 'Kelish';

  @override
  String get staffClockOutField => 'Ketish';

  @override
  String get staffStillAtWorkLower => 'hali ishda';

  @override
  String get staffStillAtWork => 'Hali ishda';

  @override
  String get staffEndBeforeStartShort => 'Ketish kelishdan oldin';

  @override
  String staffDurationLabel(String duration) {
    return 'Davomiyligi: $duration';
  }

  @override
  String get staffEntryNote => 'Izoh (tahrir sababi)';

  @override
  String get staffMonth1 => 'Yanvar';

  @override
  String get staffMonth2 => 'Fevral';

  @override
  String get staffMonth3 => 'Mart';

  @override
  String get staffMonth4 => 'Aprel';

  @override
  String get staffMonth5 => 'May';

  @override
  String get staffMonth6 => 'Iyun';

  @override
  String get staffMonth7 => 'Iyul';

  @override
  String get staffMonth8 => 'Avgust';

  @override
  String get staffMonth9 => 'Sentabr';

  @override
  String get staffMonth10 => 'Oktabr';

  @override
  String get staffMonth11 => 'Noyabr';

  @override
  String get staffMonth12 => 'Dekabr';

  @override
  String get staffPrevMonth => 'Oldingi oy';

  @override
  String get staffNextMonth => 'Keyingi oy';

  @override
  String get staffCurrentMonth => 'Joriy';

  @override
  String get staffMotivationHint =>
      'Sotuvchi tushumi bekor qilingan cheklarsiz, shu oyda qilingan qaytarishlar ayirilgan holda';

  @override
  String get staffNoSellers => 'Sotuvchilar yoʻq';

  @override
  String get staffNoSellersHint =>
      'Xodim kartasida sotuv rejasi va komissiyani belgilang';

  @override
  String get staffNetRevenue => 'Sof tushum';

  @override
  String staffPlanValue(String amount) {
    return 'Reja $amount';
  }

  @override
  String get staffCommissionDue => 'Toʻlanadigan komissiya';

  @override
  String get staffRevenue => 'Tushum';

  @override
  String get staffRefunds => 'Qaytarishlar';

  @override
  String get staffReceiptsLabel => 'Cheklar';

  @override
  String get staffAvgCheck => 'Oʻrtacha chek';

  @override
  String staffCommissionPct(String pct) {
    return 'Komissiya $pct%';
  }

  @override
  String staffPlanLeft(String done, String plan, String left) {
    return '$done / $plan · qoldi $left';
  }

  @override
  String staffPlanDone(String done, String plan) {
    return '$done / $plan · reja bajarildi';
  }

  @override
  String get staffActionLabel => 'Amal';

  @override
  String get staffAllActions => 'Barcha amallar';

  @override
  String get staffNoRecords => 'Yozuvlar topilmadi';

  @override
  String get staffNoRecordsHint => 'Davr yoki filtrlarni oʻzgartiring';

  @override
  String staffAuditLimit(String n) {
    return 'Oxirgi $n ta yozuv koʻrsatilgan — filtrni aniqlashtiring';
  }

  @override
  String get staffSystem => 'tizim';

  @override
  String get syncErrNetwork =>
      'Sinxronlash serveri bilan aloqa yoʻq. Internetni tekshiring.';

  @override
  String get syncErrAuth =>
      'Email yoki parol notoʻgʻri yoki sessiya tugagan. Qaytadan kiring.';

  @override
  String get syncErrForbidden => 'Bu doʻkonga kirish huquqi yoʻq.';

  @override
  String get syncErrEnvironmentMismatch =>
      'Demo-baza faqat test doʻkoniga ulanishi mumkin.';

  @override
  String get syncErrNotEmpty =>
      'Bu bazada allaqachon maʼlumotlar bor (tovarlar, sotuvlar, mijozlar). Uni mavjud doʻkonga ulab boʻlmaydi: ikki baza birlashtirilmaydi. Toza oʻrnatishdan foydalaning.';

  @override
  String get syncErrServer => 'Sinxronlash serverida xatolik.';

  @override
  String get syncErrNotConfigured => 'Sinxronlash sozlanmagan.';

  @override
  String get syncErrNotSignedIn => 'Avval sinxronlash hisobiga kiring.';

  @override
  String get syncErrInvalidProject =>
      'Loyiha ID si notoʻgʻri: faqat kichik lotin harflari, raqamlar va chiziqcha, 6 dan 30 tagacha belgi.';

  @override
  String get syncErrInvalidApiKey =>
      'Web API key notoʻgʻri. Uni Firebase loyihasi sozlamalaridan qaytadan nusxalang.';

  @override
  String get syncErrProjectMismatch =>
      'Web API key boshqa Firebase loyihasiga tegishli. Loyiha ID si va Web API key ni bitta loyihaning sozlamalaridan nusxalang.';

  @override
  String get syncErrSignInDisabled =>
      'Firebase loyihasida email va parol bilan kirish yoqilmagan (Authentication › Sign-in method › Email/Password).';

  @override
  String get syncErrAccountDisabled =>
      'Bu hisob Firebase loyihasida oʻchirilgan.';

  @override
  String get syncErrTooManyAttempts =>
      'Kirishga urinishlar juda koʻp. Bir necha daqiqa kutib, qaytadan urinib koʻring.';

  @override
  String get syncErrProtocol => 'Sinxronlash serveridan kutilmagan javob.';

  @override
  String get syncErrStoreNotFound => 'Doʻkon topilmadi.';

  @override
  String get syncErrAlreadyConnected =>
      'Bu baza allaqachon doʻkonga ulangan. Avval sinxronlashni oʻchiring.';

  @override
  String get syncPhaseOff => 'Oʻchirilgan';

  @override
  String get syncPhaseIdle => 'Sinxronlangan';

  @override
  String get syncPhaseSyncing => 'Sinxronlanmoqda…';

  @override
  String get syncPhaseError => 'Sinxronlash xatosi';

  @override
  String get syncPhaseOffline => 'Aloqa yoʻq';

  @override
  String get syncEnvTest => 'Test doʻkoni';

  @override
  String get syncEnvProduction => 'Ishchi doʻkon';

  @override
  String syncConflictTitle(String subject) {
    return 'Sinxronlash ziddiyati: $subject';
  }

  @override
  String syncConflictSubjectBarcode(String code) {
    return 'shtrix-kod $code';
  }

  @override
  String syncConflictSubjectCard(String code) {
    return 'mijoz kartasi $code';
  }

  @override
  String syncConflictSubjectGiftCard(String code) {
    return 'sertifikat $code';
  }

  @override
  String syncConflictSubjectStock(String name) {
    return '“$name” qoldigʻi';
  }

  @override
  String syncConflictSubjectBonus(String name) {
    return '“$name” bonuslari';
  }

  @override
  String syncConflictBarcodeBody(String code, String winner, String loser) {
    return '$code shtrix-kodi turli kassalarda ikki tovarga berilgan. U “$winner” tovarida qoldirildi, “$loser” tovarining shtrix-kodi tozalandi.';
  }

  @override
  String syncConflictCardBody(String code, String winner, String loser) {
    return '$code karta raqami turli kassalarda ikki mijozga berilgan. U “$winner” mijozida qoldirildi, “$loser” mijozining karta raqami tozalandi.';
  }

  @override
  String syncConflictGiftCodeBody(String code, String newCode) {
    return '$code sertifikat kodi turli kassalarda takrorlandi. Dublikat bloklandi va $newCode kodini oldi.';
  }

  @override
  String syncConflictStockBody(String name, String qty) {
    return '“$name” tovarining qoldigʻi turli kassalardagi sotuvlardan keyin manfiy boʻldi ($qty). Qoldiqni tekshiring.';
  }

  @override
  String syncConflictGiftBalanceBody(String code, String amount) {
    return '$code sertifikati turli kassalarda nominaldan koʻp sarflandi: balans $amount.';
  }

  @override
  String syncConflictBonusBody(String name, String amount) {
    return '“$name” mijozining bonuslari turli kassalardagi amallardan keyin manfiy boʻldi ($amount).';
  }

  @override
  String get syncSectionDesc =>
      'Bitta doʻkonning bir nechta kassasi bulut orqali umumiy tovarlar, mijozlar va sotuvlar bilan ishlaydi. Internet boʻlmasa ham kassa ishlayveradi, oʻzgarishlar aloqa paydo boʻlganda yuboriladi.';

  @override
  String get syncUnavailable =>
      'Dasturning bu versiyasida sinxronlash mavjud emas.';

  @override
  String get syncOffTitle => 'Sinxronlash oʻchirilgan';

  @override
  String get syncOffMessage =>
      'Bu kassa alohida ishlaydi. Barcha kassalar umumiy maʼlumotlarni koʻrishi uchun uni bulutdagi doʻkonga ulang.';

  @override
  String get syncConnect => 'Ulash';

  @override
  String get syncSyncNow => 'Hozir sinxronlash';

  @override
  String get syncDisconnect => 'Uzish';

  @override
  String get syncSignInAgain => 'Qayta kirish';

  @override
  String get syncStoreLabel => 'Doʻkon';

  @override
  String get syncDeviceCode => 'Kassa kodi';

  @override
  String syncDeviceCodeExample(String example) {
    return 'chek raqamlari: $example';
  }

  @override
  String get syncPending => 'Yuborilishi kutilmoqda';

  @override
  String get syncLastSync => 'Oxirgi sinxronlash';

  @override
  String get syncNever => 'hali boʻlmagan';

  @override
  String get syncAccount => 'Hisob';

  @override
  String syncNextRetry(String time) {
    return 'Keyingi urinish: $time';
  }

  @override
  String syncDoneToast(String pushed, String pulled) {
    return 'Sinxronlash tugadi: $pushed ta yuborildi, $pulled ta olindi';
  }

  @override
  String get syncDisconnectTitle => 'Sinxronlashni uzasizmi?';

  @override
  String syncDisconnectMessage(String store) {
    return 'Kassa “$store” doʻkoni bilan maʼlumot almashishni toʻxtatadi. Bu kassadagi barcha maʼlumotlar saqlanadi, chek raqamlari takrorlanmaydi. Istalgan vaqtda qayta ulanish mumkin.';
  }

  @override
  String get syncDisconnectedToast =>
      'Sinxronlash uzildi. Kassadagi maʼlumotlar saqlandi.';

  @override
  String get syncConnectTitle => 'Bulutga ulanish';

  @override
  String get syncSignInIntro =>
      'Firebase loyihasi ID si, Web API key va doʻkon egasining hisob maʼlumotlarini kiriting.';

  @override
  String get syncProjectId => 'Firebase loyihasi ID si *';

  @override
  String get syncProjectIdHint => 'masalan, dreampos-1a2b3';

  @override
  String get syncProjectIdHelp =>
      'Firebase › Project settings › General › Project ID';

  @override
  String get syncApiKey => 'Web API key *';

  @override
  String get syncApiKeyHelp =>
      'Oʻsha sahifada: Web API key (AIza bilan boshlanadi)';

  @override
  String get syncEmail => 'Email *';

  @override
  String get syncPassword => 'Parol *';

  @override
  String get syncPasswordShow => 'Parolni koʻrsatish';

  @override
  String get syncPasswordHide => 'Parolni yashirish';

  @override
  String get syncPasswordNote => 'Parol kassada saqlanmaydi.';

  @override
  String get syncSignIn => 'Kirish';

  @override
  String get syncInvalidEmail => 'Email notoʻgʻri';

  @override
  String syncSignedInAs(String email) {
    return 'Kirildi: $email';
  }

  @override
  String get syncChooseAction => 'Bu kassa bilan nima qilamiz?';

  @override
  String get syncCreateStore => 'Bulutda doʻkon yaratish';

  @override
  String get syncCreateStoreHint =>
      'Bu kassa birinchi boʻladi. Uning barcha maʼlumotlari bulutga yuklanadi.';

  @override
  String get syncJoinStore => 'Mavjud doʻkonga ulash';

  @override
  String get syncJoinStoreHint =>
      'Doʻkon maʼlumotlari bu kassaga yuklanadi. Faqat boʻsh baza uchun.';

  @override
  String get syncStoreName => 'Doʻkon nomi *';

  @override
  String get syncEnvironment => 'Doʻkon turi';

  @override
  String get syncEnvTestHint =>
      'Oʻrganish va tekshirish uchun. Demo-baza faqat bunga ulanadi.';

  @override
  String get syncEnvProductionHint =>
      'Haqiqiy ish uchun. Turini keyin oʻzgartirib boʻlmaydi.';

  @override
  String get syncEnvProductionDemo => 'Demo-baza uchun mavjud emas';

  @override
  String get syncCreateAndUpload => 'Yaratish va yuklash';

  @override
  String get syncChooseStore => 'Doʻkonni tanlang';

  @override
  String get syncNoStores =>
      'Bu hisobda doʻkonlar yoʻq. Birinchi kassada doʻkon yarating yoki egasidan sizni qoʻshishni soʻrang.';

  @override
  String get syncUploading => 'Maʼlumotlar bulutga yuklanmoqda…';

  @override
  String get syncDownloading => 'Doʻkon maʼlumotlari yuklanmoqda…';

  @override
  String syncConnectedToast(String store, String code) {
    return 'Kassa “$store” doʻkoniga ulandi. Kassa kodi: $code';
  }

  @override
  String get syncIntegrityTitle => 'Yaxlitlikni tekshirish';

  @override
  String get syncIntegrityDesc =>
      'Qoldiqlar, qarzlar, bonuslar va balanslarni harakat jurnallari bilan solishtiradi. Hech narsani oʻzgartirmaydi.';

  @override
  String get syncIntegrityRun => 'Tekshirish';

  @override
  String get syncIntegrityNotRun => 'Tekshiruv hali oʻtkazilmagan.';

  @override
  String get syncIntegrityOk =>
      'Farqlar yoʻq: barcha qoldiq va balanslar jurnallarga mos.';

  @override
  String syncIntegrityFound(String count) {
    return 'Topilgan farqlar: $count';
  }

  @override
  String syncIntegrityValues(String cached, String derived) {
    return 'saqlangan $cached · jurnal boʻyicha $derived';
  }

  @override
  String get syncCacheStock => 'Tovar qoldigʻi';

  @override
  String get syncCacheDebt => 'Mijoz qarzi';

  @override
  String get syncCacheBonus => 'Mijoz bonuslari';

  @override
  String get syncCacheSupplierBalance => 'Taʼminotchi balansi';

  @override
  String get syncCacheGiftBalance => 'Sertifikat balansi';

  @override
  String get syncCacheGiftStatus => 'Sertifikat holati';

  @override
  String get syncCachePoPaid => 'Buyurtma boʻyicha toʻlangan';

  @override
  String get syncCachePoReceived => 'Buyurtma pozitsiyasi boʻyicha olingan';

  @override
  String get syncCacheSaleRefunded => 'Chek boʻyicha qaytarilgan';

  @override
  String get syncCacheSaleStatus => 'Chek holati';

  @override
  String get syncCacheReturnedQty => 'Chek pozitsiyasi boʻyicha qaytarilgan';

  @override
  String get syncConflictsTitle => 'Sinxronlash ziddiyatlari';

  @override
  String get syncConflictsSubtitle =>
      'Kassalar oʻrtasida maʼlumot almashishda avtomatik hal qilingan holatlar';

  @override
  String get syncConflictsEmpty => 'Ziddiyatlar yoʻq';

  @override
  String get syncConflictsShowResolved => 'Koʻrilganlarni koʻrsatish';

  @override
  String get syncConflictsMarkAll => 'Hammasini koʻrilgan deb belgilash';

  @override
  String get syncConflictMarkRead => 'Koʻrilgan deb belgilash';

  @override
  String get syncConflictKindBarcode => 'Shtrix-kod takrorlandi';

  @override
  String get syncConflictKindCard => 'Karta raqami takrorlandi';

  @override
  String get syncConflictKindGiftCode => 'Sertifikat kodi takrorlandi';

  @override
  String get syncConflictKindStock => 'Manfiy qoldiq';

  @override
  String get syncConflictKindGiftBalance => 'Sertifikatning manfiy balansi';

  @override
  String get syncConflictKindBonus => 'Manfiy bonuslar';

  @override
  String get syncConflictKindNormalize => 'Yangilashda tekislash';

  @override
  String get syncConflictKindOther => 'Ziddiyat';

  @override
  String syncIndicatorTooltip(String state, String count) {
    return '$state. Yuborilishi kutilmoqda: $count. Sinxronlash uchun bosing.';
  }

  @override
  String syncSubjectReceipt(String number) {
    return 'Chek №$number';
  }

  @override
  String syncSubjectOrder(String number) {
    return 'Buyurtma №$number';
  }

  @override
  String get syncErrTestData =>
      'Bu baza test doʻkoniga ulangan edi va boshqa kassalarning test maʼlumotlarini oʻz ichiga olishi mumkin. Undan ishchi doʻkon yaratib boʻlmaydi: test maʼlumotlarisiz bazadan foydalaning.';

  @override
  String syncConflictSubjectSale(String number) {
    return 'chek №$number';
  }

  @override
  String syncConflictSubjectDocNumber(String number) {
    return 'hujjat raqami $number';
  }

  @override
  String get syncConflictSubjectDevice => 'kassa kodi';

  @override
  String syncConflictNumberBody(String number, String newNumber) {
    return '$number raqami ikki xil hujjatda chiqdi (masalan, ulangan kassada zaxira nusxa tiklangandan keyin). Yangiroq hujjat $newNumber raqamini oldi.';
  }

  @override
  String syncConflictVoidReturnBody(String number, String amount) {
    return 'Chek №$number bir kassada bekor qilindi, boshqasida esa u boʻyicha $amount qaytarish rasmiylashtirildi. Pul va tovar ikki marta hisobga olindi: kassa va qoldiqlarni tekshiring.';
  }

  @override
  String syncConflictOverReturnBody(
    String number,
    String refunded,
    String total,
  ) {
    return 'Chek №$number boʻyicha turli kassalarda sotilganidan koʻproq qaytarildi: chek summasi $total boʻlgani holda $refunded qaytarildi. Kassa va qoldiqlarni tekshiring.';
  }

  @override
  String syncConflictIdentityBody(String oldCode, String newCode) {
    return 'Bu baza ishlashda davom etgan $oldCode kassasining nusxasi boʻlib chiqdi (zaxira nusxa tiklangan yoki baza boshqa kompyuterga koʻchirilgan). Nusxada boʻlmagan maʼlumotlar bulutdan yuklandi, kassa esa hujjat raqamlari takrorlanmasligi uchun yangi $newCode kodini oldi.';
  }

  @override
  String get syncConflictKindNumber => 'Hujjat raqami takrorlandi';

  @override
  String get syncConflictKindVoidReturn =>
      'Bekor qilingan chek boʻyicha qaytarish';

  @override
  String get syncConflictKindOverReturn => 'Qaytarish sotuvdan koʻp';

  @override
  String get syncConflictKindIdentity => 'Kassa bazasining nusxasi';

  @override
  String get syncConflictKindDoubleVoid =>
      'Sertifikat ikki marta bekor qilindi';

  @override
  String syncConflictDoubleVoidBody(
    String code,
    String number,
    String amount,
    String shift,
  ) {
    return '$code sertifikat sotuvi (№$number) ikki kassada bekor qilindi va pul ($amount) ikki marta qaytarildi. Faqat bitta bekor qilish hisobga olindi: №$shift smena hisobotida bu qaytarish yoʻq. Kassani tekshiring.';
  }

  @override
  String get syncConflictKindVoidRedeem =>
      'Bekor qilingan sertifikat bilan toʻlov';

  @override
  String syncConflictVoidRedeemBody(String code, String amount) {
    return '$code sertifikati bir kassada bekor qilindi (pul qaytarildi), boshqasida esa u bilan $amount toʻlandi. Summa ikki marta hisobga olindi: kassani tekshiring.';
  }

  @override
  String syncJoinRejoinHint(String name) {
    return 'Bazada allaqachon maʼlumotlar bor, shuning uchun faqat bu kassa uzilgan “$name” doʻkoniga ulanish mumkin.';
  }

  @override
  String get syncConflictKindJoinUsers => 'Bu kassaning xodimlari oʻchirildi';

  @override
  String get syncConflictSubjectJoinUsers => 'bu kassaning xodimlari';

  @override
  String syncConflictJoinUsersBody(String names) {
    return 'Doʻkonga ulanishda bu kassada ulanishdan oldin yaratilgan xodimlar oʻchirildi: $names. Ularning PIN-kodlari doʻkon xodimlarining PIN-kodlari bilan mos kelishi mumkin edi. Doʻkon xodimlarining PIN-kodlari bilan kiring; kerakli xodimni yangi PIN-kod bilan qayta yoqish mumkin.';
  }

  @override
  String get syncConflictKindRejected =>
      'Bulutdan kelgan oʻzgarish oʻtkazib yuborildi';

  @override
  String syncConflictRejectedBody(String entity, String id) {
    return '$entity yozuvining ($id) oʻzgarishi bulutdan buzilgan holda yoki mos kelmaydigan dastur versiyasidan keldi, shuning uchun u oʻtkazib yuborildi. Qolgan maʼlumotlar odatdagidek sinxronlanadi. Barcha kassalarda DreamPOSning bir xil versiyasi oʻrnatilganini tekshiring.';
  }

  @override
  String get syncErrEmailExists =>
      'Bu email bilan hisob allaqachon mavjud. U bilan kiring («Kirish») yoki boshqa email kiriting.';

  @override
  String get syncErrWeakPassword =>
      'Bulut parolni qabul qilmadi: u juda oddiy. Uzunroq parol oʻylab toping (kamida 8 ta belgi, harflar va raqamlar).';

  @override
  String get syncErrInvalidEmail =>
      'Bulut bu emailni qabul qilmadi. Manzilni tekshiring.';

  @override
  String get syncErrSignUpDisabled =>
      'Firebase loyihasida yangi hisoblarni roʻyxatdan oʻtkazish oʻchirilgan (Authentication › Settings › User actions › Enable create (sign-up)). Hisobni Firebase konsolida yarating (Authentication › Users › Add user) va u bilan kiring yoki roʻyxatdan oʻtishni vaqtincha yoqing.';

  @override
  String get syncErrSignUpTooManyAttempts =>
      'Bu qurilmadan roʻyxatdan oʻtishga urinishlar juda koʻp. Bir necha daqiqa kutib, qaytadan urinib koʻring.';

  @override
  String get syncAuthModeSignIn => 'Kirish';

  @override
  String get syncAuthModeSignUp => 'Ega hisobini yaratish';

  @override
  String get syncSignUpIntro =>
      'Firebase loyihangizda doʻkon egasining yangi hisobi yaratiladi. Soʻng bulutda doʻkon yaratasiz yoki mavjud doʻkonga ulanasiz.';

  @override
  String get syncPasswordNewHelp =>
      'Kamida 8 ta belgi. Parol kassada saqlanmaydi.';

  @override
  String get syncPasswordRepeat => 'Parolni takrorlang *';

  @override
  String get syncPasswordTooShort => 'Kamida 8 ta belgi';

  @override
  String get syncPasswordMismatch => 'Parollar mos kelmaydi';

  @override
  String get syncSignUpSubmit => 'Hisob yaratish';

  @override
  String get syncNoAccountSignUp => 'Hisobingiz yoʻqmi? Roʻyxatdan oʻtish';

  @override
  String get syncHaveAccountSignIn => 'Hisobingiz bormi? Kirish';

  @override
  String syncAccountCreated(String email) {
    return 'Hisob yaratildi: $email';
  }

  @override
  String get syncNewAccountNoStores =>
      'Yangi hisobda hali doʻkonlar yoʻq. «Yangi doʻkon yaratish» tugmasini bosing, doʻkonni sozlang, soʻng Sozlamalar › Sinxronlash boʻlimida shu hisob bilan kirib, «Bulutda doʻkon yaratish»ni tanlang.';

  @override
  String get syncErrPasswordPolicy =>
      'Parol Firebase loyihangizning parol talablariga mos kelmaydi (Authentication › Settings › Password policy): masalan, bosh harflar, raqamlar yoki belgilar kerak. Shu talablarga mos parol oʻylab toping.';

  @override
  String get syncSignUpDisableHint =>
      'Ega hisobi yaratildi. Endi Firebase konsolida mustaqil roʻyxatdan oʻtishni yoping: Authentication › Settings › User actions — «Enable create (sign-up)» belgisini olib tashlang. Aks holda Web API key kalitini bilgan har kim hisob ochishi mumkin.';

  @override
  String get syncSignInWithThisEmail => 'Shu email bilan kirish';

  @override
  String get warrantyTitle => 'Kafolat';

  @override
  String get warrantySubtitle => 'Kafolat va servis arizalari';

  @override
  String get warrantyStatusReceived => 'Qabul qilingan';

  @override
  String get warrantyStatusInRepair => 'Taʼmirda';

  @override
  String get warrantyStatusReplaced => 'Almashtirilgan';

  @override
  String get warrantyStatusRefunded => 'Pul qaytarilgan';

  @override
  String get warrantyStatusRejected => 'Rad etilgan';

  @override
  String get warrantyStatusReturned => 'Mijozga berilgan';

  @override
  String get warrantyActionInRepair => 'Taʼmirga berish';

  @override
  String get warrantyActionReplace => 'Mahsulotni almashtirish';

  @override
  String get warrantyActionRefund => 'Pulni qaytarish';

  @override
  String get warrantyActionReject => 'Rad etish';

  @override
  String get warrantyActionReturn => 'Mijozga berish';

  @override
  String get warrantyGroupOpen => 'Jarayonda';

  @override
  String get warrantyGroupResolved => 'Hal qilingan';

  @override
  String get warrantyGroupClosed => 'Berilgan';

  @override
  String get warrantyNotSet => 'belgilanmagan';

  @override
  String warrantyActUntilActive(String date) {
    return '$date gacha (amalda)';
  }

  @override
  String warrantyActUntilExpired(String date) {
    return '$date gacha (muddati oʻtgan)';
  }

  @override
  String get warrantyActTitle =>
      'MAHSULOTNI KAFOLAT XIZMATIGA QABUL QILISH DALOLATNOMASI';

  @override
  String warrantyActNumber(String number, String date) {
    return '№$number, $date';
  }

  @override
  String get warrantySerialNumber => 'Seriya raqami';

  @override
  String get warrantyActPurchaseDoc => 'Xarid hujjati';

  @override
  String get warrantyActNotPresented => 'taqdim etilmagan';

  @override
  String warrantyReceiptRef(String number, String date) {
    return 'chek №$number, $date';
  }

  @override
  String get warrantyWarranty => 'Kafolat';

  @override
  String get warrantyActProblem => 'Bildirilgan nosozlik';

  @override
  String get warrantyActCompleteness => 'Butlik va tashqi koʻrinish';

  @override
  String get warrantyResolution => 'Qaror';

  @override
  String get warrantyActTerms =>
      'Ariza isteʼmolchilar huquqlarini himoya qilish toʻgʻrisidagi qonunchilikka muvofiq muddatda koʻrib chiqiladi. Mahsulot ushbu dalolatnoma taqdim etilganda beriladi.';

  @override
  String get warrantyActHandedBy => 'Topshirdi (mijoz):';

  @override
  String get warrantyActReceivedBy => 'Qabul qildi (xodim):';

  @override
  String warrantyActJobName(String number) {
    return 'Kafolat $number';
  }

  @override
  String warrantyClaimAccepted(String number) {
    return 'Ariza №$number qabul qilindi';
  }

  @override
  String get warrantyPrintActQuestion =>
      'Mijoz imzosi uchun qabul dalolatnomasini chop etasizmi?';

  @override
  String get warrantyPrintAct => 'Dalolatnomani chop etish';

  @override
  String get warrantySearchHintWide =>
      'Ariza yoki chek raqami, mijoz, seriya raqami, mahsulot';

  @override
  String get warrantySearchHint => 'Ariza, chek, mijoz, S/N, mahsulot';

  @override
  String get warrantyNewClaim => 'Yangi ariza';

  @override
  String get warrantyClaimFab => 'Ariza';

  @override
  String get warrantySelectClaim => 'Arizani tanlang';

  @override
  String get warrantySelectClaimHint =>
      'Ariza kartasi, holatni oʻzgartirish va dalolatnomani chop etish';

  @override
  String get warrantyEmptyTitle => 'Hozircha arizalar yoʻq';

  @override
  String get warrantyEmptyFiltered =>
      'Qidiruvni oʻzgartiring yoki boshqa holatni tanlang';

  @override
  String get warrantyEmptyHint =>
      'Mahsulotni chek raqami boʻyicha yoki qoʻlda kafolatga qabul qiling';

  @override
  String get warrantyShowMore => 'Yana koʻrsatish';

  @override
  String get warrantyNoProduct => 'mahsulot koʻrsatilmagan';

  @override
  String warrantyReceiptShort(String number) {
    return 'chek №$number';
  }

  @override
  String warrantyDaysShort(String days) {
    return '$days kun';
  }

  @override
  String get warrantyClaimTitle => 'Kafolat arizasi';

  @override
  String get warrantyClaimNotFound => 'Ariza topilmadi';

  @override
  String warrantyClaimNumber(String number) {
    return 'Ariza №$number';
  }

  @override
  String warrantyAcceptedAt(String date) {
    return 'qabul qilingan: $date';
  }

  @override
  String get warrantyActButton => 'Qabul dalolatnomasi';

  @override
  String get warrantyProductName => 'Nomi';

  @override
  String get warrantyPurchase => 'Xarid';

  @override
  String get warrantyNoReceipt => 'cheksiz';

  @override
  String get warrantyOpenReceipt => 'Chekni ochish';

  @override
  String warrantyUntil(String date) {
    return '$date gacha';
  }

  @override
  String warrantyExpiredOn(String date) {
    return '$date da tugagan';
  }

  @override
  String get warrantyNotSpecified => 'koʻrsatilmagan';

  @override
  String get warrantyProblem => 'Nosozlik';

  @override
  String get warrantyHistory => 'Tarix';

  @override
  String get warrantyHistoryCreated => 'Ariza qabul qilindi';

  @override
  String warrantyStatusChanged(String status) {
    return 'Holat: $status';
  }

  @override
  String warrantyStatusChangedWriteOff(String status) {
    return 'Holat: $status · 1 dona hisobdan chiqarildi';
  }

  @override
  String get warrantyRefundTitle => 'Pul qaytarishni rasmiylashtiring';

  @override
  String get warrantyRefundMessage =>
      'Pul faqat “Cheklar” boʻlimida chek boʻyicha qaytarish orqali qaytariladi — shunda kassa, ombor va hisobotlar toʻgʻri qoladi. Rasmiylashtirishga oʻtasizmi?';

  @override
  String get warrantyOpenReceipts => '“Cheklar”ni ochish';

  @override
  String warrantyOpenReceiptNumber(String number) {
    return 'Chek №$number ni ochish';
  }

  @override
  String get warrantyRefundHint =>
      'Qaror — pulni qaytarish. Chek boʻyicha qaytarishni rasmiylashtiring (omborga qaytarmasdan).';

  @override
  String get warrantyToReceipt => 'Chekka';

  @override
  String get warrantyHintInRepair => 'Servis markazi, taxminiy muddat';

  @override
  String get warrantyHintReplaced =>
      'Masalan: yangisiga almashtirildi, seriya № …';

  @override
  String get warrantyHintRefunded =>
      'Masalan: nuqson tasdiqlandi, pul qaytarildi';

  @override
  String get warrantyHintRejected =>
      'Rad etish sababi: zarba izlari, ochilgan, shartlar buzilgan…';

  @override
  String get warrantyHintReturned => 'Kimga va qachon berildi';

  @override
  String warrantyTransition(String number, String from, String to) {
    return 'Ariza №$number: $from → $to';
  }

  @override
  String get warrantyResolutionRequired => 'Qaror *';

  @override
  String get warrantyEnterResolution => 'Qarorni kiriting';

  @override
  String get warrantyWriteOffOne => 'Ombordan 1 dona hisobdan chiqarish';

  @override
  String get warrantyWriteOffHint =>
      'Sabab: “Kafolat boʻyicha almashtirish” — mijozga berilgan mahsulot qoldiqdan chiqadi';

  @override
  String get warrantyWriteOffUnavailable =>
      'Mavjud emas: ombor operatsiyalariga huquq yoʻq yoki mahsulot koʻrsatilmagan';

  @override
  String get warrantyRefundNote =>
      'Holat pulni harakatlantirmaydi. Saqlagandan soʻng “Cheklar” boʻlimida chek boʻyicha qaytarishni rasmiylashtiring.';

  @override
  String get warrantyNewClaimTitle => 'Yangi kafolat arizasi';

  @override
  String get warrantyEnterReceiptDigits =>
      'Chek raqamini faqat raqamlar bilan kiriting';

  @override
  String warrantyReceiptNotFound(String number) {
    return 'Chek №$number topilmadi';
  }

  @override
  String get warrantyBlockVoided => 'chek bekor qilingan';

  @override
  String get warrantyBlockReturned => 'mahsulot qaytarilgan';

  @override
  String get warrantyExpiredTitle => 'Kafolat muddati tugagan';

  @override
  String get warrantyNotSetTitle => 'Kafolat belgilanmagan';

  @override
  String get warrantyPaidRepairQuestion =>
      'Arizani pullik taʼmir yoki ekspertiza sifatida qabul qilish mumkin. Qabul qilasizmi?';

  @override
  String get warrantyAccept => 'Qabul qilish';

  @override
  String get warrantyDuplicateTitle => 'Ochiq ariza allaqachon bor';

  @override
  String warrantyDuplicateMessage(String number, String status) {
    return 'Chekdagi bu mahsulot boʻyicha ariza №$number allaqachon qabul qilingan ($status). Yana bittasini yaratasizmi?';
  }

  @override
  String get warrantyFindReceiptAndItem =>
      'Chekni toping va undan mahsulotni tanlang';

  @override
  String get warrantySelectProduct => 'Mahsulotni tanlang';

  @override
  String get warrantyByReceipt => 'Chek boʻyicha';

  @override
  String get warrantyWithoutReceipt => 'Cheksiz';

  @override
  String get warrantySerialImei => 'Seriya raqami / IMEI';

  @override
  String get warrantyProblemLabel => 'Nosozlik tavsifi *';

  @override
  String get warrantyProblemHint =>
      'Nima ishlamayapti, qachon paydo boʻldi, tashqi koʻrinish, butlik';

  @override
  String get warrantyDescribeProblem => 'Nosozlikni tavsiflang';

  @override
  String get warrantySubmit => 'Arizani qabul qilish';

  @override
  String get warrantyReceiptNumber => 'Chek raqami';

  @override
  String get warrantyFind => 'Topish';

  @override
  String warrantyReceiptPickItem(String number, String date) {
    return 'Chek №$number, $date — mahsulotni tanlang';
  }

  @override
  String get warrantyReceiptVoided =>
      'Chek bekor qilingan — u boʻyicha mahsulotni qabul qilib boʻlmaydi. “Cheksiz” rejimidan foydalaning.';

  @override
  String get warrantyNoWarranty => 'kafolatsiz';

  @override
  String warrantyChipUntil(String date) {
    return 'kafolat $date gacha';
  }

  @override
  String warrantyChipExpired(String date) {
    return 'kafolat $date da tugagan';
  }

  @override
  String warrantyBannerActive(String date) {
    return '$date gacha kafolatda';
  }

  @override
  String warrantyBannerExpired(String date) {
    return 'Kafolat $date da tugagan. Arizani pullik taʼmir sifatida qabul qilish mumkin.';
  }

  @override
  String get warrantyBannerNone => 'Bu mahsulotga kafolat belgilanmagan';

  @override
  String get warrantySelectProductRequired => 'Mahsulotni tanlang *';

  @override
  String get warrantyRequiredNoReceipt => 'Cheksiz ariza uchun majburiy';

  @override
  String get warrantyManualHint =>
      'Cheksiz yoki tizimdan tashqari sotilgan mahsulot uchun';

  @override
  String get warrantyCustomerOptional => 'Mijoz (ixtiyoriy)';

  @override
  String get warrantyCustomerHint => 'Tayyor boʻlganda bogʻlanish uchun kerak';

  @override
  String get warrantyRemoveCustomer => 'Mijozni olib tashlash';

  @override
  String get warrantyReceiptLineNotFound => 'Chek pozitsiyasi topilmadi';

  @override
  String warrantyCannotTransition(String from, String to) {
    return 'Arizani “$from” holatidan “$to” holatiga oʻtkazib boʻlmaydi';
  }

  @override
  String get warrantyEnterClaimResolution => 'Ariza boʻyicha qarorni kiriting';

  @override
  String get warrantyWriteOffOnlyReplace =>
      'Hisobdan chiqarish faqat almashtirishda mumkin';

  @override
  String get warrantyNoProductInClaim => 'Arizada mahsulot koʻrsatilmagan';

  @override
  String get warrantyStockUnavailable => 'Ombor mavjud emas';

  @override
  String get warrantyChangedByOther =>
      'Ariza boshqa foydalanuvchi tomonidan allaqachon oʻzgartirilgan';
}
