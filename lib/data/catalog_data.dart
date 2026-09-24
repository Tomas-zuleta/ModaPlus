import 'package:flutter/material.dart';

import '../models/product.dart';

const List<String> categories = [
  'Camisas',
  'Camisetas',
  'Pantalones',
  'Chaquetas',
  'Busos',
  'Vestidos',
];

IconData categoryIcon(String category) {
  switch (category) {
    case 'Camisas':
      return Icons.checkroom;
    case 'Camisetas':
      return Icons.dry_cleaning_outlined;
    case 'Pantalones':
      return Icons.accessibility_new;
    case 'Chaquetas':
      return Icons.dry_cleaning;
    case 'Busos':
      return Icons.layers_outlined;
    default:
      return Icons.woman;
  }
}

const _black = ProductColor('Negro', Color(0xFF1F2937));
const _white = ProductColor('Blanco', Color(0xFFF3F4F6));
const _gray = ProductColor('Gris', Color(0xFF9CA3AF));
const _blue = ProductColor('Azul', Color(0xFF3B5BA9));
const _beige = ProductColor('Beige', Color(0xFFE5D3B3));
const _green = ProductColor('Verde', Color(0xFF3B8B67));
const _pink = ProductColor('Rosado', Color(0xFFF4B6C2));

const _letterSizes = ['S', 'M', 'L', 'XL'];
const _jeanSizes = ['28', '30', '32', '34', '36'];
const _dressSizes = ['XS', 'S', 'M', 'L'];

const List<Product> catalogProducts = [
  Product(
    id: 'p01',
    name: 'Camisa Oxford Beige',
    sku: 'CM-330-BEI',
    category: 'Camisas',
    price: 99000,
    stock: 24,
    description: 'Camisa de algodón con corte regular y cuello clásico. '
        'Ideal para la oficina o para salidas casuales.',
    sizes: _letterSizes,
    colors: [_beige, _white, _blue],
    tone: Color(0xFFD9C7A3),
  ),
  Product(
    id: 'p02',
    name: 'Camisa Lino Manga Larga',
    sku: 'CM-347-WHT',
    category: 'Camisas',
    price: 109000,
    stock: 18,
    description: 'Lino fresco y ligero, perfecto para climas cálidos. '
        'Acabado arrugado natural.',
    sizes: _letterSizes,
    colors: [_white, _beige],
    tone: Color(0xFFCFC6B5),
  ),
  Product(
    id: 'p03',
    name: 'Camiseta Básica Blanca',
    sku: 'CT-101-WHT',
    category: 'Camisetas',
    price: 45000,
    stock: 60,
    description: 'Camiseta de algodón peinado, cuello redondo y ajuste '
        'cómodo. Un básico para todos los días.',
    sizes: _letterSizes,
    colors: [_white, _black, _gray],
    tone: Color(0xFFB8BDD0),
  ),
  Product(
    id: 'p04',
    name: 'Camiseta Estampada',
    sku: 'CT-155-BLK',
    category: 'Camisetas',
    price: 59000,
    stock: 30,
    description: 'Camiseta oversize con estampado frontal de edición '
        'limitada.',
    sizes: _letterSizes,
    colors: [_black, _white],
    tone: Color(0xFF6B7280),
  ),
  Product(
    id: 'p05',
    name: 'Pantalón Cargo Minimal',
    sku: 'PT-045-GRY',
    category: 'Pantalones',
    price: 139000,
    stock: 20,
    description: 'Pantalón cargo de corte recto con bolsillos laterales '
        'discretos. Tela resistente y cómoda.',
    sizes: _jeanSizes,
    colors: [_gray, _black, _green],
    tone: Color(0xFF7C8794),
  ),
  Product(
    id: 'p06',
    name: 'Jean Slim Fit',
    sku: 'JN-210-BLU',
    category: 'Pantalones',
    price: 129000,
    stock: 35,
    description: 'Jean de mezclilla elástica con corte ajustado. '
        'Comodidad y estilo en un solo producto.',
    sizes: _jeanSizes,
    colors: [_blue, _black],
    tone: Color(0xFF3B5BA9),
  ),
  Product(
    id: 'p07',
    name: 'Jean Mom Vintage',
    sku: 'JN-233-LBL',
    category: 'Pantalones',
    price: 135000,
    stock: 22,
    description: 'Tiro alto y pierna recta con lavado vintage. '
        'Un clásico que nunca pasa de moda.',
    sizes: _jeanSizes,
    colors: [_blue, _gray],
    tone: Color(0xFF7D9BD1),
  ),
  Product(
    id: 'p08',
    name: 'Chaqueta Utility Tech',
    sku: 'JK-992-BLK',
    category: 'Chaquetas',
    price: 189000,
    stock: 15,
    description: 'Chaqueta técnica con bolsillos funcionales y cierre '
        'frontal. Repele el agua ligera.',
    sizes: _letterSizes,
    colors: [_black, _green, _gray],
    tone: Color(0xFF1F2937),
  ),
  Product(
    id: 'p09',
    name: 'Chaqueta Bomber Verde',
    sku: 'JK-215-GRN',
    category: 'Chaquetas',
    price: 175000,
    stock: 12,
    description: 'Bomber clásica con puños acanalados y forro interior '
        'suave.',
    sizes: _letterSizes,
    colors: [_green, _black],
    tone: Color(0xFF1F4D3A),
  ),
  Product(
    id: 'p10',
    name: 'Buso Canguro Classic',
    sku: 'BS-118-GRY',
    category: 'Busos',
    price: 119000,
    stock: 28,
    description: 'Buso con capota y bolsillo canguro en felpa suave. '
        'Calidez y comodidad.',
    sizes: _letterSizes,
    colors: [_gray, _black, _beige],
    tone: Color(0xFF9CA3AF),
  ),
  Product(
    id: 'p11',
    name: 'Buso Cuello Alto',
    sku: 'BS-190-BLK',
    category: 'Busos',
    price: 95000,
    stock: 26,
    description: 'Buso de punto fino con cuello alto. Perfecto para '
        'combinar con chaquetas.',
    sizes: _letterSizes,
    colors: [_black, _beige],
    tone: Color(0xFF374151),
  ),
  Product(
    id: 'p12',
    name: 'Vestido Lino Verde',
    sku: 'VS-402-GRN',
    category: 'Vestidos',
    price: 159000,
    stock: 14,
    description: 'Vestido de lino con corte en A y tirantes ajustables. '
        'Elegancia fresca para el día.',
    sizes: _dressSizes,
    colors: [_green, _beige],
    tone: Color(0xFF5FA37F),
  ),
  Product(
    id: 'p13',
    name: 'Vestido Floral Midi',
    sku: 'VS-455-PNK',
    category: 'Vestidos',
    price: 145000,
    stock: 16,
    description: 'Vestido midi con estampado floral y falda con vuelo. '
        'Ideal para ocasiones especiales.',
    sizes: _dressSizes,
    colors: [_pink, _white],
    tone: Color(0xFFE59AAE),
  ),
];