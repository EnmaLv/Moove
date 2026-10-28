class BusViaje {
  final int id;
  final String? turno;
  final String estado;
  final String? fechaInicio;
  final String? vehiculoPlaca;
  final String? rutaNombre;
  final String? conductorNombre;

  const BusViaje({
    required this.id,
    this.turno,
    required this.estado,
    this.fechaInicio,
    this.vehiculoPlaca,
    this.rutaNombre,
    this.conductorNombre,
  });

  factory BusViaje.fromJson(Map<String, dynamic> j) {
    final vehiculo = (j['vehiculo'] ?? j['vehiculo_transporte'] ?? {})
        as Map<String, dynamic>;
    final ruta = (j['bus_ruta'] ??
            j['ruta_transporte'] ??
            j['ruta'] ??
            {}) as Map<String, dynamic>;
    final conductor = (j['conductor'] ?? {}) as Map<String, dynamic>;
    final persona = (conductor['persona'] ??
            conductor['usuario']?['persona'] ??
            {}) as Map<String, dynamic>;

    final rawId = j['id'] ?? j['id_vjt'];
    final rawTurno = j['turno'] ?? j['turno_vjt'];
    final rawEstado = j['estado'] ??
        j['estado_viaje'] ??
        j['estado_viaje_vjt'] ??
        'programado';
    final rawFecha = j['fecha_inicio'] ?? j['fecha_inicio_vjt'];
    final rawPlaca = vehiculo['placa'] ?? vehiculo['placa_vtr'];
    final rawRutaNombre = ruta['nombre'] ?? ruta['nombre_rtr'];
    final rawConductorNombre = persona['nombre_persona'] ??
        persona['nombres_per'] ??
        conductor['nombre'] ??
        conductor['nombre_use'];

    return BusViaje(
      id: _toInt(rawId),
      turno: rawTurno?.toString(),
      estado: rawEstado.toString(),
      fechaInicio: rawFecha?.toString(),
      vehiculoPlaca: rawPlaca?.toString(),
      rutaNombre: rawRutaNombre?.toString(),
      conductorNombre: rawConductorNombre?.toString(),
    );
  }

  bool get enCurso => estado == 'en_curso';
  bool get programado => estado == 'programado';

  static int _toInt(dynamic v) =>
      v is int ? v : int.parse(v?.toString() ?? '0');
}