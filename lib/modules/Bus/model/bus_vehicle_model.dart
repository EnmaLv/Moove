class BusVehiculo {
  final int id;
  final String placa;
  final int modeloId;
  final String modeloNombre;
  final String marcaNombre;
  final int anio;
  final String color;
  final int peso;
  final int cantidadPasajeros;
  final int tipoCombustibleId;
  final String combustibleNombre;
  final int cantidadBocas;
  final double capacidadTanqueLitros;
  final double consumoLitrosKm;
  final double kmActual;
  final double kmProximoMantenimiento;
  final int? conductorId;
  final int sedeId;
  final String sedeNombre;
  final bool activo;
  final String estado;

  const BusVehiculo({
    required this.id,
    required this.placa,
    required this.modeloId,
    required this.modeloNombre,
    required this.marcaNombre,
    required this.anio,
    required this.color,
    required this.peso,
    required this.cantidadPasajeros,
    required this.tipoCombustibleId,
    required this.combustibleNombre,
    required this.cantidadBocas,
    required this.capacidadTanqueLitros,
    required this.consumoLitrosKm,
    required this.kmActual,
    required this.kmProximoMantenimiento,
    this.conductorId,
    required this.sedeId,
    required this.sedeNombre,
    required this.activo,
    required this.estado,
  });

    factory BusVehiculo.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // Conversiones seguras
    final dynamic rawModelo = j['modelo'] ?? j['modelo_vehiculo'];
    final Map<String, dynamic> modelo = rawModelo is Map 
        ? Map<String, dynamic>.from(rawModelo) 
        : <String, dynamic>{};

    final dynamic rawMarca = modelo['marca'] ?? modelo['marca_vehiculo'];
    final Map<String, dynamic> marca = rawMarca is Map 
        ? Map<String, dynamic>.from(rawMarca) 
        : <String, dynamic>{};

    final dynamic rawTipoComb = j['tipo_combustible'];
    final Map<String, dynamic> tipoComb = rawTipoComb is Map 
        ? Map<String, dynamic>.from(rawTipoComb) 
        : <String, dynamic>{};

    final dynamic rawSede = j['sede'];
    final Map<String, dynamic> sede = rawSede is Map 
        ? Map<String, dynamic>.from(rawSede) 
        : <String, dynamic>{};

    final rawActivo = j['activo'] ?? j['status_id'];

    return BusVehiculo(
      id: toInt(j['id'] ?? j['id_vtr']),
      placa: (j['placa'] ?? j['placa_vtr'] ?? '').toString(),
      modeloId: toInt(j['modelo_id'] ?? j['mov_id'] ?? modelo['id'] ?? modelo['id_mov']),
      modeloNombre: (modelo['nombre'] ?? modelo['nombre_mov'] ?? 'Desconocido').toString(),
      marcaNombre: (marca['nombre'] ?? marca['nombre_mav'] ?? '').toString(),
      anio: toInt(j['anio'] ?? j['anio_vtr']),
      color: (j['color'] ?? j['color_vtr'] ?? '').toString(),
      peso: toInt(j['peso'] ?? j['peso_vtr']),
      cantidadPasajeros: toInt(j['cantidad_pasajeros'] ?? j['capacidad_pasajeros_vtr']),
      tipoCombustibleId: toInt(j['tipo_combustible_id'] ?? j['tcb_id'] ?? tipoComb['id'] ?? tipoComb['id_tcb']),
      combustibleNombre: (tipoComb['nombre'] ?? tipoComb['nombre_tcb'] ?? 'Desconocido').toString(),
      cantidadBocas: toInt(j['cantidad_cilindros'] ?? j['cantidad_cilindros_vtr']),
      capacidadTanqueLitros: toDouble(j['capacidad_tanque_litros'] ?? j['capacidad_tanque_litros_vtr']),
      consumoLitrosKm: toDouble(j['consumo_litros_km'] ?? j['consumo_urbano_vtr']),
      kmActual: toDouble(j['km_actual'] ?? j['km_actual_vtr']),
      kmProximoMantenimiento: toDouble(j['km_proximo_mantenimiento'] ?? j['km_proximo_mantenimiento_vtr']),
      conductorId: (j['conductor_id'] ?? j['conductor_use_id']) != null
          ? toInt(j['conductor_id'] ?? j['conductor_use_id'])
          : null,
      sedeId: toInt(j['sede_id'] ?? j['sed_id'] ?? sede['id'] ?? sede['id_sed']),
      sedeNombre: (sede['nombre'] ?? sede['nombre_sed'] ?? 'Matriz').toString(),
      activo: rawActivo == true || rawActivo == 1,
      estado: (j['estado'] ?? j['estado_operativo_vtr'] ?? 'disponible').toString(),
    );
  }

  BusVehiculo copyWith({
    String? placa,
    int? modeloId,
    String? modeloNombre,
    String? marcaNombre,
    int? anio,
    String? color,
    int? peso,
    int? cantidadPasajeros,
    int? tipoCombustibleId,
    String? combustibleNombre,
    int? cantidadBocas,
    double? capacidadTanqueLitros,
    double? consumoLitrosKm,
    double? kmActual,
    double? kmProximoMantenimiento,
    int? sedeId,
    String? sedeNombre,
    bool? activo,
    String? estado,
  }) {
    return BusVehiculo(
      id: id,
      placa: placa ?? this.placa,
      modeloId: modeloId ?? this.modeloId,
      modeloNombre: modeloNombre ?? this.modeloNombre,
      marcaNombre: marcaNombre ?? this.marcaNombre,
      anio: anio ?? this.anio,
      color: color ?? this.color,
      peso: peso ?? this.peso,
      cantidadPasajeros: cantidadPasajeros ?? this.cantidadPasajeros,
      tipoCombustibleId: tipoCombustibleId ?? this.tipoCombustibleId,
      combustibleNombre: combustibleNombre ?? this.combustibleNombre,
      cantidadBocas: cantidadBocas ?? this.cantidadBocas,
      capacidadTanqueLitros:
          capacidadTanqueLitros ?? this.capacidadTanqueLitros,
      consumoLitrosKm: consumoLitrosKm ?? this.consumoLitrosKm,
      kmActual: kmActual ?? this.kmActual,
      kmProximoMantenimiento:
          kmProximoMantenimiento ?? this.kmProximoMantenimiento,
      conductorId: conductorId,
      sedeId: sedeId ?? this.sedeId,
      sedeNombre: sedeNombre ?? this.sedeNombre,
      activo: activo ?? this.activo,
      estado: estado ?? this.estado,
    );
  }
}