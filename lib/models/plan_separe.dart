import '../utils/format.dart';

enum PlanStatus { active, completed, cancelled }

extension PlanStatusLabel on PlanStatus {
  String get label => switch (this) {
    PlanStatus.active => 'Activo',
    PlanStatus.completed => 'Pagado',
    PlanStatus.cancelled => 'Anulado',
  };
}

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
  const Abono(this.date, this.amount);
}

class PlanSepare {
  final String id;
  final String clientName;
  final String clientDoc;
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
    this.status = PlanStatus.active,
    this.annulNote,
  }) {
    if (status == PlanStatus.active && balance == 0) {
      status = PlanStatus.completed;
    }
  }

  int get total => items.fold<int>(0, (s, i) => s + i.subtotal);
  int get paid => abonos.fold<int>(0, (s, a) => s + a.amount);
  int get balance => total - paid;
  bool get isActive => status == PlanStatus.active;
  bool get canReceivePayments => isActive && balance > 0;

  void addPayment(int amount, {DateTime? date}) {
    if (!canReceivePayments) {
      throw StateError('El plan no admite nuevos abonos.');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Debe ser mayor que cero.');
    }
    if (amount > balance) {
      throw ArgumentError.value(
        amount,
        'amount',
        'No puede superar el saldo pendiente.',
      );
    }

    abonos.insert(0, Abono(date ?? DateTime.now(), amount));
    if (balance == 0) status = PlanStatus.completed;
  }

  double get progress =>
      total == 0 ? 0.0 : (paid / total).clamp(0.0, 1.0).toDouble();

  /// Plazo máximo: 2 meses desde la creación.
  DateTime get dueDate =>
      DateTime(createdAt.year, createdAt.month + 2, createdAt.day);

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;

  /// Regla de la ficha: menos del 50% abonado => queda a favor de la tienda.
  String get annulOutcome {
    if (paid * 2 < total) {
      return 'El abono de ${formatCop(paid)} queda a favor de la tienda '
          '(se abonó menos del 50%).';
    }
    return 'El abono de ${formatCop(paid)} se acredita como saldo a favor '
        'del cliente (se abonó el 50% o más).';
  }
}
