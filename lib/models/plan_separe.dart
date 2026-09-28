import 'dart:typed_data';

import '../utils/format.dart';

enum PlanStatus { active, completed, cancelled }

class PlanItem {
  final String name;
  final String size;
  final String color;
  final int quantity;
  final int unitPrice;

  const PlanItem({
    required this.name,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
  });

  int get subtotal => quantity * unitPrice;
}

class Abono {
  final DateTime date;
  final int amount;
  final String method;
  final Uint8List? voucherBytes;

  const Abono(
    this.date,
    this.amount, {
    this.method = 'Efectivo',
    this.voucherBytes,
  });
}

class PlanSepare {
  final String id;
  final String clientName;
  final String clientDoc;
  final String clientEmail;
  final DateTime createdAt;
  final List<PlanItem> items;
  final List<Abono> abonos;
  PlanStatus status;
  String? annulNote;

  PlanSepare({
    required this.id,
    required this.clientName,
    required this.clientDoc,
    required this.createdAt,
    required this.items,
    required this.abonos,
    this.clientEmail = '',
    this.status = PlanStatus.active,
    this.annulNote,
  }) {
    if (status == PlanStatus.active && balance == 0) {
      status = PlanStatus.completed;
    }
  }

  int get total => items.fold<int>(0, (sum, item) => sum + item.subtotal);
  int get paid => abonos.fold<int>(0, (sum, abono) => sum + abono.amount);
  int get balance => total - paid;
  bool get isActive => status == PlanStatus.active;
  bool get canReceivePayments => isActive && balance > 0;

  void addPayment(
    int amount, {
    DateTime? date,
    String method = 'Efectivo',
    Uint8List? voucherBytes,
  }) {
    if (!canReceivePayments) {
      throw StateError('El plan no admite nuevos abonos.');
    }
    if (amount <= 0 || amount > balance) {
      throw ArgumentError.value(amount, 'amount', 'Valor de abono no válido.');
    }
    abonos.insert(
      0,
      Abono(
        date ?? DateTime.now(),
        amount,
        method: method,
        voucherBytes: voucherBytes,
      ),
    );
    if (balance == 0) status = PlanStatus.completed;
  }

  double get progress =>
      total == 0 ? 0.0 : (paid / total).clamp(0.0, 1.0).toDouble();

  DateTime get dueDate =>
      DateTime(createdAt.year, createdAt.month + 2, createdAt.day);

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;

  String get annulOutcome {
    if (paid * 2 < total) {
      return 'El abono de ${formatCop(paid)} queda a favor de la tienda '
          '(se abonó menos del 50%).';
    }
    return 'El abono de ${formatCop(paid)} se acredita como saldo a favor '
        'del cliente (se abonó el 50% o más).';
  }
}