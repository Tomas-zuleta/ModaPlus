import '../models/ranked_product.dart';

enum RankPeriod { monthly, yearly }

class _Row {
  final String name;
  final String sku;
  final int month;
  final int year;
  const _Row(this.name, this.sku, this.month, this.year);
}

const List<_Row> _rows = [
  _Row('Chaqueta Utility Tech', 'JK-992-BLK', 1204, 11800),
  _Row('Pantalón Cargo Minimal', 'PT-045-GRY', 985, 9400),
  _Row('Jean Slim Fit', 'JN-210-BLU', 870, 8100),
  _Row('Camisa Oxford Beige', 'CM-330-BEI', 812, 7600),
  _Row('Buso Canguro Classic', 'BS-118-GRY', 764, 7050),
  _Row('Camiseta Básica Blanca', 'CT-101-WHT', 720, 6900),
  _Row('Vestido Lino Verde', 'VS-402-GRN', 655, 5900),
  _Row('Chaqueta Bomber Verde', 'JK-215-GRN', 610, 5500),
  _Row('Pantaloneta Deportiva', 'PN-077-BLK', 540, 5200),
  _Row('Camisa Lino Manga Larga', 'CM-347-WHT', 505, 4700),
  _Row('Buso Cuello Alto', 'BS-190-BLK', 430, 3900),
  _Row('Jean Mom Vintage', 'JN-233-LBL', 390, 3600),
  _Row('Vestido Floral Midi', 'VS-455-PNK', 210, 2100),
  _Row('Camiseta Estampada', 'CT-155-BLK', 145, 1500),
  _Row('Pantalón Lino Crudo', 'PT-088-BEI', 27, 360),
  _Row('Sudadera Classic Fit', 'SW-554-RED', 31, 410),
  _Row('Gorra Heritage Logo', 'HT-002-BLU', 24, 300),
  _Row('Chaleco Acolchado', 'JK-330-BEI', 18, 240),
  _Row('Camiseta Oversize Neón', 'TS-881-YEL', 12, 150),
  _Row('Bufanda Lana', 'AC-021-GRY', 9, 120),
];

List<RankedProduct> _sorted(RankPeriod period, {required bool desc}) {
  final list = _rows
      .map((r) => RankedProduct(
            name: r.name,
            sku: r.sku,
            units: period == RankPeriod.monthly ? r.month : r.year,
          ))
      .toList();
  list.sort((a, b) =>
      desc ? b.units.compareTo(a.units) : a.units.compareTo(b.units));
  return list.take(10).toList();
}

List<RankedProduct> topProducts(RankPeriod period) =>
    _sorted(period, desc: true);

List<RankedProduct> lowProducts(RankPeriod period) =>
    _sorted(period, desc: false);