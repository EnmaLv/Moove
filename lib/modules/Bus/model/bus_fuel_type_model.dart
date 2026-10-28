class BusTipoCombustible {
  final int id;
  final String nombre;
  final String descripcion;
  final bool estado;

  const BusTipoCombustible({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
  });

  factory BusTipoCombustible.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? j['id_tcb'];
    final rawNombre = j['nombre'] ?? j['nombre_tcb'] ?? '';
    final rawDesc = j['descripcion'] ?? j['descripcion_tcb'] ?? 'Ninguna';
    final rawEstado = j['estado'] ?? j['status_id'];

    return BusTipoCombustible(
      id: _toInt(rawId),
      nombre: rawNombre.toString(),
      descripcion: rawDesc.toString(),
      estado: rawEstado == true || rawEstado == 1,
    );
  }

  BusTipoCombustible copyWith(
          {String? nombre, String? descripcion, bool? estado}) =>
      BusTipoCombustible(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        estado: estado ?? this.estado,
      );

  static int _toInt(dynamic v) =>
      v is int ? v : int.parse(v?.toString() ?? '0');
}