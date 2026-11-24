// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Error';

  @override
  String get commonEmpty => 'No data';

  @override
  String get commonNothingFound => 'Nothing found';

  @override
  String get commonPrint => 'Print';

  @override
  String get commonExport => 'Export';

  @override
  String get commonImport => 'Import';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonDate => 'Date';

  @override
  String get commonTime => 'Time';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonQty => 'Quantity';

  @override
  String get commonPrice => 'Price';

  @override
  String get commonCost => 'Cost';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonReason => 'Reason';

  @override
  String get commonComment => 'Comment';

  @override
  String get commonNote => 'Note';

  @override
  String get commonName => 'Name';

  @override
  String get commonPersonName => 'Name';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonAddress => 'Address';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonAll => 'All';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonPeriod => 'Period';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonWeek => 'Week';

  @override
  String get commonMonth => 'Month';

  @override
  String get commonYear => 'Year';

  @override
  String get commonActions => 'Actions';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonMore => 'More';

  @override
  String get commonShowAll => 'Show all';

  @override
  String get commonRequired => 'Required field';

  @override
  String get commonInvalidAmount => 'Invalid amount';

  @override
  String get commonEnterNumber => 'Enter a number';

  @override
  String get commonMustBePositive => 'Must be greater than zero';

  @override
  String get commonAmountMustBePositive => 'Must be greater than zero';

  @override
  String get commonCannotBeNegative => 'Cannot be negative';

  @override
  String get commonIntegerOnly => 'Whole numbers only';

  @override
  String get commonEnterName => 'Enter a name';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonProduct => 'Product';

  @override
  String get commonProducts => 'Products';

  @override
  String get commonCustomer => 'Customer';

  @override
  String get commonCustomers => 'Customers';

  @override
  String get commonSupplier => 'Supplier';

  @override
  String get commonCashier => 'Cashier';

  @override
  String get commonEmployee => 'Employee';

  @override
  String get commonShift => 'Shift';

  @override
  String get commonReceipt => 'Receipt';

  @override
  String get commonSale => 'Sale';

  @override
  String get commonReturn => 'Return';

  @override
  String get commonPayment => 'Payment';

  @override
  String get commonPaymentMethod => 'Payment method';

  @override
  String get commonDiscount => 'Discount';

  @override
  String get commonChange => 'Change';

  @override
  String get commonDebt => 'Debt';

  @override
  String get commonBonuses => 'Bonuses';

  @override
  String get commonBalance => 'Balance';

  @override
  String get commonGiftCard => 'Gift card';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonBarcode => 'Barcode';

  @override
  String get commonSku => 'SKU';

  @override
  String get commonStock => 'Stock';

  @override
  String get commonUnit => 'Unit';

  @override
  String get commonVat => 'VAT';

  @override
  String get commonDocument => 'Document';

  @override
  String get commonVoided => 'Voided';

  @override
  String get commonEnabled => 'On';

  @override
  String get commonDisabled => 'Off';

  @override
  String get commonNew => 'New';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonCustomerNotFound => 'Customer not found';

  @override
  String commonPositionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String commonDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '$count document',
    );
    return '$_temp0';
  }

  @override
  String commonReceiptsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts',
      one: '$count receipt',
    );
    return '$_temp0';
  }

  @override
  String commonReturnsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count returns',
      one: '$count return',
    );
    return '$_temp0';
  }

  @override
  String commonMarksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '$count entry',
    );
    return '$_temp0';
  }

  @override
  String commonProductsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '$count product',
    );
    return '$_temp0';
  }

  @override
  String commonCustomersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '$count customer',
    );
    return '$_temp0';
  }

  @override
  String commonDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get payCash => 'Cash';

  @override
  String get payCard => 'Card';

  @override
  String get payTransfer => 'Transfer';

  @override
  String get payBonus => 'Bonuses';

  @override
  String get payDebt => 'On credit';

  @override
  String get payGiftCard => 'Gift card';

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'l';

  @override
  String get unitM => 'm';

  @override
  String get unitPack => 'pack';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleStorekeeper => 'Storekeeper';

  @override
  String get coreLanguage => 'Language';

  @override
  String get coreUiLanguage => 'Interface language';

  @override
  String get coreReceiptLanguage => 'Receipt language';

  @override
  String get coreDuplicateBarcode =>
      'A product with this barcode already exists';

  @override
  String get coreDuplicateCard => 'A card with this number already exists';

  @override
  String get coreDuplicateCode => 'This code already exists';

  @override
  String get coreDuplicateRecord => 'This record already exists';

  @override
  String get coreErase => 'Erase';

  @override
  String get corePickProductTitle => 'Select product';

  @override
  String get corePickProductHint => 'Name, SKU or barcode';

  @override
  String coreSkuShort(String sku) {
    return 'SKU $sku';
  }

  @override
  String coreStockShort(String qty) {
    return 'stock $qty';
  }

  @override
  String get coreNewCustomer => 'New customer';

  @override
  String get coreNameRequiredLabel => 'Name *';

  @override
  String get coreCustomerSearchHint => 'Name, phone or card number';

  @override
  String get coreCreateCustomer => 'Create customer';

  @override
  String coreCardShort(String number) {
    return 'card $number';
  }

  @override
  String coreDiscountShort(String percent) {
    return 'discount $percent%';
  }

  @override
  String coreDebtShort(String amount) {
    return 'debt $amount';
  }

  @override
  String coreBonusShort(String amount) {
    return 'bonuses $amount';
  }

  @override
  String get corePinFormat => 'PIN must be 4–8 digits';

  @override
  String get corePinTooSimple => 'PIN is too simple';

  @override
  String corePrintPhone(String phone) {
    return 'Tel: $phone';
  }

  @override
  String corePrintTaxId(String taxId) {
    return 'TIN: $taxId';
  }

  @override
  String coreReceiptTitle(String number) {
    return 'RECEIPT No. $number';
  }

  @override
  String coreReceiptCopyTitle(String number) {
    return 'RECEIPT COPY No. $number';
  }

  @override
  String corePrintCashier(String name) {
    return 'Cashier: $name';
  }

  @override
  String corePrintCustomer(String name) {
    return 'Customer: $name';
  }

  @override
  String corePrintWarrantyUntil(String date) {
    return 'Warranty until $date';
  }

  @override
  String get corePrintTotal => 'TOTAL';

  @override
  String get corePrintVatIncluded => 'incl. VAT';

  @override
  String get corePrintBonusEarned => 'Bonuses earned';

  @override
  String get corePrintCustomerDebt => 'Customer debt';

  @override
  String get corePrintVoided => '*** VOIDED ***';

  @override
  String corePrintReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String corePrintJobReceipt(String number) {
    return 'Receipt $number';
  }

  @override
  String corePrintJobGift(String number) {
    return 'Gift card $number';
  }

  @override
  String coreGiftSlipTitle(String number) {
    return 'Gift card sale No. $number';
  }

  @override
  String coreGiftSlipCopyTitle(String number) {
    return 'COPY · Gift card sale No. $number';
  }

  @override
  String get coreGiftSlipNote =>
      'This gift card is not a fiscal receipt for goods';

  @override
  String get coreGiftCode => 'Gift card code';

  @override
  String get coreGiftFaceValue => 'Face value';

  @override
  String get coreGiftValidity => 'Valid until';

  @override
  String get coreGiftNoExpiry => 'no expiry';

  @override
  String coreGiftUntil(String date) {
    return 'until $date';
  }

  @override
  String get navDashboard => 'Overview';

  @override
  String get navPos => 'Register';

  @override
  String get navSales => 'Receipts';

  @override
  String get navShifts => 'Shift';

  @override
  String get navProducts => 'Products';

  @override
  String get navInventory => 'Stock';

  @override
  String get navPurchasing => 'Purchasing';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navMarketing => 'Marketing';

  @override
  String get navWarranty => 'Warranty';

  @override
  String get navReports => 'Reports';

  @override
  String get navStaff => 'Staff';

  @override
  String get navSettings => 'Settings';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get appMenu => 'Menu';

  @override
  String get appShiftClosed => 'Shift closed';

  @override
  String appShiftChip(String number, String time) {
    return 'Shift No. $number · since $time';
  }

  @override
  String get appProfile => 'Profile';

  @override
  String get appLockSwitch => 'Lock / switch cashier';

  @override
  String get domCustomerDiscount => 'Customer discount';

  @override
  String get errPinInUse => 'This PIN is already used by another employee';

  @override
  String errTooManyAttempts(String minutes) {
    return 'Too many wrong attempts. Wait $minutes minutes';
  }

  @override
  String get errAccountLockedTryLater =>
      'Account is temporarily locked. Try again later';

  @override
  String get errAccountLocked => 'Account is temporarily locked';

  @override
  String get errWrongPin => 'Wrong PIN';

  @override
  String get errAmountMustBePositive => 'Amount must be greater than zero';

  @override
  String get errNoDebt => 'The customer has no debt';

  @override
  String get errAmountExceedsDebt => 'Amount exceeds the customer’s debt';

  @override
  String get errOpenShiftForCash => 'Open a shift to accept cash';

  @override
  String get errBonusNegative => 'Bonus balance cannot be negative';

  @override
  String get errGiftCodeTooShort =>
      'Gift card code must be at least 6 characters';

  @override
  String get errGiftCodeTooLong => 'Gift card code is too long';

  @override
  String get errGiftCodeChars => 'Code: Latin letters and digits only';

  @override
  String get errFaceValuePositive => 'Face value must be greater than zero';

  @override
  String get errExpiryPassed => 'The expiry date has already passed';

  @override
  String get errOpenShiftToSellGift => 'Open a shift to sell a gift card';

  @override
  String get errChoosePaymentMethod => 'Choose a payment method';

  @override
  String get errGiftPaymentMethods =>
      'A gift card can be paid only by cash, card or transfer';

  @override
  String get errPaymentMustBePositive =>
      'Payment amount must be greater than zero';

  @override
  String get errGiftPaymentsMismatch =>
      'Payments do not match the gift card face value';

  @override
  String get errCashNotInPayment => 'Cash is not part of the payment';

  @override
  String get errCashTenderedLess => 'Cash received is less than the amount due';

  @override
  String errGiftCodeExists(String code) {
    return 'A gift card with code $code already exists';
  }

  @override
  String get errDocumentNotFound => 'Document not found';

  @override
  String get errGiftSaleAlreadyVoided => 'The sale is already voided';

  @override
  String get errGiftNotFound => 'Gift card not found';

  @override
  String get errGiftUsedCannotVoid =>
      'The gift card has been used — it cannot be voided';

  @override
  String get errVoidReasonRequired => 'Enter the reason for voiding';

  @override
  String get errOpenShiftToVoid => 'Open a shift to void the sale';

  @override
  String errGiftSaleNumberVoided(String number) {
    return 'Gift card sale No. $number is already voided';
  }

  @override
  String get errAddLine => 'Add at least one line';

  @override
  String get errPurchasePriceNegative => 'Purchase price cannot be negative';

  @override
  String get errRetailPricePositive => 'Retail price must be greater than zero';

  @override
  String get errProductNotFound => 'Product not found';

  @override
  String errProductDeleted(String name) {
    return 'Product “$name” has been deleted';
  }

  @override
  String errLinePurchasePriceNegative(String name) {
    return '$name: purchase price is negative';
  }

  @override
  String errProductRepeated(String name) {
    return 'Product “$name” appears more than once — merge the lines';
  }

  @override
  String get errSupplierNotFound => 'Supplier not found';

  @override
  String get errOrderNotFound => 'Order not found';

  @override
  String get errOrderOtherSupplier => 'The order belongs to another supplier';

  @override
  String errOrderClosed(String number) {
    return 'Order No. $number is already closed';
  }

  @override
  String get errOrderLineNotFound => 'The item is not in the order';

  @override
  String get errOrderLineWithoutOrder =>
      'An order item is given without the order';

  @override
  String get errReversalReasonRequired => 'Enter the reason for the reversal';

  @override
  String get errReceiptNotFound => 'Goods receipt not found';

  @override
  String errReceiptAlreadyReversed(String number) {
    return 'Goods receipt No. $number is already reversed';
  }

  @override
  String errSupplierDeletedNoReversal(String name, String number) {
    return 'Supplier “$name” has been deleted — goods receipt No. $number cannot be reversed';
  }

  @override
  String get errQtyMustBePositive => 'Quantity must be greater than zero';

  @override
  String errQtyIntegerOnly(String unit) {
    return 'Only whole numbers are allowed for “$unit”';
  }

  @override
  String get errQtyTooLarge => 'Quantity is too large';

  @override
  String get errCartEmpty => 'The receipt is empty';

  @override
  String get errPriceNegative => 'Price cannot be negative';

  @override
  String get errPaymentNegative => 'Payment amount cannot be negative';

  @override
  String errUnknownPaymentMethodNamed(String method) {
    return 'Unknown payment method: $method';
  }

  @override
  String get errUnknownPaymentMethod => 'Unknown payment method';

  @override
  String get errOpenShiftToSell => 'Open a shift to sell';

  @override
  String get errShiftClosedOpenNew => 'The shift is closed. Open a new shift';

  @override
  String get errProductNotFoundOrDeleted => 'Product not found or deleted';

  @override
  String get errPromoInvalid => 'Invalid promo code';

  @override
  String errManualDiscountLimit(String percent, String limit) {
    return 'Manual discount $percent% exceeds the allowed $limit%. Manager approval required';
  }

  @override
  String get errNonCashExceedsTotal =>
      'Non-cash payment exceeds the receipt total';

  @override
  String errInsufficientPayment(String amount) {
    return 'Insufficient payment: $amount short';
  }

  @override
  String get errBonusNeedsCustomer => 'Select a customer to pay with bonuses';

  @override
  String get errLoyaltyDisabled => 'The bonus program is turned off';

  @override
  String errInsufficientBonus(String amount) {
    return 'Not enough bonuses: $amount available';
  }

  @override
  String errBonusMaxRedeem(String amount) {
    return 'Bonuses can cover at most $amount';
  }

  @override
  String get errDebtNeedsCustomer => 'Select a customer to sell on credit';

  @override
  String errCreditLimitExceeded(String limit, String debt) {
    return 'Customer credit limit ($limit) exceeded. Current debt: $debt';
  }

  @override
  String get errNoCredit => 'The customer has no credit line';

  @override
  String errGiftCardNotFound(String code) {
    return 'Gift card $code not found';
  }

  @override
  String errGiftCardInactive(String code) {
    return 'Gift card $code is not active';
  }

  @override
  String errGiftCardExpired(String code) {
    return 'Gift card $code has expired';
  }

  @override
  String errGiftCardInsufficient(String code, String amount) {
    return 'Gift card $code has only $amount';
  }

  @override
  String get errSelectReturnItems => 'Select items to return';

  @override
  String get errSaleNotFound => 'Receipt not found';

  @override
  String get errFullyReturned => 'This receipt has already been fully returned';

  @override
  String errReturnPeriodExpired(String days) {
    return 'The return period ($days days) has expired';
  }

  @override
  String get errLineNotInSale => 'The item is not from this receipt';

  @override
  String errReturnQtyExceeded(String name, String qty) {
    return '“$name”: at most $qty can be returned';
  }

  @override
  String get errSaleNoCustomer => 'The receipt has no customer';

  @override
  String get errOpenShiftForCashRefund => 'Open a shift to refund cash';

  @override
  String get errVoidOnlyWithoutReturns =>
      'Only a receipt without returns can be voided';

  @override
  String get errSaleOtherShift =>
      'The receipt is from another shift — process a return';

  @override
  String get errAmountNegative => 'Amount cannot be negative';

  @override
  String errShiftAlreadyOpen(String number) {
    return 'Shift No. $number is already open';
  }

  @override
  String get errUnknownOperation => 'Unknown operation';

  @override
  String get errShiftClosed => 'The shift is closed';

  @override
  String get errNotEnoughCash => 'Not enough cash in the till';

  @override
  String get errShiftAlreadyClosed => 'The shift is already closed';

  @override
  String errInsufficientStock(String name, String qty) {
    return 'Not enough “$name”: $qty in stock';
  }

  @override
  String get errCountClosed => 'The stocktake is already closed';

  @override
  String errSupplierDeleted(String name) {
    return 'Supplier “$name” has been deleted — the operation is not possible';
  }

  @override
  String get errOpenShiftForCashPayout =>
      'Open a shift to pay cash from the till';

  @override
  String errOverpaySupplier(String amount) {
    return 'Amount exceeds the debt to the supplier ($amount). Confirm the overpayment.';
  }

  @override
  String errOrderCancelled(String number) {
    return 'Order No. $number is cancelled';
  }

  @override
  String get errShiftClosedOpenShift => 'The shift is closed — open a shift';

  @override
  String get errCancelReasonRequired =>
      'Enter the reason for cancelling the payment';

  @override
  String get errPaymentNotFound => 'Payment not found';

  @override
  String get errPaymentAlreadyCancelled => 'The payment is already cancelled';

  @override
  String get errPaymentShiftClosed =>
      'The payment’s shift is closed — it cannot be cancelled';

  @override
  String get errAdjustmentZero => 'Adjustment amount cannot be zero';

  @override
  String get errAdjustmentReasonRequired =>
      'Enter the reason for the adjustment';

  @override
  String get authEnterPin => 'Enter PIN';

  @override
  String get authDemoMode => 'Demo mode';

  @override
  String get setupDefaultReceiptFooter => 'Thank you for your purchase!';

  @override
  String get setupWelcome => 'Welcome to DreamPOS';

  @override
  String get setupIntro =>
      'Setup takes less than a minute. You can change everything later in “Settings”.';

  @override
  String get setupStart => 'Get started';

  @override
  String get setupStoreName => 'Store name *';

  @override
  String get setupEnterStoreName => 'Enter a name';

  @override
  String get setupTaxId => 'TIN / STIR';

  @override
  String get setupCurrency => 'Base currency';

  @override
  String setupCurrencyExample(String amount) {
    return 'Example: $amount';
  }

  @override
  String get setupCurrencyWarning =>
      'The currency cannot be changed after the first sale — all amounts in the database depend on it.';

  @override
  String get setupOwnerName => 'Your name (owner) *';

  @override
  String get setupPin => 'PIN (4–8 digits) *';

  @override
  String get setupPinRepeat => 'Repeat PIN *';

  @override
  String get setupPinMismatch => 'PINs do not match';

  @override
  String get setupDemo => 'Fill with demo data';

  @override
  String get setupDemoHint =>
      'Products, customers and promotions to explore the system. Do not enable for a real store.';

  @override
  String get setupStepStore => 'Store';

  @override
  String get setupStepCurrency => 'Currency';

  @override
  String get setupStepOwner => 'Owner';

  @override
  String get custCreated => 'Customer created';

  @override
  String get custNoneToExport => 'No customers to export';

  @override
  String custCsvCopied(String count) {
    return 'Customers copied as CSV: $count — paste into Excel';
  }

  @override
  String custTotalCount(String count) {
    return 'Total: $count';
  }

  @override
  String get custExportTooltip => 'Copy current list as CSV (for Excel)';

  @override
  String get custNewTooltip => 'New customer (Ctrl+N)';

  @override
  String get custNew => 'New customer';

  @override
  String get custSelectTitle => 'Select a customer';

  @override
  String get custSelectMessage =>
      'The customer’s purchases, debts, bonuses and favorite products will appear here.';

  @override
  String get custStatCustomers => 'Customers';

  @override
  String get custStatReceivable => 'Receivables';

  @override
  String custOverdueLower(String amount) {
    return 'overdue $amount';
  }

  @override
  String custOverdue(String amount) {
    return 'Overdue $amount';
  }

  @override
  String get custStatBonusLiability => 'Bonus liability';

  @override
  String get custSearchHintWide => 'Name, phone or card (Ctrl+F)';

  @override
  String get custSearchHint => 'Name, phone, card';

  @override
  String custSortTooltip(String sort) {
    return 'Sort: $sort';
  }

  @override
  String get custTagFilter => 'Filter by tag';

  @override
  String custTagTooltip(String tag) {
    return 'Tag: $tag';
  }

  @override
  String get custAllTags => 'All tags';

  @override
  String get custEmptyTitle => 'No customers yet';

  @override
  String get custEmptyMessage =>
      'Add customers to give discounts, award bonuses and sell on credit.';

  @override
  String get custAdd => 'Add customer';

  @override
  String get custNotFoundTitle => 'No one found';

  @override
  String get custNotFoundMessage => 'Change the search or reset filters';

  @override
  String get custResetFilters => 'Reset filters';

  @override
  String custTileCard(String card) {
    return 'card $card';
  }

  @override
  String custDiscountLower(String value) {
    return 'discount $value';
  }

  @override
  String custTilePurchases(String amount) {
    return 'purchases $amount';
  }

  @override
  String custTileVisits(String count) {
    return 'visits: $count';
  }

  @override
  String get custTileNeverBought => 'no purchases';

  @override
  String custTileLastVisit(String date) {
    return 'last visit $date';
  }

  @override
  String get custBirthdayToday => 'Birthday today';

  @override
  String custBirthdayIn(String days) {
    return 'Birthday in $days d';
  }

  @override
  String custTileDebt(String amount) {
    return 'debt $amount';
  }

  @override
  String get custTileOverdueChip => 'overdue';

  @override
  String custTileBonus(String amount) {
    return 'bonuses $amount';
  }

  @override
  String get custCardTitle => 'Customer card';

  @override
  String custDeleteDebt(String amount) {
    return 'Cannot delete a customer with a debt of $amount. Accept the payment first.';
  }

  @override
  String get custDeleteOverpaid =>
      'Cannot delete a customer with an overpayment.';

  @override
  String get custDeleteTitle => 'Delete customer?';

  @override
  String custDeleteMessage(String name) {
    return '“$name” will be hidden from the list. Sales history is kept.';
  }

  @override
  String custDeleteBonusLost(String amount) {
    return 'Bonuses of $amount will be unavailable.';
  }

  @override
  String get custDeleted => 'Customer deleted';

  @override
  String get custNotFoundOrDeleted => 'Customer not found or deleted';

  @override
  String get custKpiSpent => 'Total spent';

  @override
  String get custKpiVisits => 'Visits';

  @override
  String get custKpiAvg => 'Average sale';

  @override
  String get custKpiLastVisit => 'Last visit';

  @override
  String get custNoPurchasesYet => 'No purchases yet';

  @override
  String get custNoPurchasesLower => 'no purchases';

  @override
  String custLimit(String amount) {
    return 'Limit $amount';
  }

  @override
  String custLimitLower(String amount) {
    return 'limit $amount';
  }

  @override
  String get custNoCredit => 'No credit line';

  @override
  String get custNoCreditLower => 'no credit line';

  @override
  String get custBdayToday => 'today!';

  @override
  String custBdayIn(String days) {
    return 'in $days d';
  }

  @override
  String custDiscountChip(String percent) {
    return 'Discount $percent%';
  }

  @override
  String get custDelete => 'Delete customer';

  @override
  String get custNoPayPerm => 'No permission to accept payments';

  @override
  String get custAcceptDebtPayment => 'Accept debt payment';

  @override
  String get custNoEditPerm => 'No permission to edit customers';

  @override
  String get custRemind => 'Remind';

  @override
  String get custNeedPromoPerm =>
      'Requires the “Promotions and bonuses” permission';

  @override
  String get custReminder => 'Reminder';

  @override
  String get custTabSales => 'Purchases';

  @override
  String get custTabSalesShort => 'Purchases';

  @override
  String get custTabLedgerShort => 'Activity';

  @override
  String get custTabLedger => 'Debts and bonuses';

  @override
  String get custTabFavShort => 'Favorites';

  @override
  String get custTabFav => 'Favorite products';

  @override
  String get custAgoToday => 'today';

  @override
  String get custAgoYesterday => 'yesterday';

  @override
  String custAgoDays(String days) {
    return '$days d ago';
  }

  @override
  String get custCopy => 'Copy';

  @override
  String custCopied(String text) {
    return 'Copied: $text';
  }

  @override
  String get custSalesEmptyTitle => 'No purchases yet';

  @override
  String get custSalesEmptyMessage =>
      'Select the customer at the till to build up history and bonuses.';

  @override
  String custReceiptNo(String number) {
    return 'Receipt No. $number';
  }

  @override
  String custReturnLower(String amount) {
    return 'return $amount';
  }

  @override
  String custReturnedQty(String qty) {
    return 'returned $qty';
  }

  @override
  String custBonusEarned(String amount) {
    return 'Bonuses earned: $amount';
  }

  @override
  String get custLedgerEmpty => 'No debt or bonus activity';

  @override
  String custDueUntil(String date) {
    return 'due $date';
  }

  @override
  String custBalanceAfter(String amount) {
    return 'balance $amount';
  }

  @override
  String get custDuePassed => 'overdue';

  @override
  String get custFavEmpty => 'No purchase data yet';

  @override
  String custBought(String qty) {
    return 'bought $qty';
  }

  @override
  String get custSegDebtors => 'Debtors';

  @override
  String get custSegOverdue => 'Overdue';

  @override
  String get custSegVip => 'VIP';

  @override
  String get custSegSleeping => 'Inactive';

  @override
  String get custSegBirthdays => 'Birthdays';

  @override
  String get custSegAllHint => 'All customers';

  @override
  String get custSegDebtorsHint => 'Customers with unpaid debt';

  @override
  String get custSegOverdueHint => 'Debt payment is overdue';

  @override
  String get custSegVipHint => 'Top 10% of customers by total spent';

  @override
  String custSegSleepingHint(String days) {
    return 'No purchases for over $days days';
  }

  @override
  String custSegBirthdaysHint(String days) {
    return 'Birthday within the next $days days';
  }

  @override
  String get custSortName => 'By name';

  @override
  String get custSortLastVisit => 'By last visit';

  @override
  String get custSortSpent => 'By total spent';

  @override
  String get custSortDebt => 'By debt';

  @override
  String get custSortBonus => 'By bonuses';

  @override
  String get custSortCreated => 'Newest first';

  @override
  String get custLedgerDebtSale => 'Sale on credit';

  @override
  String get custLedgerDebtPayment => 'Debt payment';

  @override
  String get custLedgerDebtAdjust => 'Debt adjustment';

  @override
  String get custLedgerBonusEarn => 'Bonus earned';

  @override
  String get custLedgerBonusSpend => 'Bonus spent';

  @override
  String get custLedgerBonusAdjust => 'Bonus adjustment';

  @override
  String get custStatusCompleted => 'Paid';

  @override
  String get custStatusPartReturned => 'Partly returned';

  @override
  String get custStatusReturned => 'Returned';

  @override
  String get custStatusHeld => 'On hold';

  @override
  String custReminderGreeting(String name, String store, String debt) {
    return 'Hello, $name! Your debt at $store is $debt.';
  }

  @override
  String custReminderOverdue(String amount) {
    return 'Of this, overdue: $amount.';
  }

  @override
  String custReminderDue(String date) {
    return 'Payment due by $date.';
  }

  @override
  String get custReminderAsk =>
      'Please settle the debt on your next visit to the store.';

  @override
  String custReminderPhone(String phone) {
    return 'Contact phone: $phone.';
  }

  @override
  String get custThanks => 'Thank you!';

  @override
  String get custCsvCard => 'Card';

  @override
  String get custCsvDiscount => 'Discount %';

  @override
  String custPaymentAccepted(String amount) {
    return 'Payment of $amount accepted';
  }

  @override
  String get custCurrentDebt => 'Current debt:';

  @override
  String get custPayAmount => 'Payment amount *';

  @override
  String custNotMoreThanDebt(String amount) {
    return 'Not more than the debt ($amount)';
  }

  @override
  String custFullAmountValue(String amount) {
    return 'Full amount: $amount';
  }

  @override
  String get custFullAmount => 'Full amount';

  @override
  String get custShiftClosedCash =>
      'The shift is closed: open a shift to accept cash or choose another method.';

  @override
  String custCashToShift(String number) {
    return 'Cash will be recorded in the till of shift No. $number';
  }

  @override
  String get custPrintSlip => 'Print payment receipt';

  @override
  String get custAcceptPayment => 'Accept payment';

  @override
  String get custPdfSlipTitle => 'PAYMENT RECEIPT';

  @override
  String get custPdfSlipSubtitle => 'debt repayment';

  @override
  String get custPdfDebtBefore => 'Debt before payment';

  @override
  String custPdfPaid(String method) {
    return 'Paid ($method)';
  }

  @override
  String get custPdfDebtAfter => 'Remaining debt';

  @override
  String get custPdfSignature => 'Customer signature: ____________';

  @override
  String custPdfJobName(String name) {
    return 'Payment receipt $name';
  }

  @override
  String custBonusAdded(String amount) {
    return 'Added $amount';
  }

  @override
  String custBonusRemoved(String amount) {
    return 'Deducted $amount';
  }

  @override
  String custBonusHeader(String name, String amount) {
    return '$name · balance $amount';
  }

  @override
  String get custBonusAdd => 'Add';

  @override
  String get custBonusRemove => 'Deduct';

  @override
  String get custBonusAmount => 'Bonus amount *';

  @override
  String custBonusOnlyOnBalance(String amount) {
    return 'Only $amount on balance';
  }

  @override
  String get custReasonRequired => 'Reason *';

  @override
  String get custReasonHint => 'E.g. compensation for a delayed order';

  @override
  String get custReasonError => 'Enter the reason for the adjustment';

  @override
  String get custOurStore => 'our store';

  @override
  String get custReminderTitle => 'Debt reminder';

  @override
  String get custPhoneCopied => 'Phone copied';

  @override
  String get custReminderEmpty => 'The reminder text is empty';

  @override
  String get custReminderCopied => 'Reminder text copied';

  @override
  String custPhoneValue(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get custReminderSendHint =>
      'Send the text by messenger or SMS from your phone.';

  @override
  String get custCopyPhone => 'Copy phone';

  @override
  String get custCopyText => 'Copy text';

  @override
  String get custEditTitle => 'Edit customer';

  @override
  String get custBirthday => 'Birthday';

  @override
  String get custCardTaken => 'This card is already linked to another customer';

  @override
  String get custPhoneUsedTitle => 'Phone already in use';

  @override
  String custPhoneUsedMessage(String phone, String name) {
    return 'The number $phone already belongs to “$name”. Save another customer with this number?';
  }

  @override
  String get custNameField => 'Name *';

  @override
  String get custEnterName => 'Enter the customer’s name';

  @override
  String custPhoneExists(String names) {
    return 'Already exists: $names';
  }

  @override
  String get custPhoneTooShort => 'Number too short';

  @override
  String get custPhoneTooLong => 'Number too long';

  @override
  String get custEmailInvalidFormat => 'Invalid email format';

  @override
  String get custCardNumber => 'Card number';

  @override
  String get custGenerateCard => 'Generate card number';

  @override
  String get custNotSet => 'Not set';

  @override
  String get custNoDiscountPerm => 'No permission to change the discount';

  @override
  String get custPersonalDiscount => 'Personal discount';

  @override
  String get custDiscountHelper =>
      'Not combined with promotions: the best one applies';

  @override
  String get custPercentRange => 'From 0 to 100%';

  @override
  String get custNoDebtPerm => 'No permission to manage debts';

  @override
  String get custDebtLimit => 'Debt limit';

  @override
  String get custDebtLimitHelper => '0 — no sales on credit';

  @override
  String get custManagerOnly => 'Manager only';

  @override
  String get custTags => 'Tags';

  @override
  String get custTagsHelper => 'Comma-separated, e.g. wholesale, regular';

  @override
  String get custNote => 'Note';

  @override
  String get custCardGenFailed =>
      'Could not generate a card number, please try again';

  @override
  String get custNameTooLong => 'Name is too long';

  @override
  String get custDiscountRange => 'Discount must be from 0 to 100%';

  @override
  String get custDebtLimitNegative => 'Debt limit cannot be negative';

  @override
  String get custEmailInvalid => 'Invalid email';

  @override
  String custCardTakenBy(String card) {
    return 'Card $card is already linked to another customer';
  }

  @override
  String get custNoAssignDiscountPerm =>
      'No permission to give the customer a discount';

  @override
  String get custNoOpenCreditPerm =>
      'No permission to open credit for the customer';

  @override
  String get custNoChangeDiscountPerm =>
      'No permission to change the customer’s discount';

  @override
  String get custNoChangeDebtLimitPerm =>
      'No permission to change the debt limit';

  @override
  String get custDeleteDebtRepo =>
      'Cannot delete a customer with a debt. Accept the debt payment first.';

  @override
  String get dash7Days => '7 days';

  @override
  String get dashAllReceipts => 'All receipts';

  @override
  String get dashAvgCheck => 'Average sale';

  @override
  String dashBarTooltip(String revenue, String receipts) {
    return 'Revenue: $revenue\nReceipts: $receipts';
  }

  @override
  String get dashDebtAllPaid => 'All customers have paid';

  @override
  String get dashDebtLoading => 'Debts…';

  @override
  String get dashDebtNone => 'No debts';

  @override
  String dashDebtTotal(String amount) {
    return 'Customer debt: $amount';
  }

  @override
  String dashDebtors(String count) {
    return 'Debtors: $count';
  }

  @override
  String dashDuration(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get dashGrossProfit => 'Gross profit';

  @override
  String dashMargin(String pct) {
    return 'margin $pct%';
  }

  @override
  String get dashNoAccess => 'No access to this section';

  @override
  String get dashNoPaymentsToday => 'No payments today yet';

  @override
  String get dashNoReceipts => 'No receipts yet';

  @override
  String get dashNoSales => 'No sales yet';

  @override
  String get dashOnbProductsButton => 'To products';

  @override
  String dashOnbProductsDone(String count) {
    return 'Products in the catalog: $count. Add more or import stock.';
  }

  @override
  String get dashOnbProductsText =>
      'Add products with prices and stock — by hand or with a barcode scanner.';

  @override
  String get dashOnbProductsTitle => 'Add products';

  @override
  String get dashOnbSaleButton => 'Go to register';

  @override
  String get dashOnbSaleText =>
      'Scan a product or pick it at the register and take payment.';

  @override
  String get dashOnbSaleTitle => 'Make your first sale';

  @override
  String get dashOnbShiftButton => 'Open shift';

  @override
  String dashOnbShiftDone(String number) {
    return 'Shift No. $number is open — you can sell.';
  }

  @override
  String get dashOnbShiftText =>
      'Enter the opening float so you can reconcile cash in the evening.';

  @override
  String get dashOnbShiftTitle => 'Open a shift';

  @override
  String get dashPaymentsToday => 'Payments today';

  @override
  String dashPcs(String count) {
    return '$count pcs';
  }

  @override
  String get dashPos => 'Register';

  @override
  String dashReceiptNumber(String number) {
    return 'Receipt No. $number';
  }

  @override
  String get dashReceipts => 'Receipts';

  @override
  String get dashRecentReceipts => 'Recent receipts';

  @override
  String get dashReports => 'Reports';

  @override
  String get dashReturns => 'Returns';

  @override
  String get dashRevenue14 => 'Revenue, last 14 days';

  @override
  String dashRevenueSummary(String total, String avg) {
    return 'Total $total · avg $avg per trading day';
  }

  @override
  String get dashRevenueToday => 'Revenue today';

  @override
  String get dashRevenueTooltip =>
      'Sales minus returns (voided receipts are excluded)';

  @override
  String get dashShiftClosed => 'Shift closed';

  @override
  String get dashShiftClosedText => 'Sales are blocked until a shift is opened';

  @override
  String get dashShiftLong => 'Open too long';

  @override
  String get dashShiftLongText =>
      'The shift has been open for over 16 hours — close it and reconcile the till.';

  @override
  String dashShiftOpen(String number) {
    return 'Shift No. $number open';
  }

  @override
  String get dashShiftRunning => 'Running';

  @override
  String dashShiftSince(String time) {
    return 'Since $time';
  }

  @override
  String dashShiftTotals(String receipts, String revenue) {
    return 'Receipts: $receipts · revenue $revenue';
  }

  @override
  String get dashStatusPartReturned => 'partly returned';

  @override
  String get dashStatusReturned => 'returned';

  @override
  String get dashStatusVoided => 'voided';

  @override
  String dashStepsDone(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get dashStockLoading => 'Stock…';

  @override
  String dashStockLow(String low, String out) {
    return 'Running low: $low · out of stock: $out';
  }

  @override
  String get dashStockOk => 'Stock is sufficient';

  @override
  String get dashStockSubtitle => 'Products below minimum stock';

  @override
  String get dashTitle => 'Overview';

  @override
  String dashTodayDate(String date) {
    return 'Today, $date';
  }

  @override
  String get dashTop5 => 'Top 5 products';

  @override
  String dashVoidedSuffix(String count) {
    return ' · voided receipts: $count';
  }

  @override
  String get dashWelcome => 'Welcome to DreamPOS!';

  @override
  String get dashWelcomeText =>
      'Three steps — and revenue, profit, top products and tips will appear here.';

  @override
  String dashYesterdaySoFar(String value) {
    return 'yesterday by now: $value';
  }

  @override
  String get invReceipt => 'Goods receipt';

  @override
  String get invMoveReceiptReversal => 'Goods receipt reversal';

  @override
  String get invWriteoff => 'Write-off';

  @override
  String get invAdjustment => 'Adjustment';

  @override
  String get invCount => 'Stocktake';

  @override
  String get invMoveTransfer => 'Transfer';

  @override
  String get invMovements => 'Movements';

  @override
  String get invStockTab => 'Stock';

  @override
  String get invReasonDefect => 'Defect';

  @override
  String get invReasonExpired => 'Expired';

  @override
  String get invReasonSpoiled => 'Spoiled';

  @override
  String get invReasonShortage => 'Shortage';

  @override
  String get invReasonPersonalUse => 'Personal use';

  @override
  String get invReasonOther => 'Other';

  @override
  String get invReceiptPosted => 'Posted';

  @override
  String get invReceiptReversed => 'Reversed';

  @override
  String get invCountDraft => 'Draft';

  @override
  String get invCountCompleted => 'Posted';

  @override
  String get invCountCancelled => 'Cancelled';

  @override
  String get invDeletedProduct => 'Deleted product';

  @override
  String invReceiptRef(String number) {
    return 'Goods receipt No. $number';
  }

  @override
  String get invFilterLow => 'Low';

  @override
  String get invFilterOut => 'Out of stock';

  @override
  String get invFilterNegative => 'Negative';

  @override
  String get invQtyRequired => 'Enter a quantity';

  @override
  String get invQtyNegative => 'Quantity cannot be negative';

  @override
  String get invQtyPositive => 'Quantity must be greater than zero';

  @override
  String invQtyIntegerOnly(String unit) {
    return 'Only whole numbers are allowed for “$unit”';
  }

  @override
  String get invQtyTooLarge => 'Quantity is too large';

  @override
  String get invAddAtLeastOneLine => 'Add at least one line';

  @override
  String invCostNegative(String name) {
    return '$name: purchase price is negative';
  }

  @override
  String invRetailMustBePositive(String name) {
    return '$name: retail price must be greater than zero';
  }

  @override
  String get invSelectCategory => 'Select a category';

  @override
  String get invSelectProducts => 'Select products';

  @override
  String get invNoProductsToCount => 'No products to count';

  @override
  String get invCountClosed => 'The stocktake is already closed';

  @override
  String get invNoCountedQty => 'No counted quantities entered';

  @override
  String get invNoAccess => 'No access';

  @override
  String get invNoAccessMessage =>
      'Stock operations are available to storekeepers, managers and owners';

  @override
  String get invNoProductsTitle => 'No products yet';

  @override
  String get invNoProductsMessage =>
      'Add products in “Products”, then record a goods receipt.';

  @override
  String get invChangeFiltersOrQuery => 'Change the filters or search';

  @override
  String get invStockValue => 'Stock value';

  @override
  String get invPositionsTracked => 'Tracked items';

  @override
  String get invStockAtCost => 'Stock at cost';

  @override
  String get invStockAtRetail => 'Stock at retail';

  @override
  String invPotentialMargin(String amount) {
    return 'Potential markup $amount';
  }

  @override
  String get invLowOutNegative => 'Low / out / negative';

  @override
  String get invAllCategories => 'All categories';

  @override
  String get invSearchHint => 'Name, SKU, barcode';

  @override
  String get invStatusOut => 'Out';

  @override
  String invSkuShort(String sku) {
    return 'SKU $sku';
  }

  @override
  String invMinShort(String qty) {
    return 'min $qty';
  }

  @override
  String get invInactive => 'inactive';

  @override
  String invQuickReceiptTitle(String name) {
    return 'Goods receipt: $name';
  }

  @override
  String invCurrentStock(String qty) {
    return 'Current stock: $qty';
  }

  @override
  String get invUnitCostRequired => 'Unit purchase price *';

  @override
  String get invPostIn => 'Receive';

  @override
  String get invSelectProduct => 'Select a product';

  @override
  String get invSpecifyWriteoffReason => 'Specify the write-off reason';

  @override
  String get invDescribeReason => 'Describe the reason in the comment';

  @override
  String get invWriteoffConfirmTitle => 'Write off the product?';

  @override
  String invWriteoffConfirmMessage(
    String name,
    String qty,
    String amount,
    String reason,
  ) {
    return '$name\n$qty worth $amount (at cost)\nReason: $reason';
  }

  @override
  String get invWriteoffAction => 'Write off';

  @override
  String invWrittenOff(String qty, String name) {
    return 'Written off $qty of “$name”';
  }

  @override
  String get invChooseProduct => 'Choose a product…';

  @override
  String invStockLine(String qty) {
    return 'Stock: $qty';
  }

  @override
  String invStockLineWithCost(String qty, String cost) {
    return 'Stock: $qty · cost $cost';
  }

  @override
  String get invCommentRequired => 'Comment *';

  @override
  String invWriteoffSum(String amount) {
    return 'Write-off value: $amount';
  }

  @override
  String get invStockUnchanged => 'Stock has not changed';

  @override
  String get invStockCorrected => 'Stock corrected';

  @override
  String get invAdjustTitle => 'Stock adjustment';

  @override
  String invBookStock(String qty) {
    return 'Book stock: $qty';
  }

  @override
  String get invActualStock => 'Actual stock';

  @override
  String get invReasonRequired => 'Reason *';

  @override
  String get invSpecifyAdjustReason => 'Specify the adjustment reason';

  @override
  String get invUseCountHint => 'For a full stock check, use a stocktake.';

  @override
  String invHistoryTitle(String name) {
    return 'Movements: $name';
  }

  @override
  String get invNoMovementsYet => 'No movements yet';

  @override
  String invPriceDetail(String amount) {
    return 'price $amount';
  }

  @override
  String invStockAfter(String qty) {
    return 'stock $qty';
  }

  @override
  String get invNewWriteoff => 'New write-off';

  @override
  String get invWhatToWriteOff => 'What to write off?';

  @override
  String get invWriteoffs30 => 'Write-offs, last 30 days';

  @override
  String get invNoWriteoffs30 => 'No write-offs in the last 30 days';

  @override
  String invTotalAtCost(String amount) {
    return 'Total at cost: $amount';
  }

  @override
  String get invDays7 => '7 days';

  @override
  String get invDays30 => '30 days';

  @override
  String get invAllTime => 'All time';

  @override
  String get invPeriodCustom => 'Period…';

  @override
  String get invMovementsPeriod => 'Movements period';

  @override
  String get invType => 'Type';

  @override
  String get invAllTypes => 'All types';

  @override
  String get invAllProducts => 'All products';

  @override
  String get invFilterByProduct => 'Filter by product';

  @override
  String get invNoMovements => 'No movements';

  @override
  String get invChangeFiltersOrPeriod => 'Change the filters or period';

  @override
  String invRecords(String count) {
    return 'Records: $count';
  }

  @override
  String invRecordsLimited(String count, String limit) {
    return 'Records: $count (showing the last $limit — refine the filter)';
  }

  @override
  String invInOut(String inQty, String outQty) {
    return 'in +$inQty · out $outQty';
  }

  @override
  String invCurrentStockOf(String name, String qty) {
    return 'Current stock of “$name”: $qty';
  }

  @override
  String get invDocsPeriod => 'Documents period';

  @override
  String get invSearchShort => 'No. or invoice';

  @override
  String get invSearchLong => 'Search: goods receipt or invoice No.';

  @override
  String get invAllSuppliers => 'All suppliers';

  @override
  String get invNoDocs => 'No documents';

  @override
  String get invPostedAppearHere => 'Posted goods receipts will appear here';

  @override
  String invDocsCount(String count) {
    return 'Documents: $count';
  }

  @override
  String invDocsCountLimited(String count, String limit) {
    return 'Documents: $count (showing the last $limit — refine the filter)';
  }

  @override
  String invPostedFor(String amount) {
    return 'posted $amount';
  }

  @override
  String get invNoSupplier => 'No supplier';

  @override
  String get invDeletedSupplier => 'Deleted supplier';

  @override
  String invOrderRef(String number) {
    return 'Order No. $number';
  }

  @override
  String get invOrder => 'Order';

  @override
  String get invNoHeader => 'No.';

  @override
  String invNumber(String number) {
    return 'No. $number';
  }

  @override
  String get invInvoice => 'Invoice';

  @override
  String get invPositionsHeader => 'Lines';

  @override
  String get invSource => 'Source';

  @override
  String invInvoiceShort(String invoice) {
    return 'inv. $invoice';
  }

  @override
  String get invReceiptDocTitle => 'Goods receipt';

  @override
  String invReceiptPostedToast(String number) {
    return 'Goods receipt No. $number posted';
  }

  @override
  String invReceiptPostedToastDetails(String number, String details) {
    return 'Goods receipt No. $number posted · $details';
  }

  @override
  String invReverseTitle(String number) {
    return 'Reverse goods receipt No. $number?';
  }

  @override
  String get invReverseInfo =>
      'Stock will decrease by the document quantities and costs will be recalculated. Retail prices changed by this goods receipt will revert unless they were changed later.';

  @override
  String invReverseSupplierDebt(String supplier, String amount) {
    return 'The debt to supplier $supplier will decrease by $amount.';
  }

  @override
  String get invReverseIrreversible => 'A reversal cannot be undone.';

  @override
  String get invReverseReasonLabel => 'Reversal reason *';

  @override
  String get invReverseReasonRequired => 'Specify the reversal reason';

  @override
  String get invReverse => 'Reverse';

  @override
  String get invDocNotFound => 'Document not found';

  @override
  String get invDocNotFoundMessage =>
      'It may have been deleted or not synced yet';

  @override
  String get invSupplierInvoice => 'Supplier invoice';

  @override
  String get invManualReceipt => 'Manual goods receipt';

  @override
  String get invAcceptedBy => 'Received by';

  @override
  String invReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String invTotalsLine(String count, String qty) {
    return 'Lines: $count · quantity $qty';
  }

  @override
  String invTotalLine(String amount) {
    return 'Total: $amount';
  }

  @override
  String get invPositionsTitle => 'Lines';

  @override
  String get invNoLinesInDoc => 'The document has no lines';

  @override
  String invReversedToast(String number) {
    return 'Goods receipt No. $number reversed';
  }

  @override
  String get invQtyShort => 'Qty';

  @override
  String get invPurchasePrice => 'Purchase price';

  @override
  String get invNewRetailPrice => 'New retail price';

  @override
  String invWasPrice(String amount) {
    return 'was $amount';
  }

  @override
  String invPriceWas(String price, String old) {
    return '$price (was $old)';
  }

  @override
  String invRetailPriceLine(String price) {
    return 'Retail price: $price';
  }

  @override
  String get invNewReceipt => 'New goods receipt';

  @override
  String get invDocuments => 'Documents';

  @override
  String invScanNotFound(String code) {
    return 'No product with barcode/SKU “$code”';
  }

  @override
  String get invAddToReceipt => 'Add to goods receipt';

  @override
  String get invClearDocTitle => 'Clear the document?';

  @override
  String get invClearDocMessage =>
      'All lines will be removed from the document.';

  @override
  String get invCheckFields => 'Check the highlighted fields';

  @override
  String get invPostReceiptTitle => 'Post the goods receipt?';

  @override
  String invPostReceiptMessage(String count, String amount) {
    return 'Lines: $count\nAmount: $amount';
  }

  @override
  String invPostReceiptDebt(String supplier, String amount) {
    return 'The debt to “$supplier” will increase by $amount';
  }

  @override
  String get invPost => 'Post';

  @override
  String invLinesFor(String count, String amount) {
    return 'Lines: $count, $amount';
  }

  @override
  String invPositionsLower(String count) {
    return 'lines $count';
  }

  @override
  String get invPostReceipt => 'Post goods receipt';

  @override
  String get invSupplierHelper =>
      'If set, the goods receipt amount is added to the debt to the supplier';

  @override
  String get invInvoiceNoShort => 'Invoice No.';

  @override
  String get invInvoiceNoLong => 'Supplier invoice No.';

  @override
  String get invScanShort => 'Barcode or SKU';

  @override
  String get invScanLong => 'Scan a barcode or enter an SKU';

  @override
  String get invAddProduct => 'Add product';

  @override
  String get invEmptyDoc => 'The document is empty';

  @override
  String get invEmptyDocMessage =>
      'Scan a product or tap “Add product”. To receive against a supplier order, use “Purchasing”.';

  @override
  String get invSpecifyPurchasePrice => 'Enter the purchase price';

  @override
  String get invNewPrice => 'New price';

  @override
  String get invNoPricePermission => 'No permission to change prices';

  @override
  String get invInvalidPrice => 'Invalid price';

  @override
  String get invDeleteLine => 'Delete line';

  @override
  String invLineInfo(String qty, String price) {
    return 'Stock $qty · retail $price';
  }

  @override
  String invMarkupPart(String percent) {
    return 'markup $percent%';
  }

  @override
  String get invNewCount => 'New stocktake';

  @override
  String get invSelectCount => 'Select a stocktake';

  @override
  String get invSelectCountMessage =>
      'or create a new one to compare actual stock with book stock';

  @override
  String get invNoCountsYet => 'No stocktakes yet';

  @override
  String get invNoCountsMessage => 'Regular counts help catch shortages early';

  @override
  String invCountTitle(String number) {
    return 'Stocktake No. $number';
  }

  @override
  String get invAddToCount => 'Add product to stocktake';

  @override
  String get invAddAtLeastOneProduct => 'Add at least one product';

  @override
  String get invSelected => 'Selected';

  @override
  String get invCategoryRequired => 'Category *';

  @override
  String get invRemove => 'Remove';

  @override
  String get invCountNoteHint => 'area, person in charge';

  @override
  String get invCountCreateInfo =>
      'Book stock is fixed when the stocktake is created. Sales during the count are taken into account when posting: the difference is calculated from the current stock.';

  @override
  String invProductNotFound(String code) {
    return 'Product “$code” not found';
  }

  @override
  String get invNotInSheetTitle => 'Product is not on the sheet';

  @override
  String invNotInSheetMessage(String name, String unit) {
    return '“$name” is not part of this stocktake. Add it and count 1 $unit?';
  }

  @override
  String invAddedOne(String name) {
    return '“$name” added: 1';
  }

  @override
  String invCompleteTitle(String number) {
    return 'Post stocktake No. $number?';
  }

  @override
  String invCompleteCounted(String counted, String total) {
    return 'Lines counted: $counted of $total.';
  }

  @override
  String invCompleteUncounted(String count) {
    return 'Not counted: $count — their stock will not change.';
  }

  @override
  String invCompleteSurplus(String count) {
    return 'Surplus lines: $count';
  }

  @override
  String invCompleteSurplusSum(String count, String amount) {
    return 'Surplus lines: $count, $amount';
  }

  @override
  String invCompleteShortage(String count) {
    return 'Shortage lines: $count';
  }

  @override
  String invCompleteShortageSum(String count, String amount) {
    return 'Shortage lines: $count, $amount';
  }

  @override
  String invCompleteNet(String amount) {
    return 'Net: $amount';
  }

  @override
  String invCompleteChanged(String count) {
    return 'For $count lines the stock changed after the sheet was created (sales, goods receipts). Differences are calculated from the CURRENT stock.';
  }

  @override
  String get invCompleteFinal =>
      'Stock will be set to the counted quantities. This cannot be undone.';

  @override
  String invCountCompletedToast(String number) {
    return 'Stocktake No. $number posted';
  }

  @override
  String invCancelCountTitle(String number) {
    return 'Cancel stocktake No. $number?';
  }

  @override
  String get invCancelCountMessage =>
      'Entered data stays in the history; stock will not change.';

  @override
  String get invCancelCount => 'Cancel stocktake';

  @override
  String get invCountCancelledToast => 'Stocktake cancelled';

  @override
  String get invCountNotFound => 'Stocktake not found';

  @override
  String invChangedWarning(String count) {
    return 'For $count lines the book stock changed after the sheet was created (sales/goods receipts). The difference is calculated from the current stock.';
  }

  @override
  String get invScanPlusOne => 'Scan: +1 counted';

  @override
  String get invSearchInSheet => 'Search the sheet';

  @override
  String invFilterAllCount(String count) {
    return 'All ($count)';
  }

  @override
  String invFilterUncounted(String count) {
    return 'Not counted ($count)';
  }

  @override
  String get invDiscrepancies => 'Differences';

  @override
  String get invNoLinesForFilter => 'No lines match the filter';

  @override
  String invCreatedAt(String date) {
    return 'created $date';
  }

  @override
  String invCompletedAt(String date) {
    return 'posted $date';
  }

  @override
  String invCountedChip(String counted, String total) {
    return 'Counted $counted/$total';
  }

  @override
  String invSurplusChip(String count) {
    return 'Surplus $count';
  }

  @override
  String invShortageChip(String count) {
    return 'Shortage $count';
  }

  @override
  String get invSaving => 'Saving…';

  @override
  String get invDraftSaved => 'Draft saved';

  @override
  String get invBlank => 'Sheet';

  @override
  String get invCancelShort => 'Cancel';

  @override
  String get invProductBookStock => 'Product · book stock';

  @override
  String get invFact => 'Counted';

  @override
  String get invDiff => 'Difference';

  @override
  String invBookShort(String qty) {
    return 'book $qty';
  }

  @override
  String invNowShort(String qty) {
    return 'now $qty';
  }

  @override
  String get invFactHint => 'counted';

  @override
  String get invNotCounted => 'not counted';

  @override
  String get invNumberQ => 'number?';

  @override
  String get invInvalidShort => 'invalid';

  @override
  String invSheetTitle(String number) {
    return 'Stocktake sheet No. $number';
  }

  @override
  String invPageOf(String page, String total) {
    return 'p. $page/$total';
  }

  @override
  String invSheetSubtitle(String store, String date, String count) {
    return '$store · created $date · lines $count';
  }

  @override
  String get invCountedBy => 'Counted by: ____________________';

  @override
  String get invCheckedBy => 'Checked by: ____________________';

  @override
  String invDateLine(String date) {
    return 'Date: $date';
  }

  @override
  String get invBarcodeSku => 'Barcode / SKU';

  @override
  String get invUnitShort => 'Unit';

  @override
  String get invBook => 'Book';

  @override
  String invCountFileName(String number) {
    return 'Stocktake $number';
  }

  @override
  String invReceiptPdfTitle(String number, String date) {
    return 'Goods receipt note No. $number dated $date';
  }

  @override
  String get invHandedBy => 'Delivered by: ____________________';

  @override
  String get invAcceptedByLine => 'Received by: ____________________';

  @override
  String get invBasis => 'Basis';

  @override
  String invSupplierOrderRef(String number) {
    return 'Supplier order No. $number';
  }

  @override
  String get invReversedCaps => 'REVERSED';

  @override
  String get invNewRetailShort => 'New retail';

  @override
  String invReceiptFileName(String number) {
    return 'Goods receipt $number';
  }

  @override
  String get mktTitle => 'Marketing';

  @override
  String get mktTabPromos => 'Promotions';

  @override
  String get mktTabGiftCards => 'Gift cards';

  @override
  String get mktTabLoyalty => 'Loyalty';

  @override
  String get mktTabMailing => 'Campaigns';

  @override
  String get mktTypePercentOrder => '% off receipt';

  @override
  String get mktTypeAmountOrder => 'Amount off receipt';

  @override
  String get mktTypePercentCategory => '% off category';

  @override
  String get mktTypePercentProduct => '% off product';

  @override
  String get mktTypeBuyXGetY => 'Buy X, get Y';

  @override
  String get mktTypePromoCode => 'Promo code';

  @override
  String get mktHelpPercentOrder =>
      'A percentage off the receipt total after line discounts. You can set a minimum receipt total. Only one receipt discount applies — the best one.';

  @override
  String get mktHelpAmountOrder =>
      'A fixed amount off the receipt (e.g. 10,000 on purchases from 100,000). It is spread across lines proportionally, so returns are exact.';

  @override
  String get mktHelpPercentCategory =>
      'A percentage off every product in the chosen category. It does not stack with other line discounts or the customer’s personal discount — the best one wins.';

  @override
  String get mktHelpPercentProduct =>
      'A percentage off one product. It does not stack with other line discounts — the best one wins.';

  @override
  String get mktHelpBuyXGetY =>
      'Buy X units of an item and get Y more free. E.g. “2+1”: every third unit is free. Works on a single item line.';

  @override
  String get mktHelpPromoCode =>
      'A receipt discount for a code the cashier enters at the till. Set a percentage or an amount and a minimum receipt total. It competes with other receipt discounts — the best one applies.';

  @override
  String get mktStatusActive => 'Active';

  @override
  String get mktStatusScheduled => 'Scheduled';

  @override
  String get mktStatusFinished => 'Finished';

  @override
  String get mktStatusDisabled => 'Disabled';

  @override
  String get mktErrEnterName => 'Enter the promotion name';

  @override
  String get mktErrSelectType => 'Select the promotion type';

  @override
  String get mktErrEnterPercent => 'Enter the discount percentage';

  @override
  String get mktErrPercentRange =>
      'The discount percentage must be above 0 and at most 100';

  @override
  String get mktErrEnterAmount => 'Enter the discount amount';

  @override
  String mktErrPromoCodeMinAmount(String amount) {
    return 'A promo code discount must be at least $amount';
  }

  @override
  String get mktErrDiscountAboveMin =>
      'The discount cannot exceed the minimum receipt total';

  @override
  String get mktErrSelectCategory => 'Select a category';

  @override
  String get mktErrSelectProduct => 'Select a product';

  @override
  String get mktErrBuyMin => '“Buy” — at least 1 pc';

  @override
  String get mktErrGetMin => '“Get” — at least 1 pc';

  @override
  String get mktErrQtyTooLarge => 'Quantity is too large';

  @override
  String get mktErrEnterCode => 'Enter the promo code';

  @override
  String get mktErrCodeTooShort => 'Promo code: at least 3 characters';

  @override
  String get mktErrCodeTooLong => 'Promo code is too long';

  @override
  String get mktErrCodeChars => 'Promo code: letters, digits, “-” and “_” only';

  @override
  String mktErrCodeTaken(String code) {
    return 'Promo code $code is already used by another active promotion';
  }

  @override
  String get mktErrMinNegative => 'The minimum total cannot be negative';

  @override
  String get mktErrEndBeforeStart =>
      'The end date cannot be before the start date';

  @override
  String mktDescMinOrder(String amount) {
    return ' from $amount';
  }

  @override
  String mktDescOrder(String value, String min) {
    return '$value off receipt$min';
  }

  @override
  String mktDescCategory(String value, String target) {
    return '$value off category “$target”';
  }

  @override
  String mktDescProduct(String value, String target) {
    return '$value off “$target”';
  }

  @override
  String mktDescBuyXGetY(String buy, String get, String target) {
    return '$buy+$get: buy $buy, get $get free — “$target”';
  }

  @override
  String mktDescPromoCode(String code, String value, String min) {
    return 'Code $code: $value off receipt$min';
  }

  @override
  String get mktPeriodUnlimited => 'No end date';

  @override
  String mktPeriodUntil(String date) {
    return 'until $date';
  }

  @override
  String mktPeriodFrom(String date) {
    return 'from $date';
  }

  @override
  String get mktPromoSaved => 'Promotion saved';

  @override
  String get mktDeletePromoTitle => 'Delete promotion?';

  @override
  String mktDeletePromoMessage(String name) {
    return '“$name” will no longer apply at the till. Past receipts do not change.';
  }

  @override
  String get mktPromoDeleted => 'Promotion deleted';

  @override
  String get mktPromoSearchHint => 'Name or promo code';

  @override
  String get mktNewPromo => 'New promotion';

  @override
  String get mktTestOnReceipt => 'Test on a receipt';

  @override
  String mktChipAll(String count) {
    return 'All $count';
  }

  @override
  String get mktPromosEmptyTitle => 'No promotions yet';

  @override
  String get mktPromosEmptyMessage =>
      'Create a receipt, category or product discount, a “2+1” deal or a promo code. The till applies it automatically.';

  @override
  String get mktCreatePromo => 'Create promotion';

  @override
  String get mktPromosNoMatch => 'No promotions match this filter';

  @override
  String get mktTurnOff => 'Turn off';

  @override
  String get mktTurnOn => 'Turn on';

  @override
  String get mktDuplicate => 'Duplicate';

  @override
  String get mktEditPromo => 'Edit promotion';

  @override
  String mktCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get mktProductDeleted => 'Product deleted';

  @override
  String get mktStartDate => 'Start date';

  @override
  String get mktLastDay => 'Last day of the promotion';

  @override
  String get mktPromoProduct => 'Product for the promotion';

  @override
  String get mktNameLabel => 'Name *';

  @override
  String get mktNameHint => 'E.g. Weekend sale';

  @override
  String get mktEnterName => 'Enter a name';

  @override
  String get mktPromoType => 'Promotion type';

  @override
  String get mktValidityPeriod => 'Validity period';

  @override
  String get mktDateFrom => 'From';

  @override
  String get mktDateTo => 'To (inclusive)';

  @override
  String get mktPromoEnabled => 'Promotion enabled';

  @override
  String mktStatusLine(String status) {
    return 'Status: $status';
  }

  @override
  String get mktUnlimited => 'no limit';

  @override
  String get mktPromoCodeLabel => 'Promo code *';

  @override
  String get mktMin3Chars => 'At least 3 characters';

  @override
  String get mktDiscountColon => 'Discount:';

  @override
  String mktAmountIn(String currency) {
    return 'amount, $currency';
  }

  @override
  String get mktCreateCategoriesFirst =>
      'Create categories in “Products” first';

  @override
  String get mktCategoryLabel => 'Category *';

  @override
  String get mktProductLabel => 'Product *';

  @override
  String get mktPickProduct => 'Choose a product…';

  @override
  String get mktBuyQty => 'Buy (pcs)';

  @override
  String get mktGetQty => 'Get free (pcs)';

  @override
  String get mktMin1 => 'At least 1';

  @override
  String mktBuyGetPreview(String total, String free) {
    return 'In a receipt of $total pcs, $free pcs are free';
  }

  @override
  String get mktDiscountLabel => 'Discount *';

  @override
  String get mktEnterPercent => 'Enter a percentage';

  @override
  String get mktPercentRangeShort => 'Above 0 and at most 100';

  @override
  String get mktDiscountAmountLabel => 'Discount amount *';

  @override
  String get mktMinOrderLabel => 'Min. receipt total';

  @override
  String get mktMinOrderHelper => 'Empty — no limit';

  @override
  String get mktSimTitle => 'Test promotions on a receipt';

  @override
  String get mktSimAddProductTitle => 'Add a product to the test receipt';

  @override
  String mktSimIntro(String count) {
    return 'Add items to see which discounts the till applies. Active promotions: $count. Line discounts do not stack — the best of an item/category promotion, “N+M” and the customer’s personal discount wins. Of the receipt discounts (receipt promotion, promo code) only one applies, the best.';
  }

  @override
  String get mktSimAddProduct => 'Add product';

  @override
  String get mktSimCustomerDiscount => 'Customer discount';

  @override
  String get mktSim0To100 => 'From 0 to 100';

  @override
  String get mktSimEmptyTitle => 'The test receipt is empty';

  @override
  String get mktSimEmptyMessage => 'Add one or more products';

  @override
  String mktSimPricePer(String price, String unit) {
    return '$price per $unit';
  }

  @override
  String mktSimOrderShare(String amount) {
    return '−$amount · share of receipt discount';
  }

  @override
  String get mktSimQtyPositive => 'Enter a quantity above zero';

  @override
  String get mktSimQtyShort => 'Qty';

  @override
  String get mktRemove => 'Remove';

  @override
  String get mktSimSubtotal => 'Subtotal';

  @override
  String get mktSimToPay => 'Amount due';

  @override
  String get mktSimCodeAccepted => 'Promo code accepted';

  @override
  String get mktSimCodeRejected =>
      'Promo code not found, inactive or the receipt total is below the minimum';

  @override
  String get mktSimApplied => 'Applied discounts:';

  @override
  String get mktSimNone => 'none';

  @override
  String get mktLoyaltyProgram => 'Bonus program';

  @override
  String get mktLoyaltyOn => 'On';

  @override
  String get mktLoyaltyOff => 'Off';

  @override
  String get mktLoyaltyEarn => 'Earning';

  @override
  String mktLoyaltyEarnValue(String percent) {
    return '$percent% of the amount paid (excluding bonus payments)';
  }

  @override
  String get mktLoyaltyRedeem => 'Paying with bonuses';

  @override
  String mktLoyaltyRedeemValue(String percent) {
    return 'up to $percent% of the receipt total';
  }

  @override
  String get mktLoyaltyRate => 'Rate';

  @override
  String mktLoyaltyRateValue(String amount) {
    return '1 bonus = $amount';
  }

  @override
  String get mktLoyaltyNote =>
      'Bonuses are earned automatically on sales to a customer and reversed proportionally on returns.';

  @override
  String get mktOpenSettings => 'Open settings';

  @override
  String get mktNoSettingsRight => 'No permission to change settings';

  @override
  String get mktEditInSettings => 'Change in settings';

  @override
  String get mktStatLiability => 'Bonus liability';

  @override
  String get mktStatLiabilityShort => 'Liability';

  @override
  String mktStatHolders(String count) {
    return 'held by $count customers';
  }

  @override
  String get mktStatEarned30 => 'Earned, last 30 days';

  @override
  String get mktStatEarned => 'Earned';

  @override
  String get mktStat30Days => 'last 30 days';

  @override
  String get mktStatSpent30 => 'Spent, last 30 days';

  @override
  String get mktStatSpent => 'Spent';

  @override
  String get mktStatAdjusted30 => 'Adjustments, last 30 days';

  @override
  String get mktStatAdjusted => 'Adjustments';

  @override
  String get mktStatAdjustedHint => 'manual and on returns';

  @override
  String mktTplBirthday(String name, String store) {
    return 'Hello, $name! $store wishes you a happy birthday! Come and get your gift.';
  }

  @override
  String mktTplSleeping(String name, String store, String bonus) {
    return 'Hello, $name! Long time no see — $store has lots of new arrivals. Your bonuses: $bonus. See you soon!';
  }

  @override
  String mktTplDebt(String name, String store, String debt) {
    return 'Hello, $name! A reminder that your debt at $store is $debt. Thank you!';
  }

  @override
  String mktTplVip(String name, String store, String bonus) {
    return 'Hello, $name! You are our VIP customer. $store has special offers for you. Your bonuses: $bonus.';
  }

  @override
  String mktTplAll(String name) {
    return 'Hello, $name! ';
  }

  @override
  String get mktOurStore => 'our store';

  @override
  String get mktSegment => 'Segment';

  @override
  String get mktMessageText => 'Message text';

  @override
  String mktTemplateVars(
    String name,
    String fullname,
    String store,
    String debt,
    String bonus,
    String discount,
  ) {
    return 'Placeholders: $name — first name, $fullname, $store, $debt, $bonus, $discount';
  }

  @override
  String mktPhonesCopied(String count) {
    return 'Phone numbers copied: $count';
  }

  @override
  String mktCopyPhones(String count) {
    return 'Copy phones ($count)';
  }

  @override
  String mktMessagesCopied(String count) {
    return 'Messages copied: $count';
  }

  @override
  String get mktCopyMessages => 'Copy messages';

  @override
  String get mktSmsNote =>
      'No SMS gateway is connected: copy the list and send the messages via a messenger or phone.';

  @override
  String mktNoPhoneNote(String count) {
    return 'Without a phone: $count — they are left out of the list.';
  }

  @override
  String get mktNoPhone => 'no phone';

  @override
  String get mktToday => 'today';

  @override
  String mktInDays(String days) {
    return 'in $days d';
  }

  @override
  String mktLastVisit(String date) {
    return 'last visit $date';
  }

  @override
  String mktPurchases(String amount) {
    return 'purchases $amount';
  }

  @override
  String get mktOverdue => 'overdue';

  @override
  String get mktSegmentEmpty => 'Nobody in this segment';

  @override
  String get mktGiftActive => 'Active';

  @override
  String get mktGiftUsed => 'Used';

  @override
  String get mktGiftExpired => 'Expired';

  @override
  String get mktGiftBlocked => 'Blocked';

  @override
  String get mktErrUniqueCode => 'Could not generate a unique code';

  @override
  String get mktErrUnblockVoided =>
      'The gift card sale is voided — it cannot be unblocked';

  @override
  String mktBlockTitle(String code) {
    return 'Block $code?';
  }

  @override
  String get mktGiftBlockedMsg => 'Gift card blocked';

  @override
  String get mktGiftUnblockedMsg => 'Gift card unblocked';

  @override
  String get mktGiftSalesSegment => 'Sales';

  @override
  String get mktNoSellRight => 'No permission to sell';

  @override
  String get mktStatActiveShort => 'Active';

  @override
  String get mktStatActive => 'Active gift cards';

  @override
  String get mktStatActiveHint => 'gift cards';

  @override
  String get mktStatOutstandingShort => 'Outstanding';

  @override
  String get mktStatOutstanding => 'Outstanding balance';

  @override
  String get mktStatOutstandingHintShort => 'on gift cards';

  @override
  String get mktStatOutstandingHint => 'store liability';

  @override
  String get mktGiftSearchHint => 'Code or customer';

  @override
  String get mktGiftSaleTooltip => 'Gift card sale (advance, not revenue)';

  @override
  String get mktIssue => 'Issue';

  @override
  String get mktCheckBalance => 'Check balance';

  @override
  String get mktGiftsEmptyTitle => 'No gift cards yet';

  @override
  String get mktGiftsEmptyMessage =>
      'Sell gift cards — they can be accepted as payment at the till.';

  @override
  String get mktIssueGift => 'Issue gift card';

  @override
  String get mktCustomerLower => 'customer';

  @override
  String get mktCodeCopied => 'Code copied';

  @override
  String mktOfAmount(String amount) {
    return 'of $amount';
  }

  @override
  String get mktFaceValueLower => 'face value';

  @override
  String mktIssuedOn(String date) {
    return 'issued $date';
  }

  @override
  String get mktNoExpiryLower => 'no expiry';

  @override
  String mktUntil(String date) {
    return 'until $date';
  }

  @override
  String get mktSaleDocument => 'Sale document';

  @override
  String get mktGiftBlank => 'Printable gift card';

  @override
  String get mktCopyCode => 'Copy code';

  @override
  String get mktUnblock => 'Unblock';

  @override
  String get mktBlock => 'Block';

  @override
  String get mktGiftBalanceTitle => 'Gift card balance';

  @override
  String get mktCodeEnterOrScan => 'Code (type or scan)';

  @override
  String get mktFind => 'Find';

  @override
  String mktFaceValueAmount(String amount) {
    return 'Face value $amount';
  }

  @override
  String get mktNoExpiry => 'No expiry';

  @override
  String mktValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get mktPdfGiftTitle => 'GIFT CARD';

  @override
  String mktPdfValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get mktPdfGiftNote =>
      'Present this gift card at the till.\nNot exchangeable for cash.';

  @override
  String mktVoidSaleTitle(String number) {
    return 'Void sale No. $number';
  }

  @override
  String get mktReasonRequired => 'Reason *';

  @override
  String mktVoidSaleQuestion(String number) {
    return 'Void sale No. $number?';
  }

  @override
  String mktVoidSaleMessage(String code, String amount, String payments) {
    return 'Gift card $code will be blocked. Refund $amount to the buyer: $payments. The refund goes to the current shift.';
  }

  @override
  String get mktVoid => 'Void';

  @override
  String mktSaleVoided(String number) {
    return 'Sale No. $number voided';
  }

  @override
  String get mktBlank => 'Printable';

  @override
  String get mktNoSaleDocument =>
      'This gift card was issued before sale documents existed — there is no document, so it cannot be voided.';

  @override
  String mktFaceValueLowerAmount(String amount) {
    return 'face value $amount';
  }

  @override
  String get mktNoVoidRight => 'No permission to void sales';

  @override
  String get mktOpenShiftToVoid => 'Open a shift to void the sale';

  @override
  String get mktChecking => 'Checking…';

  @override
  String mktSaleNumber(String number) {
    return 'Sale No. $number';
  }

  @override
  String mktVoidedAt(String date) {
    return 'Voided $date';
  }

  @override
  String get mktVoidTooltip =>
      'The gift card will be blocked and the money refunded to the buyer';

  @override
  String get mktVoidSale => 'Void sale';

  @override
  String get mktSaleCompleted => 'Completed';

  @override
  String get mktSaleVoidedStatus => 'Voided';

  @override
  String get mktPeriod7Days => '7 days';

  @override
  String get mktPeriod30Days => '30 days';

  @override
  String get mktPeriodAllTime => 'All time';

  @override
  String get mktGiftSalesEmptyTitle => 'No gift card sales';

  @override
  String get mktGiftSalesEmptyMessage =>
      'No documents with this status in the selected period.';

  @override
  String mktCompletedFor(String amount) {
    return 'completed for $amount';
  }

  @override
  String mktVoidedCount(String count) {
    return 'voided: $count';
  }

  @override
  String mktReasonLower(String reason) {
    return 'reason: $reason';
  }

  @override
  String get mktPayMixed => 'Split';

  @override
  String get mktValidUntilInclusive => 'Valid until (inclusive)';

  @override
  String mktPayExceeds(String amount) {
    return 'Card and transfer exceed the face value by $amount';
  }

  @override
  String get mktPayEnterCardTransfer => 'Enter the card and/or transfer amount';

  @override
  String mktPayTenderedShort(String amount) {
    return 'Received less than required: $amount';
  }

  @override
  String get mktCodeExists => 'This code already exists';

  @override
  String get mktValidUntilLabel => 'Valid until';

  @override
  String get mktNoExpiryCap => 'No expiry';

  @override
  String get mktBuyerOptional => 'Buyer (optional)';

  @override
  String get mktNotSelected => 'Not selected';

  @override
  String get mktRemoveBuyer => 'Remove buyer';

  @override
  String get mktGiftSaleTitle => 'Gift card sale';

  @override
  String get mktShiftClosedNote =>
      'The shift is closed: open a shift to sell a gift card.';

  @override
  String mktShiftAdvanceNote(String number) {
    return 'Shift No. $number. This is an advance, not revenue: the payment goes to the “Gift cards” section of the shift report.';
  }

  @override
  String get mktFaceValueRequired => 'Face value *';

  @override
  String get mktGiftCodeRequired => 'Gift card code *';

  @override
  String get mktGiftCodeHelper =>
      'Generated automatically; you can scan or type your own';

  @override
  String get mktGenerate => 'Generate';

  @override
  String get mktMin6Chars => 'At least 6 characters';

  @override
  String get mktMax32Chars => 'At most 32 characters';

  @override
  String get mktSellGift => 'Sell gift card';

  @override
  String get mktTenderedCash => 'Cash received';

  @override
  String get mktTenderedHelper => 'Empty — no change';

  @override
  String get mktSlipNumber => 'Slip number (optional)';

  @override
  String get mktTransferNumber => 'Transfer number (optional)';

  @override
  String get mktInCash => 'In cash';

  @override
  String mktPrintFailed(String error) {
    return 'Could not print: $error';
  }

  @override
  String get mktGiftSold => 'Gift card sold';

  @override
  String notifOutOfStockTitle(String name) {
    return 'Out of stock: $name';
  }

  @override
  String notifOutOfStockBody(String qty) {
    return 'Stock $qty. Place a purchase order so you don’t lose sales.';
  }

  @override
  String notifLowStockTitle(String name) {
    return 'Low stock: $name';
  }

  @override
  String notifLowStockBody(String qty, String min) {
    return 'Stock $qty, minimum $min.';
  }

  @override
  String notifDebtTitle(String name) {
    return 'Overdue debt: $name';
  }

  @override
  String notifDebtBody(String overdue, String date) {
    return '$overdue overdue, payment was due $date. Remind the customer to pay.';
  }

  @override
  String notifDebtBodyPartial(String overdue, String debt, String date) {
    return '$overdue of $debt overdue, payment was due $date. Remind the customer to pay.';
  }

  @override
  String notifBirthdayTitle(String name) {
    return 'Birthday: $name';
  }

  @override
  String get notifBirthdayBody =>
      'Congratulate the customer and offer a gift or bonuses.';

  @override
  String notifBirthdayBodyAge(String age) {
    return 'Turns $age. Congratulate the customer and offer a gift or bonuses.';
  }

  @override
  String notifShiftTitle(String number, String hours) {
    return 'Shift No. $number open for $hours h';
  }

  @override
  String notifShiftBody(String date, String time) {
    return 'Opened $date at $time. Close the shift and reconcile the cash in the till.';
  }

  @override
  String get notifKindLowStock => 'Low stock';

  @override
  String get notifKindOutOfStock => 'Out of stock';

  @override
  String get notifKindDebt => 'Debts';

  @override
  String get notifKindBirthday => 'Birthdays';

  @override
  String get notifKindShift => 'Shifts';

  @override
  String get notifKindTask => 'Tasks';

  @override
  String get notifKindSystem => 'System';

  @override
  String get notifDeleted => 'Notification deleted';

  @override
  String get notifUndo => 'Undo';

  @override
  String get notifCheckNone => 'Check complete — no new notifications';

  @override
  String notifCheckCreated(String count) {
    return 'New notifications: $count';
  }

  @override
  String get notifDeleteReadTitle => 'Delete read notifications?';

  @override
  String notifDeleteReadMessage(String count) {
    return 'Notifications to delete: $count. Unread ones will stay.';
  }

  @override
  String get notifDeleteReadDone => 'Read notifications deleted';

  @override
  String get notifNoAccess =>
      'No access to this section — contact the administrator';

  @override
  String get notifAllReadShort => 'All read';

  @override
  String notifUnreadCount(String count) {
    return 'Unread: $count';
  }

  @override
  String get notifCheckNowTooltip => 'Check now (F5)';

  @override
  String get notifCheckNow => 'Check now';

  @override
  String get notifReadAll => 'Mark all read';

  @override
  String get notifAllRead => 'All notifications read';

  @override
  String get notifDeleteRead => 'Delete read';

  @override
  String get notifEmptyTitle => 'No notifications';

  @override
  String get notifEmptyMessage =>
      'Reminders about products running out, overdue debts, customer birthdays and unclosed shifts will appear here. Checks run automatically every 10 minutes.';

  @override
  String notifFilterAll(String count) {
    return 'All ($count)';
  }

  @override
  String notifFilterUnread(String count) {
    return 'Unread ($count)';
  }

  @override
  String get notifNoneOfKind => 'No notifications of this type';

  @override
  String get notifGoTo => 'Open';

  @override
  String get notifMarkUnread => 'Mark as unread';

  @override
  String get notifMarkRead => 'Mark as read';

  @override
  String posNotFound(String code) {
    return 'Not found: $code';
  }

  @override
  String get posShiftNotOpenSell =>
      'The shift is not open. Open a shift to sell';

  @override
  String get posHints =>
      'F2 search · F4 customer · F8 park · F9 parked · F12 / Ctrl+Enter pay · Del remove · +/− quantity · ↑↓ select line · Esc clear search · 3*code — multiple units';

  @override
  String get posShiftNotOpenBanner =>
      'The shift is not open — sales are unavailable';

  @override
  String get posShiftNotOpenAskManager =>
      'The shift is not open. Ask a manager to open it';

  @override
  String get posOpenShift => 'Open shift';

  @override
  String get posCartEmpty => 'Receipt is empty';

  @override
  String posTotalPositions(String count) {
    return 'Total · items: $count';
  }

  @override
  String posReceiptPositions(String count) {
    return 'Receipt · items: $count';
  }

  @override
  String get posParkedReceipts => 'Parked receipts';

  @override
  String get posCartActions => 'Receipt actions';

  @override
  String get posPark => 'Park receipt';

  @override
  String get posSeller => 'Seller';

  @override
  String get posSellGiftCard => 'Sell gift card';

  @override
  String get posClearCart => 'Clear receipt';

  @override
  String get posNoSellPerm => 'No permission to sell';

  @override
  String get posNeedOpenShift => 'An open shift is required';

  @override
  String posProductInactive(String name) {
    return '“$name” is no longer for sale';
  }

  @override
  String get posBadMultiplier => 'Invalid multiplier. Example: 3*4780000000011';

  @override
  String get posMultipleFound =>
      'Several products found — choose one from the list';

  @override
  String posProductNotFound(String code) {
    return 'Product “$code” not found';
  }

  @override
  String get posNoPricePerm => 'No permission to change prices';

  @override
  String get posLineDiscount => 'Line discount';

  @override
  String posLineDiscountFor(String name) {
    return 'Discount on “$name”';
  }

  @override
  String get posOrderDiscount => 'Receipt discount';

  @override
  String get posPromoCode => 'Promo code';

  @override
  String get posCode => 'Code';

  @override
  String get posClearCartQ => 'Clear receipt?';

  @override
  String posClearCartMessage(String count) {
    return 'All items ($count) will be removed from the receipt.';
  }

  @override
  String get posNothingToPark => 'Nothing to park — the receipt is empty';

  @override
  String get posParkNote => 'Comment (customer name, etc.)';

  @override
  String get posParkedDone => 'Receipt parked (F9 — parked list)';

  @override
  String get posAutoParked => 'Parked automatically';

  @override
  String posRestoredRepriced(String count) {
    return 'Receipt restored. Items repriced from the price list: $count';
  }

  @override
  String get posRestored => 'Receipt restored';

  @override
  String get posGiftNeedShift => 'Open a shift to sell a gift card';

  @override
  String get posShiftNotOpen => 'The shift is not open';

  @override
  String get posGiftNeedShiftDot => 'Open a shift to sell a gift card.';

  @override
  String get posNoShiftPerm => 'No permission to open a shift — ask a manager';

  @override
  String get posShiftOpened => 'Shift opened. You can sell now';

  @override
  String get posCartEmptyAdd => 'The receipt is empty — add products';

  @override
  String posPromoInvalid(String code) {
    return 'Promo code “$code” is invalid — remove or correct it';
  }

  @override
  String get posManualDiscounts => 'Manual discounts on the receipt';

  @override
  String get posManualOverLimit =>
      'Manual discounts exceed your limit — get manager approval or reduce the discount';

  @override
  String posQtyIntegerOnly(String unit) {
    return 'Only whole quantities for “$unit”';
  }

  @override
  String get posQtyTooSmall => 'Quantity too small';

  @override
  String get posLineNotFound => 'Line not found';

  @override
  String get posDiscountNegative => 'Discount cannot be negative';

  @override
  String get posDiscountOver100 => 'Discount cannot exceed 100%';

  @override
  String get posDiscountOverLine => 'Discount exceeds the line amount';

  @override
  String get posDiscountOverCart => 'Discount exceeds the receipt amount';

  @override
  String get posCartEmptyHint =>
      'Scan a barcode or pick a product from the catalog';

  @override
  String posPositions(String count) {
    return 'Items: $count';
  }

  @override
  String get posSellerTooltip => 'Sales assistant (for incentives)';

  @override
  String get posParkedTooltip => 'Parked receipts (F9)';

  @override
  String get posParkedShort => 'Parked';

  @override
  String get posCustomerF4 => 'Customer (F4)';

  @override
  String posCustDiscount(String percent) {
    return 'discount $percent%';
  }

  @override
  String posCustBonus(String amount) {
    return 'bonuses $amount';
  }

  @override
  String posCustDebt(String amount) {
    return 'debt $amount';
  }

  @override
  String posCustDebtLimit(String amount) {
    return 'limit $amount';
  }

  @override
  String get posDetachCustomer => 'Remove customer from receipt';

  @override
  String get posPromotion => 'Promotion';

  @override
  String get posManualDiscount => 'Manual discount';

  @override
  String get posApprovedMark => '(approved)';

  @override
  String posOrderDiscountLine(String amount) {
    return 'Receipt discount: −$amount';
  }

  @override
  String posOnlyInStock(String qty) {
    return 'Only $qty in stock';
  }

  @override
  String get posLess => 'Less (−)';

  @override
  String get posMore => 'More (+)';

  @override
  String get posEditPrice => 'Change price';

  @override
  String get posRemoveLine => 'Remove line (Del)';

  @override
  String posPromoInvalidChip(String code) {
    return '$code — invalid';
  }

  @override
  String get posRemovePromo => 'Remove promo code';

  @override
  String posOrderDiscountValue(String value) {
    return 'Receipt discount $value';
  }

  @override
  String get posRemoveDiscount => 'Remove discount';

  @override
  String get posSubtotal => 'Subtotal';

  @override
  String get posVatIncluded => 'incl. VAT';

  @override
  String posDiscountCalcFailed(String error) {
    return 'Could not calculate discounts: $error';
  }

  @override
  String get posOpenShiftToSell => 'Open a shift to sell';

  @override
  String get posAddProducts => 'Add products to the receipt';

  @override
  String get posPayTooltip => 'Pay (F12 or Ctrl+Enter)';

  @override
  String get posPay => 'Pay';

  @override
  String get posPayF12 => 'Pay  ·  F12';

  @override
  String posNonCashOver(String amount) {
    return 'Non-cash payment exceeds the receipt total by $amount';
  }

  @override
  String posMissing(String amount) {
    return 'Short by $amount';
  }

  @override
  String get posCashNotNeeded => 'No cash needed — the receipt is already paid';

  @override
  String get posDebtDue => 'Debt due date';

  @override
  String posDays(String days) {
    return '$days d';
  }

  @override
  String get posPickDate => 'Pick a date';

  @override
  String posUntil(String date) {
    return 'until $date';
  }

  @override
  String posBonusMax(String amount) {
    return 'Bonuses can cover at most $amount';
  }

  @override
  String posCreditExceeded(String amount) {
    return 'Credit limit exceeded: $amount available';
  }

  @override
  String get posCheckGiftCode => 'Check the gift card code';

  @override
  String posGiftOnly(String amount) {
    return 'Only $amount on the gift card';
  }

  @override
  String get posEnterGiftCode => 'Enter the gift card code';

  @override
  String get posGiftNotFound => 'Gift card not found';

  @override
  String posGiftInactive(String status) {
    return 'Gift card is not active ($status)';
  }

  @override
  String get posGiftUsed => 'used';

  @override
  String posGiftExpired(String date) {
    return 'Expired on $date';
  }

  @override
  String get posGiftEmpty => 'The gift card has no balance';

  @override
  String get posAll => 'All';

  @override
  String get posToPay => 'Amount due';

  @override
  String posRounding(String amount) {
    return 'Rounding: −$amount';
  }

  @override
  String posCustomerValue(String name) {
    return 'Customer: $name';
  }

  @override
  String get posCloseEsc => 'Close (Esc)';

  @override
  String get posCashReceived => 'Cash received';

  @override
  String posCashNeeded(String amount) {
    return 'Cash due: $amount';
  }

  @override
  String get posNoChange => 'Exact amount';

  @override
  String get posByCard => 'By card';

  @override
  String get posByTransfer => 'By transfer';

  @override
  String get posMixed => 'Split payment';

  @override
  String get posTransferRef => 'Transaction No. / comment (optional)';

  @override
  String posBonusHelper(String balance, String max) {
    return 'Balance $balance · up to $max can be used';
  }

  @override
  String posDebtNoLimit(String debt) {
    return 'Debt $debt · no limit set';
  }

  @override
  String posDebtHelper(String debt, String limit, String available) {
    return 'Debt $debt of $limit · $available available';
  }

  @override
  String get posSelectCustomerForDebt =>
      'Select a customer to pay on credit or with bonuses';

  @override
  String get posSelectCustomerForDebtF4 =>
      'Select a customer to pay on credit or with bonuses (F4)';

  @override
  String get posGiftCode => 'Gift card code';

  @override
  String posGiftBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String get posCheck => 'Check';

  @override
  String get posPayByGift => 'Gift card payment';

  @override
  String get posProcessing => 'Processing…';

  @override
  String get posConfirmPay => 'Complete payment';

  @override
  String get posConfirmPayEnter => 'Complete payment (Enter)';

  @override
  String get posNonCashOverpay => 'Non-cash overpayment';

  @override
  String get posMissingLabel => 'Short';

  @override
  String get posQtyWeight => 'Quantity / weight';

  @override
  String get posQtyExample => 'E.g. 0.75';

  @override
  String get posSalePrice => 'Sale price';

  @override
  String posListPrice(String amount) {
    return 'List price: $amount';
  }

  @override
  String get posNewPrice => 'New price';

  @override
  String get posRestoreListPrice => 'Restore list price';

  @override
  String get posNotMore100 => 'Not more than 100%';

  @override
  String posMoreThanAmount(String amount) {
    return 'More than the amount ($amount)';
  }

  @override
  String posAmountValue(String amount) {
    return 'Amount: $amount';
  }

  @override
  String get posPercentSeg => 'Percent, %';

  @override
  String get posDiscountPct => 'Discount, %';

  @override
  String get posDiscountAmount => 'Discount, amount';

  @override
  String posDiscountSummary(String amount, String percent, String due) {
    return 'Discount: $amount ($percent%) · due $due';
  }

  @override
  String posOverLimit(String limit) {
    return 'Exceeds your $limit% limit — a manager PIN is required';
  }

  @override
  String posYourLimit(String limit) {
    return 'Your discount limit: $limit%';
  }

  @override
  String posApproverNoPerm(String name) {
    return '$name: no permission to approve discounts';
  }

  @override
  String posApproverLimitNotHigher(String name) {
    return '$name: discount limit is not higher than the cashier’s';
  }

  @override
  String posApproverLimit(String name, String limit, String requested) {
    return '$name’s limit is $limit%, requested $requested%';
  }

  @override
  String get posOtherPinNeeded =>
      'Another employee’s PIN is required (manager or owner)';

  @override
  String get posManagerApproval => 'Manager approval';

  @override
  String posApprovalMessage(String what, String percent, String limit) {
    return '$what: $percent% — above the cashier’s limit ($limit%).\nA manager or the owner enters their PIN.';
  }

  @override
  String get posOpenShiftHint =>
      'Count the cash in the drawer and enter the opening float.';

  @override
  String get posOpeningCash => 'Opening float';

  @override
  String get posOpeningCashHelper => '0 is fine if the drawer is empty';

  @override
  String get posSellerConsultant => 'Sales assistant';

  @override
  String get posCashierDefault => 'Cashier (default)';

  @override
  String get posNoParked => 'No parked receipts';

  @override
  String get posNoParkedHint =>
      'Park the current receipt (F8) to serve the next customer';

  @override
  String get posParkedTapHint => 'Tap a receipt to bring it back to the till';

  @override
  String posAndMore(String count) {
    return 'and $count more';
  }

  @override
  String posReceiptFrom(String time) {
    return 'Receipt at $time';
  }

  @override
  String get posDeleteParked => 'Delete parked receipt';

  @override
  String get posDeleteParkedQ => 'Delete parked receipt?';

  @override
  String get posDeleteParkedMessage =>
      'The products on this receipt will be lost.';

  @override
  String get posSearchHintShort => 'Barcode or name';

  @override
  String get posSearchHint => 'Scan a barcode or type a name (F2)';

  @override
  String get posClearEsc => 'Clear (Esc)';

  @override
  String get posFavorites => 'Favorites';

  @override
  String posNoResults(String query) {
    return 'No products match “$query”. Check the name or scan the barcode.';
  }

  @override
  String get posCategoryEmpty => 'No products in this category';

  @override
  String get posCatalogEmpty => 'The catalog is empty';

  @override
  String get posCatalogEmptyHint =>
      'Add products under “Products” to start selling';

  @override
  String get posNoStockTracking => 'stock not tracked';

  @override
  String posPrintFailed(String error) {
    return 'Could not print the receipt: $error';
  }

  @override
  String posSaleDone(String number) {
    return 'Receipt No. $number completed';
  }

  @override
  String posReceiptSum(String amount) {
    return 'Receipt total: $amount';
  }

  @override
  String posDiscountValue(String amount) {
    return 'Discount: $amount';
  }

  @override
  String posBonusEarned(String amount) {
    return 'Bonuses earned: $amount';
  }

  @override
  String get posPrintAgain => 'Print again';

  @override
  String get posPrintReceipt => 'Print receipt';

  @override
  String get posNewSale => 'New sale (Enter)';

  @override
  String get prodRoundNearest => 'To nearest';

  @override
  String get prodRoundUp => 'Up';

  @override
  String get prodRoundDown => 'Down';

  @override
  String get prodRoundNone => 'No rounding';

  @override
  String prodRoundTo(String amount) {
    return 'To $amount';
  }

  @override
  String get prodStockAll => 'All stock';

  @override
  String get prodStockIn => 'In stock';

  @override
  String get prodStockLow => 'Low';

  @override
  String get prodStockOut => 'Out of stock';

  @override
  String get prodStockNegative => 'Negative';

  @override
  String get prodActive => 'Active';

  @override
  String get prodArchive => 'Archived';

  @override
  String get prodSortName => 'By name';

  @override
  String get prodSortPrice => 'By price';

  @override
  String get prodSortStock => 'By stock';

  @override
  String get prodSortMargin => 'By margin';

  @override
  String get prodSortUpdated => 'By last change';

  @override
  String get prodUnitShort => 'Unit';

  @override
  String get prodDelimTab => 'tab';

  @override
  String get prodDelimSemicolon => 'semicolon';

  @override
  String get prodDelimComma => 'comma';

  @override
  String prodImpErrMissing(String field) {
    return '$field: missing';
  }

  @override
  String prodImpErrNegative(String field) {
    return '$field: cannot be negative';
  }

  @override
  String prodImpErrNotNumber(String field, String value) {
    return '$field: “$value” is not a number';
  }

  @override
  String get prodImpErrNoName => 'Name is missing';

  @override
  String get prodNameTooLong => 'Name is longer than 200 characters';

  @override
  String prodImpErrBarcodeSci(String code) {
    return 'Barcode “$code” was corrupted by Excel (scientific notation)';
  }

  @override
  String prodImpErrBarcodeDup(String code, String line) {
    return 'Duplicate barcode $code (line $line)';
  }

  @override
  String get prodEan13BadCheck => 'Invalid EAN-13 check digit';

  @override
  String prodImpErrUnit(String unit) {
    return 'Unknown unit “$unit” (pcs, kg, g, l, m, pack)';
  }

  @override
  String prodImpErrStockNotNumber(String value) {
    return 'Stock: “$value” is not a number';
  }

  @override
  String get prodImpErrStockNegative => 'Stock cannot be negative';

  @override
  String prodImpErrStockInteger(String unit) {
    return 'Stock in “$unit” must be a whole number';
  }

  @override
  String get prodPriceBelowCost => 'Price is below cost';

  @override
  String get prodMoveReceipt => 'Goods receipt';

  @override
  String get prodMoveReceiptReversal => 'Goods receipt reversal';

  @override
  String get prodMoveWriteoff => 'Write-off';

  @override
  String get prodMoveAdjustment => 'Adjustment';

  @override
  String get prodMoveInventory => 'Stocktake';

  @override
  String get prodMoveTransfer => 'Transfer';

  @override
  String get prodErrEnterName => 'Enter the product name';

  @override
  String get prodErrPriceNegative => 'Price cannot be negative';

  @override
  String get prodErrCostNegative => 'Cost cannot be negative';

  @override
  String get prodErrWholesaleNegative => 'Wholesale price cannot be negative';

  @override
  String get prodErrVatRange => 'VAT must be between 0 and 100%';

  @override
  String get prodErrMinStockNegative => 'Minimum stock cannot be negative';

  @override
  String get prodErrInitStockNegative => 'Opening stock cannot be negative';

  @override
  String prodErrBarcodeUsedBy(String code, String name) {
    return 'Barcode $code is already used by “$name”';
  }

  @override
  String prodErrInitStockInteger(String unit) {
    return 'Opening stock in “$unit” must be a whole number';
  }

  @override
  String get prodNoPricePerm => 'No permission to change prices';

  @override
  String prodErrBarcodeUsedOther(String code) {
    return 'Barcode $code is already used by another product';
  }

  @override
  String get prodErrAlreadyDeleted => 'The product has already been deleted';

  @override
  String prodErrFractionalStock(String qty, String unit) {
    return 'Stock $qty is fractional — fix it in “Stock” first, then change the unit to “$unit”';
  }

  @override
  String get prodErrHasHistory =>
      'The product has history (sales, stock movements). It can only be archived.';

  @override
  String prodErrPriceNegativeFor(String name) {
    return 'Price cannot be negative: $name';
  }

  @override
  String get prodErrEnterCategoryName => 'Enter the category name';

  @override
  String get prodErrCategoryNameTooLong => 'Name is longer than 120 characters';

  @override
  String prodErrCategoryExists(String name) {
    return 'Category “$name” already exists';
  }

  @override
  String prodErrCategoryInUse(String count) {
    return 'Products in the category: $count — choose where to move them';
  }

  @override
  String get prodErrPickOtherCategory => 'Choose a different category';

  @override
  String get prodImpNoteStockUnchanged => 'Stock is not changed — use “Stock”';

  @override
  String prodImpNoteBarcodeTaken(String name) {
    return 'Barcode already belongs to “$name”';
  }

  @override
  String get prodNotFoundTitle => 'Product not found';

  @override
  String prodBarcodeNotInCatalog(String code) {
    return 'Barcode $code is not in the catalog. Create a new product with this barcode?';
  }

  @override
  String get prodCategories => 'Categories';

  @override
  String get prodImportFromCsv => 'Import from CSV';

  @override
  String get prodExportToCsv => 'Export to CSV';

  @override
  String get prodByCurrentFilter => 'current filter';

  @override
  String get prodWholeCatalog => 'whole catalog';

  @override
  String get prodNewProduct => 'New product';

  @override
  String get prodNoCategory => 'No category';

  @override
  String get prodSearchHintShort => 'Name, SKU, barcode';

  @override
  String get prodSearchHint => 'Name, SKU or barcode (Ctrl+F)';

  @override
  String get prodAllCategories => 'All categories';

  @override
  String get prodFavorites => 'Favorites';

  @override
  String get prodSortTooltip => 'Sort (pick again to reverse the order)';

  @override
  String prodCountLabel(String count) {
    return 'Products: $count';
  }

  @override
  String get prodSelect => 'Select';

  @override
  String get prodNoEditPerm => 'No permission to edit products';

  @override
  String get prodPricesPercent => 'Prices, %';

  @override
  String get prodPriceLabels => 'Price tags';

  @override
  String get prodToArchive => 'Archive';

  @override
  String get prodRestore => 'Restore';

  @override
  String get prodCancelSelection => 'Clear selection (Esc)';

  @override
  String prodSelectedCount(String count) {
    return 'Selected: $count';
  }

  @override
  String get prodTryOtherFilters => 'Try changing the filters';

  @override
  String prodNoResultsFor(String query) {
    return 'No products match “$query”';
  }

  @override
  String get prodResetFilters => 'Reset filters';

  @override
  String get prodCatalogEmpty => 'The catalog is empty';

  @override
  String get prodEmptyHintEditor =>
      'Add your first product or load a list from Excel (CSV).';

  @override
  String get prodEmptyHintViewer =>
      'Products are added by a manager or administrator.';

  @override
  String get prodImportCsv => 'Import CSV';

  @override
  String get prodStockUntracked => 'Stock is not tracked';

  @override
  String prodStockLowTip(String qty) {
    return 'Low: minimum $qty';
  }

  @override
  String get prodStockNegativeTip =>
      'Negative stock — check goods receipts/stocktakes';

  @override
  String prodSkuShort(String sku) {
    return 'SKU $sku';
  }

  @override
  String get prodCostShort => 'Cost';

  @override
  String get prodMargin => 'Margin';

  @override
  String get prodArchiveOneQ => 'Archive the product?';

  @override
  String prodArchiveManyQ(String count) {
    return 'Archive products ($count)?';
  }

  @override
  String get prodArchiveMessage =>
      'Archived products are not sold and are hidden at the register. Sales history is kept. You can restore them at any time (“Archived” filter).';

  @override
  String get prodRestored => 'Products are back on sale';

  @override
  String get prodArchived => 'Moved to archive';

  @override
  String get prodCannotDeleteArchived =>
      'The product has history — it cannot be deleted and is already archived';

  @override
  String get prodCannotDeleteTitle => 'Cannot delete';

  @override
  String prodCannotDeleteMessage(String name) {
    return '“$name” has sales or stock movements — it must stay in the database for reports. Move it to the archive?';
  }

  @override
  String get prodMovedToArchive => 'Product moved to archive';

  @override
  String prodDeleteQ(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get prodDeleteMessage =>
      'The product has no history and will be removed from the catalog.';

  @override
  String get prodDeleted => 'Product deleted';

  @override
  String get prodNotFoundOrDeleted => 'Product not found or deleted';

  @override
  String get prodPriceLabel => 'Price tag';

  @override
  String get prodDuplicate => 'Duplicate';

  @override
  String get prodUnfavorited => 'Removed from favorites';

  @override
  String get prodFavorited => 'Added to favorites';

  @override
  String get prodUnfavorite => 'Remove from favorites';

  @override
  String get prodFavorite => 'Add to favorites';

  @override
  String get prodRestoreFromArchive => 'Restore from archive';

  @override
  String get prodFavoriteChip => 'Favorite';

  @override
  String get prodNoStockTracking => 'Stock not tracked';

  @override
  String get prodNoReceiptsYet => 'no goods receipts yet';

  @override
  String get prodToday => 'today';

  @override
  String prodDaysAgo(String days) {
    return '$days d ago';
  }

  @override
  String prodWholesaleShort(String price) {
    return 'wholesale $price';
  }

  @override
  String prodPerUnit(String unit) {
    return 'per $unit';
  }

  @override
  String prodMarginLower(String pct) {
    return 'margin $pct';
  }

  @override
  String get prodUntrackedLower => 'not tracked';

  @override
  String prodMinShort(String qty) {
    return 'min $qty';
  }

  @override
  String get prodMinNotSet => 'no minimum set';

  @override
  String get prodSold => 'Sold';

  @override
  String get prodLast30Days => 'last 30 days';

  @override
  String prodLast30DaysReceipts(String count) {
    return 'last 30 days · receipts: $count';
  }

  @override
  String get prodRevenue => 'Revenue';

  @override
  String get prodLastReceipt => 'Last goods receipt';

  @override
  String get prodSpecs => 'Details';

  @override
  String get prodWholesalePrice => 'Wholesale price';

  @override
  String get prodNoVatLower => 'no VAT';

  @override
  String get prodNegativeSale => 'Selling at zero stock';

  @override
  String get prodAllowed => 'allowed';

  @override
  String get prodForbidden => 'not allowed';

  @override
  String get prodWarranty => 'Warranty';

  @override
  String get prodNoneLower => 'none';

  @override
  String prodMonthsShort(String count) {
    return '$count mo';
  }

  @override
  String get prodUpdatedAt => 'Updated';

  @override
  String get prodMovements => 'Stock movements';

  @override
  String get prodLast50 => 'last 50';

  @override
  String get prodNoMovements =>
      'No movements yet. Goods receipts are entered in “Stock” or “Purchasing”.';

  @override
  String prodStockAfterShort(String qty) {
    return 'stock $qty';
  }

  @override
  String prodCopySuffix(String name) {
    return '$name (copy)';
  }

  @override
  String get prodReplaceBarcodeQ => 'Replace the barcode?';

  @override
  String prodReplaceBarcodeMessage(String code) {
    return 'The current barcode $code will be replaced with an internal one. Old labels will no longer scan.';
  }

  @override
  String get prodReplace => 'Replace';

  @override
  String get prodCloseUnsavedQ => 'Close without saving?';

  @override
  String get prodUnsavedLost => 'Your changes will be lost.';

  @override
  String get prodCheckFields => 'Check the highlighted fields';

  @override
  String prodBarcodeInUseBy(String name) {
    return 'Already used by “$name”';
  }

  @override
  String prodBarcodeAssignedTo(String code, String name) {
    return 'Barcode $code is already assigned to “$name”';
  }

  @override
  String prodPriceBelowCostMessage(String price, String cost) {
    return 'The price $price is below cost $cost. Every sale will be at a loss. Save anyway?';
  }

  @override
  String get prodZeroPrice => 'Zero price';

  @override
  String get prodZeroPriceMessage =>
      'The product will be sold for free. Continue?';

  @override
  String prodCreated(String name) {
    return 'Product “$name” created';
  }

  @override
  String get prodChangesSaved => 'Changes saved';

  @override
  String get prodCopyTitle => 'Copy of product';

  @override
  String get prodEditTitle => 'Edit product';

  @override
  String get prodCreateProduct => 'Create product';

  @override
  String get prodCloseEsc => 'Close (Esc)';

  @override
  String get prodEditorShortcuts => 'Ctrl+S — save, Esc — close';

  @override
  String get prodSectionBasic => 'General';

  @override
  String get prodNameRequired => 'Name *';

  @override
  String get prodNewCategory => 'New category';

  @override
  String get prodUnitLabel => 'Unit of measure';

  @override
  String get prodFractionalHint => 'Fractional quantity (sold by weight)';

  @override
  String get prodDescription => 'Description';

  @override
  String get prodActiveSwitch => 'Active (on sale)';

  @override
  String get prodFavoriteSwitch => 'Favorite at the register';

  @override
  String get prodSectionPrices => 'Prices';

  @override
  String get prodRetailPriceRequired => 'Retail price *';

  @override
  String get prodRetailPrice => 'Retail price';

  @override
  String get prodCostHintNew => 'For opening stock';

  @override
  String get prodCostHintAvg => 'Average from goods receipts';

  @override
  String get prodMarginColon => 'Margin: ';

  @override
  String get prodMarkupColon => 'Markup: ';

  @override
  String get prodProfitPerUnitColon => 'Profit per unit: ';

  @override
  String get prodVatIncluded => 'VAT (included in price)';

  @override
  String get prodNoVat => 'No VAT';

  @override
  String get prodVatOther => 'Other';

  @override
  String get prodInternalEan => 'Internal EAN-13';

  @override
  String get prodSectionCodes => 'Codes';

  @override
  String get prodScanOrType => 'Scan or type';

  @override
  String get prodGenerateBarcode => 'Generate internal EAN-13 (prefix 200)';

  @override
  String get prodBarcodeTooLong => 'Barcode is too long';

  @override
  String get prodBarcodeNoSpaces => 'Barcode must not contain spaces';

  @override
  String get prodSkuLabel => 'SKU';

  @override
  String prodSkuFree(String sku) {
    return 'Available: $sku';
  }

  @override
  String prodSkuUse(String sku) {
    return 'Use $sku';
  }

  @override
  String get prodSectionStock => 'Stock';

  @override
  String get prodTrackStock => 'Track stock';

  @override
  String get prodAllowNegative => 'Allow selling at zero stock';

  @override
  String get prodMinStock => 'Minimum stock';

  @override
  String get prodMinStockHint => 'Below this the product is marked “Low”';

  @override
  String get prodEnterNonNegative => 'Enter a number ≥ 0';

  @override
  String get prodInitialStock => 'Opening stock';

  @override
  String get prodInitialStockHint => 'Received as “Opening stock”';

  @override
  String get prodCurrentStock => 'Current stock';

  @override
  String get prodCurrentStockHint =>
      'Changed in “Stock”: goods receipts, write-offs, stocktakes';

  @override
  String get prodSectionWarranty => 'Warranty and supplier';

  @override
  String get prodMonthsSuffix => 'mo';

  @override
  String get prodWarrantyHint => '0 — no warranty';

  @override
  String get prodWarrantyRange => '0 to 240 months';

  @override
  String get prodSuppliersHint => 'Suppliers are added in “Purchasing”';

  @override
  String get prodNotSpecified => 'Not set';

  @override
  String get prodUnitNamePcs => 'Piece (pcs)';

  @override
  String get prodUnitNameKg => 'Kilogram (kg)';

  @override
  String get prodUnitNameG => 'Gram (g)';

  @override
  String get prodUnitNameL => 'Liter (l)';

  @override
  String get prodUnitNameM => 'Meter (m)';

  @override
  String get prodUnitNamePack => 'Pack';

  @override
  String prodBulkCategoryTitle(String count) {
    return 'Category for selected products ($count)';
  }

  @override
  String prodBulkCategoryDone(String count) {
    return 'Category changed for products: $count';
  }

  @override
  String get prodBulkPriceTitle => 'Change prices by %';

  @override
  String get prodBulkPctError =>
      'Enter a percentage from −99 to 1000, e.g. 10 or −5';

  @override
  String get prodBulkNoChange =>
      'Prices will not change — try another percentage or rounding';

  @override
  String prodBulkPriceConfirmQ(String count) {
    return 'Change prices of selected products ($count)?';
  }

  @override
  String get prodBulkPriceConfirmMessage =>
      'Every change is written to the audit log. Price tags will need to be reprinted.';

  @override
  String get prodChangePrices => 'Change prices';

  @override
  String prodBulkPriceDone(String count) {
    return 'Prices updated for products: $count';
  }

  @override
  String get prodChangePct => 'Change, %';

  @override
  String get prodChangePctHint => 'e.g. 10 or -5';

  @override
  String get prodChangePctHelper => 'Plus raises prices, minus lowers them';

  @override
  String get prodChangePctRange => '−99 to 1000';

  @override
  String get prodRounding => 'Rounding';

  @override
  String prodWillChange(String count) {
    return 'Will change: $count';
  }

  @override
  String prodBelowCostCount(String count) {
    return 'Below cost: $count';
  }

  @override
  String prodCostMarginLine(String cost, String margin) {
    return 'cost $cost · margin $margin';
  }

  @override
  String prodApplyTo(String count) {
    return 'Apply to $count';
  }

  @override
  String get prodErrEnterNameShort => 'Enter a name';

  @override
  String get prodColor => 'Color';

  @override
  String prodDeleteCategoryQ(String name) {
    return 'Delete category “$name”?';
  }

  @override
  String get prodCategoryEmptyMsg => 'The category has no products.';

  @override
  String get prodCategoryDeleted => 'Category deleted';

  @override
  String prodCategoryMoveQ(String count) {
    return 'Products in the category: $count. Where should they go?';
  }

  @override
  String get prodMoveTo => 'Move to';

  @override
  String get prodMoveAndDelete => 'Move and delete';

  @override
  String get prodCategoryDeletedMoved => 'Category deleted, products moved';

  @override
  String get prodNoCategoriesYet => 'No categories yet';

  @override
  String get prodCategoriesHint =>
      'Categories help find products quickly at the register and in reports.';

  @override
  String prodCategoriesFooter(String count) {
    return 'Drag to change the order at the register. Products without a category: $count.';
  }

  @override
  String get prodImportTitle => 'Import products from CSV';

  @override
  String get prodImpEnterPath => 'Enter the path to a .csv file';

  @override
  String prodImpFileNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String get prodImpFileTooBig => 'The file is larger than 20 MB';

  @override
  String prodImpFileLoaded(String name) {
    return 'File loaded: $name';
  }

  @override
  String get prodImpPasteOrLoad => 'Paste data from Excel or load a file';

  @override
  String get prodImpNoRows => 'No data rows';

  @override
  String prodImpTooManyRows(String count) {
    return 'Too many rows ($count). Split the file into parts of up to 20,000 rows.';
  }

  @override
  String get prodImpNothing => 'Nothing to import — fix the errors in the data';

  @override
  String prodImpDone(String created, String updated) {
    return 'Created $created, updated $updated';
  }

  @override
  String prodImpDoneSkipped(String count) {
    return ', skipped $count';
  }

  @override
  String prodImpDoneCategories(String count) {
    return ', new categories $count';
  }

  @override
  String get prodImpIntro =>
      'Copy rows from Excel / Google Sheets and paste them below, or enter the path to a .csv file. Columns: name; barcode; SKU; category; price; cost; unit; stock. The header and delimiter (; , tab) are detected automatically.';

  @override
  String get prodImpPasteHint => 'Paste data (Ctrl+V)…';

  @override
  String get prodImpOrPath => 'Or file path';

  @override
  String get prodImpPathHint => 'C:\\Users\\...\\products.csv';

  @override
  String get prodImpLoad => 'Load';

  @override
  String get prodImpUpdateExisting => 'Update existing products by barcode';

  @override
  String get prodImpUpdateExistingHint =>
      'Otherwise rows with a known barcode are skipped. Stock of existing products is not changed.';

  @override
  String get prodImpSample => 'Example';

  @override
  String get prodImpCheck => 'Check';

  @override
  String prodImpRows(String count) {
    return 'Rows: $count';
  }

  @override
  String prodImpNew(String count) {
    return 'New: $count';
  }

  @override
  String prodImpUpdateCount(String count) {
    return 'Update: $count';
  }

  @override
  String prodImpSkipErrors(String count) {
    return 'Skipped/errors: $count';
  }

  @override
  String prodImpNewCategories(String count) {
    return 'New categories: $count';
  }

  @override
  String prodImpDelimiterWithHeader(String delimiter) {
    return 'Delimiter: $delimiter, with header';
  }

  @override
  String prodImpDelimiterNoHeader(String delimiter) {
    return 'Delimiter: $delimiter, no header';
  }

  @override
  String get prodImpNoPricePerm =>
      'No permission to change prices: prices of existing products will not be updated.';

  @override
  String get prodImpUpdate => 'Update';

  @override
  String get prodImpSkip => 'Skip';

  @override
  String get prodImpNoName => '(no name)';

  @override
  String get prodImpBackToData => 'Back to data';

  @override
  String prodImpImportN(String count) {
    return 'Import $count';
  }

  @override
  String get prodExpNothing => 'No products to export for the current filter';

  @override
  String get prodExpFileStem => 'products';

  @override
  String prodExpDoneTitle(String count) {
    return 'Products exported: $count';
  }

  @override
  String get prodExpCopied =>
      'The data was copied to the clipboard — paste it into Excel (Ctrl+V).';

  @override
  String get prodExpSaved => 'File saved:';

  @override
  String prodExpSaveFailed(String error) {
    return 'Could not save the file: $error';
  }

  @override
  String get prodExpCopyPath => 'Copy path';

  @override
  String get prodLabelSmall => 'Small 4×10 (52×29 mm)';

  @override
  String get prodLabelMedium => 'Medium 3×8 (70×37 mm)';

  @override
  String get prodLabelLarge => 'Large 2×5 (105×59 mm)';

  @override
  String get prodPrintLabelsTitle => 'Print price tags';

  @override
  String get prodCopiesRange => 'Number of copies — 1 to 100';

  @override
  String prodLabelsIntro(String count) {
    return 'Products: $count. A4 format, dashed cut lines.';
  }

  @override
  String get prodLabelSize => 'Tag size';

  @override
  String get prodCopiesEach => 'Copies of each';

  @override
  String prodLabelsTotal(String total, String pages) {
    return 'Total tags: $total\nA4 pages: $pages';
  }

  @override
  String get prodPrintBarcode => 'Print barcode';

  @override
  String get prodPreparingPdf => 'Preparing PDF…';

  @override
  String get purActCopied =>
      'Reconciliation statement copied — paste it into Excel';

  @override
  String get purActCopyCsv => 'Copy CSV';

  @override
  String get purActFilePrefix => 'Reconciliation';

  @override
  String get purActFileSupplier => 'supplier';

  @override
  String get purActLegend =>
      'Charges (+) increase the store’s debt to the supplier; payments (−) reduce it. A positive balance is the store’s debt, a negative one is an advance with the supplier.';

  @override
  String get purActPrint => 'Print / PDF';

  @override
  String get purActSaveCsv => 'Save CSV (Excel)';

  @override
  String get purActShare => 'Share PDF';

  @override
  String get purActShort => 'Reconciliation';

  @override
  String get purActTitle => 'Reconciliation statement';

  @override
  String get purActive => 'Active';

  @override
  String get purAddOneProduct => 'Add at least one product';

  @override
  String get purAddSupplier => 'Add supplier';

  @override
  String get purAddToOrder => 'Add to order';

  @override
  String purAdjustDone(String amount) {
    return 'Adjustment $amount posted';
  }

  @override
  String get purAdjustReasonHint => 'E.g. per reconciliation statement dated …';

  @override
  String get purAdjustTitle => 'Balance adjustment';

  @override
  String get purAdvanceLower => 'advance';

  @override
  String purAdvanceLowerValue(String amount) {
    return 'advance $amount';
  }

  @override
  String purAdvanceSuffix(String amount) {
    return '$amount advance';
  }

  @override
  String purAdvanceValue(String amount) {
    return 'Advance with supplier: $amount';
  }

  @override
  String get purAdvanceWithSupplier => 'Advance with supplier';

  @override
  String purAfterAdjust(String value) {
    return 'After adjustment: $value';
  }

  @override
  String get purAllAsOrdered => 'All as ordered';

  @override
  String get purAllReceived => 'All order lines have been received';

  @override
  String get purAllTimeLower => 'all time';

  @override
  String get purAmountRequired => 'Amount *';

  @override
  String purBalanceLower(String value) {
    return 'balance $value';
  }

  @override
  String get purBuyer => 'Buyer';

  @override
  String get purCancelCashHint =>
      'A cash payment can only be cancelled while its shift is open.';

  @override
  String get purCancelOrder => 'Cancel order';

  @override
  String purCancelOrderTitle(String number) {
    return 'Cancel order No. $number?';
  }

  @override
  String get purCancelPayment => 'Cancel payment';

  @override
  String purCancelPaymentMessage(String date, String method) {
    return 'The payment dated $date ($method) stays in the history marked “Cancelled”; the debt to the supplier grows by this amount.';
  }

  @override
  String purCancelPaymentTitle(String amount) {
    return 'Cancel the $amount payment?';
  }

  @override
  String get purCancelReasonLabel => 'Cancellation reason *';

  @override
  String purCancelledAt(String date) {
    return 'Cancelled $date';
  }

  @override
  String get purCancelledFem => 'Cancelled';

  @override
  String get purCashNeedsShift =>
      'Paying cash from the till requires an open shift. Open a shift or choose another method.';

  @override
  String purCashOutFromShift(String number) {
    return 'Will be recorded as a cash payout from shift No. $number';
  }

  @override
  String get purChangesSaved => 'Changes saved';

  @override
  String get purCheckPhone => 'Check the phone number';

  @override
  String get purChooseAnotherPeriod => 'Choose another period';

  @override
  String purCloseOrderTitle(String number) {
    return 'Close order No. $number without the remaining items?';
  }

  @override
  String get purCloseWithoutRest => 'Close without remaining items';

  @override
  String get purClosingBalance => 'Closing balance';

  @override
  String get purClosingShort => 'Closing';

  @override
  String purConclusionNone(String at) {
    return 'As of $at, neither party owes the other.';
  }

  @override
  String purConclusionStoreOwes(
    String at,
    String store,
    String supplier,
    String amount,
  ) {
    return 'As of $at, “$store” owes “$supplier” $amount.';
  }

  @override
  String purConclusionSupplierOwes(
    String at,
    String supplier,
    String store,
    String amount,
  ) {
    return 'As of $at, “$supplier” owes “$store” $amount (advance).';
  }

  @override
  String get purContactPerson => 'Contact person';

  @override
  String purCoverDays(String days) {
    return 'lasts $days d';
  }

  @override
  String get purCreateOrder => 'Create order';

  @override
  String get purCreateOrders => 'Create orders';

  @override
  String purCreatedOn(String date) {
    return 'created $date';
  }

  @override
  String purDaysShort(String n) {
    return '$n d';
  }

  @override
  String get purDaysSuffix => 'd';

  @override
  String get purDebtOnly => 'With debt only';

  @override
  String get purDecrease => 'Payments (−)';

  @override
  String get purDecreaseDebt => 'Decrease debt';

  @override
  String get purDeleteLine => 'Delete line';

  @override
  String get purDeleteSupplierMessage =>
      'The supplier will be hidden from lists. Order and payment history is kept.';

  @override
  String purDeleteSupplierTitle(String name) {
    return 'Delete supplier “$name”?';
  }

  @override
  String get purDeletedProduct => 'Deleted product';

  @override
  String get purDeliveryDate => 'Delivery date';

  @override
  String purDeliveryOn(String date) {
    return 'Delivery $date';
  }

  @override
  String get purDraftSaved => 'Draft order saved';

  @override
  String get purEditorEmptyHint =>
      'Add products with the scanner, the “Product” button or from the “Auto-order” tab';

  @override
  String purEditorTotal(String amount, String count) {
    return 'Total: $amount · lines $count';
  }

  @override
  String get purEnterAdjustReason => 'Enter the adjustment reason';

  @override
  String get purEnterPrice => 'Enter a price';

  @override
  String get purEnterReason => 'Enter a reason';

  @override
  String get purEnterSupplierName => 'Enter the supplier name';

  @override
  String get purErrAddOneProduct => 'Add at least one product to the order';

  @override
  String get purErrAlreadyClosed => 'The order is already closed';

  @override
  String get purErrAlreadySent => 'The order has already been sent';

  @override
  String purErrDeleteNonZeroBalance(String balance) {
    return 'Cannot delete a supplier with a non-zero balance ($balance)';
  }

  @override
  String get purErrDuplicateProduct =>
      'A product appears twice in the order — merge the lines';

  @override
  String get purErrEnterQtyOneLine => 'Enter a quantity for at least one line';

  @override
  String get purErrLineNotFound => 'Line not found in the order';

  @override
  String purErrLinePriceNegative(String name) {
    return '“$name”: the price cannot be negative';
  }

  @override
  String get purErrLineTwice => 'An order line is listed twice';

  @override
  String get purErrNameTooLong => 'The name is too long';

  @override
  String get purErrNoLines => 'The order has no lines';

  @override
  String get purErrNothingToOrder => 'Nothing to order';

  @override
  String get purErrOnlyDraftEditable => 'Only a draft order can be edited';

  @override
  String purErrOrderAlreadyStatus(String number, String status) {
    return 'Order No. $number is already $status';
  }

  @override
  String purErrReceiveAtMost(String name, String qty) {
    return '“$name”: you can receive at most $qty';
  }

  @override
  String purErrSupplierExists(String name) {
    return 'Supplier “$name” already exists';
  }

  @override
  String purErrSupplierHasOpenOrders(String n) {
    return 'The supplier has open orders ($n)';
  }

  @override
  String get purErrSupplierNameRequired => 'Enter the supplier name';

  @override
  String purErrWholeQty(String name) {
    return '“$name”: whole quantity only';
  }

  @override
  String purExpectedOn(String date) {
    return 'expected $date';
  }

  @override
  String get purFromBuyer => 'On behalf of the buyer';

  @override
  String get purFromSupplier => 'On behalf of the supplier';

  @override
  String get purFullyReceivedSuffix => ' — order fully received';

  @override
  String purHeadingAllTime(String period) {
    return 'for $period';
  }

  @override
  String purHeadingPeriod(String period) {
    return 'for the period $period';
  }

  @override
  String get purIncrease => 'Charges (+)';

  @override
  String get purIncreaseDebt => 'Increase debt';

  @override
  String get purInvalid => 'Invalid';

  @override
  String purInvoiceShort(String number) {
    return 'inv. $number';
  }

  @override
  String purItemProgress(String ordered, String received) {
    return 'ordered $ordered · received $received';
  }

  @override
  String purItemRestSuffix(String qty) {
    return ' · $qty outstanding';
  }

  @override
  String purLastReceipt(String date, String count) {
    return 'last goods receipt $date · goods receipts: $count';
  }

  @override
  String get purLedgerAdjustment => 'Adjustment';

  @override
  String get purLedgerEmpty => 'No transactions yet';

  @override
  String get purLedgerEmptyMessage =>
      'Goods receipts, payments and adjustments with the running balance will appear here';

  @override
  String get purLedgerEmptyPeriod => 'No transactions in this period';

  @override
  String purLedgerOpNumbered(String op, String number) {
    return '$op No. $number';
  }

  @override
  String get purLedgerOpening => 'Opening balance';

  @override
  String get purLedgerPaymentCancel => 'Payment cancellation';

  @override
  String get purLedgerPeriodHelp => 'Settlement period';

  @override
  String get purLedgerReceipt => 'Goods receipt';

  @override
  String get purLedgerReceiptReversal => 'Goods receipt reversal';

  @override
  String get purMarkOrdered => 'Mark as ordered';

  @override
  String get purMax160Chars => 'No more than 160 characters';

  @override
  String purMaxQty(String qty) {
    return 'Max $qty';
  }

  @override
  String get purMethodTransfer => 'Bank transfer';

  @override
  String purMinValue(String qty) {
    return 'min $qty';
  }

  @override
  String get purNameRequiredLabel => 'Name *';

  @override
  String get purNewOrder => 'New order';

  @override
  String get purNewPo => 'New purchase order';

  @override
  String get purNewSupplier => 'New supplier';

  @override
  String get purNoAccess => 'No access';

  @override
  String get purNoAccessMessage =>
      'Purchasing is available to storekeepers, managers and owners';

  @override
  String get purNoCashOutPermission =>
      'No permission to pay cash from the till';

  @override
  String get purNoCashPermission => 'No permission for cash operations';

  @override
  String get purNoChange => 'no change';

  @override
  String get purNoDebt => 'no debt';

  @override
  String get purNoLinesAdded => 'No lines added';

  @override
  String get purNoOrders => 'No purchase orders yet';

  @override
  String get purNoOrdersForFilter => 'No orders match the filter';

  @override
  String get purNoOrdersMessage =>
      'Create an order manually or use the “Auto-order” tab';

  @override
  String get purNoOrdersYet => 'No orders yet';

  @override
  String get purNoPaymentsYet => 'No payments yet';

  @override
  String get purNoProductsForFilter => 'No products match the filter';

  @override
  String get purNoReceiptsYet => 'No goods received for this order yet';

  @override
  String get purNoSales => 'no sales';

  @override
  String get purNoSupplier => 'No supplier';

  @override
  String get purNoSupplierHelper =>
      'These products have no supplier in their cards';

  @override
  String get purNoSuppliers => 'No suppliers yet';

  @override
  String get purNoSuppliersMessage =>
      'Add suppliers to place orders and track debts';

  @override
  String purNowValue(String value) {
    return 'Now: $value';
  }

  @override
  String get purNumberGeZero => 'Number ≥ 0';

  @override
  String purOnOrderValue(String qty) {
    return 'on order $qty';
  }

  @override
  String get purOpeningBalance => 'Opening balance';

  @override
  String get purOpeningShort => 'Opening';

  @override
  String get purOperation => 'Transaction';

  @override
  String purOrderAmount(String amount) {
    return 'Order total $amount';
  }

  @override
  String get purOrderButton => 'Order';

  @override
  String get purOrderCancelled => 'Order cancelled';

  @override
  String get purOrderClosed => 'Order closed';

  @override
  String get purOrderFromSupplier => 'Order from supplier';

  @override
  String purOrderListTitle(String number, String supplier) {
    return 'No. $number · $supplier';
  }

  @override
  String get purOrderNotFound => 'Order not found';

  @override
  String purOrderNumber(String number) {
    return 'Order No. $number';
  }

  @override
  String get purOrderReceipts => 'Goods receipts for this order';

  @override
  String get purOrderSavedSent => 'Order saved and marked as sent';

  @override
  String purOrderSent(String number) {
    return 'Order No. $number sent to the supplier';
  }

  @override
  String purOrderedRest(String ordered, String rest) {
    return 'ordered $ordered · outstanding $rest';
  }

  @override
  String get purOurDebtLower => 'we owe';

  @override
  String purOurDebtLowerValue(String amount) {
    return 'we owe $amount';
  }

  @override
  String get purOurDebtToSupplier => 'We owe the supplier';

  @override
  String purOurDebtValue(String amount) {
    return 'We owe: $amount';
  }

  @override
  String purOverpayMessage(String debt, String amount, String advance) {
    return 'Debt to the supplier: $debt.\nPaying $amount leaves an advance of $advance. Continue?';
  }

  @override
  String get purOverpayTitle => 'Amount exceeds the debt';

  @override
  String purPaidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String get purPay => 'Pay';

  @override
  String get purPayWithAdvance => 'Pay with advance';

  @override
  String purPaymentCancelled(String amount) {
    return 'Payment of $amount cancelled';
  }

  @override
  String get purPaymentCommentLabel => 'Comment (payment ref. No.…)';

  @override
  String purPaymentDone(String amount) {
    return 'Payment of $amount recorded';
  }

  @override
  String get purPaymentTitle => 'Supplier payment';

  @override
  String get purPeriodAll => 'All time';

  @override
  String get purPeriodCustom => 'Custom…';

  @override
  String get purPeriodLastMonth => 'Last month';

  @override
  String get purPeriodQuarter => 'Quarter';

  @override
  String get purPeriodThisMonth => 'This month';

  @override
  String purPeriodUntil(String date) {
    return 'until $date';
  }

  @override
  String get purPoColBarcode => 'Barcode / SKU';

  @override
  String get purPoColNo => 'No.';

  @override
  String get purPoColQty => 'Qty';

  @override
  String get purPoColReceived => 'Received';

  @override
  String purPoDated(String date, String status) {
    return 'dated $date · $status';
  }

  @override
  String purPoExpected(String date) {
    return 'Expected delivery date: $date';
  }

  @override
  String purPoNote(String note) {
    return 'Note: $note';
  }

  @override
  String purPoOrderedBy(String line) {
    return 'Ordered by: $line';
  }

  @override
  String purPoPrintName(String number) {
    return 'Purchase order $number';
  }

  @override
  String get purPoShort => 'Purchase order';

  @override
  String purPoSupplier(String name) {
    return 'Supplier: $name';
  }

  @override
  String purPoTitle(String number) {
    return 'Purchase order No. $number';
  }

  @override
  String purPoTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get purPostAdjust => 'Post adjustment';

  @override
  String get purPriceRiseChip => 'Up > 10%';

  @override
  String get purPriceRiseFilter => 'Price up > 10%';

  @override
  String get purPricesEmpty => 'No goods receipts in this period';

  @override
  String get purPricesEmptyMessage =>
      'Purchase price history is built from goods receipts';

  @override
  String purPricesSummary(String count, String spikes) {
    return 'Products received: $count · up more than 10%: $spikes';
  }

  @override
  String purProductNotFound(String code) {
    return 'Product “$code” not found';
  }

  @override
  String get purPurchasePrice => 'Purchase price';

  @override
  String get purQtyMoreThanZero => 'over 0';

  @override
  String get purQtyMoreThanZeroCap => 'Over 0';

  @override
  String get purQtyWhole => 'whole';

  @override
  String get purQtyWholeCap => 'Whole';

  @override
  String get purReasonRequired => 'Reason *';

  @override
  String get purRecalculate => 'Recalculate';

  @override
  String purReceiptNumber(String number) {
    return 'Goods receipt No. $number';
  }

  @override
  String purReceiptPosted(String number, String amount) {
    return 'Goods receipt No. $number posted, $amount';
  }

  @override
  String purReceiveConfirmMessage(String count, String amount) {
    return 'Lines: $count, worth $amount.\nStock goes up and the debt to the supplier grows by this amount.';
  }

  @override
  String get purReceiveConfirmTitle => 'Receive goods?';

  @override
  String get purReceiveEnterQty =>
      'Enter the received quantity for at least one line';

  @override
  String get purReceiveGoods => 'Receive goods';

  @override
  String get purReceiveShort => 'Receive';

  @override
  String get purReceiveStaysOpen =>
      'The order stays open — the shortfall can be received later.';

  @override
  String purReceiveTitle(String number) {
    return 'Receiving order No. $number';
  }

  @override
  String get purReceiveWillClose => 'The order will be closed as received.';

  @override
  String purReceivedAmount(String amount) {
    return 'Received worth $amount';
  }

  @override
  String get purReceivedField => 'Received';

  @override
  String purReceivedOn(String date) {
    return 'received $date';
  }

  @override
  String get purReorderAssignSupplier =>
      'Choose a supplier for products without one';

  @override
  String purReorderConfirmHead(String count) {
    return 'Drafts to create: $count';
  }

  @override
  String purReorderConfirmLine(String name, String count) {
    return '• $name: lines: $count';
  }

  @override
  String get purReorderConfirmTitle => 'Create orders?';

  @override
  String purReorderCreated(String count) {
    return 'Draft orders created: $count. Review them on the “Orders” tab';
  }

  @override
  String get purReorderDaysInvalid => 'Enter a stock cover of 1 to 365 days';

  @override
  String get purReorderDaysLabel => 'Cover, days';

  @override
  String get purReorderEmpty => 'Nothing to order';

  @override
  String get purReorderEmptyMessage =>
      'Stock covers the selected period. Set minimum stock in product cards.';

  @override
  String get purReorderHint =>
      'Average usage is based on 30 days of sales; stock, minimums and open orders are taken into account.';

  @override
  String get purReorderNothingSelected => 'No lines selected';

  @override
  String purReorderSkipped(String count) {
    return 'Lines without a supplier skipped: $count';
  }

  @override
  String purRetailSuffix(String price) {
    return ' · retail $price';
  }

  @override
  String purSalesPerDay(String value) {
    return 'sales/day $value';
  }

  @override
  String get purSaveAndSend => 'Save and send';

  @override
  String get purSaveDraft => 'Save draft';

  @override
  String get purSearchOrder => 'Search orders';

  @override
  String get purSelectOrder => 'Select an order';

  @override
  String get purSelectOrderMessage =>
      'Open an order from the list on the left or create a new one';

  @override
  String get purSelectSupplier => 'Select a supplier';

  @override
  String purSelectedCount(String count) {
    return 'Lines selected: $count';
  }

  @override
  String get purShiftClosedNoCash =>
      'Shift is closed — cannot pay cash from the till';

  @override
  String get purSignatureCaption =>
      'signature                         full name';

  @override
  String get purStampPlace => 'Stamp';

  @override
  String get purStatusCancelled => 'Cancelled';

  @override
  String get purStatusDraft => 'Draft';

  @override
  String get purStatusOrdered => 'Ordered';

  @override
  String get purStatusPartial => 'Partly received';

  @override
  String get purStatusReceived => 'Received';

  @override
  String purStockValue(String qty) {
    return 'stock $qty';
  }

  @override
  String get purStore => 'Store';

  @override
  String get purSupplierAdded => 'Supplier added';

  @override
  String get purSupplierDeleted => 'Supplier deleted';

  @override
  String get purSupplierInvoiceNo => 'Supplier invoice No.';

  @override
  String get purSupplierNotFound => 'Supplier not found or deleted';

  @override
  String get purSupplierRequired => 'Supplier *';

  @override
  String get purTabLedger => 'Settlements';

  @override
  String get purTabOrders => 'Orders';

  @override
  String get purTabPayments => 'Payments';

  @override
  String get purTabPrices => 'Purchase prices';

  @override
  String get purTabReorder => 'Auto-order';

  @override
  String get purTabSuppliers => 'Suppliers';

  @override
  String get purTaxId => 'TIN';

  @override
  String get purTaxIdInvalid => 'TIN: 9 to 14 digits';

  @override
  String purTaxIdValue(String taxId) {
    return 'TIN $taxId';
  }

  @override
  String get purTitle => 'Purchasing';

  @override
  String purToPost(String amount) {
    return 'To receive: $amount';
  }

  @override
  String get purTurnover => 'Period turnover';

  @override
  String get purUrgent => 'Urgent';

  @override
  String purWeOwe(String amount) {
    return 'We owe: $amount';
  }

  @override
  String get purZeroAll => 'Zero all';

  @override
  String get repAbcHintA => 'Core revenue (top 80%)';

  @override
  String get repAbcHintB => 'Medium share (next 15%)';

  @override
  String get repAbcHintC => 'Small share (last 5%)';

  @override
  String get repGiftSalesTitle => 'Gift card sales (advance, not revenue)';

  @override
  String get repGiftSalesHint =>
      'Money for sold gift cards is an advance. It becomes revenue when goods are paid with the gift card.';

  @override
  String repGiftSalesSubtitle(String period, String sold, String voided) {
    return '$period · sold $sold, voided $voided';
  }

  @override
  String get repColSold => 'Sold';

  @override
  String get repColVoided => 'Voided';

  @override
  String get repGiftVoidedTooltip =>
      'Refunded to buyers when the sale was voided';

  @override
  String get repPeriodLastMonth => 'Last month';

  @override
  String get repPeriodQuarter => 'Quarter';

  @override
  String get repPeriodCustom => 'Custom';

  @override
  String get repNoCategory => 'No category';

  @override
  String get repNotSpecified => 'Not specified';

  @override
  String get repNoReason => 'No reason';

  @override
  String get repExportFolder => 'Reports';

  @override
  String repForecastTitle(String days) {
    return 'Demand forecast and order for $days days';
  }

  @override
  String repAsOf(String date) {
    return 'as of $date';
  }

  @override
  String get repColSalesPerDay => 'Sales/day';

  @override
  String get repColSalesPerDayTooltip =>
      '28-day average (for new items — days since created, at least 7)';

  @override
  String get repColTrend7 => '7-day trend';

  @override
  String get repColTrend7Tooltip =>
      'Sales pace of the last 7 days vs. the average';

  @override
  String get repColCover => 'Covers';

  @override
  String get repColRunsOut => 'Runs out';

  @override
  String get repColToOrder => 'To order';

  @override
  String get repColOrderSum => 'Order total';

  @override
  String repDaysShort(String days) {
    return '$days d';
  }

  @override
  String get repAlreadyOut => 'already out';

  @override
  String get repOutOfStock => 'Out of stock';

  @override
  String get repRisk => 'Risk';

  @override
  String get repNormal => 'OK';

  @override
  String get repNoSalesShort => 'No sales';

  @override
  String get repRunOutIn7 => 'Run out in 7 days';

  @override
  String get repOutButWanted => 'Out of stock but in demand';

  @override
  String get repItemsToOrder => 'Items to order';

  @override
  String get repOrderSumAtCost => 'Order total (at cost)';

  @override
  String get repForecastHow => 'How the forecast works';

  @override
  String repForecastHelp(String horizon, String riskDays) {
    return '• Sales/day = sold in the last 28 days (net of returns) ÷ 28. For new products — days since added, but at least 7.\n• Covers = stock ÷ sales/day.\n• To order = sales/day × $horizon d + minimum stock − current stock.\n• “Risk” — the product runs out within $riskDays days.';
  }

  @override
  String repNothingToOrder(String days) {
    return 'Nothing to order — stock covers $days days';
  }

  @override
  String get repNoTrackedProducts => 'No stock-tracked products';

  @override
  String get repOnlyToOrder => 'Only items to order';

  @override
  String get repGoToPurchasing => 'Go to purchasing';

  @override
  String repInsQuoted(String name) {
    return '“$name”';
  }

  @override
  String repInsWeekExpl(String week, String prev) {
    return 'Last 7 days: $week, previous 7 days: $prev (net revenue after returns).';
  }

  @override
  String repInsRevenueUpTitle(String pct) {
    return 'Weekly revenue is up $pct';
  }

  @override
  String repInsRevenueUpExpl(String base) {
    return '$base Great result — check that you have enough stock of best sellers.';
  }

  @override
  String repInsRevenueDownTitle(String pct) {
    return 'Weekly revenue is down $pct';
  }

  @override
  String repInsRevenueDownExpl(String base) {
    return '$base Check that best sellers are in stock and run a promotion.';
  }

  @override
  String get repInsActLaunchPromo => 'Run a promotion';

  @override
  String repInsOutOfStockOne(String name) {
    return 'Best seller out of stock: $name';
  }

  @override
  String repInsOutOfStockMany(String items) {
    return '$items that were selling are out of stock';
  }

  @override
  String repInsOutOfStockExpl(String names) {
    return '$names — stock is 0, but they sold in the last 4 weeks. Every day without stock is lost revenue.';
  }

  @override
  String get repInsActOrderSupplier => 'Order from supplier';

  @override
  String repInsStockoutTitle(String name, String days) {
    return '$name will run out in $days';
  }

  @override
  String repInsStockoutExpl(
    String stock,
    String avg,
    String window,
    String reorder,
    String horizon,
  ) {
    return 'Stock $stock, sells $avg per day on average (over $window). We recommend ordering $reorder for $horizon.';
  }

  @override
  String get repInsActPurchase => 'Create purchase order';

  @override
  String get repInsStockoutMoreOne =>
      '1 more product will run out within a week';

  @override
  String repInsStockoutMoreMany(String items) {
    return '$items more will run out within a week';
  }

  @override
  String get repInsStockoutMoreExpl =>
      'See the “Demand forecast” tab for recommended order quantities.';

  @override
  String repInsCategoryTitle(String name, String pct) {
    return 'Category “$name” brings $pct of profit';
  }

  @override
  String repInsCategoryExpl(String profit, String total) {
    return 'Last 30 days: $profit of $total gross profit. Keep this category in stock and on display.';
  }

  @override
  String get repInsActOpenProducts => 'Open products';

  @override
  String repInsLossTitle(String name) {
    return '$name is sold at a loss';
  }

  @override
  String repInsLowMarginTitle(String name) {
    return '$name margin is below 5%';
  }

  @override
  String repInsMarginExpl(String revenue, String cost, String margin) {
    return 'Last 30 days: revenue $revenue, cost $cost, margin $margin%. Raise the price or review the purchase price and discounts.';
  }

  @override
  String get repInsActChangePrice => 'Change price';

  @override
  String repInsInactiveTitle(String customers) {
    return '$customers haven’t visited in 60 days — run a promotion';
  }

  @override
  String get repInsInactiveExpl =>
      'These customers used to buy but haven’t returned for over 60 days. A personal discount or bonuses often bring back 10–20% of them.';

  @override
  String get repInsActCreatePromo => 'Create promotion';

  @override
  String repInsDiscountsTitle(String pct) {
    return 'Discounts took $pct of revenue';
  }

  @override
  String repInsDiscountsExpl(String discounts, String subtotal) {
    return 'Last 30 days: discounts were $discounts of $subtotal before discounts. Check promotions and manual cashier discounts (“Staff” tab).';
  }

  @override
  String get repInsActCheckPromos => 'Check promotions';

  @override
  String repInsReturnsTitle(String pct) {
    return 'Returns — $pct of sales';
  }

  @override
  String repInsReturnsExpl(String returns, String amount) {
    return 'Last 30 days: $returns for $amount. Normal for retail is up to 3–5%. Check product quality and return reasons.';
  }

  @override
  String get repInsActOpenReceipts => 'Open receipts';

  @override
  String repInsPeakTitle(String from, String to) {
    return 'Peak hours $from–$to — add a second cashier';
  }

  @override
  String repInsPeakExpl(String from, String to, String pct) {
    return '$from:00 to $to:00 accounts for $pct of all receipts in 30 days. A second cashier at that time will cut queues and lost sales.';
  }

  @override
  String get repInsActStaff => 'Staff';

  @override
  String repInsDeadTitle(String items) {
    return '$items haven’t sold in 60 days';
  }

  @override
  String repInsDeadExplCost(String amount) {
    return '$amount at cost is tied up in them. Mark them down or run a promotion to free up cash.';
  }

  @override
  String get repInsDeadExpl =>
      'Mark them down or run a promotion to free up cash and shelf space.';

  @override
  String get repInsActOpenInventory => 'Open stock';

  @override
  String repInsOverdueTitle(String customers) {
    return 'Overdue debts: $customers';
  }

  @override
  String repInsOverdueExpl(String amount) {
    return '$amount overdue — the payment due date for these debts has passed. Remind customers and don’t sell to them on credit until paid.';
  }

  @override
  String get repInsActOpenCustomers => 'Open customers';

  @override
  String repInsTopTitle(String name) {
    return 'Best seller of the week — $name';
  }

  @override
  String repInsTopExpl(String amount, String pct) {
    return 'Revenue $amount in 7 days ($pct of all sales). Make sure it stays in stock.';
  }

  @override
  String get repInsActCheckStock => 'Check stock';

  @override
  String get repSevCritical => 'Urgent';

  @override
  String get repSevWarning => 'Warning';

  @override
  String get repSevInfo => 'Tip';

  @override
  String get repSevPositive => 'Good';

  @override
  String get repInsightsIntro =>
      'Tips based on your data for the last 30 days. Calculated on this device, offline; each explains where the numbers come from.';

  @override
  String get repRefresh => 'Refresh';

  @override
  String get repInsightsEmptyTitle => 'No tips yet';

  @override
  String get repInsightsEmptyMessage =>
      'Tips will appear once at least a week of sales has accumulated. No problems with stock, debts or margins found.';

  @override
  String get repByProducts => 'By product';

  @override
  String get repByCategories => 'By category';

  @override
  String get repSalesByCategory => 'Sales by category';

  @override
  String get repColProducts => 'Products';

  @override
  String get repColQty => 'Qty';

  @override
  String get repColRevenue => 'Revenue';

  @override
  String get repColRevenueShare => 'Revenue share';

  @override
  String get repProfitByCategory => 'Profit by category';

  @override
  String get repRevenueByCategory => 'Revenue by category';

  @override
  String get repSalesByProduct => 'Sales by product';

  @override
  String get repColShare => 'Share';

  @override
  String get repAbcTooltip => 'A — 80% of revenue, B — next 15%, C — last 5%';

  @override
  String repAbcClass(String cls, String hint) {
    return 'Class $cls — $hint';
  }

  @override
  String repProductsShort(String count) {
    return 'Products: $count';
  }

  @override
  String repRevenueSharePct(String pct) {
    return '$pct% of revenue';
  }

  @override
  String get repNoSales => 'No sales in the period';

  @override
  String get repSearchProduct => 'Search product';

  @override
  String get repNoDataForPeriod => 'No data for the period';

  @override
  String repShowMore(String shown, String total) {
    return 'Show more ($shown of $total shown)';
  }

  @override
  String get repNoSort => 'Unsorted';

  @override
  String repSortBy(String column) {
    return 'Sort: $column';
  }

  @override
  String get repCopyCsv => 'Copy CSV';

  @override
  String get repSaveCsv => 'Save CSV (Excel)';

  @override
  String get repSavePdf => 'Save PDF';

  @override
  String get repTableCopied =>
      'Table copied — paste it into Excel or a message';

  @override
  String get repFileSaved => 'File saved';

  @override
  String get repCopyPath => 'Copy path';

  @override
  String get repNoSalesInPeriod => 'No sales in the selected period';

  @override
  String get repPickAnotherPeriod =>
      'Choose another period at the top of the screen.';

  @override
  String repPrevPeriod(String amount) {
    return 'prev. period: $amount';
  }

  @override
  String get repNetRevenue => 'Net revenue';

  @override
  String get repNetRevenueTooltip =>
      'Sales minus returns for the period (voided receipts excluded)';

  @override
  String get repReturns => 'Returns';

  @override
  String repReturnsHint(String count, String pct) {
    return '$count pcs · $pct of sales';
  }

  @override
  String get repDiscounts => 'Discounts';

  @override
  String repDiscountsHint(String pct) {
    return '$pct of pre-discount total';
  }

  @override
  String get repReceipts => 'Receipts';

  @override
  String repVoidedCount(String count) {
    return 'voided: $count';
  }

  @override
  String get repNoVoids => 'no voids';

  @override
  String get repAvgCheck => 'Avg. sale';

  @override
  String get repGrossProfit => 'Gross profit';

  @override
  String get repGrossProfitTooltip =>
      'Net revenue minus cost of goods sold (including returns to stock)';

  @override
  String get repMargin => 'Margin';

  @override
  String repCostHint(String amount) {
    return 'cost: $amount';
  }

  @override
  String get repSalesByDay => 'Sales by day';

  @override
  String get repProfit => 'Profit';

  @override
  String get repNetRevenueByDay => 'Net revenue by day';

  @override
  String repTipNetRevenue(String amount) {
    return 'Net revenue: $amount';
  }

  @override
  String repTipReceipts(String count) {
    return 'Receipts: $count';
  }

  @override
  String repTipReturns(String amount) {
    return 'Returns: $amount';
  }

  @override
  String get repSalesByHour => 'Sales by hour';

  @override
  String get repHour => 'Hour';

  @override
  String get repReceiptsPerDay => 'Receipts/day';

  @override
  String get repReceiptsPerDayTooltip =>
      'Average number of receipts in this hour per day';

  @override
  String get repReceiptsShare => 'Receipt share';

  @override
  String get repLoadByHour => 'Load by hour';

  @override
  String repPeak(String from, String to) {
    return 'Peak: $from:00–$to:00';
  }

  @override
  String get repLoadByHourHint =>
      'How many receipts are rung up each hour — helps plan shifts and a second cashier.';

  @override
  String repTipReceiptsPerDay(String count, String perDay) {
    return 'Receipts: $count (≈$perDay per day)';
  }

  @override
  String repTipSales(String amount) {
    return 'Sales: $amount';
  }

  @override
  String get repByWeekday => 'By weekday';

  @override
  String repTipReceiptsLower(String count) {
    return 'receipts: $count';
  }

  @override
  String get repTitle => 'Reports';

  @override
  String get repTabSales => 'Sales';

  @override
  String get repTabStaff => 'Staff';

  @override
  String get repTabPayments => 'Payments';

  @override
  String get repTabStock => 'Stock';

  @override
  String get repTabForecast => 'Demand forecast';

  @override
  String get repTabInsights => 'AI insights';

  @override
  String get repForecastSubtitle => 'Based on sales in the last 28 days';

  @override
  String get repLast30Days => 'Last 30 days';

  @override
  String repPeriodTooltip(String period) {
    return 'Period: $period';
  }

  @override
  String get repPeriodCustomMenu => 'Custom…';

  @override
  String get repPickPeriod => 'Select period';

  @override
  String get repFrom => 'From';

  @override
  String get repTo => 'To';

  @override
  String get repWdMon => 'Mo';

  @override
  String get repWdTue => 'Tu';

  @override
  String get repWdWed => 'We';

  @override
  String get repWdThu => 'Th';

  @override
  String get repWdFri => 'Fr';

  @override
  String get repWdSat => 'Sa';

  @override
  String get repWdSun => 'Su';

  @override
  String get repDeltaNew => 'new';

  @override
  String get repSalesByCashier => 'Sales by cashier';

  @override
  String get repSalesBySeller => 'Sales by sales assistant';

  @override
  String get repStaffDiscountsTooltip =>
      'Discounts in the employee’s receipts and their share of the pre-discount total';

  @override
  String get repStaffReturnsTooltip =>
      'Returns on this employee’s receipts made in the period';

  @override
  String get repColVoidedShort => 'Voided';

  @override
  String get repVoidedReceipts => 'Voided receipts';

  @override
  String get repCashiers => 'Cashiers';

  @override
  String get repSellers => 'Sales assistants';

  @override
  String get repNetRevenueByStaff => 'Net revenue by employee';

  @override
  String get repPaymentsByMethod => 'Payments by method';

  @override
  String get repColReceived => 'Received';

  @override
  String get repColRefunded => 'Refunded';

  @override
  String get repPaymentsStructure => 'Payment mix';

  @override
  String get repNoPayments => 'No payments in the period';

  @override
  String get repCustomerDebts => 'Customer debts';

  @override
  String get repDebtIssued => 'Sold on credit';

  @override
  String get repDebtCollected => 'Collected';

  @override
  String get repDebtAdjusted => 'Adjustments (returns, voids)';

  @override
  String get repDebtChange => 'Debt change for the period';

  @override
  String repDebtOutstanding(String count) {
    return 'Current customer debt ($count)';
  }

  @override
  String get repStockByCategory => 'Stock by category (current)';

  @override
  String get repColPositions => 'Items';

  @override
  String get repColAtCost => 'At cost';

  @override
  String get repColAtRetail => 'At retail';

  @override
  String get repColPotentialProfit => 'Potential profit';

  @override
  String get repPositionsInStock => 'Items in stock';

  @override
  String repCategoriesCount(String count) {
    return 'categories: $count';
  }

  @override
  String get repStockAtCost => 'Stock at cost';

  @override
  String get repStockAtCostTooltip => 'How much money is invested in stock';

  @override
  String get repStockAtCostHint => 'invested in goods';

  @override
  String get repStockAtRetail => 'Stock at retail prices';

  @override
  String get repStockAtRetailHint => 'if everything sells at current prices';

  @override
  String get repPotentialProfit => 'Potential profit';

  @override
  String repAvgMarkup(String pct) {
    return 'average markup $pct';
  }

  @override
  String get repNoStock => 'No products with positive stock';

  @override
  String repDeadStockTitle(String days) {
    return 'Dead stock: no sales for $days days';
  }

  @override
  String get repColFrozen => 'Tied up';

  @override
  String get repColLastSale => 'Last sale';

  @override
  String get repNeverSold => 'never sold';

  @override
  String get repNoDeadStock => 'Great — no dead stock';

  @override
  String repDeadStockHint(String days) {
    return 'Products in stock that haven’t sold for $days days. Mark them down, run a promotion or return them to the supplier.';
  }

  @override
  String get repWriteOffsByReason => 'Write-offs by reason';

  @override
  String get repColOperations => 'Operations';

  @override
  String get repNoWriteOffs => 'No write-offs in the period';

  @override
  String get salesStatusCompleted => 'Completed';

  @override
  String get salesStatusPartial => 'Partly returned';

  @override
  String get salesStatusReturned => 'Returned';

  @override
  String get salesStatusHeld => 'On hold';

  @override
  String get salesPeriodWeek => '7 days';

  @override
  String get salesPeriodAll => 'All time';

  @override
  String get salesPeriodCustom => 'Period…';

  @override
  String get salesRefundHintCash => 'Pay out cash from the till';

  @override
  String get salesRefundHintCard => 'Refund to the card via the terminal';

  @override
  String get salesRefundHintTransfer => 'Refund by transfer';

  @override
  String get salesRefundHintDebt => 'Reduce the customer’s debt';

  @override
  String get salesRefundHintBonus => 'Credit the customer’s bonus account';

  @override
  String salesReturnPeriodExpired(String days) {
    return 'The return period ($days days) has expired';
  }

  @override
  String get salesVoidAlready => 'The receipt is already voided';

  @override
  String get salesVoidOnlyNoReturns =>
      'Only a receipt without returns can be voided';

  @override
  String get salesVoidShiftClosed =>
      'The receipt’s shift is closed — process a return';

  @override
  String get salesVoidOtherShift =>
      'The receipt is from another shift — process a return';

  @override
  String get salesReasonDefect => 'Defective';

  @override
  String get salesReasonNotFit => 'Not suitable';

  @override
  String get salesReasonCashierError => 'Cashier error';

  @override
  String get salesReasonOther => 'Other';

  @override
  String get salesPickPeriod => 'Select a period';

  @override
  String salesSlipTitle(String number) {
    return 'GOODS RETURN SLIP No. $number';
  }

  @override
  String get salesSlipBySale => 'Original receipt';

  @override
  String salesSlipSaleRef(String number, String date) {
    return 'No. $number dated $date';
  }

  @override
  String get salesSlipBuyer => 'Customer';

  @override
  String get salesSlipMethod => 'Refund method';

  @override
  String get salesSlipRestock => 'Back to stock';

  @override
  String get salesSlipYes => 'yes';

  @override
  String get salesSlipNoRestock => 'no (defective / not for resale)';

  @override
  String get salesSlipQty => 'Qty';

  @override
  String salesSlipTotal(String amount) {
    return 'Total refund: $amount';
  }

  @override
  String salesSlipIssued(String name) {
    return 'Issued by: $name ____________';
  }

  @override
  String get salesSlipReceived => 'Received by: ____________';

  @override
  String salesSlipJobName(String number) {
    return 'Return $number';
  }

  @override
  String salesReturnWizardTitle(String number) {
    return 'Return for receipt No. $number';
  }

  @override
  String salesNotMore(String qty) {
    return 'Max $qty';
  }

  @override
  String get salesIntegerOnly => 'Whole number only';

  @override
  String get salesCheckQty => 'Check the quantity in the highlighted lines';

  @override
  String get salesSelectItems => 'Select items and quantities to return';

  @override
  String get salesEnterReason => 'Enter the return reason';

  @override
  String get salesOpenShiftForCash => 'Open a shift to refund in cash';

  @override
  String get salesConfirmReturnTitle => 'Process the return?';

  @override
  String salesConfirmReturnMessage(
    String method,
    String amount,
    String count,
    String restock,
  ) {
    return '$method: $amount\nItems: $count. $restock';
  }

  @override
  String get salesRestockYes => 'The goods will go back to stock.';

  @override
  String get salesRestockNo => 'The goods will NOT go back to stock.';

  @override
  String get salesDoReturn => 'Process return';

  @override
  String get salesAllReturned => 'All items have already been returned';

  @override
  String salesReturnExpiredBanner(String reason, String date) {
    return '$reason. A return for the receipt dated $date is not possible — for a defect, file a warranty claim.';
  }

  @override
  String get salesWhatToReturn => 'Items to return';

  @override
  String get salesReturnAll => 'Return all';

  @override
  String get salesHowToRefund => 'How to refund';

  @override
  String get salesNoShiftNoCash =>
      'No shift is open — a cash refund is not possible';

  @override
  String salesDebtExcess(String debt, String excess) {
    return 'Customer debt is $debt — the excess $excess becomes the customer’s advance';
  }

  @override
  String salesPaidList(String list) {
    return 'Paid: $list';
  }

  @override
  String get salesRestockTitle => 'Return goods to stock';

  @override
  String get salesRestockOn => 'Stock will increase by the returned quantity';

  @override
  String get salesRestockOff =>
      'Goods will not go back to stock (defective). You can file a warranty claim after the return';

  @override
  String get salesReasonLabel => 'Return reason *';

  @override
  String get salesReasonRequired => 'Enter a reason';

  @override
  String salesBonusClawback(String amount) {
    return 'Up to $amount of earned bonuses will be deducted from the customer';
  }

  @override
  String get salesToRefund => 'To refund';

  @override
  String salesBought(String qty) {
    return 'bought $qty';
  }

  @override
  String salesReturnedQty(String qty) {
    return 'returned $qty';
  }

  @override
  String salesPaidAmount(String amount) {
    return 'paid $amount';
  }

  @override
  String get salesLess => 'Less';

  @override
  String get salesMore => 'More';

  @override
  String salesOfQty(String qty) {
    return 'of $qty';
  }

  @override
  String get salesReceiptNotFound => 'Receipt not found';

  @override
  String get salesReceiptVoided => 'The receipt is voided';

  @override
  String get salesReceiptCopy => 'Receipt copy';

  @override
  String get salesReceiptText => 'Receipt text';

  @override
  String get salesVoid => 'Void';

  @override
  String salesReturnsSection(String count) {
    return 'Returns ($count)';
  }

  @override
  String salesReceiptNo(String number) {
    return 'Receipt No. $number';
  }

  @override
  String salesShiftNo(String number) {
    return 'shift No. $number';
  }

  @override
  String salesVoidedReason(String reason) {
    return 'Voided: $reason';
  }

  @override
  String get salesParticipants => 'People';

  @override
  String get salesSeller => 'Sales assistant';

  @override
  String get salesNoCustomer => 'no customer';

  @override
  String get salesPromoCode => 'Promo code';

  @override
  String salesItemsSection(String count) {
    return 'Items ($count)';
  }

  @override
  String get salesSubtotal => 'Subtotal';

  @override
  String get salesVatIncluded => 'incl. VAT';

  @override
  String get salesBonusEarned => 'Bonuses earned';

  @override
  String get salesRefunded => 'Refunded';

  @override
  String get salesReceiptTextCopied => 'Receipt text copied';

  @override
  String get salesCopy => 'Copy';

  @override
  String salesVoidPromptTitle(String number) {
    return 'Void receipt No. $number';
  }

  @override
  String get salesReasonRequiredLabel => 'Reason *';

  @override
  String get salesVoidConfirmTitle => 'Void the receipt?';

  @override
  String salesVoidConfirmMessage(String number, String amount) {
    return 'Receipt No. $number for $amount will be cancelled in full: goods go back to stock, payments are refunded by the original methods. This cannot be undone.';
  }

  @override
  String salesVoidDone(String number) {
    return 'Receipt No. $number voided';
  }

  @override
  String salesReturnDoneTitle(String number) {
    return 'Return No. $number processed';
  }

  @override
  String get salesNotRestockedHint =>
      'The goods were not returned to stock. If this is a warranty defect, file a warranty claim.';

  @override
  String get salesWarrantyClaim => 'Warranty claim';

  @override
  String get salesReturnSlip => 'Return slip';

  @override
  String salesItemDiscount(String amount) {
    return 'discount $amount';
  }

  @override
  String salesItemWarranty(String date) {
    return 'warranty until $date';
  }

  @override
  String salesReturnHeader(String number, String date) {
    return 'Return No. $number · $date';
  }

  @override
  String get salesToStock => 'to stock';

  @override
  String get salesNoRestock => 'not restocked';

  @override
  String salesReasonValue(String reason) {
    return 'Reason: $reason';
  }

  @override
  String salesReceiptNoNotFound(String number) {
    return 'Receipt No. $number not found';
  }

  @override
  String get salesTitle => 'Receipts';

  @override
  String get salesSubtitle => 'Sales history and returns';

  @override
  String get salesTabReturns => 'Returns';

  @override
  String get salesNoShiftReceipts =>
      'No shift is open. You only see receipts of the current shift.';

  @override
  String salesShiftReceipts(String number) {
    return 'Showing receipts of the current shift No. $number';
  }

  @override
  String get salesSelectReceipt => 'Select a receipt';

  @override
  String get salesSelectReceiptHint =>
      'Receipt items, payments, returns and actions will appear here';

  @override
  String get salesNoReceipts => 'No receipts found';

  @override
  String get salesNoReceiptsFiltered =>
      'Change the search or reset the filters';

  @override
  String get salesNoSalesInShift => 'No sales in the current shift yet';

  @override
  String get salesNoSalesInPeriod => 'No sales in the selected period';

  @override
  String get salesResetFilters => 'Reset filters';

  @override
  String get salesShowAllTime => 'Show all time';

  @override
  String get salesShowMore => 'Show more';

  @override
  String get salesSearchHint => 'Receipt number, customer or item';

  @override
  String get salesAnyFem => 'Any';

  @override
  String get salesReceiptsLabel => 'Receipts';

  @override
  String get salesSalesLabel => 'Sales';

  @override
  String get salesVoidedLabel => 'Voided';

  @override
  String salesPositionsShort(String n) {
    return 'Items: $n';
  }

  @override
  String get salesNoReturns => 'No returns';

  @override
  String get salesChangeSearch => 'Change the search';

  @override
  String get salesNoReturnsHint =>
      'Returns are processed from the receipt card on the “Receipts” tab';

  @override
  String salesReturnTitle(String number, String sale) {
    return 'Return No. $number · receipt No. $sale';
  }

  @override
  String get salesReturnsSearchHint => 'Number, customer or reason';

  @override
  String get salesMethodLabel => 'Method';

  @override
  String get salesAnyMasc => 'Any';

  @override
  String get salesNoShiftReturns =>
      'No shift is open. You only see returns of the current shift.';

  @override
  String salesShiftReturns(String number) {
    return 'Showing returns of the current shift No. $number';
  }

  @override
  String get salesReturnsCountLabel => 'Returns';

  @override
  String get salesSumLabel => 'Amount';

  @override
  String get salesSelectReturn => 'Select a return';

  @override
  String get salesSelectReturnHint =>
      'The receipt, returned items and the printable slip will appear here';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNoAccess => 'No access';

  @override
  String get settingsNoAccessMessage =>
      'Only the owner or an administrator can change settings.';

  @override
  String get settingsSecStore => 'Store';

  @override
  String get settingsSecStoreHint => 'Name, details, receipt';

  @override
  String get settingsSecCurrency => 'Currency and taxes';

  @override
  String get settingsSecCurrencyHint => 'Base currency, VAT';

  @override
  String get settingsSecSales => 'Sales';

  @override
  String get settingsSecSalesHint => 'Shifts, returns, payment';

  @override
  String get settingsSecLoyalty => 'Loyalty';

  @override
  String get settingsSecLoyaltyHint => 'Bonus program';

  @override
  String get settingsSecDevices => 'Registers and devices';

  @override
  String get settingsSecDevicesHint => 'Registers, printer, scanner';

  @override
  String get settingsSecAppearance => 'Appearance';

  @override
  String get settingsSecAppearanceHint => 'Light and dark theme';

  @override
  String get settingsSecBackup => 'Backup';

  @override
  String get settingsSecBackupHint => 'Copies and restore';

  @override
  String get settingsSecData => 'Data';

  @override
  String get settingsSecDataHint => 'Demo mode, export';

  @override
  String get settingsSecAbout => 'About';

  @override
  String get settingsSecAboutHint => 'Version, license, help';

  @override
  String get settingsDiscardTitle => 'Discard changes?';

  @override
  String get settingsDiscardMessage =>
      'This section has unsaved changes. If you leave, they will be lost.';

  @override
  String get settingsDiscardOk => 'Don’t save';

  @override
  String get settingsUnsavedBar => 'Unsaved changes (Ctrl+S to save)';

  @override
  String get settingsCancelVerb => 'Cancel';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String settingsSwitchOn(String title) {
    return '“$title” turned on';
  }

  @override
  String settingsSwitchOff(String title) {
    return '“$title” turned off';
  }

  @override
  String get settingsCopied => 'Copied';

  @override
  String settingsErrPercentRange(String min, String max) {
    return 'Enter a value from $min to $max';
  }

  @override
  String get settingsErrPercentNumber => 'Enter a number, e.g. 2 or 2.5';

  @override
  String settingsErrPercentAllowed(String min, String max) {
    return 'Allowed from $min to $max %';
  }

  @override
  String get settingsErrTwoDecimals => 'No more than two decimal places';

  @override
  String get settingsErrReturnDaysEmpty =>
      'Enter the number of days (0 = no limit)';

  @override
  String get settingsErrReturnDaysInt => 'Enter a whole number of days';

  @override
  String get settingsErrNotNegative => 'Cannot be negative';

  @override
  String get settingsErrReturnDaysMax => 'No more than 3650 days (10 years)';

  @override
  String get settingsErrStoreNameRequired =>
      'Store name is required: it is printed on the receipt';

  @override
  String settingsErrMaxLength(String max) {
    return 'No more than $max characters';
  }

  @override
  String get settingsErrPhoneChars =>
      'Only digits, spaces, +, - and parentheses';

  @override
  String get settingsErrPhoneDigits => 'Check the number: 5 to 15 digits';

  @override
  String get settingsErrTaxIdDigits => 'TIN must contain digits only';

  @override
  String get settingsErrTaxIdLength => 'TIN must have 9 to 14 digits';

  @override
  String get settingsErrFooterLines => 'No more than 6 lines';

  @override
  String settingsErrBanknoteNotNumber(String value) {
    return '“$value” is not a number. Use a dot for decimals';
  }

  @override
  String settingsErrBanknoteNoFraction(String value, String code) {
    return '“$value”: $code has no fractional units';
  }

  @override
  String settingsErrBanknoteTooManyDecimals(String value) {
    return '“$value”: too many decimal places';
  }

  @override
  String settingsErrBanknotePositive(String value) {
    return '“$value”: the denomination must be greater than zero';
  }

  @override
  String settingsErrBanknoteTooBig(String value) {
    return '“$value”: the denomination is too large';
  }

  @override
  String settingsErrBanknoteDuplicate(String value) {
    return 'Denomination “$value” is listed twice';
  }

  @override
  String settingsErrBanknotesMax(String max) {
    return 'No more than $max denominations: the buttons must fit on screen';
  }

  @override
  String get settingsErrRegisterNameEmpty => 'Enter a register name';

  @override
  String get settingsErrRegisterDuplicate =>
      'A register with this name already exists';

  @override
  String get settingsCurrencyLocked =>
      'The currency cannot be changed: the database already has sales';

  @override
  String get settingsRegisterBusy =>
      'A shift is open on this register. Close the shift first, then disable or delete the register.';

  @override
  String get settingsRoundingNone => 'No rounding';

  @override
  String settingsRoundingStep(String amount) {
    return 'Multiples of $amount';
  }

  @override
  String settingsLoyaltyExample(
    String purchase,
    String earned,
    String symbol,
    String percent,
    String redeem,
  ) {
    return 'A purchase of $purchase earns $earned bonuses (1 bonus = 1 $symbol). Bonuses can cover up to $percent% of a receipt, max $redeem.';
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
  String get settingsSampleCashier => 'Sample';

  @override
  String get settingsSampleItemMilk => 'Milk 2.5% 1 L';

  @override
  String get settingsSampleItemBread => 'White bread';

  @override
  String get settingsSampleItemTea => 'Black tea 100 g';

  @override
  String settingsDiagPlatform(String value) {
    return 'Platform: $value';
  }

  @override
  String settingsDiagStore(String value) {
    return 'Store: $value';
  }

  @override
  String settingsCurrencyValue(String value) {
    return 'Currency: $value';
  }

  @override
  String settingsDiagDemo(String value) {
    return 'Demo mode: $value';
  }

  @override
  String get settingsYesLower => 'yes';

  @override
  String get settingsNoLower => 'no';

  @override
  String settingsDiagDbSize(String value) {
    return 'Database size: $value';
  }

  @override
  String settingsDiagProducts(String value) {
    return 'Products: $value';
  }

  @override
  String settingsDiagSales(String value) {
    return 'Sales: $value';
  }

  @override
  String settingsDiagCustomers(String value) {
    return 'Customers: $value';
  }

  @override
  String settingsDiagUsers(String value) {
    return 'Employees: $value';
  }

  @override
  String settingsDiagLastBackup(String value) {
    return 'Last backup: $value';
  }

  @override
  String settingsDiagGenerated(String value) {
    return 'Generated: $value';
  }

  @override
  String get settingsErrBackupFailed => 'Could not create a backup';

  @override
  String settingsErrNotBackup(String name) {
    return 'File “$name” is not a DreamPOS backup';
  }

  @override
  String get settingsCsvName => 'Name';

  @override
  String get settingsCsvMinStock => 'Min. stock';

  @override
  String get settingsCsvVatPercent => 'VAT %';

  @override
  String get settingsCsvActive => 'Active';

  @override
  String get settingsCsvCard => 'Card';

  @override
  String get settingsCsvDiscountPercent => 'Discount %';

  @override
  String get settingsCsvDebtLimit => 'Debt limit';

  @override
  String get settingsCsvTotalSpent => 'Total spent';

  @override
  String get settingsCsvVisits => 'Visits';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutTagline =>
      'Point of sale and accounting for retail stores. Works offline.';

  @override
  String get settingsLicense => 'License';

  @override
  String get settingsPlan => 'Plan: “Store” (1 location)';

  @override
  String get settingsTrialExpired => 'Trial expired';

  @override
  String get settingsTrial => 'Trial';

  @override
  String get settingsTrialEnded =>
      'The trial has ended. Contact support to extend it; your data is kept.';

  @override
  String settingsTrialLeft(int count, String total, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left of $total · installed $date',
      one: '$count day left of $total · installed $date',
    );
    return '$_temp0';
  }

  @override
  String get settingsSupport => 'Contact support';

  @override
  String get settingsSupportHint =>
      'When contacting support, attach the details below: they help us sort things out faster. They contain no personal customer data.';

  @override
  String get settingsInfoCopied => 'Details copied';

  @override
  String get settingsCopyInfo => 'Copy details';

  @override
  String get settingsRefresh => 'Refresh';

  @override
  String get settingsAppearanceDesc =>
      'The theme applies at once to every screen of this app.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeHint =>
      '“Auto” follows the Windows/Android setting. The dark theme is easier on the eyes during evening shifts and saves battery on phones with OLED screens. The light theme reads better in a brightly lit sales floor.';

  @override
  String settingsBackupCreated(String name, String size) {
    return 'Backup created: $name ($size)';
  }

  @override
  String get settingsBackupDeleteTitle => 'Delete backup?';

  @override
  String settingsBackupDeleteMessage(String name, String date, String size) {
    return '$name\n$date · $size\n\nThe file will be permanently deleted from disk.';
  }

  @override
  String get settingsBackupDeleted => 'Backup deleted';

  @override
  String get settingsRestoreTitle => 'Restore data from backup?';

  @override
  String settingsRestoreMessage(String date) {
    return 'The backup from $date will replace ALL current data: products, sales, customers, shifts and settings. Everything done after that date will be lost.\n\nA backup of the current data is created automatically before restoring.\n\nThe data is replaced the next time the app starts.';
  }

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsRestartTitle => 'Restart the app';

  @override
  String get settingsRestartMessage =>
      'Restore is ready.\n\n1. Close DreamPOS on this computer.\n2. Start the app again: the data will be replaced with the backup.\n3. Sign in and check the products and latest sales.\n\nDo not make sales before restarting: they will be lost.';

  @override
  String get settingsGotIt => 'Got it';

  @override
  String get settingsRestoreCancelled => 'Restore cancelled';

  @override
  String get settingsBackupDesc =>
      'A database backup protects against data loss from a broken computer, a virus or a mistake. Also keep copies on a USB stick or in the cloud.';

  @override
  String get settingsRestorePending =>
      'Restore from backup is ready. Restart the app to replace the data.';

  @override
  String get settingsLastBackup => 'Last backup';

  @override
  String get settingsNeverBackedUp => 'never';

  @override
  String get settingsBackupWeekly =>
      'We recommend backing up at least once a week';

  @override
  String get settingsBackupCreateNow => 'Back up now';

  @override
  String get settingsAutoBackup => 'Daily automatic backup';

  @override
  String get settingsAutoBackupHint => 'Created once a day when the app starts';

  @override
  String get settingsBackupFolder => 'Backup folder';

  @override
  String get settingsCopyPath => 'Copy path';

  @override
  String get settingsPathCopied => 'Path copied';

  @override
  String get settingsBackups => 'Backups';

  @override
  String get settingsNoBackups => 'No backups yet. Tap “Back up now”.';

  @override
  String get settingsRestoreInfo =>
      'Restoring replaces all app data with the backup contents and requires a restart. A backup of the current data is created automatically first.';

  @override
  String get settingsCurUzs => 'Uzbek som';

  @override
  String get settingsCurTjs => 'Tajik somoni';

  @override
  String get settingsCurKzt => 'Kazakhstani tenge';

  @override
  String get settingsCurKgs => 'Kyrgyz som';

  @override
  String get settingsCurRub => 'Russian ruble';

  @override
  String get settingsCurUsd => 'US dollar';

  @override
  String settingsCurChangeTitle(String code) {
    return 'Change currency to $code?';
  }

  @override
  String settingsCurChangeSymbol(String symbol) {
    return 'All amounts will be shown in “$symbol”.';
  }

  @override
  String settingsCurChangeRescale(String products, String from, String to) {
    return 'Warning: you already have $products products. Prices are stored in minor units, so a price of $from will become $to. Check and fix prices after changing the currency.';
  }

  @override
  String get settingsCurChangeResetsCash =>
      'Quick cash banknotes and cash rounding will be reset to the defaults for the new currency (Sales section).';

  @override
  String get settingsCurChangeFinal =>
      'After the first sale the currency can no longer be changed.';

  @override
  String get settingsCurChangeOk => 'Change currency';

  @override
  String get settingsCurrencyDesc =>
      'The currency used for accounting and the default VAT rate for new products.';

  @override
  String get settingsCurBase => 'Base currency';

  @override
  String get settingsCurLockedTooltip =>
      'Currency is locked after the first sale';

  @override
  String get settingsCurLockedBanner =>
      'Currency is locked: the database already has sales. All amounts in receipts, reports, debts and bonuses are stored in this currency; changing it would corrupt the whole history.';

  @override
  String settingsCurCheckFailed(String error) {
    return 'Could not check for sales: $error';
  }

  @override
  String settingsCurExampleCents(String amount) {
    return 'Example: $amount · with decimals';
  }

  @override
  String settingsCurExampleNoCents(String amount) {
    return 'Example: $amount · no decimals';
  }

  @override
  String get settingsVatDefault => 'Default VAT for new products';

  @override
  String get settingsVatHelper => '0 if the store does not pay VAT';

  @override
  String get settingsVatInfo =>
      'Product prices include VAT. The VAT amount is taken out of the price at the product rate and printed on the receipt as “incl. VAT”. The rate can be changed in the product card.';

  @override
  String settingsFileSaved(String path) {
    return 'File saved: $path';
  }

  @override
  String get settingsDataDesc =>
      'Demo mode and export of reference data to Excel files.';

  @override
  String get settingsMode => 'Mode';

  @override
  String get settingsDemoMode => 'Demo mode';

  @override
  String get settingsLiveDb => 'Live database';

  @override
  String get settingsDemoText =>
      'The database now holds demo products, customers and sales. They help you get to know the app. Do not mix them with real trading.';

  @override
  String get settingsLiveText => 'The app works with real store data.';

  @override
  String get settingsDemoWarning =>
      'Demo data cannot be deleted with a button: it is irreversible and would affect reports, stock and the log. To start with a clean database:';

  @override
  String get settingsDemoStep1 =>
      'Create a backup (Backup section) in case you need the demo data again.';

  @override
  String get settingsDemoStep2 => 'Close the app.';

  @override
  String get settingsDemoStep3 =>
      'Delete the database file and, if present, the files next to it whose names end in “wal” or “shm”.';

  @override
  String settingsDbFile(String path) {
    return 'Database file: $path';
  }

  @override
  String get settingsDemoStep4 =>
      'Start DreamPOS: the setup wizard opens. Do not tick “Fill with demo data”.';

  @override
  String get settingsCopyDbPath => 'Copy database path';

  @override
  String get settingsExportProductsHint => 'Name, barcode, prices, stock';

  @override
  String get settingsExportCustomersHint =>
      'Contacts, discounts, bonuses and debts';

  @override
  String get settingsExportInfo =>
      'Files are saved to “Documents/DreamPOS/exports” as CSV (separator “;”, UTF-8 encoding) and open in Excel and Google Sheets. The customer file contains phone numbers and debts: do not share it with outsiders.';

  @override
  String get settingsLastFile => 'Last file';

  @override
  String get settingsDevicesDesc =>
      'Store registers, binding this computer to a register, scanner and receipt printer.';

  @override
  String settingsRegisterAdded(String name) {
    return 'Register “$name” added';
  }

  @override
  String get settingsRegisterSaved => 'Register saved';

  @override
  String settingsRegisterDeleteTitle(String name) {
    return 'Delete register “$name”?';
  }

  @override
  String get settingsRegisterDeleteMessage =>
      'The register will disappear from the list. Its receipts and reports are kept.';

  @override
  String get settingsRegisterDeleted => 'Register deleted';

  @override
  String get settingsRegisters => 'Registers';

  @override
  String get settingsNoRegisters =>
      'No registers yet. Add a register if the store has several checkouts: reports will then show where each receipt was rung up.';

  @override
  String get settingsRegisterDisabled => 'Disabled';

  @override
  String get settingsThisDevice => 'This computer';

  @override
  String settingsRegisterDefaultName(String number) {
    return 'Register $number';
  }

  @override
  String get settingsNewRegister => 'New register';

  @override
  String get settingsRegister => 'Register';

  @override
  String get settingsRegisterNameHint => 'Register 1, Warehouse, Dept. No. 2';

  @override
  String get settingsRegisterActive => 'Active';

  @override
  String get settingsRegisterActiveHint =>
      'A disabled register cannot be selected for work';

  @override
  String get settingsThisDeviceHint =>
      'Choose which register this device works as. The setting is stored only on this computer and is not copied to others.';

  @override
  String get settingsAddRegisterFirst =>
      'Add at least one active register first.';

  @override
  String get settingsDeviceRegister => 'This device’s register';

  @override
  String get settingsNotSelected => 'Not selected';

  @override
  String get settingsDeviceRegisterSet => 'Register selected for this device';

  @override
  String get settingsDeviceRegisterGone =>
      'The previously selected register was deleted or disabled. Choose another one.';

  @override
  String get settingsTestPrintTitle => 'TEST PRINT';

  @override
  String get settingsNotFiscal => 'Not a fiscal document';

  @override
  String get settingsTestReceiptJob => 'Test receipt';

  @override
  String get settingsPrinter => 'Receipt printer';

  @override
  String settingsPrinterHint(String width) {
    return 'Receipts print through the system print dialog. Install the printer driver and make it the default printer. Current paper width: $width mm (changed in the Store section).';
  }

  @override
  String get settingsPrintTest => 'Print test receipt';

  @override
  String get settingsScanner => 'Barcode scanner';

  @override
  String get settingsScannerTip1 =>
      'Plug in a USB scanner: it works like a keyboard and usually needs no driver.';

  @override
  String get settingsScannerTip2 =>
      'The scanner must send Enter after the code (CR suffix). Most models are set up this way.';

  @override
  String get settingsScannerTip3 =>
      'Keyboard layout: if other characters appear instead of digits, switch the layout to EN or set the scanner to “numeric” mode.';

  @override
  String get settingsScannerTip4 =>
      'Test: open product search and scan a barcode; the whole code should appear.';

  @override
  String get settingsScannerTip5 =>
      'Wireless scanners work the same way; keep the base within 10 m of the register.';

  @override
  String get settingsLoyaltyDesc =>
      'Bonus program: customers earn bonuses on purchases and use them to pay part of later purchases. 1 bonus = 1 unit of currency.';

  @override
  String get settingsLoyaltyEnabled => 'Bonus program enabled';

  @override
  String get settingsLoyaltyEnabledHint =>
      'Only customers selected on the receipt earn bonuses';

  @override
  String get settingsRules => 'Rules';

  @override
  String get settingsLoyaltyOff =>
      'The program is off: bonuses are neither earned nor spent. Customers’ accumulated balances are kept.';

  @override
  String get settingsEarnLabel => 'Earn per purchase';

  @override
  String get settingsPercentRangeHelper => 'From 0 to 100';

  @override
  String get settingsRedeemLabel => 'Pay with bonuses, max';

  @override
  String get settingsRedeemSuffix => '% of receipt';

  @override
  String get settingsLoyaltyEnterPercents =>
      'Enter percentages from 0 to 100 to see an example.';

  @override
  String get settingsLoyaltyReturnInfo =>
      'When goods are returned, the bonuses earned on them are deducted proportionally. New percentages apply to future sales; past receipts are not recalculated.';

  @override
  String get settingsShiftOffTitle => 'Allow sales without a shift?';

  @override
  String get settingsShiftOffMessage =>
      'Not recommended. Without an open shift:\n• there is no cash control or Z report;\n• sales belong to no shift, so discrepancies cannot be traced;\n• cashiers can sell without counting the float.\n\nTurn this off only if the register does not accept cash.';

  @override
  String get settingsShiftOffOk => 'Turn off anyway';

  @override
  String get settingsNegativeTitle => 'Allow selling at zero stock?';

  @override
  String get settingsNegativeMessage =>
      'Stock may go negative. This is handy if goods receipts are entered after sales, but it hides mix-ups and shortages. Negative stock must be fixed regularly with goods receipts or stocktakes.';

  @override
  String get settingsAllow => 'Allow';

  @override
  String get settingsSalesDesc =>
      'Rules the register checks on every sale and return.';

  @override
  String get settingsControl => 'Control';

  @override
  String get settingsRequireShift => 'Sell only during an open shift';

  @override
  String get settingsRequireShiftHint =>
      'Recommended: cash control and a Z report for every shift';

  @override
  String get settingsAllowNegative => 'Allow selling at zero stock';

  @override
  String get settingsAllowNegativeHint =>
      'Stock can go negative (for all products)';

  @override
  String get settingsDebtLimit => 'Credit only for customers with a limit';

  @override
  String get settingsDebtLimitHint =>
      'Selling on credit to a customer without a set limit is blocked';

  @override
  String get settingsReturns => 'Returns';

  @override
  String get settingsReturnDays => 'Return period, days';

  @override
  String get settingsDaysSuffix => 'days';

  @override
  String get settingsReturnNoLimit => 'No time limit';

  @override
  String settingsReturnWithin(String days) {
    return 'Returns by receipt are possible within $days days. 0 = no limit';
  }

  @override
  String get settingsQuickCash => 'Quick cash payment';

  @override
  String get settingsBanknotesLabel => 'Banknotes on the payment screen';

  @override
  String settingsBanknotesHelper(String max) {
    return 'Comma-separated, up to $max. Empty = default set';
  }

  @override
  String get settingsPosButtons => 'Buttons at the register:';

  @override
  String get settingsCashRounding => 'Cash rounding';

  @override
  String get settingsRoundingLabel => 'Round the total for cash payments';

  @override
  String settingsRoundingChanged(String value) {
    return 'Rounding: $value';
  }

  @override
  String get settingsRoundingOff => 'The cash total is not rounded.';

  @override
  String settingsRoundingExample(String from, String to) {
    return 'Example: $from → $to. Rounded down, in the customer’s favor, for cash payments only.';
  }

  @override
  String get settingsStoreName => 'Store name *';

  @override
  String get settingsStoreNameHelper =>
      'Shown in the receipt header and on the sign-in screen';

  @override
  String get settingsAddressHint => '12 Navoi St, Tashkent';

  @override
  String get settingsTaxId => 'TIN / BIN';

  @override
  String get settingsTaxIdHelper => 'Digits only, 9–14 characters';

  @override
  String get settingsFooter => 'Receipt footer';

  @override
  String get settingsFooterHint =>
      'Thank you for your purchase!\nExchange and return within 14 days';

  @override
  String get settingsPaperWidth => 'Paper width';

  @override
  String get settingsPaperWidthHint =>
      'See the printer manual: 58 mm is compact, 80 mm is standard';

  @override
  String settingsMm(String width) {
    return '$width mm';
  }

  @override
  String get settingsAutoPrint => 'Print receipt automatically';

  @override
  String get settingsAutoPrintHint =>
      'Right after payment, without asking the cashier';

  @override
  String get settingsStoreDesc =>
      'Store details and receipt layout. Changes show up in the sample receipt at once.';

  @override
  String get settingsReceiptSample => 'Sample receipt';

  @override
  String get shiftClosingTitle => 'Close shift';

  @override
  String get shiftClosed => 'Shift closed';

  @override
  String get shiftCloseConfirmTitle => 'Close the shift?';

  @override
  String shiftCountedValue(String amount) {
    return 'Counted: $amount';
  }

  @override
  String shiftExpectedValue(String amount) {
    return 'Expected: $amount';
  }

  @override
  String get shiftShortage => 'Shortage';

  @override
  String get shiftSurplus => 'Surplus';

  @override
  String shiftCollectionAtCloseValue(String amount) {
    return 'Collection at close: $amount';
  }

  @override
  String get shiftCloseConfirmMessage =>
      'After closing, sales are unavailable until a new shift is opened.';

  @override
  String get shiftCloseAction => 'Close shift';

  @override
  String get shiftCountCashHint => 'Count the cash in the drawer.';

  @override
  String get shiftByDenomination => 'By denomination';

  @override
  String get shiftByTotal => 'Total';

  @override
  String get shiftCashInDrawer => 'Cash in drawer';

  @override
  String get shiftExpectedInDrawer => 'Expected in drawer';

  @override
  String get shiftInclGiftCash => 'incl. gift cards (cash)';

  @override
  String get shiftCounted => 'Counted';

  @override
  String get shiftDifference => 'Difference';

  @override
  String get shiftDiffReasonLabel => 'Reason for difference *';

  @override
  String get shiftNoteOptional => 'Note (optional)';

  @override
  String get shiftCollectionAtClose => 'Collection at close';

  @override
  String shiftCollectionSummary(String collect, String leave) {
    return 'Hand over $collect, leave $leave as float';
  }

  @override
  String get shiftCollectionHint =>
      'Hand over part of the takings and leave a float for the next shift';

  @override
  String get shiftCollectionAmount => 'Collection amount';

  @override
  String get shiftCollectAll => 'Hand over all';

  @override
  String get shiftNoDifference => 'no difference';

  @override
  String get shiftShortageLower => 'shortage';

  @override
  String get shiftSurplusLower => 'surplus';

  @override
  String shiftOpenedToast(String amount) {
    return 'Shift opened. Float: $amount';
  }

  @override
  String get shiftOpenHint =>
      'To start selling, open a shift and enter the float in the drawer.';

  @override
  String get shiftOpeningCash => 'Opening float';

  @override
  String get shiftOpeningSuggested =>
      'Suggested: what was left after the last shift';

  @override
  String get shiftOpeningCashNow => 'Cash in the drawer now';

  @override
  String get shiftNoRightOpen => 'No permission to open a shift';

  @override
  String get shiftOpenAction => 'Open shift';

  @override
  String get shiftSales => 'Sales';

  @override
  String shiftSalesHint(String receipts, String avg) {
    return '$receipts · avg $avg';
  }

  @override
  String get shiftReturns => 'Returns';

  @override
  String get shiftNoReturns => 'No returns';

  @override
  String get shiftGrossProfit => 'Gross profit';

  @override
  String get shiftNetRevenue => 'Revenue net of returns';

  @override
  String shiftRevenueValue(String amount) {
    return 'Revenue $amount';
  }

  @override
  String shiftExpectedHint(String amount) {
    return 'Cash · float $amount';
  }

  @override
  String get shiftXReport => 'X report';

  @override
  String get shiftZReport => 'Z report';

  @override
  String shiftNumber(String number) {
    return 'Shift No. $number';
  }

  @override
  String get shiftStatusOpen => 'Open';

  @override
  String shiftOpenedAt(String date) {
    return 'Opened $date';
  }

  @override
  String get shiftJustNow => 'just now';

  @override
  String shiftRunning(String duration) {
    return 'running $duration';
  }

  @override
  String shiftHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String shiftMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get shiftCloseTooltip =>
      'Count the drawer and close the shift (Z report)';

  @override
  String get shiftNoRightClose => 'No permission to close the shift';

  @override
  String get shiftCashOperations => 'Cash operations';

  @override
  String get shiftNoRightCash => 'No permission for cash operations';

  @override
  String get shiftOperationsList => 'Shift operations';

  @override
  String get shiftNoOperations => 'No pay-ins or pay-outs yet';

  @override
  String shiftNumberOpen(String number) {
    return 'Shift No. $number open';
  }

  @override
  String get shiftTabCurrent => 'Current shift';

  @override
  String get shiftTabHistory => 'Shift history';

  @override
  String get shiftOnlyMine => 'My shifts only';

  @override
  String get shiftHistoryEmptyTitle => 'No shifts yet';

  @override
  String get shiftHistoryEmptyMessage =>
      'Closed shifts and their Z reports will appear here';

  @override
  String get shiftPickShift => 'Select a shift';

  @override
  String get shiftPickShiftMessage => 'Its printable report will appear here';

  @override
  String get shiftNow => 'now';

  @override
  String get shiftEnterCountedCash => 'Enter the cash amount in the drawer';

  @override
  String get shiftAmountNegative => 'Amount cannot be negative';

  @override
  String get shiftCollectionNegative => 'Collection amount cannot be negative';

  @override
  String get shiftCollectionTooBig =>
      'Collection cannot exceed the counted amount';

  @override
  String get shiftEnterDiffReason => 'Enter the reason for the difference';

  @override
  String get shiftKindPayIn => 'Pay-in';

  @override
  String get shiftKindPayOut => 'Pay-out';

  @override
  String get shiftKindExpense => 'Expense';

  @override
  String get shiftKindCollection => 'Collection';

  @override
  String get shiftExpRent => 'Rent';

  @override
  String get shiftExpSalary => 'Salaries';

  @override
  String get shiftExpSupplies => 'Supplies';

  @override
  String get shiftExpTransport => 'Transport';

  @override
  String get shiftExpUtilities => 'Utilities';

  @override
  String get shiftExpOther => 'Other';

  @override
  String get shiftKindPayInHint => 'Float top-up, returned advances, etc.';

  @override
  String get shiftKindPayOutHint =>
      'Cash out of the drawer (advance, petty cash)';

  @override
  String get shiftKindExpenseHint => 'Paying store expenses from the drawer';

  @override
  String get shiftKindCollectionHint => 'Handing takings to the owner / bank';

  @override
  String get shiftPickExpenseCategory => 'Choose an expense category';

  @override
  String shiftCashInDrawerNow(String amount) {
    return 'In drawer now: $amount';
  }

  @override
  String get shiftEnterAmount => 'Enter an amount';

  @override
  String shiftOnlyInDrawer(String amount) {
    return 'Only $amount in the drawer';
  }

  @override
  String get shiftExpenseCategory => 'Expense category';

  @override
  String get shiftReasonRequired => 'Reason / comment *';

  @override
  String get shiftPayOutHint => 'Who received the money and why';

  @override
  String get shiftEnterReason => 'Enter a reason';

  @override
  String get shiftSaving => 'Saving…';

  @override
  String get shiftPost => 'Post';

  @override
  String get shiftZShiftNo => 'Shift No.';

  @override
  String get shiftZOpened => 'Opened';

  @override
  String get shiftZClosed => 'Closed';

  @override
  String get shiftZReceipts => 'Receipts';

  @override
  String get shiftZSalesTotal => 'Sales total';

  @override
  String shiftZIncl(String method) {
    return 'incl. $method';
  }

  @override
  String get shiftZDiscounts => 'Discounts';

  @override
  String get shiftZAvgCheck => 'Avg. sale';

  @override
  String get shiftZVoidedReceipts => 'Voided receipts';

  @override
  String get shiftZReturnsCount => 'Returns';

  @override
  String get shiftZReturnsTotal => 'Returns total';

  @override
  String get shiftZGiftCards => 'Gift cards';

  @override
  String get shiftZSold => 'Sold';

  @override
  String get shiftZGiftSalesTotal => 'Sales total (advance)';

  @override
  String get shiftZVoided => 'Voided';

  @override
  String get shiftZRefundedToBuyers => 'Refunded to buyers';

  @override
  String get shiftZCashImpact => 'Effect on drawer (cash)';

  @override
  String get shiftZAdvanceNote => 'advance, not included in revenue';

  @override
  String get shiftZSummary => 'Summary';

  @override
  String get shiftZNetRevenue => 'Revenue (net of returns)';

  @override
  String get shiftZCash => 'Drawer (cash)';

  @override
  String get shiftZOpeningCash => 'Opening float';

  @override
  String get shiftZCashSales => 'Cash sales';

  @override
  String get shiftZCashRefunds => 'Cash refunds';

  @override
  String get shiftZDebtCash => 'Debt payments (cash)';

  @override
  String get shiftZDebtNonCash => 'Debt payments (non-cash)';

  @override
  String get shiftZSupplierPaid => 'Supplier payments';

  @override
  String get shiftZGiftCash => 'Gift cards (cash, advance)';

  @override
  String get shiftZActual => 'Actual';

  @override
  String shiftZPrinted(String date) {
    return 'Printed: $date';
  }

  @override
  String get shiftZCashierSign => 'Cashier';

  @override
  String get shiftZReceivedSign => 'Received by';

  @override
  String shiftZTitleA4(String title, String number) {
    return '$title — shift No. $number';
  }

  @override
  String shiftZGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String shiftZFileName(String title, String number) {
    return '$title shift $number';
  }

  @override
  String get shiftPrintUnavailable => 'Printing is unavailable';

  @override
  String get shiftRoll80 => '80 mm receipt roll';

  @override
  String get shiftSheetA4 => 'A4 sheet';

  @override
  String shiftReportHeader(String title, String number) {
    return '$title · shift No. $number';
  }

  @override
  String get shiftReportTitle => 'Shift report';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffNoAccess => 'No access';

  @override
  String get staffNoAccessHint =>
      'Available to the owner and administrator only';

  @override
  String get staffTabTime => 'Work time';

  @override
  String get staffTabMotivation => 'Incentives';

  @override
  String get staffTabRoles => 'Roles and permissions';

  @override
  String get staffTabAudit => 'Activity log';

  @override
  String get staffRolesHint =>
      'Role permissions are set by the system. To change an employee’s access, change their role.';

  @override
  String get staffPermColumn => 'Permission';

  @override
  String get staffErrLastOwner =>
      'This is the only active owner. Assign another owner first';

  @override
  String get staffErrNameTooLong => 'Name is too long';

  @override
  String get staffErrSetPin => 'Set a PIN';

  @override
  String get staffErrMaxDiscountRange => 'Max. discount must be 0–100%';

  @override
  String get staffErrCommissionRange => 'Commission must be 0–100%';

  @override
  String get staffErrPlanNegative => 'Target cannot be negative';

  @override
  String get staffErrPhoneFormat => 'Invalid phone format';

  @override
  String get staffErrOwnerRoleOnlyOwner =>
      'Only the owner can assign the “Owner” role';

  @override
  String get staffErrOwnerEditOnlyOwner =>
      'Only the owner can edit the owner’s details';

  @override
  String get staffErrCannotDeactivateSelf =>
      'You cannot deactivate your own account';

  @override
  String get staffErrActivateNeedsPin =>
      'Set a new PIN to activate the employee';

  @override
  String staffDurationMin(String m) {
    return '$m min';
  }

  @override
  String staffDurationHm(String h, String m) {
    return '$h h $m min';
  }

  @override
  String staffErrAlreadyClockedIn(String time) {
    return 'Already clocked in at $time';
  }

  @override
  String get staffErrClockInFirst => 'Clock in first';

  @override
  String get staffErrEndBeforeStart =>
      'Clock-out time must be after clock-in time';

  @override
  String get staffErrStartInFuture => 'Clock-in time cannot be in the future';

  @override
  String get staffErrEndInFuture => 'Clock-out time cannot be in the future';

  @override
  String get staffErrTooLong => 'A shift cannot last more than 24 hours';

  @override
  String staffErrOverlap(String from, String to) {
    return 'Overlaps another entry ($from — $to)';
  }

  @override
  String get staffNow => 'now';

  @override
  String get staffErrOpenExists => 'The employee already has an open entry';

  @override
  String get staffPermSell => 'Selling (register)';

  @override
  String get staffPermApplyDiscount => 'Manual discounts';

  @override
  String get staffPermVoidSale => 'Voiding receipts';

  @override
  String get staffPermRefund => 'Returns';

  @override
  String get staffPermOpenCloseShift => 'Open/close shift';

  @override
  String get staffPermCashInOut => 'Cash in/out';

  @override
  String get staffPermViewProducts => 'View products';

  @override
  String get staffPermEditProducts => 'Edit products';

  @override
  String get staffPermEditPrices => 'Change prices';

  @override
  String get staffPermViewCost => 'Cost and profit';

  @override
  String get staffPermStockOps => 'Stock operations';

  @override
  String get staffPermPurchasing => 'Purchasing';

  @override
  String get staffPermViewCustomers => 'View customers';

  @override
  String get staffPermEditCustomers => 'Edit customers';

  @override
  String get staffPermManageDebts => 'Customer debts';

  @override
  String get staffPermManagePromotions => 'Promotions and marketing';

  @override
  String get staffPermViewReports => 'Reports';

  @override
  String get staffPermViewAllShifts => 'All shifts';

  @override
  String get staffPermManageStaff => 'Staff management';

  @override
  String get staffPermManageSettings => 'Settings';

  @override
  String get staffPermViewAudit => 'Activity log';

  @override
  String get staffAuditAuthLogin => 'Signed in';

  @override
  String get staffAuditAuthFail => 'Wrong PIN';

  @override
  String get staffAuditAuthLogout => 'Signed out';

  @override
  String get staffAuditSaleDiscount => 'Receipt discount';

  @override
  String get staffAuditSaleReturn => 'Return';

  @override
  String get staffAuditSaleVoid => 'Receipt voided';

  @override
  String get staffAuditSaleCreate => 'Sale';

  @override
  String get staffAuditShiftOpen => 'Shift opened';

  @override
  String get staffAuditShiftClose => 'Shift closed';

  @override
  String get staffAuditCashPayIn => 'Cash in';

  @override
  String get staffAuditCashPayOut => 'Cash out';

  @override
  String get staffAuditCashExpense => 'Cash expense';

  @override
  String get staffAuditCashCollection => 'Cash collection';

  @override
  String get staffAuditStockReceive => 'Goods receipt';

  @override
  String get staffAuditStockWriteoff => 'Write-off';

  @override
  String get staffAuditStockAdjust => 'Stock adjustment';

  @override
  String get staffAuditStockSet => 'Stock set';

  @override
  String get staffAuditUserCreate => 'Employee created';

  @override
  String get staffAuditUserUpdate => 'Employee details changed';

  @override
  String get staffAuditUserRole => 'Employee role changed';

  @override
  String get staffAuditUserPinChange => 'PIN changed';

  @override
  String get staffAuditUserActivate => 'Employee activated';

  @override
  String get staffAuditUserDeactivate => 'Employee deactivated';

  @override
  String get staffAuditProductPrice => 'Price change';

  @override
  String get staffAuditDebtPayment => 'Debt payment';

  @override
  String get staffAuditBonusAdjust => 'Bonus adjustment';

  @override
  String get staffAuditInventoryComplete => 'Stocktake posted';

  @override
  String get staffAuditDiscountOverride => 'Discount over limit';

  @override
  String get staffAuditDiscountApprove => 'Discount approved by manager';

  @override
  String get staffAuditAuthApproveFail => 'Wrong approval PIN';

  @override
  String get staffAuditBackupAuto => 'Automatic backup';

  @override
  String get staffAuditTimeClockIn => 'Clocked in';

  @override
  String get staffAuditTimeClockOut => 'Clocked out';

  @override
  String get staffAuditTimeAdd => 'Time entry added';

  @override
  String get staffAuditTimeEdit => 'Time entry edited';

  @override
  String get staffAuditTimeDelete => 'Time entry deleted';

  @override
  String get staffAuditStockReceipt => 'Goods receipt';

  @override
  String get staffAuditProductCreate => 'Product created';

  @override
  String get staffAuditProductUpdate => 'Product updated';

  @override
  String get staffAuditProductDelete => 'Product deleted';

  @override
  String get staffAuditProductCost => 'Cost change';

  @override
  String get staffAuditProductImport => 'Product import';

  @override
  String get staffAuditProductBulkPrice => 'Bulk price change';

  @override
  String get staffAuditProductBulkCategory => 'Bulk category change';

  @override
  String get staffAuditCategoryDelete => 'Category deleted';

  @override
  String get staffAuditCustomerCreate => 'Customer created';

  @override
  String get staffAuditCustomerDelete => 'Customer deleted';

  @override
  String get staffAuditCustomerTerms => 'Customer terms changed';

  @override
  String get staffAuditSupplierPayment => 'Supplier payment';

  @override
  String get staffAuditSupplierDelete => 'Supplier deleted';

  @override
  String get staffAuditPoOrdered => 'Purchase order sent';

  @override
  String get staffAuditPoReceive => 'Purchase order received';

  @override
  String get staffAuditPromotionCreate => 'Promotion created';

  @override
  String get staffAuditPromotionUpdate => 'Promotion updated';

  @override
  String get staffAuditPromotionDelete => 'Promotion deleted';

  @override
  String get staffAuditGiftCardIssue => 'Gift card issued';

  @override
  String get staffAuditWarrantyCreate => 'Warranty claim created';

  @override
  String get staffAuditWarrantyStatus => 'Warranty claim status changed';

  @override
  String get staffAuditInventoryCreate => 'Stocktake started';

  @override
  String get staffAuditInventoryCancel => 'Stocktake cancelled';

  @override
  String get staffAuditPosPriceEdit => 'Price edited in receipt';

  @override
  String get staffAuditPosCartClear => 'Receipt cleared';

  @override
  String get staffAuditSettingsChange => 'Settings changed';

  @override
  String get staffAuditRegisterDelete => 'Register deleted';

  @override
  String get staffAuditRegisterBindDevice => 'Device linked to register';

  @override
  String get staffAuditDataExport => 'Data export';

  @override
  String get staffAuditBackupCreate => 'Backup created';

  @override
  String get staffAuditBackupDelete => 'Backup deleted';

  @override
  String get staffAuditBackupRestoreScheduled => 'Restore scheduled';

  @override
  String get staffAuditBackupRestoreCancelled => 'Restore cancelled';

  @override
  String get staffAuditBackupRestoreApplied => 'Data restored from backup';

  @override
  String get staffGroupAuth => 'Sign-in';

  @override
  String get staffGroupSale => 'Sales';

  @override
  String get staffGroupShift => 'Shifts';

  @override
  String get staffGroupCash => 'Cash';

  @override
  String get staffGroupStock => 'Stock';

  @override
  String get staffGroupInventory => 'Stocktake';

  @override
  String get staffGroupUser => 'Staff';

  @override
  String get staffGroupTime => 'Work time';

  @override
  String get staffGroupProduct => 'Products';

  @override
  String get staffGroupDebt => 'Debts';

  @override
  String get staffGroupBonus => 'Bonuses';

  @override
  String get staffGroupDiscount => 'Discounts';

  @override
  String get staffGroupPos => 'Register (receipt)';

  @override
  String get staffGroupCustomer => 'Customers';

  @override
  String get staffGroupSupplier => 'Suppliers';

  @override
  String get staffGroupPo => 'Purchasing';

  @override
  String get staffGroupPromotion => 'Promotions';

  @override
  String get staffGroupSettings => 'Settings';

  @override
  String get staffGroupBackup => 'Backups';

  @override
  String get staffDetailDiscount => 'discount';

  @override
  String get staffDetailTotal => 'total';

  @override
  String get staffDetailOpening => 'float';

  @override
  String get staffDetailExpected => 'expected';

  @override
  String get staffDetailCounted => 'counted';

  @override
  String get staffDetailManual => 'manual discount';

  @override
  String get staffDetailMethod => 'method';

  @override
  String get staffMethodCash => 'cash';

  @override
  String get staffMethodCard => 'card';

  @override
  String get staffMethodDebt => 'on credit';

  @override
  String get staffMethodBonus => 'bonuses';

  @override
  String get staffMethodTransfer => 'transfer';

  @override
  String get staffMethodGiftCard => 'gift card';

  @override
  String staffDetailPromos(String list) {
    return 'promotions: $list';
  }

  @override
  String staffDetailReturnNo(String number) {
    return 'return receipt No. $number';
  }

  @override
  String get staffSearchHint => 'Name or phone';

  @override
  String get staffInactiveFilter => 'Inactive';

  @override
  String get staffInactiveFilterTip => 'Show deactivated employees';

  @override
  String get staffAddUser => 'Add employee';

  @override
  String get staffEmpty => 'No employees yet';

  @override
  String get staffNobodyFound => 'Nobody found';

  @override
  String get staffEmptyHint =>
      'Add cashiers and managers so they can sign in with a PIN';

  @override
  String staffDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get staffDeactivateMessage =>
      'The employee will not be able to sign in, and their open time entry will be closed. Sales and shift history is kept. You can activate them again at any time.';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String staffDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String staffActivateTitle(String name) {
    return 'Activate $name';
  }

  @override
  String get staffActivateMessage =>
      'Set a new PIN — the old one may have been given to another employee.';

  @override
  String staffReactivated(String name) {
    return '$name is active again';
  }

  @override
  String get staffNeverLoggedIn => 'never signed in';

  @override
  String staffLastLogin(String date) {
    return 'signed in $date';
  }

  @override
  String get staffYou => 'You';

  @override
  String get staffInactiveChip => 'Inactive';

  @override
  String get staffAtWork => 'At work';

  @override
  String get staffTodayLower => 'today';

  @override
  String get staffEditAction => 'Edit';

  @override
  String get staffActivate => 'Activate';

  @override
  String get staffNewUser => 'New employee';

  @override
  String staffUserTitle(String name) {
    return 'Employee: $name';
  }

  @override
  String get staffDemoteTitle => 'Lower your own role?';

  @override
  String staffDemoteMessage(String role) {
    return 'After saving, you (“$role”) will lose access to the “Staff” section. Only the owner or an administrator can restore it.';
  }

  @override
  String get staffDemote => 'Lower';

  @override
  String get staffUserAdded => 'Employee added';

  @override
  String get staffChangesSaved => 'Changes saved';

  @override
  String get staffFrom0To100 => '0 to 100';

  @override
  String get staffNameLabel => 'Name *';

  @override
  String get staffOwnerRoleLocked =>
      'Only the owner can change the owner’s role';

  @override
  String get staffRoleLabel => 'Role *';

  @override
  String get staffPinSection => 'Sign-in PIN';

  @override
  String get staffResetPin => 'Reset PIN';

  @override
  String get staffResetPinHint => 'The employee will sign in with a new PIN';

  @override
  String get staffPinLabel => 'PIN *';

  @override
  String get staffPinRepeatLabel => 'Repeat PIN *';

  @override
  String get staffPinMismatch => 'PINs do not match';

  @override
  String get staffPinHint => '4–8 digits, unique for each employee';

  @override
  String get staffLimitsSection => 'Limits and incentives';

  @override
  String get staffMaxDiscount => 'Max. discount';

  @override
  String get staffMaxDiscountHelper => 'without approval';

  @override
  String get staffCommission => 'Commission';

  @override
  String get staffCommissionHelper => 'of net revenue';

  @override
  String get staffSalesPlan => 'Monthly sales target';

  @override
  String get staffSalesPlanHelper => '0 or empty — no target';

  @override
  String get staffSaving => 'Saving…';

  @override
  String get staffEnterPin => 'Enter PIN';

  @override
  String get staffPinMin4 => 'At least 4 digits';

  @override
  String get staffNewPin => 'New PIN';

  @override
  String get staffPin4to8 => '4 to 8 digits';

  @override
  String get staffRepeatPin => 'Repeat PIN';

  @override
  String get staffNoPlan => 'no target';

  @override
  String get staffClockIn => 'Clock in';

  @override
  String staffClockedIn(String time) {
    return 'Clocked in at $time';
  }

  @override
  String get staffClockInShort => 'Start work';

  @override
  String get staffClockOutTitle => 'Clock out?';

  @override
  String staffClockOutMessage(String time, String duration) {
    return 'At work since $time ($duration).';
  }

  @override
  String get staffClockOut => 'Clock out';

  @override
  String get staffClockedOut => 'Clocked out';

  @override
  String staffClockOutTip(String time) {
    return 'At work since $time · clock out';
  }

  @override
  String staffAtWorkSince(String time) {
    return 'At work since $time';
  }

  @override
  String staffClockOutShortDur(String duration) {
    return 'Clock out · $duration';
  }

  @override
  String staffClockOutDur(String duration) {
    return 'Clock out · $duration';
  }

  @override
  String get staffThisWeek => 'This week';

  @override
  String get staffThisMonth => 'This month';

  @override
  String get staffLastMonth => 'Last month';

  @override
  String get staffAllEmployees => 'All employees';

  @override
  String get staffEntryShort => 'Entry';

  @override
  String get staffAddEntry => 'Add entry';

  @override
  String get staffNoMarks => 'No entries for the period';

  @override
  String get staffNoMarksHint =>
      'Employees clock in and out with the “Clock in” button';

  @override
  String get staffAtWorkLower => 'at work';

  @override
  String get staffNewEntryTitle => 'New time entry';

  @override
  String get staffEntryTitle => 'Time entry';

  @override
  String get staffSelectEmployee => 'Select an employee';

  @override
  String get staffEntrySaved => 'Entry saved';

  @override
  String get staffDeleteEntryTitle => 'Delete entry?';

  @override
  String get staffDeleteEntryMessage =>
      'The action will be recorded in the log.';

  @override
  String get staffEntryDeleted => 'Entry deleted';

  @override
  String get staffEmployeeRequired => 'Employee *';

  @override
  String get staffClockInField => 'Clock-in';

  @override
  String get staffClockOutField => 'Clock-out';

  @override
  String get staffStillAtWorkLower => 'still at work';

  @override
  String get staffStillAtWork => 'Still at work';

  @override
  String get staffEndBeforeStartShort => 'Clock-out is before clock-in';

  @override
  String staffDurationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get staffEntryNote => 'Comment (reason for edit)';

  @override
  String get staffMonth1 => 'January';

  @override
  String get staffMonth2 => 'February';

  @override
  String get staffMonth3 => 'March';

  @override
  String get staffMonth4 => 'April';

  @override
  String get staffMonth5 => 'May';

  @override
  String get staffMonth6 => 'June';

  @override
  String get staffMonth7 => 'July';

  @override
  String get staffMonth8 => 'August';

  @override
  String get staffMonth9 => 'September';

  @override
  String get staffMonth10 => 'October';

  @override
  String get staffMonth11 => 'November';

  @override
  String get staffMonth12 => 'December';

  @override
  String get staffPrevMonth => 'Previous month';

  @override
  String get staffNextMonth => 'Next month';

  @override
  String get staffCurrentMonth => 'Current';

  @override
  String get staffMotivationHint =>
      'Sales assistant revenue excluding voided receipts, minus returns made this month';

  @override
  String get staffNoSellers => 'No sales assistants';

  @override
  String get staffNoSellersHint =>
      'Set a sales target and commission in the employee card';

  @override
  String get staffNetRevenue => 'Net revenue';

  @override
  String staffPlanValue(String amount) {
    return 'Target $amount';
  }

  @override
  String get staffCommissionDue => 'Commission due';

  @override
  String get staffRevenue => 'Revenue';

  @override
  String get staffRefunds => 'Returns';

  @override
  String get staffReceiptsLabel => 'Receipts';

  @override
  String get staffAvgCheck => 'Average sale';

  @override
  String staffCommissionPct(String pct) {
    return 'Commission $pct%';
  }

  @override
  String staffPlanLeft(String done, String plan, String left) {
    return '$done of $plan · $left to go';
  }

  @override
  String staffPlanDone(String done, String plan) {
    return '$done of $plan · target met';
  }

  @override
  String get staffActionLabel => 'Action';

  @override
  String get staffAllActions => 'All actions';

  @override
  String get staffNoRecords => 'No records found';

  @override
  String get staffNoRecordsHint => 'Change the period or filters';

  @override
  String staffAuditLimit(String n) {
    return 'Showing the last $n records — refine the filter';
  }

  @override
  String get staffSystem => 'system';

  @override
  String get warrantyTitle => 'Warranty';

  @override
  String get warrantySubtitle => 'Warranty and service claims';

  @override
  String get warrantyStatusReceived => 'Received';

  @override
  String get warrantyStatusInRepair => 'In repair';

  @override
  String get warrantyStatusReplaced => 'Replaced';

  @override
  String get warrantyStatusRefunded => 'Refunded';

  @override
  String get warrantyStatusRejected => 'Rejected';

  @override
  String get warrantyStatusReturned => 'Returned to customer';

  @override
  String get warrantyActionInRepair => 'Send to repair';

  @override
  String get warrantyActionReplace => 'Replace item';

  @override
  String get warrantyActionRefund => 'Refund';

  @override
  String get warrantyActionReject => 'Reject';

  @override
  String get warrantyActionReturn => 'Return to customer';

  @override
  String get warrantyGroupOpen => 'Open';

  @override
  String get warrantyGroupResolved => 'Resolved';

  @override
  String get warrantyGroupClosed => 'Handed back';

  @override
  String get warrantyNotSet => 'not set';

  @override
  String warrantyActUntilActive(String date) {
    return 'until $date (valid)';
  }

  @override
  String warrantyActUntilExpired(String date) {
    return 'until $date (expired)';
  }

  @override
  String get warrantyActTitle => 'WARRANTY SERVICE ACCEPTANCE CERTIFICATE';

  @override
  String warrantyActNumber(String number, String date) {
    return 'No. $number dated $date';
  }

  @override
  String get warrantySerialNumber => 'Serial number';

  @override
  String get warrantyActPurchaseDoc => 'Proof of purchase';

  @override
  String get warrantyActNotPresented => 'not presented';

  @override
  String warrantyReceiptRef(String number, String date) {
    return 'receipt No. $number dated $date';
  }

  @override
  String get warrantyWarranty => 'Warranty';

  @override
  String get warrantyActProblem => 'Reported fault';

  @override
  String get warrantyActCompleteness => 'Contents and condition';

  @override
  String get warrantyResolution => 'Resolution';

  @override
  String get warrantyActTerms =>
      'The claim is reviewed within the period set by consumer protection law. The item is returned on presentation of this certificate.';

  @override
  String get warrantyActHandedBy => 'Handed over by (customer):';

  @override
  String get warrantyActReceivedBy => 'Received by (employee):';

  @override
  String warrantyActJobName(String number) {
    return 'Warranty $number';
  }

  @override
  String warrantyClaimAccepted(String number) {
    return 'Claim No. $number received';
  }

  @override
  String get warrantyPrintActQuestion =>
      'Print the acceptance certificate for the customer to sign?';

  @override
  String get warrantyPrintAct => 'Print certificate';

  @override
  String get warrantySearchHintWide =>
      'Claim or receipt no., customer, serial no., item';

  @override
  String get warrantySearchHint => 'Claim, receipt, customer, S/N, item';

  @override
  String get warrantyNewClaim => 'New claim';

  @override
  String get warrantyClaimFab => 'Claim';

  @override
  String get warrantySelectClaim => 'Select a claim';

  @override
  String get warrantySelectClaimHint =>
      'Claim details, status changes and certificate printing';

  @override
  String get warrantyEmptyTitle => 'No claims yet';

  @override
  String get warrantyEmptyFiltered =>
      'Change the search or pick another status';

  @override
  String get warrantyEmptyHint =>
      'Take an item in under warranty by receipt number or manually';

  @override
  String get warrantyShowMore => 'Show more';

  @override
  String get warrantyNoProduct => 'no item specified';

  @override
  String warrantyReceiptShort(String number) {
    return 'receipt No. $number';
  }

  @override
  String warrantyDaysShort(String days) {
    return '$days d';
  }

  @override
  String get warrantyClaimTitle => 'Warranty claim';

  @override
  String get warrantyClaimNotFound => 'Claim not found';

  @override
  String warrantyClaimNumber(String number) {
    return 'Claim No. $number';
  }

  @override
  String warrantyAcceptedAt(String date) {
    return 'received $date';
  }

  @override
  String get warrantyActButton => 'Acceptance certificate';

  @override
  String get warrantyProductName => 'Name';

  @override
  String get warrantyPurchase => 'Purchase';

  @override
  String get warrantyNoReceipt => 'no receipt';

  @override
  String get warrantyOpenReceipt => 'Open receipt';

  @override
  String warrantyUntil(String date) {
    return 'until $date';
  }

  @override
  String warrantyExpiredOn(String date) {
    return 'expired $date';
  }

  @override
  String get warrantyNotSpecified => 'not specified';

  @override
  String get warrantyProblem => 'Fault';

  @override
  String get warrantyHistory => 'History';

  @override
  String get warrantyHistoryCreated => 'Claim received';

  @override
  String warrantyStatusChanged(String status) {
    return 'Status: $status';
  }

  @override
  String warrantyStatusChangedWriteOff(String status) {
    return 'Status: $status · 1 unit written off';
  }

  @override
  String get warrantyRefundTitle => 'Process the refund';

  @override
  String get warrantyRefundMessage =>
      'Money is refunded only through a receipt return in “Receipts”, so the till, stock and reports stay correct. Go to the return now?';

  @override
  String get warrantyOpenReceipts => 'Open “Receipts”';

  @override
  String warrantyOpenReceiptNumber(String number) {
    return 'Open receipt No. $number';
  }

  @override
  String get warrantyRefundHint =>
      'Resolution: refund. Process a receipt return (without restocking).';

  @override
  String get warrantyToReceipt => 'To receipt';

  @override
  String get warrantyHintInRepair => 'Service center, estimated time';

  @override
  String get warrantyHintReplaced =>
      'E.g. replaced with a new one, serial No. …';

  @override
  String get warrantyHintRefunded => 'E.g. defect confirmed, refund';

  @override
  String get warrantyHintRejected =>
      'Reason: impact marks, opened, terms violated…';

  @override
  String get warrantyHintReturned => 'Who it was handed to and when';

  @override
  String warrantyTransition(String number, String from, String to) {
    return 'Claim No. $number: $from → $to';
  }

  @override
  String get warrantyResolutionRequired => 'Resolution *';

  @override
  String get warrantyEnterResolution => 'Enter the resolution';

  @override
  String get warrantyWriteOffOne => 'Write off 1 unit from stock';

  @override
  String get warrantyWriteOffHint =>
      'Reason: “Warranty replacement” — the item given to the customer leaves stock';

  @override
  String get warrantyWriteOffUnavailable =>
      'Unavailable: no stock permissions or no item specified';

  @override
  String get warrantyRefundNote =>
      'The status does not move money. After saving, process a receipt return in “Receipts”.';

  @override
  String get warrantyNewClaimTitle => 'New warranty claim';

  @override
  String get warrantyEnterReceiptDigits => 'Enter the receipt number in digits';

  @override
  String warrantyReceiptNotFound(String number) {
    return 'Receipt No. $number not found';
  }

  @override
  String get warrantyBlockVoided => 'receipt voided';

  @override
  String get warrantyBlockReturned => 'item returned';

  @override
  String get warrantyExpiredTitle => 'Warranty expired';

  @override
  String get warrantyNotSetTitle => 'No warranty set';

  @override
  String get warrantyPaidRepairQuestion =>
      'The claim can be taken as a paid repair or for inspection. Accept?';

  @override
  String get warrantyAccept => 'Accept';

  @override
  String get warrantyDuplicateTitle => 'An open claim already exists';

  @override
  String warrantyDuplicateMessage(String number, String status) {
    return 'Claim No. $number for this receipt item is already open ($status). Create another one?';
  }

  @override
  String get warrantyFindReceiptAndItem =>
      'Find the receipt and pick an item from it';

  @override
  String get warrantySelectProduct => 'Select an item';

  @override
  String get warrantyByReceipt => 'By receipt';

  @override
  String get warrantyWithoutReceipt => 'No receipt';

  @override
  String get warrantySerialImei => 'Serial number / IMEI';

  @override
  String get warrantyProblemLabel => 'Fault description *';

  @override
  String get warrantyProblemHint =>
      'What does not work, since when, condition, contents';

  @override
  String get warrantyDescribeProblem => 'Describe the fault';

  @override
  String get warrantySubmit => 'Accept claim';

  @override
  String get warrantyReceiptNumber => 'Receipt number';

  @override
  String get warrantyFind => 'Find';

  @override
  String warrantyReceiptPickItem(String number, String date) {
    return 'Receipt No. $number dated $date — pick an item';
  }

  @override
  String get warrantyReceiptVoided =>
      'The receipt is voided — items from it cannot be accepted. Use “No receipt” mode.';

  @override
  String get warrantyNoWarranty => 'no warranty';

  @override
  String warrantyChipUntil(String date) {
    return 'warranty until $date';
  }

  @override
  String warrantyChipExpired(String date) {
    return 'warranty expired $date';
  }

  @override
  String warrantyBannerActive(String date) {
    return 'Under warranty until $date';
  }

  @override
  String warrantyBannerExpired(String date) {
    return 'Warranty expired $date. The claim can be taken as a paid repair.';
  }

  @override
  String get warrantyBannerNone => 'No warranty is set for this item';

  @override
  String get warrantySelectProductRequired => 'Select an item *';

  @override
  String get warrantyRequiredNoReceipt =>
      'Required for a claim without a receipt';

  @override
  String get warrantyManualHint =>
      'For an item without a receipt or sold outside the system';

  @override
  String get warrantyCustomerOptional => 'Customer (optional)';

  @override
  String get warrantyCustomerHint => 'Needed to notify when ready';

  @override
  String get warrantyRemoveCustomer => 'Remove customer';

  @override
  String get warrantyReceiptLineNotFound => 'Receipt line not found';

  @override
  String warrantyCannotTransition(String from, String to) {
    return 'Cannot move the claim from “$from” to “$to”';
  }

  @override
  String get warrantyEnterClaimResolution =>
      'Enter the resolution for the claim';

  @override
  String get warrantyWriteOffOnlyReplace =>
      'Write-off is only possible on replacement';

  @override
  String get warrantyNoProductInClaim => 'The claim has no item';

  @override
  String get warrantyStockUnavailable => 'Stock is unavailable';

  @override
  String get warrantyChangedByOther =>
      'The claim has already been changed by another user';
}
