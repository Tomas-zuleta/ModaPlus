class Talla {
  final String id;
  final String nombre;

  const Talla({required this.id, required this.nombre});

  @override
  bool operator ==(Object other) => other is Talla && other.id == id;

  @override
  int get hashCode => id.hashCode;
}