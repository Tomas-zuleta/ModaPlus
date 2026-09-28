import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/empty_state.dart';

class AbonosView extends StatelessWidget {
  const AbonosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      appBar: const DetailAppBar(title: 'ABONOS'),
      body: ListenableBuilder(
        listenable: AppStore.instance,
        builder: (context, _) {
          final payments = AppStore.instance.allAbonos;
          if (payments.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Todavía no hay abonos registrados',
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: payments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = payments[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.panelBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key.clientName),
                              Text(
                                '${entry.key.id} · ${formatDate(entry.value.date)} · ${entry.value.method}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCop(entry.value.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}