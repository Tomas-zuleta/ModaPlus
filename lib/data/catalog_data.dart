import 'package:flutter/material.dart';

import '../models/color_producto.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/talla.dart';

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

// ---------------- Catálogo de colores (tb_colores) ----------------
const _black = ColorProducto(id: 'c_black', nombre: 'Negro', codigoHex: '1F2937');
const _white = ColorProducto(id: 'c_white', nombre: 'Blanco', codigoHex: 'F3F4F6');
const _gray = ColorProducto(id: 'c_gray', nombre: 'Gris', codigoHex: '9CA3AF');
const _blue = ColorProducto(id: 'c_blue', nombre: 'Azul', codigoHex: '3B5BA9');
const _beige = ColorProducto(id: 'c_beige', nombre: 'Beige', codigoHex: 'E5D3B3');
const _green = ColorProducto(id: 'c_green', nombre: 'Verde', codigoHex: '3B8B67');
const _pink = ColorProducto(id: 'c_pink', nombre: 'Rosado', codigoHex: 'F4B6C2');

// ---------------- Catálogo de tallas (tb_tallas) ----------------
const tXS = Talla(id: 't_xs', nombre: 'XS');
const tS = Talla(id: 't_s', nombre: 'S');
const tM = Talla(id: 't_m', nombre: 'M');
const tL = Talla(id: 't_l', nombre: 'L');
const tXL = Talla(id: 't_xl', nombre: 'XL');
const t28 = Talla(id: 't_28', nombre: '28');
const t30 = Talla(id: 't_30', nombre: '30');
const t32 = Talla(id: 't_32', nombre: '32');
const t34 = Talla(id: 't_34', nombre: '34');
const t36 = Talla(id: 't_36', nombre: '36');

const _letterSizes = [tS, tM, tL, tXL];
const _jeanSizes = [t28, t30, t32, t34, t36];
const _dressSizes = [tXS, tS, tM, tL];

/// Genera una variante (tb_variantes_pro) por cada combinación talla × color.
List<ProductVariant> _variants({
  required String productId,
  required List<Talla> sizes,
  required List<ColorProducto> colors,
  required int price,
  required int stockPerVariant,
}) {
  final list = <ProductVariant>[];
  var n = 0;
  for (final talla in sizes) {
    for (final color in colors) {
      n++;
      list.add(ProductVariant(
        id: '$productId-v$n',
        productId: productId,
        talla: talla,
        color: color,
        precioVenta: price,
        stockActual: stockPerVariant,
        stockMinimo: 3,
        stockMaximo: stockPerVariant * 3,
      ));
    }
  }
  return list;
}

