# DreamPOS — архитектура и правила разработки модулей

## Структура
```
lib/
  main.dart                 запуск, открытие БД, ProviderScope
  app/                      app.dart (MaterialApp), router.dart, shell.dart, nav.dart
  core/
    db/                     tables.dart (схема), database.dart (+ .g.dart), demo_seed.dart
    printing/               receipt.dart (чек 58/80мм, текст+PDF), pdf_fonts.dart (кириллица оффлайн)
    widgets/                widgets.dart (UI‑кит), pin_pad.dart, pickers.dart (товар/клиент)
    money.dart              Money (int минорные единицы), Qty (кол-во и ед. изм.)
    permissions.dart        Role, Perm, role.can(perm)
    providers.dart          databaseProvider, сервисы, settingsProvider, sessionProvider, currentShiftProvider
    theme.dart              AppColors, Gap, Breakpoints, buildTheme
  domain/
    pricing.dart            PricingEngine (скидки/акции/НДС) — чистый Dart
    errors.dart             BusinessException
    services/               sale_service (checkout/return/void), shift_service, stock_service,
                            customer_service (долги/бонусы), auth_service
  features/<module>/        экраны и локальная логика модуля
test/                       domain/ — тесты сервисов; features/<module>/ — тесты модулей
```

## Правила для модулей (features)
1. Модуль владеет только `lib/features/<module>/` и `test/features/<module>/`.
   Изменения в `core/`, `domain/`, `app/`, `pubspec.yaml` — только через ядро (запрос в отчёте).
2. Главный экран модуля — класс из роутера (`const XxxScreen({super.key})`), имя не менять.
3. Запись продаж, возвратов, остатков, долгов, бонусов, смен — **только через сервисы** из
   `core/providers.dart`. Справочники (товары, категории, клиенты, поставщики, акции, сертификаты,
   сотрудники, настройки) можно писать через drift напрямую, всегда ставя `updatedAt` и вызывая
   `db.markDirty(table, id)`; удаление — мягкое (`deletedAt`), если на запись есть ссылки.
4. Чувствительные действия — `db.audit(...)`.
5. UI: только компоненты из `core/widgets` + Material 3; цвета — из темы/`AppColors`; отступы — `Gap`.
   Каждый экран: загрузка, ошибка, пустое состояние, адаптивность 360px…1920px, работа с клавиатуры.
6. Все суммы — `int` минорные единицы, ввод — `MoneyField`, вывод — `Money.format`.
7. Права: `ref.watch(sessionProvider)!.can(Perm.x)` — скрывать/блокировать недоступные действия.
8. Ошибки показывать `showError`, успех — `showSuccess`, опасные действия — `confirm(...)`.
9. Язык — русский; терминология: «чек», «смена», «остаток», «приход», «списание», «инвентаризация».
10. Перед сдачей: `flutter analyze lib/features/<module>` без замечаний; тесты модуля проходят.

## Ключевые потоки
- Продажа: `SaleService.quote()` для предпросмотра, `checkout()` — одна транзакция.
- Возврат: `SaleService.returnItems()`; аннулирование: `voidSale()`.
- Смена: `ShiftService.open/close/report/cashMovement`.
- Склад: `StockService.receive/writeOff/setStock/completeCount`.
- Долг/бонусы: `CustomerService.payDebt/adjustBonus`.
- Печать чека: `printReceipt(db, saleId)`; текст чека: `ReceiptData.load(...).toText()`.
