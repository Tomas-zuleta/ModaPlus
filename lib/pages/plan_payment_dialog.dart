import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/plan_separe.dart';
import '../utils/format.dart';

Future<bool> showPlanPaymentDialog(
  BuildContext context,
  PlanSepare plan,
) async {
  final controller = TextEditingController();
  String? error;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Registrar abono · ${plan.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo pendiente: ${formatCop(plan.balance)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor del abono',
                prefixText: r'$ ',
                errorText: error,
              ),
              onSubmitted: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(
                controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
              );
              if (amount == null || amount <= 0) {
                setState(() => error = 'Ingresa un valor mayor que cero');
                return;
              }
              if (amount > plan.balance) {
                setState(
                  () => error =
                      'El máximo permitido es ${formatCop(plan.balance)}',
                );
                return;
              }
              AppStore.instance.addPlanPayment(plan, amount);
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return saved ?? false;
}
