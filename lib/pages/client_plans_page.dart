import 'package:flutter/material.dart';
import '../services/supabase_data_service.dart';

class ClientPlansPage extends StatefulWidget {
  const ClientPlansPage({super.key});
  @override
  State<ClientPlansPage> createState() => _ClientPlansPageState();
}

class _ClientPlansPageState extends State<ClientPlansPage> {
  late Future<List<Map<String, dynamic>>> _plans;
  @override
  void initState() {
    super.initState();
    _reload();
  }
  void _reload() => _plans = SupabaseDataService.instance.myPlans();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PLAN SEPARE Y ABONOS'), actions: [
      IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar',
        onPressed: () => setState(_reload)),
    ]),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _plans,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('No se pudieron consultar tus planes. '
                'Comprueba tu conexión y los permisos de la cuenta.',
                textAlign: TextAlign.center),
              TextButton(onPressed: () => setState(_reload),
                child: const Text('Reintentar')),
            ])));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.credit_card_off_outlined, size: 64),
              SizedBox(height: 15),
              Text('Aún no tienes planes separe registrados',
                textAlign: TextAlign.center),
            ])));
        }
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('${rows.length} PLANES REGISTRADOS',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final row in rows)
            Card(child: ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text('Plan #${row['id_plan_separe']}'),
              subtitle: Text('Estado: ${row['estado'] ?? 'Sin estado'}\n'
                'Inicio: ${row['fecha_inicio'] ?? '-'}\n'
                'Vencimiento: ${row['fecha_vencimiento'] ?? '-'}'),
              isThreeLine: true,
            )),
        ]);
      },
    ),
  );
}
