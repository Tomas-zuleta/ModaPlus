import 'package:flutter/material.dart';

/// Texto de demostración. No sustituye términos aprobados por el comercio.
class LegalDraftPage extends StatelessWidget {
  const LegalDraftPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TÉRMINOS Y CONDICIONES')),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      Text('Términos y condiciones', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(16),
        child: Text('DOCUMENTO DE DEMOSTRACIÓN. Pendiente de revisión legal, '
          'identificación del comerciante y publicación de la versión definitiva. '
          'No constituye una política comercial aprobada.'))),
      const SizedBox(height: 12),
      for (final item in const [
        ('1. Uso de la aplicación', 'ModaPlus permite consultar productos, '
          'gestionar una cuenta y solicitar pedidos. Debes proporcionar datos veraces '
          'y proteger tus credenciales.'),
        ('2. Productos y disponibilidad', 'Los precios se muestran en pesos colombianos. '
          'La disponibilidad y el importe final se confirman antes de formalizar una compra.'),
        ('3. Pedidos y pagos', 'Los pedidos sujetos a revisión de comprobante '
          'permanecen pendientes hasta que el comercio confirme el pago. '
          'No se debe interpretar una solicitud como aprobación automática.'),
        ('4. Privacidad', 'Los datos personales se utilizarán para gestionar '
          'cuentas, pedidos y atención. Se publicará una política de tratamiento '
          'de datos independiente antes del lanzamiento.'),
        ('5. Garantías y devoluciones', 'Se respetarán los derechos de los '
          'consumidores conforme a la legislación colombiana aplicable. '
          'Las condiciones comerciales definitivas deben ser aprobadas por el negocio.'),
        ('6. Contacto', 'Dirección, NIT, correo de atención y horario: '
          'pendientes de confirmación.'),
      ])
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.$2),
          ]))),
      const SizedBox(height: 12),
      const Text('Versión: DEMO-2026-11. El consentimiento no se almacena '
        'aún de forma versionada en el servidor.'),
    ]),
  );
}
