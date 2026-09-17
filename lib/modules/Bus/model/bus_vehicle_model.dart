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
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return BusVehiculo(
      id: toInt(j['id']),
      placa: j['placa'] as String? ?? '',
      modeloId: toInt(j['modelo_id']),
      modeloNombre: j['modelo']?['nombre'] as String? ?? 'Desconocido',
      marcaNombre:
          j['modelo']?['marca']?['nombre'] as String? ??
          j['modelo']?['marca']?['nombre'] as String? ??
          '',
      anio: toInt(j['anio']),
      color: j['color'] as String? ?? '',
      peso: toInt(j['peso']),
      cantidadPasajeros: toInt(j['cantidad_pasajeros']),
      tipoCombustibleId: toInt(j['tipo_combustible_id']),
      combustibleNombre:
          j['tipo_combustible']?['nombre'] as String? ?? 'Desconocido',
      cantidadBocas: toInt(j['cantidad_cilindros']),
      capacidadTanqueLitros: toDouble(j['capacidad_tanque_litros']),
      consumoLitrosKm: toDouble(j['consumo_litros_km']),
      kmActual: toDouble(j['km_actual']),
      kmProximoMantenimiento: toDouble(j['km_proximo_mantenimiento']),
      conductorId: j['conductor_id'] != null ? toInt(j['conductor_id']) : null,
      sedeId: toInt(j['sede_id']),
      sedeNombre: j['sede']?['nombre'] as String? ?? 'Matriz',
      activo: j['activo'] == true || j['activo'] == 1,
      estado: j['estado'] as String? ?? 'disponible',
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
