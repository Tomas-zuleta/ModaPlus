import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import 'primary_button.dart';
import 'product_image.dart';
import '../pages/cart_page.dart';

/// Confirmación de carrito con resumen y acciones claras.
Future<void> showCartAddedSheet(BuildContext context, Product product, int quantity) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(
          color: AppColors.panelBorder, borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 22),
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.acid.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26)),
          const SizedBox(width: 12),
          const Expanded(child: Text('¡AGREGADO AL CARRITO!', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark))),
          IconButton(onPressed: () => Navigator.pop(sheetContext),
            icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 92, height: 112, child: ProductImage(product: product))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text('Cantidad: $quantity', style: const TextStyle(color: AppColors.slate)),
            const SizedBox(height: 7),
            Text(formatCop(product.price * quantity),
              style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w800)),
          ])),
        ]),
        const SizedBox(height: 23),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(15)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL EN TU CARRITO', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .6)),
            Text(formatCop(AppStore.instance.cartTotal), style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ])),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Ver carrito', onPressed: () => Navigator.pop(sheetContext, true)),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: () => Navigator.pop(sheetContext),
          child: const Text('SEGUIR COMPRANDO', style: TextStyle(
            decoration: TextDecoration.underline, color: AppColors.textDark,
            fontWeight: FontWeight.w800, letterSpacing: 1)))),
      ]),
    ),
  ).then((result) {
    if (result == true && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const CartPage()));
    }
  });
}
