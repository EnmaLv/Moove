class BusMarca {
  final int id;
  final String nombre;
  final bool estado;

  const BusMarca({
    required this.id,
    required this.nombre,
    required this.estado,
  });

  factory BusMarca.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? j['id_mav'];
    final rawNombre = j['nombre'] ?? j['nombre_mav'] ?? '';
    final rawEstado = j['estado'] ?? j['status_id'];

    return BusMarca(
      id: _toInt(rawId),
      nombre: rawNombre.toString(),
      estado: rawEstado == true || rawEstado == 1,
    );
  }

  BusMarca copyWith({String? nombre, bool? estado}) => BusMarca(
        id: id,
        nombre: nombre ?? this.nombre,
        estado: estado ?? this.estado,
      );

  static int _toInt(dynamic v) =>
      v is int ? v : int.parse(v?.toString() ?? '0');
}