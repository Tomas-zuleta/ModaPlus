import 'package:flutter/foundation.dart';
import 'package:modaplus/widgets/user_session.dart';
import '../models/cart_item.dart';

import '../models/order.dart';
import '../models/plan_separe.dart';
import '../models/user_role.dart';
import '../models/user_session.dart';

class AppStore extends ChangeNotifier {
  AppStore._() {
    _seed();
  }
  static final AppStore instance = AppStore._();

  UserSession? session;
  final List<PlanSepare> plans = [];
  final List<Order> orders = [];

  // ---------------- Sesión ----------------
  void startSession({
    required String name,
    required String email,
    required UserRole role,
  }) {
    session = UserSession(name: name, email: email, role: role);
    notifyListeners();
  }

  void endSession() {
    session = null;
    notifyListeners();
    void endSession() {
  session = null;
  cart.clear();
  notifyListeners();
}
  }

  void updateProfile({required String name, required String phone}) {
    if (session == null) return;
    session = session!.copyWith(name: name, phone: phone);
    notifyListeners();
  }

  // ---------------- Plan separe ----------------
  int get activePlansCount => plans.where((p) => p.isActive).length;

  int get retainedAmount =>
      plans.where((p) => p.isActive).fold<int>(0, (s, p) => s + p.paid);

  void annulPlan(PlanSepare plan) {
    plan.annulNote = plan.annulOutcome;
    plan.status = PlanStatus.cancelled;
    notifyListeners();
  }

  // ---------------- Pedidos ----------------
  String nextOrderId() => 'PED-${1000 + orders.length + 1}';

  void addOrder(Order order) {
    orders.insert(0, order);
    notifyListeners();
  }

  void changeOrderStatus(Order order, OrderStatus status, {int? paid}) {
    order.status = status;
    if (status == OrderStatus.paid) order.paid = order.total;
    if (status == OrderStatus.partial && paid != null) order.paid = paid;
    notifyListeners();
  }
    // ---------------- Carrito ----------------
  final List<CartItem> cart = [];

  int get cartCount => cart.fold<int>(0, (s, i) => s + i.quantity);
  int get cartTotal => cart.fold<int>(0, (s, i) => s + i.subtotal);

  void addToCart(CartItem item) {
    final index = cart.indexWhere((c) => c.sameLine(item));
    if (index >= 0) {
      final merged = cart[index].quantity + item.quantity;
      cart[index].quantity =
          merged > item.product.stock ? item.product.stock : merged;
    } else {
      cart.add(item);
    }
    notifyListeners();
  }

  void setCartQuantity(CartItem item, int quantity) {
    if (quantity < 1) return;
    item.quantity = quantity > item.product.stock ? item.product.stock : quantity;
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    notifyListeners();
  }

  /// Convierte el carrito en un pedido (queda visible para el administrador).
  Order placeOrder() {
    final order = Order(
      id: nextOrderId(),
      clientName: session?.name ?? 'Cliente',
      clientEmail: session?.email ?? '',
      channel: 'App móvil',
      createdAt: DateTime.now(),
      items: cart
          .map((c) => OrderItem(
                name: c.product.name,
                size: c.size,
                color: c.color.name,
                quantity: c.quantity,
                unitPrice: c.product.price,
              ))
          .toList(),
    );
    orders.insert(0, order);
    cart.clear();
    notifyListeners();
    return order;
  }

