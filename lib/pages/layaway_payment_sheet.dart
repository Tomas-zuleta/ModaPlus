import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/administrative_transactions.dart';

/// Formulario corto: se abre desde abajo y valida el saldo visible antes del RPC.
class LayawayPaymentSheet extends StatefulWidget {
  final int planId;
  final double balance;
  const LayawayPaymentSheet({super.key, required this.planId, required this.balance});

  @override
  State<LayawayPaymentSheet> createState() => _LayawayPaymentSheetState();
}

class _LayawayPaymentSheetState extends State<LayawayPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _method = 'EFECTIVO';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final value = double.parse(_amount.text.trim().replaceAll(',', '.'));
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Confirmar abono'),
        content: Text('¿Registrar un pago de COP ${value.toStringAsFixed(0)} '
          'al plan #${widget.planId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar pago')),
        ],
      ));
    if (yes != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AdministrativeTransactions.instance.registerLayawayPayment(
        planId: widget.planId, amount: value, method: _method,
        observation: _note.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Supabase no guardó el abono: ${error.message}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo registrar: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 18, 22, bottom + 24),
        child: SingleChildScrollView(child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 44, height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26, borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 18),
              Text('Registrar un abono',
                style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Plan #${widget.planId} · Saldo pendiente aproximado: '
                'COP ${widget.balance.toStringAsFixed(0)}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'COP ', labelText: '¿Cuánto está pagando?',
                  helperText: 'Escribe el valor recibido.'),
                validator: (text) {
                  final amount = double.tryParse(
                    (text ?? '').trim().replaceAll(',', '.'));
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Ingresa un valor mayor que cero.';
                  }
                  if (amount > widget.balance + 0.001) {
                    return 'El abono no puede superar el saldo pendiente.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: '¿Cómo pagó?'),
                items: const [
                  DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'TRANSFERENCIA', child: Text('Transferencia')),
                  DropdownMenuItem(value: 'QR', child: Text('QR')),
                ],
                onChanged: (value) => setState(() => _method = value ?? _method),
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej. Pago recibido en caja')),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Guardando pago...' : 'Guardar abono'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ],
          ),
        )),
      ),
    );
  }
}
