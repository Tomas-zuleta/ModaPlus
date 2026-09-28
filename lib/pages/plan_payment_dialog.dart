import 'package:flutter/material.dart';

import '../utils/format.dart';
import '../widgets/payment_method_picker.dart';

Future<PaymentSelection?> showPlanPaymentDialog(
  BuildContext context, {
  required int amount,
  required String title,
}) {
  return showDialog<PaymentSelection>(
    context: context,
    builder: (_) => _PaymentDialog(amount: amount, title: title),
  );
}

class _PaymentDialog extends StatefulWidget {
  final int amount;
  final String title;

  const _PaymentDialog({required this.amount, required this.title});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PaymentSelection? _selection;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior con título y X
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Valor a pagar: ${formatCop(widget.amount)}'),
                      const SizedBox(height: 20),
                      PaymentMethodPicker(
                        onChanged: (selection) => setState(() => _selection = selection),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _selection == null
                                ? null
                                : () => Navigator.pop(context, _selection),
                            child: const Text('Confirmar pago'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}