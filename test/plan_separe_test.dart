import 'package:flutter_test/flutter_test.dart';
import 'package:modaplus/models/plan_separe.dart';

PlanSepare buildPlan({int total = 100000}) => PlanSepare(
  id: 'PS-TEST',
  clientName: 'Cliente prueba',
  clientDoc: '123',
  createdAt: DateTime(2026, 9, 25),
  items: [
    PlanItem(
      name: 'Producto',
      size: 'M',
      color: 'Negro',
      quantity: 1,
      unitPrice: total,
    ),
  ],
  abonos: [],
);

void main() {
  test('registra un abono y actualiza el saldo', () {
    final plan = buildPlan();

    plan.addPayment(40000, date: DateTime(2026, 9, 25));

    expect(plan.paid, 40000);
    expect(plan.balance, 60000);
    expect(plan.status, PlanStatus.active);
  });

  test('impide que el abono supere el saldo pendiente', () {
    final plan = buildPlan();
    plan.addPayment(70000);

    expect(() => plan.addPayment(30001), throwsArgumentError);
    expect(plan.balance, 30000);
  });

  test('marca el plan como pagado al cubrir el saldo', () {
    final plan = buildPlan();

    plan.addPayment(100000);

    expect(plan.balance, 0);
    expect(plan.status, PlanStatus.completed);
    expect(plan.canReceivePayments, isFalse);
  });
}
