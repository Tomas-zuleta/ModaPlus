import 'package:flutter/material.dart';

enum OrderStatus { requested, verification, partial, paid, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.requested => 'Solicitado',
        OrderStatus.verification => 'En verificación',
        OrderStatus.partial => 'Abonado',
        OrderStatus.paid => 'Pagado',
        OrderStatus.delivered => 'Entregado',
        OrderStatus.cancelled => 'Anulado',
      };

  Color get color => switch (this) {
        OrderStatus.requested => const Color(0xFFB7791F),
        OrderStatus.verification => const Color(0xFF7C5CBF),
        OrderStatus.partial => const Color(0xFF3B5BA9),
        OrderStatus.paid => const Color(0xFF3B8B67),
        OrderStatus.delivered => const Color(0xFF475569),
        OrderStatus.cancelled => const Color(0xFFD32F2F),
      };

  /// Estados a los que puede pasar desde el actual.
  List<OrderStatus> get next => switch (this) {
        OrderStatus.requested => <OrderStatus>[
            OrderStatus.verification,
            OrderStatus.cancelled,
          ],
        OrderStatus.verification => <OrderStatus>[
            OrderStatus.partial,
            OrderStatus.paid,
            OrderStatus.cancelled,
          ],
        OrderStatus.partial => <OrderStatus>[
            OrderStatus.paid,
            OrderStatus.cancelled,
          ],
        OrderStatus.paid => <OrderStatus>[
            OrderStatus.delivered,
            OrderStatus.cancelled,
          ],
        OrderStatus.delivered => <OrderStatus>[],
        OrderStatus.cancelled => <OrderStatus>[],
      };
}

class OrderItem {
  final String name;
  final String size;
  final String color;
  final int quantity;
  final int unitPrice;

  const OrderItem({
    required this.name,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
  });

  int get subtotal => quantity * unitPrice;
}

class Order {
  final String id;
  final String clientName;
  final String clientEmail;
  final String channel;
  final DateTime createdAt;
  final List<OrderItem> items;
  int paid;
  OrderStatus status;

  Order({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.channel,
    required this.createdAt,
    required this.items,
    this.paid = 0,
    this.status = OrderStatus.requested,
  });

  int get total => items.fold<int>(0, (s, i) => s + i.subtotal);
  int get units => items.fold<int>(0, (s, i) => s + i.quantity);
  int get balance => total - paid;

  /// Vigencia del pedido: 1 semana.
  DateTime get expiresAt => createdAt.add(const Duration(days: 7));
  int get daysLeft => expiresAt.difference(DateTime.now()).inDays;
}