final List<Product> catalogProducts = [
  Product(
    id: 'p01',
    idCategoria: 'cat_camisas',
    category: 'Camisas',
    referencia: 'CM-330-BEI',
    name: 'Camisa Oxford Beige',
    description: 'Camisa de algodón con corte regular y cuello clásico. '
        'Ideal para la oficina o para salidas casuales.',
    tone: const Color(0xFFD9C7A3),
     photos: ['assets/images/camiseta-blanca.jpg'],
    variants: _variants(
      productId: 'p01',
      sizes: _letterSizes,
      colors: [_beige, _white, _blue],
      price: 99000,
      stockPerVariant: 6,
    ),
  ),
  Product(
    id: 'p02',
    idCategoria: 'cat_camisas',
    category: 'Camisas',
    referencia: 'CM-347-WHT',
    name: 'Camisa Lino Manga Larga',
    description: 'Lino fresco y ligero, perfecto para climas cálidos. '
        'Acabado arrugado natural.',
    tone: const Color(0xFFCFC6B5),
     photos: ['assets/images/camiseta-blanca.jpg'],
    variants: _variants(
      productId: 'p02',
      sizes: _letterSizes,
      colors: [_white, _beige],
      price: 109000,
      stockPerVariant: 5,
    ),
  ),
  Product(
    id: 'p03',
    idCategoria: 'cat_camisetas',
    category: 'Camisetas',
    referencia: 'CT-101-WHT',
    name: 'Camiseta Básica Blanca',
    description: 'Camiseta de algodón peinado, cuello redondo y ajuste '
        'cómodo. Un básico para todos los días.',
    tone: const Color(0xFFB8BDD0),
    photos: ['assets/images/camiseta-blanca.jpg'],
    variants: _variants(
      productId: 'p03',
      sizes: _letterSizes,
      colors: [_white, _black, _gray],
      price: 45000,
      stockPerVariant: 10,
    ),
  ),
  Product(
    id: 'p04',
    idCategoria: 'cat_camisetas',
    category: 'Camisetas',
    referencia: 'CT-155-BLK',
    name: 'Camiseta Estampada',
    description: 'Camiseta oversize con estampado frontal de edición '
        'limitada.',
    tone: const Color(0xFF6B7280),
    photos: ['assets/images/camisetaestampada.jpg'],
    variants: _variants(
      productId: 'p04',
      sizes: _letterSizes,
      colors: [_black, _white],
      price: 59000,
      stockPerVariant: 6,
    ),
  ),
  Product(
    id: 'p05',
    idCategoria: 'cat_pantalones',
    category: 'Pantalones',
    referencia: 'PT-045-GRY',
    name: 'Pantalón Cargo Minimal',
    description: 'Pantalón cargo de corte recto con bolsillos laterales '
        'discretos. Tela resistente y cómoda.',
    tone: const Color(0xFF7C8794),
    photos: ['assets/images/pantalon.jpg'],
    variants: _variants(
      productId: 'p05',
      sizes: _jeanSizes,
      colors: [_gray, _black, _green],
      price: 139000,
      stockPerVariant: 4,
    ),
  ),
  Product(
    id: 'p06',
    idCategoria: 'cat_pantalones',
    category: 'Pantalones',
    referencia: 'JN-210-BLU',
    name: 'Jean Slim Fit',
    description: 'Jean de mezclilla elástica con corte ajustado. '
        'Comodidad y estilo en un solo producto.',
    tone: const Color(0xFF3B5BA9),
  photos: ['assets/images/jeanslim.jpg'],
    variants: _variants(
      productId: 'p06',
      sizes: _jeanSizes,
      colors: [_blue, _black],
      price: 129000,
      stockPerVariant: 7,
    ),
  ),
  Product(
    id: 'p07',
    idCategoria: 'cat_pantalones',
    category: 'Pantalones',
    referencia: 'JN-233-LBL',
    name: 'Jean Mom Vintage',
    description: 'Tiro alto y pierna recta con lavado vintage. '
        'Un clásico que nunca pasa de moda.',
    tone: const Color(0xFF7D9BD1),
   photos: ['assets/images/jeanmom.jpg'],
    variants: _variants(
      productId: 'p07',
      sizes: _jeanSizes,
      colors: [_blue, _gray],
      price: 135000,
      stockPerVariant: 4,
    ),
  ),
  Product(
    id: 'p08',
    idCategoria: 'cat_chaquetas',
    category: 'Chaquetas',
    referencia: 'JK-992-BLK',
    name: 'Chaqueta Utility Tech',
    description: 'Chaqueta técnica con bolsillos funcionales y cierre '
        'frontal. Repele el agua ligera.',
    tone: const Color(0xFF1F2937),
   photos: ['assets/images/chaqueta.jpg'],
    variants: _variants(
      productId: 'p08',
      sizes: _letterSizes,
      colors: [_black, _green, _gray],
      price: 189000,
      stockPerVariant: 3,
    ),
  ),
  Product(
    id: 'p09',
    idCategoria: 'cat_chaquetas',
    category: 'Chaquetas',
    referencia: 'JK-215-GRN',
    name: 'Chaqueta Bomber Verde',
    description: 'Bomber clásica con puños acanalados y forro interior '
        'suave.',
    tone: const Color(0xFF1F4D3A),
    photos: ['assets/images/chaquetabomberverde.jpg'],
    variants: _variants(
      productId: 'p09',
      sizes: _letterSizes,
      colors: [_green, _black],
      price: 175000,
      stockPerVariant: 3,
    ),
  ),
  Product(
    id: 'p10',
    idCategoria: 'cat_busos',
    category: 'Busos',
    referencia: 'BS-118-GRY',
    name: 'Buso Canguro Classic',
    description: 'Buso con capota y bolsillo canguro en felpa suave. '
        'Calidez y comodidad.',
    tone: const Color(0xFF9CA3AF),
     photos: ['assets/images/busocanguro.jpg'],
    variants: _variants(
      productId: 'p10',
      sizes: _letterSizes,
      colors: [_gray, _black, _beige],
      price: 119000,
      stockPerVariant: 6,
    ),
  ),
  Product(
    id: 'p11',
    idCategoria: 'cat_busos',
    category: 'Busos',
    referencia: 'BS-190-BLK',
    name: 'Buso Cuello Alto',
    description: 'Buso de punto fino con cuello alto. Perfecto para '
        'combinar con chaquetas.',
    tone: const Color(0xFF374151),
    photos: ['assets/images/busocuelloalto.jpg'],
    variants: _variants(
      productId: 'p11',
      sizes: _letterSizes,
      colors: [_black, _beige],
      price: 95000,
      stockPerVariant: 6,
    ),
  ),
  Product(
    id: 'p12',
    idCategoria: 'cat_vestidos',
    category: 'Vestidos',
    referencia: 'VS-402-GRN',
    name: 'Vestido Lino Verde',
    description: 'Vestido de lino con corte en A y tirantes ajustables. '
        'Elegancia fresca para el día.',
    tone: const Color(0xFF5FA37F),
     photos: ['assets/images/vestido.jpg'],
    variants: _variants(
      productId: 'p12',
      sizes: _dressSizes,
      colors: [_green, _beige],
      price: 159000,
      stockPerVariant: 4,
    ),
  ),
  Product(
    id: 'p13',
    idCategoria: 'cat_vestidos',
    category: 'Vestidos',
    referencia: 'VS-455-PNK',
    name: 'Vestido Floral Midi',
    description: 'Vestido midi con estampado floral y falda con vuelo. '
        'Ideal para ocasiones especiales.',
    tone: const Color(0xFFE59AAE),
     photos: ['assets/images/vestidofloral.jpg'],
    variants: _variants(
      productId: 'p13',
      sizes: _dressSizes,
      colors: [_pink, _white],
      price: 145000,
      stockPerVariant: 4,
    ),
  ),
];