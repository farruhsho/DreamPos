import 'package:dreampos/core/money.dart';
import 'package:dreampos/features/staff/staff_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audit details are humanized', () {
    String m(int v) => Money.format(v);
    expect(auditDetailsText('sale.discount', 'discount=2850; promos=Скидка клиента, Сладкая неделя −10%'),
        'скидка ${m(2850)} · акции: Скидка клиента, Сладкая неделя −10%');
    expect(auditDetailsText('sale.return', 'return #1 total=18000 method=cash; Брак'),
        'чек возврата №1 сумма ${m(18000)} способ наличные · Брак');
    expect(auditDetailsText('cash.expense', '45000; Пакеты'), '${m(45000)} · Пакеты');
    expect(auditDetailsText('shift.close', 'expected=100; counted=90'), 'ожидалось ${m(100)} · пересчитано ${m(90)}');
    expect(auditDetailsText('user.create', 'cashier Алина'), 'Кассир Алина');
    expect(auditDetailsText('sale.void', 'Ошибка кассира'), 'Ошибка кассира');
    expect(auditDetailsText('x', null), '');
  });

  test('pluralRu', () {
    expect(pluralRu(1, 'a', 'b', 'c'), 'a');
    expect(pluralRu(3, 'a', 'b', 'c'), 'b');
    expect(pluralRu(11, 'a', 'b', 'c'), 'c');
    expect(pluralRu(22, 'a', 'b', 'c'), 'b');
    expect(pluralRu(25, 'a', 'b', 'c'), 'c');
  });
}
