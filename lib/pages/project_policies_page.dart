import 'package:flutter/material.dart';

/// Requisitos del proyecto (ficha técnica aprobada, págs. 5–8).
/// Resumen informativo: no constituye términos jurídicos vigentes ni
/// ejecuta anulaciones automáticas o movimientos de saldo.
class ProjectPoliciesPage extends StatelessWidget {
  const ProjectPoliciesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('REGLAS DEL PROYECTO')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Pedidos y Plan Separe', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(14),
        child: Text('Resumen informativo de la ficha técnica aprobada de ModaPlus, '
          'páginas 5–8. No es una política contractual definitiva. Las reglas '
          'sobre retención de dinero requieren validación legal antes de automatizarse.'))),
      const SizedBox(height: 12),
      for (final item in const [
        ('Plan Separe', 'Cuota inicial mínima de COP \$20.000 por cada prenda. '
          'Plazo máximo de dos meses. La ficha establece condiciones de anulación '
          'y tratamiento de abonos según el umbral del 50 %, pendientes de revisión legal.'),
        ('Abonos', 'El personal administrativo registra y consulta los abonos. '
          'La anulación debe ajustar saldos e inventario mediante operaciones '
          'transaccionales verificadas en el servidor.'),
        ('Pedidos', 'La ficha contempla pedidos con pago en tienda, por QR '
          'o transferencia, y vigencia de una semana en ciertos casos. '
          'Los pagos parciales y saldos a favor requieren seguimiento de plazos.'),
        ('Devoluciones', 'La ficha describe un plazo de dos semanas para '
          'presentar productos en buen estado, sin perjuicio de los derechos '
          'legales aplicables a garantías y retracto.'),
        ('Inventario', 'Las compras incrementan las existencias y las ventas '
          'las disminuyen. No deben editarse saldos directamente desde el teléfono.'),
        ('Ubicación', 'Referencia proporcionada en la ficha: Parque principal '
          'de San Cristóbal. No hay una dirección postal exacta confirmada.'),
        ('Correos', 'El registro y las ventas aprobadas tienen funciones '
          'de correo reutilizables desde la web. Los avisos automáticos de '
          'inicio de sesión, rechazo y cambios de estado aún requieren '
          'implementación y despliegue del servidor.'),
      ])
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8), Text(item.$2),
          ]))),
    ]),
  );
}
