import 'package:flutter/material.dart';

class ColorProducto {
  final String id;
  final String nombre;
  final String codigoHex;

  const ColorProducto({
    required this.id,
    required this.nombre,
    required this.codigoHex,
  });

  Color get color {
    final hex = codigoHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  bool operator ==(Object other) => other is ColorProducto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}