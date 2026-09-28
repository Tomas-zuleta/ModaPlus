import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/plan_separe.dart';
import '../models/user_role.dart';
import '../models/user_session.dart';

class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  UserSession? session;
  final List<PlanSepare> plans = [];
  final List<Order> orders = [];
  final List<CartItem> cart = [];

  void startSession({
    required String name,
    required String email,
    required UserRole role,
  }) {
    final parts = name.trim().split(RegExp(r'\s+'));
    session = UserSession(
      nombres: parts.isEmpty ? name : parts.first,
      apellidos: parts.length > 1 ? parts.skip(1).join(' ') : '',
      email: email,
      role: role,
      fechaCreacion: DateTime.now(),
    );
    notifyListeners();
  }

  void registerSession({
    required String nombres,
    required String apellidos,
    required String identificacion,
    required String phone,
    required String email,
    required UserRole role,
  }) {
    session = UserSession(
      nombres: nombres,
      apellidos: apellidos,
      identificacion: identificacion,
      phone: phone,
      email: email,
      role: role,
      fechaCreacion: DateTime.now(),
    );
    notifyListeners();
  }

  void endSession() {
    session = null;
    cart.clear();
    notifyListeners();
  }

  void updateProfile({
    required String nombres,
    required String apellidos,
    required String phone,
    required String direccion,
    String? identificacion,
  }) {
    final current = session;
    if (current == null) return;
    session = current.copyWith(
      nombres: nombres,
      apellidos: apellidos,
      phone: phone,
      direccion: direccion,
      identificacion: identificacion,
    );
    notifyListeners();
  }

  int get activePlansCount => plans.where((plan) => plan.isActive).length;
  int get retainedAmount =>
      plans.where((plan) => plan.isActive).fold(0, (sum, plan) => sum + plan.paid);

  String nextPlanId() {
    final highest = plans.fold<int>(0, (max, plan) {
      final number = int.tryParse(plan.id.replaceFirst('PS-', '')) ?? 0;
      return number > max ? number : max;
    });
    return 'PS-${(highest + 1).toString().padLeft(3, '0')}';
  }

  PlanSepare createPlan({
    required String clientName,
    required String clientDoc,
    required List<PlanItem> items,
    int initialPayment = 0,
    String clientEmail = '',
  }) {
    if (clientName.trim().isEmpty || clientDoc.trim().isEmpty || items.isEmpty) {
      throw ArgumentError('Completa los datos del cliente y agrega productos.');
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    if (initialPayment < 0 || initialPayment > total) {
      throw ArgumentError.value(initialPayment, 'initialPayment');
    }

    final now = DateTime.now();
    final plan = PlanSepare(
      id: nextPlanId(),
      clientName: clientName.trim(),
      clientDoc: clientDoc.trim(),
      clientEmail: clientEmail,
      createdAt: now,
      items: List<PlanItem>.unmodifiable(items),
      abonos: initialPayment == 0
          ? []
          : [Abono(now, initialPayment)],
    );
    plans.insert(0, plan);
    notifyListeners();
    return plan;
  }

  PlanSepare createPlanFromCart({
    required int initialDeposit,
    required String method,
    required String clientDoc,
    Uint8List? voucherBytes,
  }) {
    if (cart.isEmpty) throw StateError('El carrito está vacío.');
    final plan = createPlan(
      clientName: session?.name ?? 'Cliente',
      clientDoc: clientDoc,
      clientEmail: session?.email ?? '',
      items: cart
          .map(
            (item) => PlanItem(
              name: item.product.name,
              size: item.variant.talla.nombre,
              color: item.variant.color.nombre,
              quantity: item.quantity,
              unitPrice: item.variant.precioVenta,
            ),
          )
          .toList(),
      initialPayment: initialDeposit,
    );
    if (initialDeposit > 0 && plan.abonos.isNotEmpty) {
      final payment = plan.abonos.first;
      plan.abonos[0] = Abono(
        payment.date,
        payment.amount,
        method: method,
        voucherBytes: voucherBytes,
      );
    }
    cart.clear();
    notifyListeners();
    return plan;
  }

  void addAbono(
    PlanSepare plan,
    int amount, {
    String method = 'Efectivo',
    Uint8List? voucherBytes,
  }) {
    plan.addPayment(amount, method: method, voucherBytes: voucherBytes);
    notifyListeners();
  }

  void removeAbono(PlanSepare plan, Abono abono) {
    plan.abonos.remove(abono);
    if (plan.status == PlanStatus.completed) plan.status = PlanStatus.active;
    notifyListeners();
  }

  void annulPlan(PlanSepare plan) {
    plan.annulNote = plan.annulOutcome;
    plan.status = PlanStatus.cancelled;
    notifyListeners();
  }

  List<MapEntry<PlanSepare, Abono>> get allAbonos {
    final result = <MapEntry<PlanSepare, Abono>>[];
    for (final plan in plans) {
      for (final abono in plan.abonos) {
        result.add(MapEntry(plan, abono));
      }
    }
    result.sort((a, b) => b.value.date.compareTo(a.value.date));
    return result;
  }

  String nextOrderId() => 'PED-${1000 + orders.length + 1}';

  int get pendingOrdersCount => orders
      .where(
        (order) =>
            order.status == OrderStatus.requested ||
            order.status == OrderStatus.verification,
      )
      .length;

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

  void attachVoucher(
    Order order, {
    required String paymentAccountId,
    required Uint8List bytes,
    required String fileName,
  }) {
    order.paymentAccountId = paymentAccountId;
    order.voucherBytes = bytes;
    order.voucherFileName = fileName;
    order.voucherSentAt = DateTime.now();
    notifyListeners();
  }

  int get cartCount => cart.fold<int>(0, (sum, item) => sum + item.quantity);
  int get cartTotal => cart.fold<int>(0, (sum, item) => sum + item.subtotal);

  void addToCart(CartItem item) {
    final index = cart.indexWhere((current) => current.sameLine(item));
    if (index == -1) {
      cart.add(item);
    } else {
      final max = item.variant.stockActual;
      cart[index].quantity =
          (cart[index].quantity + item.quantity).clamp(1, max);
    }
    notifyListeners();
  }

  void setCartQuantity(CartItem item, int quantity) {
    if (quantity < 1) return;
    item.quantity = quantity.clamp(1, item.variant.stockActual);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    notifyListeners();
  }

  Order placeOrder({
    String method = 'Pago en tienda',
    String? accountId,
    Uint8List? voucherBytes,
  }) {
    if (cart.isEmpty) throw StateError('El carrito está vacío.');
    final now = DateTime.now();
    final items = cart
        .map(
          (item) => OrderItem(
            name: item.product.name,
            size: item.variant.talla.nombre,
            color: item.variant.color.nombre,
            quantity: item.quantity,
            unitPrice: item.variant.precioVenta,
          ),
        )
        .toList();
    final order = Order(
      id: nextOrderId(),
      clientName: session?.name ?? 'Cliente',
      clientEmail: session?.email ?? '',
      channel: 'App móvil',
      createdAt: now,
      items: items,
      paid: items.fold<int>(0, (sum, item) => sum + item.subtotal),
      status: OrderStatus.paid,
      paymentMethod: method,
      paymentAccountId: accountId,
      voucherBytes: voucherBytes,
      voucherSentAt: voucherBytes == null ? null : now,
    );
    orders.insert(0, order);
    cart.clear();
    notifyListeners();
    return order;
  }
}