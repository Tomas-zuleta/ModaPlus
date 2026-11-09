import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// No mostramos planes locales de ejemplo de otros clientes.
class ClientPlansPage extends StatelessWidget {
  const ClientPlansPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PLAN SEPARE Y ABONOS')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      const Text('TUS PLANES SEPARE', style: TextStyle(fontSize: 26,
        fontWeight: FontWeight.w900, color: AppColors.textDark)),
      const SizedBox(height: 8),
      const Text('Consulta tus prendas apartadas y los abonos registrados.'),
      const SizedBox(height: 20),
      Wrap(spacing: 9, runSpacing: 9, children: [
        _Stat(label: 'TOTAL RESERVADO', value: formatZero),
        _Stat(label: 'TOTAL ABONADO', value: formatZero),
        _Stat(label: 'SALDO PENDIENTE', value: formatZero),
      ]),
      const SizedBox(height: 34),
      const Icon(Icons.credit_card_off_outlined, size: 64, color: AppColors.primary),
      const SizedBox(height: 14),
      const Text('Aún no tienes planes vinculados',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 19,
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('Los planes reales aparecerán aquí cuando conectemos '
        'tu cuenta al sistema de pedidos y abonos.',
        textAlign: TextAlign.center),
    ]),
  );
}
const formatZero = '\$ 0';
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    width: 155, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: AppColors.panelBorder),
      borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slate)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20,
        fontWeight: FontWeight.w900, color: AppColors.textDark)),
    ]),
  );
}