  // ---------------- Datos de ejemplo ----------------
  void _seed() {
    final now = DateTime.now();
    DateTime ago(int days) => now.subtract(Duration(days: days));

    plans.addAll([
      PlanSepare(
        id: 'PS-001',
        clientName: 'María Fernanda Ríos',
        clientDoc: '1.037.482.910',
        createdAt: ago(40),
        items: const [
          PlanItem(name: 'Chaqueta Utility Tech', size: 'M', color: 'Negro', quantity: 1, unitPrice: 189000),
        ],
        abonos: [Abono(ago(40), 20000), Abono(ago(25), 60000), Abono(ago(10), 50000)],
      ),
      PlanSepare(
        id: 'PS-002',
        clientName: 'Carlos Andrés Zapata',
        clientDoc: '98.765.432',
        createdAt: ago(12),
        items: const [
          PlanItem(name: 'Jean Slim Fit', size: '32', color: 'Azul', quantity: 2, unitPrice: 129000),
        ],
        abonos: [Abono(ago(12), 40000)],
      ),
      PlanSepare(
        id: 'PS-003',
        clientName: 'Laura Gómez',
        clientDoc: '1.152.334.881',
        createdAt: ago(55),
        items: const [
          PlanItem(name: 'Vestido Lino Verde', size: 'S', color: 'Verde', quantity: 1, unitPrice: 159000),
        ],
        abonos: [Abono(ago(55), 20000), Abono(ago(30), 30000)],
      ),
      PlanSepare(
        id: 'PS-004',
        clientName: 'Andrés Felipe Mora',
        clientDoc: '71.335.209',
        createdAt: ago(20),
        items: const [
          PlanItem(name: 'Buso Canguro Classic', size: 'L', color: 'Gris', quantity: 1, unitPrice: 119000),
          PlanItem(name: 'Camisa Oxford Beige', size: 'M', color: 'Beige', quantity: 1, unitPrice: 99000),
        ],
        abonos: [Abono(ago(20), 40000), Abono(ago(8), 80000)],
      ),
    ]);

    final cancelled = PlanSepare(
      id: 'PS-005',
      clientName: 'Sofía Herrera',
      clientDoc: '1.020.445.671',
      createdAt: ago(65),
      status: PlanStatus.cancelled,
      items: const [
        PlanItem(name: 'Pantalón Cargo Minimal', size: '30', color: 'Gris', quantity: 1, unitPrice: 139000),
      ],
      abonos: [Abono(ago(65), 20000), Abono(ago(50), 30000)],
    );
    cancelled.annulNote = cancelled.annulOutcome;
    plans.add(cancelled);

    orders.addAll([
      Order(
        id: 'PED-1001',
        clientName: 'Valentina Ospina',
        clientEmail: 'valentina@correo.com',
        channel: 'Web',
        createdAt: ago(1),
        items: const [
          OrderItem(name: 'Camisa Oxford Beige', size: 'M', color: 'Beige', quantity: 2, unitPrice: 99000),
        ],
      ),
      Order(
        id: 'PED-1002',
        clientName: 'Juan Pablo Cardona',
        clientEmail: 'juan@correo.com',
        channel: 'App móvil',
        createdAt: ago(3),
        paid: 100000,
        status: OrderStatus.partial,
        items: const [
          OrderItem(name: 'Jean Slim Fit', size: '32', color: 'Azul', quantity: 1, unitPrice: 129000),
          OrderItem(name: 'Camiseta Básica Blanca', size: 'M', color: 'Blanco', quantity: 2, unitPrice: 45000),
        ],
      ),
      Order(
        id: 'PED-1003',
        clientName: 'Daniela Restrepo',
        clientEmail: 'daniela@correo.com',
        channel: 'Web',
        createdAt: ago(2),
        paid: 189000,
        status: OrderStatus.paid,
        items: const [
          OrderItem(name: 'Chaqueta Utility Tech', size: 'M', color: 'Negro', quantity: 1, unitPrice: 189000),
        ],
      ),
      Order(
        id: 'PED-1004',
        clientName: 'Santiago Builes',
        clientEmail: 'santiago@correo.com',
        channel: 'App móvil',
        createdAt: ago(6),
        items: const [
          OrderItem(name: 'Buso Canguro Classic', size: 'L', color: 'Gris', quantity: 1, unitPrice: 119000),
        ],
      ),
      Order(
        id: 'PED-1005',
        clientName: 'Camila Torres',
        clientEmail: 'camila@correo.com',
        channel: 'Web',
        createdAt: ago(9),
        paid: 159000,
        status: OrderStatus.delivered,
        items: const [
          OrderItem(name: 'Vestido Lino Verde', size: 'S', color: 'Verde', quantity: 1, unitPrice: 159000),
        ],
      ),
      Order(
        id: 'PED-1006',
        clientName: 'Mateo Arango',
        clientEmail: 'mateo@correo.com',
        channel: 'Web',
        createdAt: ago(12),
        status: OrderStatus.cancelled,
        items: const [
          OrderItem(name: 'Pantalón Cargo Minimal', size: '32', color: 'Gris', quantity: 1, unitPrice: 139000),
        ],
      ),
    ]);
  }
}