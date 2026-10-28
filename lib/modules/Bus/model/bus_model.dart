class BusModelo {
  final int id;
  final int marcaId;
  final String marcaNombre;
  final String nombre;
  final bool estado;

  const BusModelo({
    required this.id,
    required this.marcaId,
    required this.marcaNombre,
    required this.nombre,
    required this.estado,
  });

  factory BusModelo.fromJson(Map<String, dynamic> j) {
    // 1. Clonamos el mapa para evitar problemas de herencia en Web
    final Map<String, dynamic> json = Map<String, dynamic>.from(j);

    // 2. Parseo seguro de los IDs y Nombre principal
    int idFinal = 0;
    if (json['id'] != null) {
      idFinal = int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['id_mov'] != null) {
      idFinal = int.tryParse(json['id_mov'].toString()) ?? 0;
    }

    int marcaIdFinal = 0;
    if (json['marca_id'] != null) {
      marcaIdFinal = int.tryParse(json['marca_id'].toString()) ?? 0;
    } else if (json['mav_id'] != null) {
      marcaIdFinal = int.tryParse(json['mav_id'].toString()) ?? 0;
    }

    final String nombreFinal = json['nombre']?.toString() ?? json['nombre_mov']?.toString() ?? '';
    final bool estadoFinal = json['estado'] == true || json['estado'] == 1 || json['status_id'] == 1;

    // 3. Parseo seguro del objeto anidado "marca"
    String marcaNombreFinal = '';
    final dynamic rawMarca = json['marca'] ?? json['marca_vehiculo'];
    
    if (rawMarca != null && rawMarca is Map) {
      // Al no especificar <String, dynamic> en el cast a Map, evitamos el crash de Web
      final Map<dynamic, dynamic> marcaMap = rawMarca as Map;
      
      marcaNombreFinal = marcaMap['nombre']?.toString() ?? marcaMap['nombre_mav']?.toString() ?? '';
      
      // Si el ID de la marca vino nulo arriba, lo sacamos del mapa anidado
      if (marcaIdFinal == 0) {
        marcaIdFinal = int.tryParse((marcaMap['id'] ?? marcaMap['id_mav'] ?? 0).toString()) ?? 0;
      }
    }

    return BusModelo(
      id: idFinal,
      marcaId: marcaIdFinal,
      marcaNombre: marcaNombreFinal,
      nombre: nombreFinal,
      estado: estadoFinal,
    );
  }

  BusModelo copyWith({
    String? nombre,
    bool? estado,
    String? marcaNombre,
    int? marcaId,
  }) =>
      BusModelo(
        id: id,
        marcaId: marcaId ?? this.marcaId,
        marcaNombre: marcaNombre ?? this.marcaNombre,
        nombre: nombre ?? this.nombre,
        estado: estado ?? this.estado,
      );
}